import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../models/wechat_types.dart';
import 'ai_service.dart';
import 'silk_transcode_service.dart';
import 'wechat_media_service.dart';

/// 微信机器人服务
/// 负责长轮询消息、调用 AI 回复、发送消息
class WeChatBotService {
  LoginCredentials? _credentials;
  AISettings? _aiSettings;

  bool _running = false;
  String _getUpdatesBuf = '';
  int _consecutiveFailures = 0;
  Completer<void>? _abortCompleter;

  /// 会话过期暂停结束时间
  DateTime? _sessionPausedUntil;

  /// 消息日志回调
  void Function(LogEntry entry)? onLog;

  /// 状态变化回调
  void Function(bool isRunning)? onStatusChanged;

  /// 媒体文件路径回调（收到媒体时触发）
  void Function(String userId, MediaInfo media)? onMediaReceived;

  /// 消息发送钩子（发送前触发，可拦截或修改消息）
  /// 返回修改后的消息内容，返回 null 表示取消发送
  Future<String?> Function(String userId, String text, bool isPartial)? onMessageSending;

  /// 消息发送完成回调
  void Function(String userId, String text, bool success, dynamic error)? onMessageSent;

  static const int _maxConsecutiveFailures = 5;
  static const int _backoffDelayMs = 30000;
  static const int _retryDelayMs = 2000;
  static const int _apiTimeoutMs = 15000;
  static const int _longPollTimeoutMs = 35000;

  /// 会话过期错误码
  static const int _sessionExpiredErrcode = -14;

  /// 会话暂停时长（1小时）
  static const int _sessionPauseDurationMs = 60 * 60 * 1000;

  /// 每个用户的 contextToken (内存缓存)
  final Map<String, String> _contextTokens = {};

  /// ContextToken 持久化文件路径
  String? _contextTokenFilePath;

  /// 每个用户的会话历史
  final Map<String, List<Map<String, String>>> _conversationHistories = {};

  /// 每个用户的typing ticket
  final Map<String, String> _typingTickets = {};

  /// typing keepalive定时器
  final Map<String, Timer> _typingKeepaliveTimers = {};

  bool get isRunning => _running;
  LoginCredentials? get credentials => _credentials;

  /// 配置服务
  void configure({
    required LoginCredentials credentials,
    required AISettings aiSettings,
  }) {
    _credentials = credentials;
    _aiSettings = aiSettings;
    _contextTokenFilePath = _resolveContextTokenFilePath(credentials.accountId);
    _restoreContextTokens();
  }

  /// 获取 ContextToken 持久化文件路径
  String _resolveContextTokenFilePath(String accountId) {
    return p.join(
      Directory.current.path,
      'state',
      'wechat_bot',
      'accounts',
      '$accountId.context-tokens.json',
    );
  }

  /// 从文件恢复 ContextToken
  void _restoreContextTokens() {
    if (_contextTokenFilePath == null) return;
    
    final file = File(_contextTokenFilePath!);
    if (!file.existsSync()) return;

    try {
      final raw = file.readAsStringSync();
      final tokens = json.decode(raw) as Map<String, dynamic>;
      int count = 0;
      for (final entry in tokens.entries) {
        if (entry.value is String && entry.value.isNotEmpty) {
          _contextTokens[entry.key] = entry.value;
          count++;
        }
      }
      _addLog(LogLevel.info, '已恢复 $count 个 ContextToken');
    } catch (e) {
      _addLog(LogLevel.warn, '恢复 ContextToken 失败: $e');
    }
  }

  /// 持久化所有 ContextToken 到文件
  void _persistContextTokens() {
    if (_contextTokenFilePath == null || _credentials == null) return;

    try {
      final dir = Directory(p.dirname(_contextTokenFilePath!));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final file = File(_contextTokenFilePath!);
      file.writeAsStringSync(json.encode(_contextTokens));
    } catch (e) {
      _addLog(LogLevel.warn, '持久化 ContextToken 失败: $e');
    }
  }

  /// 启动机器人（长轮询循环）
  Future<void> start() async {
    if (_credentials == null || _aiSettings == null) {
      throw Exception('请先配置登录凭证和AI设置');
    }

    _running = true;
    _consecutiveFailures = 0;
    _abortCompleter = Completer<void>();
    onStatusChanged?.call(true);
    _addLog(LogLevel.info, '机器人已启动，开始监听消息...');

    // 发送启动通知
    try {
      await notifyStart(_credentials!.baseUrl, _credentials!.token);
      _addLog(LogLevel.info, '已发送启动通知');
    } catch (e) {
      _addLog(LogLevel.warn, '发送启动通知失败: $e');
    }

    while (_running) {
      try {
        // 检查会话是否暂停中
        if (_isSessionPaused()) {
          final remainingMs = _getRemainingPauseMs();
          _addLog(
            LogLevel.warn,
            '会话已过期，暂停中...剩余 ${remainingMs ~/ 60000} 分钟',
          );
          await _sleepWithAbort(remainingMs);
          if (!_running) break;
          _sessionPausedUntil = null;
          _addLog(LogLevel.info, '暂停结束，恢复轮询');
          continue;
        }

        final resp = await getUpdates(
          _credentials!.baseUrl,
          _credentials!.token,
          _getUpdatesBuf,
        );

        if (!resp.isSuccess) {
          // 检查会话过期错误码
          if (resp.errcode == _sessionExpiredErrcode ||
              resp.ret == _sessionExpiredErrcode) {
            _sessionPausedUntil = DateTime.now().add(
              const Duration(milliseconds: _sessionPauseDurationMs),
            );
            _addLog(
              LogLevel.error,
              '会话过期 (errcode=$_sessionExpiredErrcode)，暂停 1 小时',
            );
            _consecutiveFailures = 0;
            continue;
          }

          _consecutiveFailures++;
          _addLog(
            LogLevel.error,
            'getUpdates 错误: ret=${resp.ret} errcode=${resp.errcode} errmsg=${resp.errmsg}',
          );

          if (_consecutiveFailures >= _maxConsecutiveFailures) {
            _addLog(
              LogLevel.warn,
              '连续失败 $_consecutiveFailures 次，等待 ${_backoffDelayMs ~/ 1000}s 后重试',
            );
            _consecutiveFailures = 0;
            await _sleepWithAbort(_backoffDelayMs);
          } else {
            await _sleepWithAbort(_retryDelayMs);
          }
          continue;
        }

        _consecutiveFailures = 0;

        if (resp.getUpdatesBuf != null) {
          _getUpdatesBuf = resp.getUpdatesBuf!;
        }

        final messages = resp.msgs ?? [];
        for (final msg in messages) {
          await _handleMessage(msg);
        }
      } catch (err) {
        if (!_running) break;
        _consecutiveFailures++;
        _addLog(LogLevel.error, '轮询异常: $err');

        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          _consecutiveFailures = 0;
          await _sleepWithAbort(_backoffDelayMs);
        } else {
          await _sleepWithAbort(_retryDelayMs);
        }
      }
    }
    _addLog(LogLevel.info, '机器人已停止');
  }

  /// 停止机器人（优雅关闭）
  Future<void> stop() async {
    _addLog(LogLevel.info, '正在停止机器人...');
    
    _running = false;
    _stopAllTypingKeepalive();
    
    // 等待长轮询循环退出
    if (_abortCompleter != null) {
      await _abortCompleter!.future;
      _abortCompleter = null;
    }

    // 发送停止通知
    if (_credentials != null) {
      try {
        await notifyStop(_credentials!.baseUrl, _credentials!.token);
        _addLog(LogLevel.info, '已发送停止通知');
      } catch (e) {
        _addLog(LogLevel.warn, '发送停止通知失败: $e');
      }
    }

    onStatusChanged?.call(false);
    _addLog(LogLevel.info, '机器人已停止');
  }

  /// 检查会话是否暂停中
  bool _isSessionPaused() {
    if (_sessionPausedUntil == null) return false;
    if (DateTime.now().isAfter(_sessionPausedUntil!)) {
      _sessionPausedUntil = null;
      return false;
    }
    return true;
  }

  /// 获取剩余暂停时间（毫秒）
  int _getRemainingPauseMs() {
    if (_sessionPausedUntil == null) return 0;
    return _sessionPausedUntil!.difference(DateTime.now()).inMilliseconds;
  }

  /// 带中断的sleep
  Future<void> _sleepWithAbort(int ms) async {
    final completer = Completer<void>();
    final timer = Timer(Duration(milliseconds: ms), () {
      if (!completer.isCompleted) completer.complete();
    });

    _abortCompleter?.future.then((_) {
      timer.cancel();
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
  }

  /// 处理单条消息
  Future<void> _handleMessage(WeChatMessage msg) async {
    // 只处理 USER 类型的消息
    if (msg.messageType != WeChatMessageType.user) return;

    final fromUser = msg.fromUserId;
    if (fromUser == null || fromUser.isEmpty) return;

    // 调试模式计时
    final debug = _isDebugMode(fromUser);
    final debugTrace = <String>[];
    final debugTs = <String, int>{};
    final receivedAt = DateTime.now().millisecondsSinceEpoch;
    debugTs['received'] = receivedAt;

    if (debug) {
      final itemTypes = msg.itemList?.map((i) => i.type).join(',') ?? 'none';
      debugTrace.addAll([
        '── 收消息 ──',
        '│ msgId=${msg.messageId ?? "?"} from=$fromUser',
        '│ body="${_truncate(msg.itemList?.firstWhere((i) => i.type == WeChatItemType.text, orElse: () => MessageItem()).textItem?.text ?? "", 40)}"',
        '│ itemTypes=[$itemTypes] sessionId=${msg.sessionId ?? "?"}',
        '│ contextToken=${msg.contextToken != null ? "present" : "none"}',
      ]);
    }

    // 保存 contextToken
    if (msg.contextToken != null) {
      _contextTokens[fromUser] = msg.contextToken!;
      _persistContextTokens();
    }

    // 提取消息内容（文本+媒体）
    final messageContent = _extractMessageContent(msg);
    if (messageContent.text.isEmpty && messageContent.mediaFiles.isEmpty) return;

    _addLog(LogLevel.info, '收到消息 from=$fromUser: ${_truncate(messageContent.text, 100)}');

    // 触发媒体文件回调
    if (messageContent.mediaFiles.isNotEmpty) {
      for (final media in messageContent.mediaFiles) {
        onMediaReceived?.call(fromUser, media);
      }
    }

    // 处理斜杠命令
    final handled = await _handleSlashCommand(messageContent.text.trim(), fromUser, msg.createTimeMs);
    if (handled) {
      return;
    }

    // 获取typing ticket（如果没有缓存）
    if (!_typingTickets.containsKey(fromUser)) {
      try {
        final configResp = await getConfig(
          ilinkUserId: fromUser,
          contextToken: msg.contextToken,
        );
        if (configResp.typingTicket != null && configResp.typingTicket!.isNotEmpty) {
          _typingTickets[fromUser] = configResp.typingTicket!;
        }
      } catch (e) {
        _addLog(LogLevel.warn, '获取typing ticket失败: $e');
      }
    }
    if (debug) {
      debugTs['typingTicket'] = DateTime.now().millisecondsSinceEpoch;
    }

    // 开始Typing指示器
    _startTyping(fromUser);

    try {
      // 下载媒体文件（如果有）
      final mediaDownloadStart = DateTime.now().millisecondsSinceEpoch;
      final downloadedMedia = await _downloadMediaFiles(messageContent.mediaFiles, fromUser);
      final mediaDownloadMs = DateTime.now().millisecondsSinceEpoch - mediaDownloadStart;
      
      if (debug) {
        debugTs['mediaDownload'] = DateTime.now().millisecondsSinceEpoch;
        debugTrace.add('│ mediaDownload: ${messageContent.mediaFiles.isNotEmpty ? 'type=${messageContent.mediaFiles.first.type} cost=${mediaDownloadMs}ms' : 'none'}');
      }

      // 构建AI消息（包含媒体描述和本地路径）
      final aiMessage = _buildAiMessage(messageContent, downloadedMedia);

      // 调用 AI 回复（非流式）
      final aiStart = DateTime.now().millisecondsSinceEpoch;
      final history = _conversationHistories[fromUser] ?? [];
      
      // 保存用户消息到历史
      _addToHistory(fromUser, 'user', aiMessage);

      try {
        final aiReply = await AIService.sendMessage(
          settings: _aiSettings!,
          userMessage: aiMessage,
          conversationHistory: history,
        );
        final aiMs = DateTime.now().millisecondsSinceEpoch - aiStart;
        _addLog(LogLevel.info, 'AI 回复 to=$fromUser: ${_truncate(aiReply, 100)}');

        // 保存对话历史
        _addToHistory(fromUser, 'assistant', aiReply);

        // 停止Typing指示器
        _stopTyping(fromUser);

        if (aiReply.isNotEmpty) {
          final sendStart = DateTime.now().millisecondsSinceEpoch;
          
          // 发送AI回复消息给用户
          await sendTextMessage(
            _credentials!.baseUrl,
            _credentials!.token,
            fromUser,
            aiReply,
            _contextTokens[fromUser],
          );
          
          final sendMs = DateTime.now().millisecondsSinceEpoch - sendStart;

          // 调试模式：发送耗时统计
          if (debug) {
            await _sendDebugTiming(fromUser, msg, debugTrace, debugTs, aiReply.length, mediaDownloadMs, aiMs, sendMs);
          }
        }
      } catch (err) {
        _addLog(LogLevel.error, 'AI 调用失败: $err');

        // 停止Typing指示器
        _stopTyping(fromUser);

        await sendTextMessage(
          _credentials!.baseUrl,
          _credentials!.token,
          fromUser,
          _getErrorMessage(err),
          _contextTokens[fromUser],
        );
      }
    } catch (e) {
      _addLog(LogLevel.error, '消息处理失败: $e');
      _stopTyping(fromUser);
    }
  }

  /// 发送调试模式耗时统计消息
  Future<void> _sendDebugTiming(
    String userId,
    WeChatMessage msg,
    List<String> debugTrace,
    Map<String, int> debugTs,
    int replyLen,
    int mediaDownloadMs,
    int aiMs,
    int sendMs,
  ) async {
    final dispatchDoneAt = DateTime.now().millisecondsSinceEpoch;
    final eventTs = msg.createTimeMs ?? 0;
    final platformDelay = eventTs > 0 ? '${dispatchDoneAt - eventTs}ms' : 'N/A';
    final receivedAt = debugTs['received'] ?? dispatchDoneAt;
    final preDispatch = debugTs['mediaDownload'] ?? debugTs['typingTicket'] ?? receivedAt;
    final inboundProcessMs = preDispatch - receivedAt;
    final totalTime = eventTs > 0 ? '${dispatchDoneAt - eventTs}ms' : '${dispatchDoneAt - receivedAt}ms';

    debugTrace.addAll([
      '── 回复 ──',
      '│ textLen=$replyLen',
      '│ deliver耗时: ${sendMs}ms',
      '── 耗时 ──',
      '├ 平台→插件: $platformDelay',
      '├ 入站处理: ${inboundProcessMs}ms (mediaDownload: ${mediaDownloadMs}ms)',
      '├ AI生成: ${aiMs}ms',
      '├ 发送: ${sendMs}ms',
      '├ 总耗时: $totalTime',
      '└ eventTime: ${eventTs > 0 ? DateTime.fromMillisecondsSinceEpoch(eventTs).toIso8601String() : "N/A"}',
    ]);

    final timingText = '⏱ Debug 全链路\n${debugTrace.join('\n')}';

    try {
      await sendTextMessage(
        _credentials!.baseUrl,
        _credentials!.token,
        userId,
        timingText,
        _contextTokens[userId],
      );
      _addLog(LogLevel.info, '调试耗时统计已发送 to=$userId');
    } catch (e) {
      _addLog(LogLevel.error, '发送调试耗时统计失败: $e');
    }
  }

  /// 提取消息内容（文本+媒体）
  MessageContent _extractMessageContent(WeChatMessage msg) {
    final textParts = <String>[];
    final mediaFiles = <MediaInfo>[];
    final items = msg.itemList;

    if (items == null || items.isEmpty) {
      return MessageContent(text: '', mediaFiles: []);
    }

    for (final item in items) {
      if (item.type == WeChatItemType.text && item.textItem?.text != null) {
        final ref = item.refMsg;
        final text = item.textItem!.text!;
        if (ref != null) {
          final parts = <String>[];
          if (ref.title != null) parts.add(ref.title!);
          textParts.add(parts.isNotEmpty ? '[引用: ${parts.join(" | ")}]\n$text' : text);
        } else {
          textParts.add(text);
        }
      } else if (item.type == WeChatItemType.image && item.imageItem != null) {
        mediaFiles.add(MediaInfo(
          type: MediaType.image,
          cdnMedia: item.imageItem!.media,
          aesKey: item.imageItem!.aesKey,
        ));
      } else if (item.type == WeChatItemType.voice && item.voiceItem != null) {
        // 语音消息
        if (item.voiceItem!.text != null && item.voiceItem!.text!.isNotEmpty) {
          // 微信已自动转文字
          textParts.add('[语音] ${item.voiceItem!.text}');
        } else {
          // 语音未转文字，提示用户
          textParts.add('[语音消息，请发送文字或等待语音识别]');
        }
        mediaFiles.add(MediaInfo(
          type: MediaType.voice,
          cdnMedia: item.voiceItem!.media,
        ));
      } else if (item.type == WeChatItemType.video && item.videoItem != null) {
        mediaFiles.add(MediaInfo(
          type: MediaType.video,
          cdnMedia: item.videoItem!.media,
        ));
      } else if (item.type == WeChatItemType.file && item.fileItem != null) {
        mediaFiles.add(MediaInfo(
          type: MediaType.file,
          cdnMedia: item.fileItem!.media,
          fileName: item.fileItem!.fileName,
        ));
      }
    }

    return MessageContent(
      text: textParts.join('\n'),
      mediaFiles: mediaFiles,
    );
  }

  /// 下载媒体文件
  Future<List<DownloadedMedia>> _downloadMediaFiles(List<MediaInfo> mediaFiles, String fromUser) async {
    final downloaded = <DownloadedMedia>[];
    
    for (final media in mediaFiles) {
      try {
        final cdnMedia = media.cdnMedia;
        if (cdnMedia?.encryptQueryParam == null || cdnMedia?.encryptQueryParam?.isEmpty == true) {
          _addLog(LogLevel.warn, '媒体文件缺少加密参数，跳过');
          continue;
        }

        String? filePath;
        
        if (media.type == MediaType.image) {
          // 图片需要解密
          if (media.aesKey != null) {
            final data = await WeChatMediaService.downloadAndDecrypt(
              encryptedQueryParam: cdnMedia!.encryptQueryParam!,
              aesKeyBase64: media.aesKey!,
              label: 'image',
            );
            filePath = await WeChatMediaService.saveMediaToFile(
              data: data,
              subdir: 'images',
              extension: '.png',
            );
          }
        } else if (media.type == MediaType.voice) {
          // 语音下载（只需要 encryptQueryParam）
          if (cdnMedia!.encryptQueryParam != null && cdnMedia.encryptQueryParam!.isNotEmpty) {
            final data = await WeChatMediaService.downloadPlain(
              encryptedQueryParam: cdnMedia.encryptQueryParam!,
              fullUrl: cdnMedia.fullUrl,
              label: 'voice',
            );
            
            // 尝试将 SILK 转码为 WAV
            final wavData = await SilkTranscodeService.silkToWav(data);
            if (wavData != null) {
              filePath = await WeChatMediaService.saveMediaToFile(
                data: wavData,
                subdir: 'voice',
                extension: '.wav',
              );
              _addLog(LogLevel.info, '语音转码成功: $filePath');
            } else {
              // 转码失败，保存原始 SILK 文件
              filePath = await WeChatMediaService.saveMediaToFile(
                data: data,
                subdir: 'voice',
                extension: '.silk',
              );
              _addLog(LogLevel.warn, '语音转码失败，保存原始 SILK: $filePath');
            }
          } else {
            _addLog(LogLevel.warn, '语音文件缺少下载参数，跳过');
          }
        } else if (media.type == MediaType.video) {
          // 视频需要解密
          if (cdnMedia!.fullUrl != null && cdnMedia.fullUrl!.isNotEmpty) {
            final data = await WeChatMediaService.downloadPlain(
              encryptedQueryParam: cdnMedia.encryptQueryParam!,
              fullUrl: cdnMedia.fullUrl,
              label: 'video',
            );
            filePath = await WeChatMediaService.saveMediaToFile(
              data: data,
              subdir: 'videos',
              extension: '.mp4',
            );
          }
        } else if (media.type == MediaType.file) {
          // 文件需要解密
          if (cdnMedia!.fullUrl != null && cdnMedia.fullUrl!.isNotEmpty) {
            final data = await WeChatMediaService.downloadPlain(
              encryptedQueryParam: cdnMedia.encryptQueryParam!,
              fullUrl: cdnMedia.fullUrl,
              label: 'file',
            );
            filePath = await WeChatMediaService.saveMediaToFile(
              data: data,
              subdir: 'files',
              filename: media.fileName,
            );
          }
        }

        if (filePath != null) {
          downloaded.add(DownloadedMedia(
            type: media.type,
            filePath: filePath,
            fileName: media.fileName,
          ));
          _addLog(LogLevel.info, '媒体文件下载成功: $filePath');
          
          // 触发媒体接收回调
          onMediaReceived?.call(fromUser, MediaInfo(
            type: media.type,
            cdnMedia: media.cdnMedia,
            aesKey: media.aesKey,
            fileName: media.fileName,
          ));
        }
      } catch (e) {
        _addLog(LogLevel.error, '媒体文件下载失败: $e');
      }
    }
    
    return downloaded;
  }

  /// 构建AI消息（包含媒体描述和本地路径）
  String _buildAiMessage(MessageContent content, [List<DownloadedMedia> downloadedMedia = const []]) {
    final parts = <String>[];
    if (content.text.isNotEmpty) {
      parts.add(content.text);
    }
    
    // 添加下载的媒体文件路径（用于AI分析）
    if (downloadedMedia.isNotEmpty) {
      final mediaPaths = downloadedMedia.map((m) {
        final typeStr = m.type == MediaType.image ? '图片' : 
                        m.type == MediaType.voice ? '语音' : 
                        m.type == MediaType.video ? '视频' : '文件';
        return '[$typeStr: ${m.filePath}]';
      }).join(' ');
      parts.add(mediaPaths);
    } else if (content.mediaFiles.isNotEmpty) {
      // 如果没有下载成功，只显示媒体类型描述
      final mediaDesc = content.mediaFiles.map((m) {
        switch (m.type) {
          case MediaType.image:
            return '[图片]';
          case MediaType.voice:
            return '[语音]';
          case MediaType.video:
            return '[视频]';
          case MediaType.file:
            return '[文件: ${m.fileName ?? "未知"}]';
        }
      }).join(' ');
      parts.add(mediaDesc);
    }
    
    return parts.join('\n');
  }

  /// 添加到对话历史
  void _addToHistory(String userId, String role, String content) {
    final history = _conversationHistories[userId] ?? [];
    history.add({'role': role, 'content': content});

    // 限制历史记录长度（保留最近20条）
    if (history.length > 20) {
      _conversationHistories[userId] = history.sublist(history.length - 20);
    } else {
      _conversationHistories[userId] = history;
    }
  }

  // ========== API 请求方法 ==========

  /// 生成随机的 X-WECHAT-UIN
  static String _randomWechatUin() {
    final random = Random();
    final uint32 = random.nextInt(0xFFFFFFFF);
    return base64.encode(uint32.toString().codeUnits);
  }

  /// 构建请求头
  static Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'AuthorizationType': 'ilink_bot_token',
      'X-WECHAT-UIN': _randomWechatUin(),
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 通用 API POST 请求
  static Future<T> _apiPost<T>({
    required String baseUrl,
    required String endpoint,
    required Map<String, dynamic> body,
    String? token,
    int timeoutMs = _apiTimeoutMs,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final url = baseUrl.endsWith('/')
        ? '$baseUrl$endpoint'
        : '$baseUrl/$endpoint';

    final bodyStr = json.encode(body);
    final headers = _buildHeaders(token: token);
    headers['Content-Length'] = utf8.encode(bodyStr).length.toString();

    final uri = Uri.parse(url);
    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: utf8.encode(bodyStr),
          )
          .timeout(Duration(milliseconds: timeoutMs));

      if (response.statusCode != 200) {
        throw Exception(
            'API $endpoint responded ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
      }

      return fromJson(
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on TimeoutException {
      rethrow;
    }
  }

  /// 长轮询获取消息
  Future<GetUpdatesResponse> getUpdates(
    String baseUrl,
    String token,
    String buf, {
    int timeoutMs = _longPollTimeoutMs,
  }) async {
    try {
      return await _apiPost<GetUpdatesResponse>(
        baseUrl: baseUrl,
        endpoint: 'ilink/bot/getupdates',
        body: {'get_updates_buf': buf},
        token: token,
        timeoutMs: timeoutMs,
        fromJson: (data) => GetUpdatesResponse.fromJson(data),
      );
    } on TimeoutException {
      return GetUpdatesResponse(
        ret: 0,
        msgs: [],
        getUpdatesBuf: buf,
      );
    }
  }

  /// 发送启动通知
  Future<void> notifyStart(String baseUrl, String token) async {
    await _apiPost<Map<String, dynamic>>(
      baseUrl: baseUrl,
      endpoint: 'ilink/bot/msg/notifystart',
      body: {},
      token: token,
      fromJson: (data) => data,
    );
  }

  /// 发送停止通知
  Future<void> notifyStop(String baseUrl, String token) async {
    await _apiPost<Map<String, dynamic>>(
      baseUrl: baseUrl,
      endpoint: 'ilink/bot/msg/notifystop',
      body: {},
      token: token,
      fromJson: (data) => data,
    );
  }

  /// 获取用户配置（包含typing_ticket）
  Future<GetConfigResponse> getConfig({
    required String ilinkUserId,
    String? contextToken,
  }) async {
    try {
      return await _apiPost<GetConfigResponse>(
        baseUrl: _credentials!.baseUrl,
        endpoint: 'ilink/bot/getconfig',
        body: {
          'ilink_user_id': ilinkUserId,
          if (contextToken != null) 'context_token': contextToken,
        },
        token: _credentials!.token,
        fromJson: (data) => GetConfigResponse.fromJson(data),
      );
    } catch (e) {
      _addLog(LogLevel.warn, '获取配置失败: $e');
      return GetConfigResponse(ret: -1, errmsg: e.toString());
    }
  }

  /// 发送Typing指示器
  Future<void> sendTyping({
    required String userId,
    required int status,
  }) async {
    String? ticket = _typingTickets[userId];
    
    if (ticket == null || ticket.isEmpty) {
      _addLog(LogLevel.info, '用户 $userId 没有typing ticket，尝试获取');
      try {
        final configResp = await getConfig(
          ilinkUserId: userId,
          contextToken: _contextTokens[userId],
        );
        if (configResp.typingTicket != null && configResp.typingTicket!.isNotEmpty) {
          ticket = configResp.typingTicket!;
          _typingTickets[userId] = ticket;
          _addLog(LogLevel.info, '用户 $userId 获取typing ticket成功');
        } else {
          _addLog(LogLevel.warn, '用户 $userId 获取typing ticket失败: ${configResp.errmsg ?? "ticket为空"}');
          return;
        }
      } catch (e) {
        _addLog(LogLevel.warn, '用户 $userId 获取typing ticket异常: $e');
        return;
      }
    }

    try {
      await _apiPost<SendTypingResponse>(
        baseUrl: _credentials!.baseUrl,
        endpoint: 'ilink/bot/sendtyping',
        body: {
          'ilink_user_id': userId,
          'typing_ticket': ticket,
          'status': status,
        },
        token: _credentials!.token,
        fromJson: (data) => SendTypingResponse.fromJson(data),
      );
    } catch (e) {
      _addLog(LogLevel.warn, '发送Typing失败: $e');
      _typingTickets.remove(userId);
    }
  }

  /// 开始Typing指示器（带keepalive）
  void _startTyping(String userId) {
    // 先停止之前的keepalive
    _stopTypingKeepalive(userId);

    // 发送开始typing
    sendTyping(userId: userId, status: WeChatTypingStatus.typing);

    // 启动keepalive定时器（每5秒发送一次）
    _typingKeepaliveTimers[userId] = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (_running) {
          sendTyping(userId: userId, status: WeChatTypingStatus.typing);
        }
      },
    );
  }

  /// 停止Typing指示器
  void _stopTyping(String userId) {
    _stopTypingKeepalive(userId);
    sendTyping(userId: userId, status: WeChatTypingStatus.cancel);
  }

  /// 停止Typing keepalive定时器
  void _stopTypingKeepalive(String userId) {
    _typingKeepaliveTimers[userId]?.cancel();
    _typingKeepaliveTimers.remove(userId);
  }

  /// 停止所有Typing keepalive定时器
  void _stopAllTypingKeepalive() {
    for (final timer in _typingKeepaliveTimers.values) {
      timer.cancel();
    }
    _typingKeepaliveTimers.clear();
  }

  /// 发送文本消息（带钩子）
  Future<void> sendTextMessageWithHook(
    String baseUrl,
    String token,
    String to,
    String text,
    String? contextToken, {
    bool isPartial = false,
  }) async {
    // 触发消息发送钩子
    String? finalText = text;
    if (onMessageSending != null) {
      finalText = await onMessageSending!(to, text, isPartial);
    }

    // 如果钩子返回 null，取消发送
    if (finalText == null || finalText.isEmpty) {
      _addLog(LogLevel.info, '消息发送被钩子取消 to=$to');
      return;
    }

    try {
      await sendTextMessage(baseUrl, token, to, finalText, contextToken);
      onMessageSent?.call(to, finalText, true, null);
    } catch (error) {
      onMessageSent?.call(to, finalText, false, error);
      rethrow;
    }
  }

  /// 发送文本消息
  Future<void> sendTextMessage(
    String baseUrl,
    String token,
    String to,
    String text,
    String? contextToken,
  ) async {
    final clientId =
        'bot-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999).toString().padLeft(6, '0')}';

    final items = <MessageItem>[
      MessageItem(
        type: WeChatItemType.text,
        textItem: TextItem(text: text),
      ),
    ];

    final msg = WeChatMessage(
      fromUserId: '',
      toUserId: to,
      clientId: clientId,
      messageType: WeChatMessageType.bot,
      messageState: WeChatMessageState.finish,
      itemList: items,
      contextToken: contextToken,
    );

    await _apiPost<Map<String, dynamic>>(
      baseUrl: baseUrl,
      endpoint: 'ilink/bot/sendmessage',
      body: {'msg': msg.toJson()},
      token: token,
      fromJson: (data) => data,
    );
  }

  /// 发送图片消息
  Future<void> sendImageMessage({
    required String to,
    required String filePath,
    String text = '',
    String? contextToken,
  }) async {
    try {
      final uploaded = await WeChatMediaService.uploadFileToCdn(
        filePath: filePath,
        toUserId: to,
        baseUrl: _credentials!.baseUrl,
        token: _credentials!.token,
        mediaType: WeChatUploadMediaType.image,
      );

      final imageItem = {
        'type': WeChatItemType.image,
        'image_item': {
          'media': {
            'encrypt_query_param': uploaded.downloadEncryptedQueryParam,
            'aes_key': base64.encode(utf8.encode(uploaded.aeskey)),
            'encrypt_type': 1,
          },
          'mid_size': uploaded.fileSizeCiphertext,
        },
      };

      final items = <Map<String, dynamic>>[];
      if (text.isNotEmpty) {
        items.add({
          'type': WeChatItemType.text,
          'text_item': {'text': text},
        });
      }
      items.add(imageItem);

      await _sendMessage(to, items, contextToken);
      _addLog(LogLevel.info, '图片消息发送成功 to=$to');
    } catch (err) {
      _addLog(LogLevel.error, '发送图片失败: $err');
      rethrow;
    }
  }

  /// 发送视频消息
  Future<void> sendVideoMessage({
    required String to,
    required String filePath,
    String text = '',
    String? contextToken,
  }) async {
    try {
      final uploaded = await WeChatMediaService.uploadFileToCdn(
        filePath: filePath,
        toUserId: to,
        baseUrl: _credentials!.baseUrl,
        token: _credentials!.token,
        mediaType: WeChatUploadMediaType.video,
      );

      final videoItem = {
        'type': WeChatItemType.video,
        'video_item': {
          'media': {
            'encrypt_query_param': uploaded.downloadEncryptedQueryParam,
            'aes_key': base64.encode(utf8.encode(uploaded.aeskey)),
            'encrypt_type': 1,
          },
          'video_size': uploaded.fileSizeCiphertext,
        },
      };

      final items = <Map<String, dynamic>>[];
      if (text.isNotEmpty) {
        items.add({
          'type': WeChatItemType.text,
          'text_item': {'text': text},
        });
      }
      items.add(videoItem);

      await _sendMessage(to, items, contextToken);
      _addLog(LogLevel.info, '视频消息发送成功 to=$to');
    } catch (err) {
      _addLog(LogLevel.error, '发送视频失败: $err');
      rethrow;
    }
  }

  /// 发送文件消息
  Future<void> sendFileMessage({
    required String to,
    required String filePath,
    String text = '',
    String? contextToken,
  }) async {
    try {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;

      final uploaded = await WeChatMediaService.uploadFileToCdn(
        filePath: filePath,
        toUserId: to,
        baseUrl: _credentials!.baseUrl,
        token: _credentials!.token,
        mediaType: WeChatUploadMediaType.file,
      );

      final fileItem = {
        'type': WeChatItemType.file,
        'file_item': {
          'media': {
            'encrypt_query_param': uploaded.downloadEncryptedQueryParam,
            'aes_key': base64.encode(utf8.encode(uploaded.aeskey)),
            'encrypt_type': 1,
          },
          'file_name': fileName,
          'len': uploaded.fileSize.toString(),
        },
      };

      final items = <Map<String, dynamic>>[];
      if (text.isNotEmpty) {
        items.add({
          'type': WeChatItemType.text,
          'text_item': {'text': text},
        });
      }
      items.add(fileItem);

      await _sendMessage(to, items, contextToken);
      _addLog(LogLevel.info, '文件消息发送成功 to=$to');
    } catch (err) {
      _addLog(LogLevel.error, '发送文件失败: $err');
      rethrow;
    }
  }

  /// 发送媒体文件（根据MIME类型自动路由）
  Future<void> sendMediaFile({
    required String to,
    required String filePath,
    String text = '',
    String? contextToken,
  }) async {
    final ext = filePath.split('.').last.toLowerCase();

    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      await sendVideoMessage(to: to, filePath: filePath, text: text, contextToken: contextToken);
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      await sendImageMessage(to: to, filePath: filePath, text: text, contextToken: contextToken);
    } else {
      await sendFileMessage(to: to, filePath: filePath, text: text, contextToken: contextToken);
    }
  }

  /// 发送错误通知消息
  /// 用于向用户发送错误提示信息（fire-and-forget，不影响主流程）
  Future<void> sendErrorNotice({
    required String to,
    required String message,
    String? contextToken,
  }) async {
    if (_credentials == null) return;

    try {
      await sendTextMessage(
        _credentials!.baseUrl,
        _credentials!.token,
        to,
        message,
        contextToken,
      );
      _addLog(LogLevel.info, '错误通知已发送 to=$to');
    } catch (e) {
      _addLog(LogLevel.warn, '发送错误通知失败 to=$to: $e');
    }
  }

  /// 内部发送消息方法
  Future<void> _sendMessage(
    String to,
    List<Map<String, dynamic>> items,
    String? contextToken,
  ) async {
    final clientId = _generateClientId();

    final msg = {
      'from_user_id': '',
      'to_user_id': to,
      'client_id': clientId,
      'message_type': WeChatMessageType.bot,
      'message_state': WeChatMessageState.finish,
      'item_list': items,
      if (contextToken != null) 'context_token': contextToken,
    };

    await _apiPost<Map<String, dynamic>>(
      baseUrl: _credentials!.baseUrl,
      endpoint: 'ilink/bot/sendmessage',
      body: {'msg': msg},
      token: _credentials!.token,
      fromJson: (data) => data,
    );
  }

  /// 生成客户端ID
  String _generateClientId() {
    return 'bot-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999).toString().padLeft(6, '0')}';
  }

  /// 从消息中提取文本内容（兼容旧接口）
  static String extractTextFromMessage(WeChatMessage msg) {
    final items = msg.itemList;
    if (items == null || items.isEmpty) return '';

    for (final item in items) {
      if (item.type == WeChatItemType.text && item.textItem?.text != null) {
        final ref = item.refMsg;
        final text = item.textItem!.text!;
        if (ref == null) return text;

        final parts = <String>[];
        if (ref.title != null) parts.add(ref.title!);
        return parts.isNotEmpty ? '[引用: ${parts.join(" | ")}]\n$text' : text;
      }
    }
    return '';
  }

  // ========== 辅助方法 ==========

  void _addLog(LogLevel level, String message) {
    onLog?.call(LogEntry(level: level, message: message));
  }

  static String _truncate(String s, int maxLen) {
    return s.length <= maxLen ? s : '${s.substring(0, maxLen)}...';
  }

  /// 调试模式状态（按用户存储）
  final Map<String, bool> _debugMode = {};

  /// 检查用户是否开启调试模式
  bool _isDebugMode(String userId) {
    return _debugMode[userId] ?? false;
  }

  /// 切换用户调试模式
  bool _toggleDebugMode(String userId) {
    _debugMode[userId] = !(_debugMode[userId] ?? false);
    return _debugMode[userId]!;
  }

  /// 处理斜杠命令
  Future<bool> _handleSlashCommand(String command, String userId, int? eventTimeMs) async {
    if (!command.startsWith('/')) {
      return false;
    }

    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    _addLog(LogLevel.info, '收到斜杠命令: $cmd, 参数: ${args.isNotEmpty ? args : '无'}');

    try {
      switch (cmd) {
        case '/clear':
          await _handleClearCommand(userId);
          return true;
        case '/echo':
          await _handleEchoCommand(userId, args, eventTimeMs);
          return true;
        case '/debug':
          await _handleDebugCommand(userId);
          return true;
        case '/info':
          await _handleInfoCommand(userId);
          return true;
        case '/history':
          await _handleHistoryCommand(userId);
          return true;
        case '/help':
          await _handleHelpCommand(userId);
          return true;
        default:
          return false;
      }
    } catch (e) {
      _addLog(LogLevel.error, '斜杠命令执行失败: $e');
      await sendTextMessage(
        _credentials!.baseUrl,
        _credentials!.token,
        userId,
        '❌ 命令执行失败: ${e.toString().substring(0, 200)}',
        _contextTokens[userId],
      );
      return true;
    }
  }

  /// 处理 /clear 命令 - 重置对话历史
  Future<void> _handleClearCommand(String userId) async {
    _conversationHistories.remove(userId);
    await sendTextMessage(
      _credentials!.baseUrl,
      _credentials!.token,
      userId,
      '对话已重置 ✅',
      _contextTokens[userId],
    );
    _addLog(LogLevel.info, '已重置用户 $userId 的对话');
  }

  /// 处理 /echo 命令 - 回显消息并显示耗时统计
  Future<void> _handleEchoCommand(String userId, String args, int? eventTimeMs) async {
    final receivedAt = DateTime.now().millisecondsSinceEpoch;
    
    if (args.isNotEmpty) {
      await sendTextMessage(
        _credentials!.baseUrl,
        _credentials!.token,
        userId,
        args,
        _contextTokens[userId],
      );
    }

    final eventTs = eventTimeMs ?? 0;
    final platformDelay = eventTs > 0 ? '${receivedAt - eventTs}ms' : 'N/A';
    final timing = [
      '⏱ 通道耗时',
      '├ 事件时间: ${eventTs > 0 ? DateTime.fromMillisecondsSinceEpoch(eventTs).toIso8601String() : "N/A"}',
      '├ 平台→插件: $platformDelay',
      '└ 插件处理: ${DateTime.now().millisecondsSinceEpoch - receivedAt}ms',
    ].join('\n');

    await sendTextMessage(
      _credentials!.baseUrl,
      _credentials!.token,
      userId,
      timing,
      _contextTokens[userId],
    );
  }

  /// 处理 /debug 命令 - 切换调试模式
  Future<void> _handleDebugCommand(String userId) async {
    final enabled = _toggleDebugMode(userId);
    final status = enabled ? '开启' : '关闭';
    await sendTextMessage(
      _credentials!.baseUrl,
      _credentials!.token,
      userId,
      'Debug 模式已$status ${enabled ? '🔧' : '🔒'}',
      _contextTokens[userId],
    );
    _addLog(LogLevel.info, '用户 $userId 的调试模式已$status');
  }

  /// 处理 /help 命令 - 显示帮助信息
  Future<void> _handleHelpCommand(String userId) async {
    final helpText = [
      '🤖 微信 AI 机器人命令帮助',
      '',
      '可用命令:',
      '  /clear          - 重置对话历史',
      '  /echo [消息]    - 回显消息并显示通道耗时',
      '  /debug          - 切换调试模式',
      '  /info           - 显示系统综合信息',
      '  /history        - 显示对话历史',
      '  /help           - 显示此帮助信息',
      '',
      '调试模式开启后，每次AI回复会附带全链路耗时统计。',
    ].join('\n');

    await sendTextMessage(
      _credentials!.baseUrl,
      _credentials!.token,
      userId,
      helpText,
      _contextTokens[userId],
    );
  }

  /// 处理 /info 命令 - 显示综合信息（模型/Token/系统/余额）
  Future<void> _handleInfoCommand(String userId) async {
    final lines = <String>['📋 系统综合信息', ''];

    // 系统信息
    final now = DateTime.now();
    final uptime = _running ? '运行中' : '已停止';
    final history = _conversationHistories[userId] ?? [];
    lines.addAll([
      '🖥 系统状态',
      '  机器人: $uptime',
      '  时间: ${now.toIso8601String()}',
      '  对话: ${history.length} 条',
      if (_sessionPausedUntil != null) '  会话: 暂停中',
      '',
    ]);

    // AI 模型信息
    if (_aiSettings != null && _aiSettings!.isValid) {
      lines.addAll([
        '🤖 AI 模型',
        '  Provider: ${_aiSettings!.provider}',
        '  Model: ${_aiSettings!.model}',
        '  Base URL: ${_aiSettings!.effectiveBaseUrl}',
        '',
      ]);
    } else {
      lines.addAll(['🤖 AI 模型', '  ⚠️ 未配置', '']);
    }

    // Token 信息
    if (_credentials != null) {
      lines.addAll([
        '🔑 Token',
        '  AccountID: ${_credentials!.accountId}',
        '  Token: ${_credentials!.token}',
        '',
      ]);
    }

    // 余额信息
    if (_aiSettings != null && _aiSettings!.isValid) {
      try {
        final balance = await AIService.getBalance(_aiSettings!);
        if (balance != null) {
          lines.add('💰 余额');
          if (balance['balance_infos'] != null) {
            final balanceInfos = balance['balance_infos'] as List<dynamic>;
            for (final info in balanceInfos) {
              lines.addAll([
                '  货币: ${info['currency'] ?? 'CNY'}',
                '  总余额: ${info['total_balance'] ?? '0'}',
                '  赠送余额: ${info['granted_balance'] ?? '0'}',
                '  充值余额: ${info['topped_up_balance'] ?? '0'}',
              ]);
            }
          } else if (balance['data'] != null) {
            final data = balance['data'] as Map<String, dynamic>;
            lines.addAll([
              '  总余额: ${data['total'] ?? 'N/A'}',
              '  已使用: ${data['used'] ?? 'N/A'}',
            ]);
          } else {
            lines.add('  ${balance.toString()}');
          }
        }
      } catch (_) {
        // 余额查询失败，忽略
      }
    }

    await sendTextMessage(
      _credentials!.baseUrl,
      _credentials!.token,
      userId,
      lines.join('\n'),
      _contextTokens[userId],
    );
  }

  /// 处理 /history 命令 - 显示对话历史
  Future<void> _handleHistoryCommand(String userId) async {
    final history = _conversationHistories[userId] ?? [];
    if (history.isEmpty) {
      await sendTextMessage(
        _credentials!.baseUrl,
        _credentials!.token,
        userId,
        '📜 对话历史为空',
        _contextTokens[userId],
      );
      return;
    }

    final lines = <String>['📜 对话历史 (共 ${history.length} 条):', ''];
    for (int i = 0; i < history.length; i++) {
      final msg = history[i];
      final role = msg['role'] == 'user' ? '👤' : '🤖';
      final content = msg['content'] ?? '';
      lines.add('$role #${i + 1}: $content');
    }

    await sendTextMessage(
      _credentials!.baseUrl,
      _credentials!.token,
      userId,
      lines.join('\n'),
      _contextTokens[userId],
    );
  }

  /// 获取错误消息（根据错误类型返回友好提示）
  String _getErrorMessage(dynamic err) {
    final errStr = err.toString();
    
    if (errStr.contains('API密钥无效')) {
      return '⚠️ API密钥无效，请检查AI设置';
    } else if (errStr.contains('请求过于频繁')) {
      return '⚠️ 请求过于频繁，请稍后再试';
    } else if (errStr.contains('服务器内部错误')) {
      return '⚠️ 服务器内部错误，请稍后重试';
    } else if (errStr.contains('网络错误') || errStr.contains('SocketException')) {
      return '⚠️ 网络连接失败，请检查网络状态';
    } else if (errStr.contains('Timeout')) {
      return '⚠️ 请求超时，请稍后重试';
    } else if (errStr.contains('401')) {
      return '⚠️ 身份认证失败，请重新登录';
    } else if (errStr.contains('403')) {
      return '⚠️ 访问被拒绝，权限不足';
    } else if (errStr.contains('429')) {
      return '⚠️ 请求次数超限，请稍后再试';
    } else if (errStr.contains('500') || errStr.contains('502') || errStr.contains('503')) {
      return '⚠️ 服务器暂时不可用，请稍后重试';
    } else if (errStr.contains('媒体文件下载失败')) {
      return '⚠️ 媒体文件下载失败，请检查链接是否可访问';
    } else if (errStr.contains('CDN upload')) {
      return '⚠️ 媒体文件上传失败，请稍后重试';
    } else {
      return '抱歉，AI 暂时无法回复，请稍后再试。';
    }
  }

}


/// 媒体类型
enum MediaType { image, voice, video, file }

/// 媒体信息
class MediaInfo {
  final MediaType type;
  final CDNMedia? cdnMedia;
  final String? aesKey;
  final String? fileName;

  MediaInfo({
    required this.type,
    this.cdnMedia,
    this.aesKey,
    this.fileName,
  });
}

/// 消息内容（文本+媒体）
class MessageContent {
  final String text;
  final List<MediaInfo> mediaFiles;

  MessageContent({
    required this.text,
    required this.mediaFiles,
  });
}

/// 已下载的媒体文件信息
class DownloadedMedia {
  final MediaType type;
  final String filePath;
  final String? fileName;

  DownloadedMedia({
    required this.type,
    required this.filePath,
    this.fileName,
  });
}

/// 日志等级
enum LogLevel { info, warn, error }

/// 日志条目
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formatted {
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final levelStr = level == LogLevel.error
        ? 'ERR'
        : level == LogLevel.warn
            ? 'WRN'
            : 'INF';
    return '[$time][$levelStr] $message';
  }
}