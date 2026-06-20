import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_data_service.dart';
import '../services/theme_service.dart';
import '../screens/login_screen.dart';
import '../screens/download_management_screen.dart';
import '../screens/download_settings_screen.dart';
import '../screens/playback_settings_screen.dart';
import '../screens/danmaku_settings_screen.dart';
import '../services/page_cache_service.dart';
import '../services/live_service.dart';
import '../services/version_service.dart';
import '../services/announcement_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../widgets/update_dialog.dart';
import '../widgets/announcement_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String _role = 'user';
  String _version = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final username = await UserDataService.getUsername();
    final cookies = await UserDataService.getCookies();

    if (mounted) {
      setState(() {
        _username = username;
        _role = _parseRoleFromCookies(cookies);
      });
    }
  }

  String _parseRoleFromCookies(String? cookies) {
    if (cookies == null || cookies.isEmpty) {
      return 'user';
    }

    try {
      final cookieMap = <String, String>{};
      final cookiePairs = cookies.split(';');

      for (final cookie in cookiePairs) {
        final trimmed = cookie.trim();
        final firstEqualIndex = trimmed.indexOf('=');

        if (firstEqualIndex > 0) {
          final key = trimmed.substring(0, firstEqualIndex);
          final value = trimmed.substring(firstEqualIndex + 1);
          if (key.isNotEmpty && value.isNotEmpty) {
            cookieMap[key] = value;
          }
        }
      }

      final authCookie = cookieMap['user_auth'] ?? cookieMap['auth'];
      if (authCookie == null) {
        return 'user';
      }

      String decoded = Uri.decodeComponent(authCookie);

      if (decoded.contains('%')) {
        decoded = Uri.decodeComponent(decoded);
      }

      final authData = json.decode(decoded);
      final role = authData['role'] as String?;

      return role ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      LiveService.clearAllCache();
      PageCacheService().clearAllCache();

      await UserDataService.clearAuthData();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCheckUpdate() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在检查更新...',
              style: FontUtils.poppins(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          ),
        );
      }

      final versionInfo = await VersionService.checkForUpdate(isManualCheck: true);

      if (!mounted) return;

      if (versionInfo != null) {
        await UpdateDialog.show(context, versionInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '当前已是最新版本',
              style: FontUtils.poppins(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '检查更新失败: ${e.toString()}',
              style: FontUtils.poppins(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleViewAnnouncement() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '正在获取公告...',
              style: FontUtils.poppins(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          ),
        );
      }

      final announcement = await AnnouncementService.getAnnouncement();

      if (!mounted) return;

      if (announcement != null) {
        await AnnouncementDialog.show(context, announcement);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '暂无公告',
              style: FontUtils.poppins(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '获取公告失败: ${e.toString()}',
              style: FontUtils.poppins(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRoleTag() {
    String label;
    Color color;

    switch (_role) {
      case 'admin':
        label = '管理员';
        color = const Color(0xFFf59e0b);
        break;
      case 'owner':
        label = '站长';
        color = const Color(0xFF8b5cf6);
        break;
      case 'user':
      default:
        label = '用户';
        color = const Color(0xFF10b981);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: FontUtils.poppins(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF374151)
          : const Color(0xFFe5e7eb),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: FontUtils.poppins(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFffffff)
                      : const Color(0xFF1f2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              trailing ?? Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF666666)
                    : const Color(0xFF9ca3af),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF000000)
            : const Color(0xFFf5f5f5),
      ),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: DeviceUtils.isPC() ? 16 : -10,
              bottom: 32,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1e1e1e)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '当前用户',
                  textAlign: TextAlign.center,
                  style: FontUtils.poppins(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _username ?? '未知用户',
                      style: FontUtils.poppins(
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleTag(),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1e1e1e)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: LucideIcons.folderOutput,
                  iconColor: const Color(0xFF10b981),
                  label: '下载管理',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DownloadManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: LucideIcons.settings2,
                  iconColor: const Color(0xFF8b5cf6),
                  label: '下载设置',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DownloadSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: LucideIcons.clapperboard,
                  iconColor: const Color(0xFFf59e0b),
                  label: '播放设置',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaybackSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: LucideIcons.messageSquare,
                  iconColor: const Color(0xFFec4899),
                  label: '弹幕设置',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DanmakuSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: LucideIcons.palette,
                  iconColor: const Color(0xFF3b82f6),
                  label: '主题设置',
                  trailing: Row(
                    children: [
                      Icon(
                        themeService.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF9ca3af)
                            : const Color(0xFF6b7280),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        themeService.isDarkMode ? '深色' : '浅色',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF9ca3af)
                              : const Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    themeService.toggleTheme(context);
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: LucideIcons.bell,
                  iconColor: const Color(0xFFf59e0b),
                  label: '公告',
                  onTap: _handleViewAnnouncement,
                ),
                _buildDivider(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleCheckUpdate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.download,
                            size: 20,
                            color: Color(0xFF3b82f6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '检查更新',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFffffff)
                                  : const Color(0xFF1f2937),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          MouseRegion(
                            cursor: DeviceUtils.isPC()
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            child: GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(
                                  'https://github.com/Cai-max-gif/MoonTV',
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Text(
                                _version.isEmpty ? '1.4.3' : _version,
                                style: FontUtils.poppins(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF9ca3af)
                                      : const Color(0xFF6b7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildDivider(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleLogout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.logOut,
                            size: 20,
                            color: Color(0xFFef4444),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '登出',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              color: const Color(0xFFef4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: DeviceUtils.isTablet(context) && !DeviceUtils.isPortraitTablet(context) ? 100 : 40),
        ],
      ),
    );
  }
}