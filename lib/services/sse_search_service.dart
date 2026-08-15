import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/app_regex.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';
import '../models/search_result.dart';
import '../models/search_resource.dart';
import 'user_data_service.dart';
import 'api_service.dart';
import 'content_filter_service.dart';
import 'downstream_service.dart';


/// SSE 搜索服务
class SSESearchService {
  http.Client? _client;
  StreamSubscription? _subscription;
  StreamController<List<SearchResult>>? _incrementalResultsController;
  StreamController<String>? _errorController;
  StreamController<SearchProgress>? _progressController;

  bool _isConnected = false;
  String? _currentQuery;
  final Map<String, String> _sourceErrors = {};
  String _buffer = ''; // 用于缓冲不完整的 UTF-8 字符
  int _completedSources = 0; // 跟踪完成的源数量
  int _totalSources = 0; // 总源数量
  Timer? _timeoutTimer; // 超时定时器

  /// 获取增量结果流
  Stream<List<SearchResult>> get incrementalResultsStream =>
      _incrementalResultsController?.stream ?? const Stream.empty();

  /// 获取错误流
  Stream<String> get errorStream =>
      _errorController?.stream ?? const Stream.empty();

  /// 获取进度流
  Stream<SearchProgress> get progressStream =>
      _progressController?.stream ?? const Stream.empty();

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 当前搜索查询
  String? get currentQuery => _currentQuery;

  /// 本地搜索
  Future<void> localSearch(String query) async {
    try {
      // 获取搜索资源列表
      final allResources = await ApiService.getSearchResources();

      // 过滤掉被禁用的资源
      final resources =
          allResources.where((resource) => !resource.disabled).toList();

      if (resources.isEmpty) {
        _errorController?.add(AppStrings.sseNoAvailableResources);
        _isConnected = false;
        return;
      }

      _totalSources = resources.length;
      _completedSources = 0;

      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: 0,
        currentSource: null,
        isComplete: false,
      ));

      // 并发调用所有资源的搜索，每个调用增加 20 秒超时
      final searchFutures = resources.map((resource) {
        return _searchSingleResource(resource, query);
      }).toList();

      // 等待所有搜索完成
      await Future.wait(searchFutures);

      // 发送完成事件
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _totalSources,
        currentSource: null,
        isComplete: true,
      ));

      _isConnected = false;
    } catch (e) {
      _errorController?.add('${AppStrings.sseLocalSearchError}');
      _isConnected = false;
    }
  }

  /// 搜索单个资源
  Future<void> _searchSingleResource(
      SearchResource resource, String query) async {
    try {
      // 调用 searchFromApi 并设置 20 秒超时
      final results = await DownstreamService.searchFromApi(resource, query)
          .timeout(AppDurations.networkTimeout);

      // 增加完成计数
      _completedSources++;

      // 发送结果事件
      if (results.isNotEmpty) {
        _incrementalResultsController?.add(results);
      }

      // 发送进度更新
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: resource.name,
        isComplete: false,
      ));
    } on TimeoutException {
      // 超时处理
      _completedSources++;
      _sourceErrors[resource.key] = AppStrings.sseSearchTimeout20;

      // 发送错误进度更新
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: resource.name,
        isComplete: false,
        error: AppStrings.sseSearchTimeout20,
      ));
    } catch (e) {
      // 其他错误处理
      _completedSources++;
      _sourceErrors[resource.key] = AppStrings.networkError;

      // 发送错误进度更新
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: resource.name,
        isComplete: false,
        error: AppStrings.networkError,
      ));
    }
  }

  /// 开始搜索
  Future<void> startSearch(String query) async {
    if (query.trim().isEmpty) {
      throw Exception(AppStrings.sseEmptyQuery);
    }

    // 如果已有连接，先关闭
    if (_isConnected) {
      await stopSearch();
    }

    // 关闭之前的流控制器
    await _incrementalResultsController?.close();
    await _errorController?.close();
    await _progressController?.close();

    _currentQuery = query.trim();
    _sourceErrors.clear();
    _completedSources = 0;

    // 初始化流控制器
    _incrementalResultsController =
        StreamController<List<SearchResult>>.broadcast();
    _errorController = StreamController<String>.broadcast();
    _progressController = StreamController<SearchProgress>.broadcast();

    _isConnected = true;

    // 设置15秒超时定时器
    _timeoutTimer = Timer(AppDurations.mediumTimeout, () {
      if (_isConnected) {
        _handleTimeout();
      }
    });



    final isLocalSearch = await UserDataService.getLocalSearch();
    if (isLocalSearch) {
      localSearch(query);
      return;
    }

    try {
      // 获取服务器地址和认证信息
      final baseUrl = await UserDataService.getServerUrlWithDefault();
      // 确保使用HTTPS
      final secureBaseUrl = baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), 'https://');

      // 优先使用令牌认证
      final authToken = await UserDataService.getAuthToken();
      final cookies = await UserDataService.getCookies();

      if (authToken == null && cookies == null) {
        throw Exception(AppStrings.sseUserNotLoggedIn);
      }

      // 构建 SSE URL
      final baseUri = Uri.parse(secureBaseUrl);
      final sseUri = baseUri.replace(
        path: '${AppConfig.searchEndpoint}/ws',
        queryParameters: {
          'q': _currentQuery!,
        },
      );

      // 创建 HTTP 客户端并开始 SSE 连接
      _client = http.Client();
      final request = http.Request('GET', sseUri);
      final headers = <String, String>{
        AppConfig.headerAccept: AppConfig.headerAcceptEventStream,
        'Cache-Control': AppConfig.headerCacheControlNoCache,
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers[AppConfig.headerAuthorization] = '${AppStrings.authorizationBearer}$authToken';
      }
      if (cookies != null && cookies.isNotEmpty) {
        headers[AppConfig.headerCookie] = cookies;
      }

      request.headers.addAll(headers);

      _subscription = _client!.send(request).asStream().listen(
        _handleSSEResponse,
        onError: (error) {
          // 静默处理连接关闭错误，不显示给用户
          final errorString = error.toString().toLowerCase();
          if (errorString.contains(AppConfig.searchErrorConnectionClosed) ||
              errorString.contains(AppConfig.searchErrorClientException) ||
              errorString.contains(AppConfig.searchErrorConnectionTerminated)) {
            // 连接被关闭，这是正常情况，静默处理
            return;
          }
          _handleError(error);
        },
        onDone: _handleDone,
      );
    } catch (e) {
      _isConnected = false;

      // 检查是否是连接关闭错误，如果是则静默处理
      final errorString = e.toString().toLowerCase();
      if (errorString.contains(AppConfig.searchErrorConnectionClosed) ||
          errorString.contains(AppConfig.searchErrorClientException) ||
          errorString.contains(AppConfig.searchErrorConnectionTerminated)) {
        // 连接被关闭，这是正常情况，静默处理
        return;
      }

      _errorController?.add('${AppStrings.sseConnectionFailed}');
      rethrow;
    }
  }

  /// 处理 SSE 响应
  Future<void> _handleSSEResponse(http.StreamedResponse response) async {
    if (response.statusCode != 200) {
      _errorController?.add('${AppStrings.sseConnectionFailedStatus}${response.statusCode}');
      return;
    }

    // 重置缓冲区
    _buffer = '';

    // 使用流式 UTF-8 解码器，自动处理跨 chunk 的多字节字符
    const utf8Decoder = Utf8Decoder(allowMalformed: false);

    // 流式处理 SSE 数据
    await for (final chunk in response.stream.transform(utf8Decoder)) {
      try {
        // 将新数据添加到缓冲区
        _buffer += chunk;

        // 按行分割并处理
        final lines = _buffer.split('\n');

        // 保留最后一行（可能不完整）
        if (lines.isNotEmpty) {
          _buffer = lines.last;
          lines.removeLast();
        }

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          // SSE 格式: data: {...}
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6); // 移除 'data: ' 前缀
            _handleSSEData(jsonStr);
          }
        }
      } catch (e) {
        // 如果解码失败，尝试跳过这个块
        continue;
      }
    }
  }

  /// 处理 SSE 数据
  void _handleSSEData(String jsonStr) {
    try {
      final data = json.decode(jsonStr);

      final event = SearchEvent.fromJson(data as Map<String, dynamic>);

      switch (event.type) {
        case SearchEventType.start:
          _handleStartEvent(event as SearchStartEvent);
          break;
        case SearchEventType.sourceResult:
          _handleSourceResultEvent(event as SearchSourceResultEvent);
          break;
        case SearchEventType.sourceError:
          _handleSourceErrorEvent(event as SearchSourceErrorEvent);
          break;
        case SearchEventType.complete:
          _handleCompleteEvent(event as SearchCompleteEvent);
          break;
      }
    } catch (e) {
      _errorController?.add('${AppStrings.sseParseFailed}');
    }
  }

  /// 处理开始事件
  void _handleStartEvent(SearchStartEvent event) {
    _totalSources = event.totalSources;
    _progressController?.add(SearchProgress(
      totalSources: event.totalSources,
      completedSources: 0,
      currentSource: null,
      isComplete: false,
    ));
  }

  /// 处理搜索结果事件
  void _handleSourceResultEvent(SearchSourceResultEvent event) {
    _completedSources++;

    // 黄色内容过滤（仅在家庭模式下生效）
    UserDataService.getFamilyMode().then((familyMode) {
      final filteredResults = ContentFilterService.yellowFilter(event.results, familyMode: familyMode);

      // 只发送增量结果更新，避免全量重渲染
      if (filteredResults.isNotEmpty) {
        _incrementalResultsController?.add(List.from(filteredResults));
      }
    });

    // 更新进度（无论是否有结果都要更新）
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: event.sourceName,
      isComplete: false,
    ));
  }

  /// 处理搜索错误事件
  void _handleSourceErrorEvent(SearchSourceErrorEvent event) {
    _sourceErrors[event.source] = event.error;

    // 错误也算源完成，累计进度
    _completedSources++;

    // 更新进度
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: event.sourceName,
      isComplete: false,
      error: event.error,
    ));
  }

  /// 处理完成事件
  void _handleCompleteEvent(SearchCompleteEvent event) {
    // 如果完成源数小于总源数，说明有些源没有发送结果事件
    // 将完成源数设置为总源数
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }

    // 发送最终完成状态
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: null,
      isComplete: true,
    ));

    // 搜索完成，关闭连接
    _closeConnection();
  }

  /// 处理超时
  void _handleTimeout() {
    // 如果完成源数小于总源数，说明有些源没有发送结果事件
    // 将完成源数设置为总源数
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }

    // 发送超时状态
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: null,
      isComplete: true,
    ));

    _errorController?.add(AppStrings.sseSearchTimeout15);
    _closeConnection();
  }

  /// 关闭连接
  void _closeConnection() {
    _isConnected = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _client?.close();
    _client = null;
  }

  /// 处理 SSE 错误
  void _handleError(error) {
    _isConnected = false;

    // 检查是否是连接关闭错误，如果是则忽略
    final errorString = error.toString().toLowerCase();
    if (errorString.contains(AppConfig.searchErrorConnectionClosed) ||
        errorString.contains(AppConfig.searchErrorClientException) ||
        errorString.contains(AppConfig.searchErrorConnectionTerminated)) {
      // 连接被关闭，这是正常情况，不显示错误
      return;
    }

    // 其他错误才显示给用户
    _errorController?.add('${AppStrings.sseError}${error.toString()}');
  }

  /// 处理 SSE 关闭
  void _handleDone() {
    _isConnected = false;
  }

  /// 停止搜索
  Future<void> stopSearch() async {
    await _subscription?.cancel();
    _subscription = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _client?.close();
    _client = null;

    _isConnected = false;
    _currentQuery = null;

    // 关闭流控制器
    await _incrementalResultsController?.close();
    await _errorController?.close();
    await _progressController?.close();

    _incrementalResultsController = null;
    _errorController = null;
    _progressController = null;
  }

  /// 获取源错误信息
  Map<String, String> get sourceErrors => Map.from(_sourceErrors);

  /// 释放资源
  void dispose() {
    _client?.close();
    _subscription?.cancel();
    _incrementalResultsController?.close();
    _errorController?.close();
    _progressController?.close();
    _timeoutTimer?.cancel();
  }
}

/// 搜索进度信息
class SearchProgress {
  final int totalSources;
  final int completedSources;
  final String? currentSource;
  final bool isComplete;
  final String? error;

  SearchProgress({
    required this.totalSources,
    required this.completedSources,
    this.currentSource,
    required this.isComplete,
    this.error,
  });

  /// 获取完成百分比
  double get progressPercentage {
    if (totalSources <= 0) return 0.0;
    return (completedSources / totalSources).clamp(0.0, 1.0);
  }

  /// 是否有错误
  bool get hasError => error != null;

  /// 获取进度描述
  String get progressDescription {
    if (isComplete) {
      return AppStrings.sseSearchComplete;
    } else if (currentSource != null) {
      return '${AppStrings.sseSearching}$currentSource';
    } else {
      return AppStrings.ssePreparing;
    }
  }
}
