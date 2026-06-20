import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/wechat_types.dart';
import '../services/wechat_auth_service.dart';
import '../services/wechat_bot_service.dart';
import '../services/ai_service.dart';
import '../services/theme_service.dart';
import '../utils/font_utils.dart';
import '../utils/device_utils.dart';

/// 微信机器人管理页面
class WeChatBotPage extends StatefulWidget {
  const WeChatBotPage({super.key});

  @override
  State<WeChatBotPage> createState() => _WeChatBotPageState();
}

class _WeChatBotPageState extends State<WeChatBotPage> {
  final WeChatBotService _botService = WeChatBotService();

  bool _isLoggingIn = false;
  LoginCredentials? _credentials;
  String? _loginError;

  QRCodeResponse? _qrCode;
  QRStatus? _qrStatus;
  String? _qrStatusText;

  bool get _aiSettingsValid => _cachedSettings?.isValid ?? false;
  AISettings? _cachedSettings;

  final List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkExistingCredentials();
  }

  @override
  void dispose() {
    _botService.stop();
    super.dispose();
  }

  Future<void> _checkExistingCredentials() async {
    _cachedSettings = await AIService.loadSettings();

    final creds = await WeChatAuthService.loadCredentials();
    if (creds != null && mounted) {
      setState(() {
        _credentials = creds;
      });
      _autoStartBot();
    }
  }

  Future<void> _autoStartBot() async {
    if (!_aiSettingsValid || _credentials == null) return;

    _botService.configure(
      credentials: _credentials!,
      aiSettings: _cachedSettings!,
    );

    // 设置日志回调
    _botService.onLog = (entry) {
      if (mounted) {
        setState(() {
          _logs.add(entry);
          if (_logs.length > 100) {
            _logs.removeAt(0);
          }
        });
      }
    };

    // 设置媒体接收回调
    _botService.onMediaReceived = (userId, media) {
      if (mounted) {
        // 可以在这里处理收到的媒体文件
        // 例如：显示通知、保存到相册等
      }
    };

    await _botService.start();
  }

  Future<void> _startLogin() async {
    setState(() {
      _isLoggingIn = true;
      _loginError = null;
      _qrCode = null;
      _qrStatus = null;
    });

    try {
      final creds = await WeChatAuthService.login(
        onQRCodeReady: (qr) {
          if (mounted) {
            setState(() {
              _qrCode = qr;
              _qrStatus = QRStatus.wait;
              _qrStatusText = '请使用微信扫描二维码';
            });
          }
        },
        onStatusChanged: (status) {
          if (mounted) {
            setState(() {
              _qrStatus = status;
              switch (status) {
                case QRStatus.wait:
                  _qrStatusText = '等待扫码...';
                  break;
                case QRStatus.scaned:
                  _qrStatusText = '已扫码，请在手机上确认...';
                  break;
                case QRStatus.confirmed:
                  _qrStatusText = '登录成功!';
                  break;
                case QRStatus.expired:
                  _qrStatusText = '二维码已过期，正在刷新...';
                  break;
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _credentials = creds;
          _isLoggingIn = false;
          _qrCode = null;
          _qrStatus = null;
        });
      }
      _autoStartBot();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _loginError = e.toString();
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1e1e1e) : Colors.white,
          title: Text(
            '退出登录',
            style: FontUtils.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2c3e50),
            ),
          ),
          content: Text(
            '确定要退出微信登录吗？需要重新扫码才能使用机器人。',
            style: FontUtils.poppins(
              fontSize: 14,
              color: isDark ? const Color(0xFFb0b0b0) : const Color(0xFF7f8c8d),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                '取消',
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFb0b0b0)
                      : const Color(0xFF7f8c8d),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                '确定',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _botService.stop();
      await WeChatAuthService.clearCredentials();
      if (mounted) {
        setState(() {
          _credentials = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final textColor =
            isDark ? const Color(0xFFffffff) : const Color(0xFF2c3e50);
        final subtitleColor =
            isDark ? const Color(0xFFb0b0b0) : const Color(0xFF7f8c8d);
        final cardColor = isDark ? const Color(0xFF1e1e1e) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF333333) : const Color(0xFFe0e0e0);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
          appBar: _buildAppBar(isDark, textColor),
          body: _credentials == null
              ? _buildLoginView(
                  isDark, textColor, subtitleColor, cardColor, borderColor)
              : _buildDashboardView(
                  isDark, textColor, subtitleColor, cardColor, borderColor),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1e1e1e) : Colors.white,
      elevation: 0,
      leading: MouseRegion(
        cursor:
            DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(LucideIcons.arrowLeft, color: textColor, size: 24),
          ),
        ),
      ),
      title: Text(
        '微信 AI 机器人',
        style: FontUtils.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLoginView(bool isDark, Color textColor, Color subtitleColor,
      Color cardColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.messageCircle,
                  size: 48,
                  color: Color(0xFF27ae60),
                ),
                const SizedBox(height: 16),
                Text(
                  '微信 AI 机器人',
                  style: FontUtils.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '连接微信后，AI 将自动回复您的好友消息',
                  textAlign: TextAlign.center,
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureRow('自动回复', '好友发消息，AI 自动回复', subtitleColor),
                const SizedBox(height: 8),
                _buildFeatureRow('多轮对话', 'AI 会记住上下文', subtitleColor),
                const SizedBox(height: 8),
                _buildFeatureRow('媒体支持', '收发图片、视频、文件', subtitleColor),
                const SizedBox(height: 8),
                _buildFeatureRow('会话保护', '自动处理会话过期', subtitleColor),
                const SizedBox(height: 8),
                _buildFeatureRow('多模型', '兼容 OpenAI、DeepSeek 等', subtitleColor),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (_isLoggingIn && _qrCode != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _qrCode!.qrcodeImgContent,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_qrStatus == QRStatus.scaned)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF27ae60)),
                          ),
                        ),
                      if (_qrStatus == QRStatus.scaned)
                        const SizedBox(width: 8),
                      Text(
                        _qrStatusText ?? '等待扫码...',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: _qrStatus == QRStatus.scaned
                              ? const Color(0xFF27ae60)
                              : subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (_isLoggingIn) ...[
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: const Column(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '正在获取二维码...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7f8c8d)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (_loginError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loginError!,
                      style: FontUtils.poppins(
                          fontSize: 13, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoggingIn ? null : _startLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27ae60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _isLoggingIn ? '登录中...' : '扫码登录微信',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '使用微信扫描二维码即可登录',
            style: FontUtils.poppins(fontSize: 12, color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
      String title, String desc, Color subtitleColor) {
    return Row(
      children: [
        const Icon(Icons.check_circle,
            size: 16, color: Color(0xFF27ae60)),
        const SizedBox(width: 8),
        Text(
          '$title - $desc',
          style: FontUtils.poppins(fontSize: 13, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _buildDashboardView(bool isDark, Color textColor, Color subtitleColor,
      Color cardColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF27ae60),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '微信机器人已连接',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Account ID', _credentials!.accountId, subtitleColor),
                if (_credentials!.userId != null)
                  _buildInfoRow(
                      'User ID', _credentials!.userId!, subtitleColor),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(LucideIcons.logOut, size: 16),
                    label: Text(
                      '退出登录',
                      style: FontUtils.poppins(
                          fontSize: 14, color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 32,
                  color: Color(0xFF3498db),
                ),
                const SizedBox(height: 12),
                Text(
                  '机器人正在后台运行',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '好友发送的消息将由 AI 自动回复',
                  textAlign: TextAlign.center,
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 日志面板
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.terminal,
                      size: 16,
                      color: Color(0xFF9b59b6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '运行日志',
                      style: FontUtils.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_logs.length} 条',
                      style: FontUtils.poppins(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _logs.isEmpty
                      ? Center(
                          child: Text(
                            '暂无日志',
                            style: FontUtils.poppins(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[_logs.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                log.formatted,
                                style: FontUtils.sourceCodePro(
                                  fontSize: 11,
                                  color: log.level == LogLevel.error
                                      ? Colors.redAccent
                                      : log.level == LogLevel.warn
                                          ? Colors.orangeAccent
                                          : subtitleColor,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: FontUtils.poppins(fontSize: 13, color: subtitleColor),
          ),
          Expanded(
            child: Text(
              value,
              style: FontUtils.poppins(
                fontSize: 13,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
