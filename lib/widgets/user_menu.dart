import 'dart:convert';
import '../constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_data_service.dart';
import '../screens/login_screen.dart';
import '../services/douban_cache_service.dart';
import '../services/page_cache_service.dart';
import '../services/live_service.dart';
import '../services/local_search_cache_service.dart';
import '../services/version_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import 'update_dialog.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

class UserMenu extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onClose;

  const UserMenu({super.key, required this.isDarkMode, this.onClose});

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  String? _username;
  String _role = 'user';
  String _version = '';
  bool _localSearch = false;

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
    final localSearch = await UserDataService.getLocalSearch();

    if (mounted) {
      setState(() {
        _username = username;
        _role = _parseRoleFromCookies(cookies);
        _localSearch = localSearch;
      });
    }
  }

  String _parseRoleFromCookies(String? cookies) {
    if (cookies == null || cookies.isEmpty) {
      return 'user';
    }

    try {
      // 解析cookies字符串
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

      // 处理可能的双重编码
      String decoded = Uri.decodeComponent(authCookie);

      // 如果解码后仍然包含 %，说明是双重编码，需要再次解码
      if (decoded.contains('%')) {
        decoded = Uri.decodeComponent(decoded);
      }

      final authData = json.decode(decoded);
      final role = authData['role'] as String?;

      return role ?? 'user';
    } catch (e) {
      // 解析失败时默认为user
      return 'user';
    }
  }

  Future<void> _handleLogout() async {
    // 清空所有缓存
    LiveService.clearAllCache();
    LocalSearchCacheService().clearCache();
    PageCacheService().clearAllCache();

    // 只清除密码和cookies，保留服务器地址和用户名
    await UserDataService.clearAuthData();

    // 跳转到登录页，并移除所有之前的路由（强制销毁所有页面）
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleClearDoubanCache() async {
    try {
      await DoubanCacheService().clearAll();
      // 同时清空 Bangumi 的函数级与内存级缓存
      PageCacheService().clearCache('bangumi_calendar');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.profileClearDone)));
        // 清除后关闭菜单
        widget.onClose?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.profileClearFailed)));
        // 即便失败也关闭菜单，避免停留
        widget.onClose?.call();
      }
    }
  }

  Future<void> _handleCheckUpdate() async {
    try {
      // 显示加载提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.profileCheckingUpdate,
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.black,
            duration: AppDurations.twoSeconds,
          ),
        );
      }

      final versionInfo = await VersionService.checkForUpdate(isManualCheck: true);

      if (!mounted) return;

      if (versionInfo != null) {
        // 有新版本，显示更新对话框
        await UpdateDialog.show(context, versionInfo);
      } else {
        // 已是最新版本
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.profileAlreadyLatest,
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.profileCheckUpdateFailed}${e.toString()}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Widget _buildRoleTag() {
    String label;
    Color color;

    switch (_role) {
      case 'admin':
        label = AppStrings.profileRoleAdmin;
        color = AppColors.orange; // 橙黄色
        break;
      case 'owner':
        label = AppStrings.profileRoleOwner;
        color = AppColors.violet; // 紫色
        break;
      case 'user':
      default:
        label = AppStrings.profileRoleUser;
        color = AppColors.emerald; // 绿色
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: Text(
        label,
        style: FontUtils.poppins(
          fontSize: AppDimens.fontSize2xs,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



  Widget _buildToggleOption({
    required String title,
    required bool value,
    required Future<void> Function(bool) onChanged,
    required IconData icon,
  }) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: widget.isDarkMode
                  ? AppColors.gray400
                  : AppColors.gray500,
            ),
            Gap.w12,
            Expanded(
              child: Text(
                title,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: widget.isDarkMode
                      ? AppColors.white
                      : AppColors.textDarkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await onChanged(!value);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: AppDurations.normal,
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  color: value
                      ? AppColors.emerald
                      : (widget.isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray),
                ),
                child: AnimatedAlign(
                  duration: AppDurations.normal,
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
          color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: AppColors.black30,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击菜单内容时关闭
              child: Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? AppColors.inputBgDark
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black30,
                      blurRadius: AppDimens.shadowBlurLg,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 用户信息区域
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.profileCurrentUser,
                            textAlign: TextAlign.center,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXs,
                              color: widget.isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Gap.h8,
                          // 用户名
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _username ?? AppStrings.profileUnknownUser,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeXxl,
                                  color: widget.isDarkMode
                                      ? AppColors.white
                                      : AppColors.textDarkGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Gap.w8,
                              // 角色标签
                              _buildRoleTag(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
                    ),
                    // 本地搜索选项
                    _buildToggleOption(
                      title: AppStrings.profileLocalSearch,
                      value: _localSearch,
                      onChanged: (value) async {
                        await UserDataService.saveLocalSearch(value);
                        setState(() {
                          _localSearch = value;
                        });
                      },
                      icon: LucideIcons.search,
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
                    ),
                    // 清除豆瓣缓存按钮
                    Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        onTap: _handleClearDoubanCache,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.trash2,
                                size: 20,
                                color: AppColors.orange,
                              ),
                              Gap.w12,
                              Text(
                                AppStrings.profileClearDoubanCache,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeXl,
                                  color: widget.isDarkMode
                                      ? AppColors.white
                                      : AppColors.textDarkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
                    ),
                    // 检查更新按钮
                    Material(
                      color: AppColors.transparent,
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
                                color: AppColors.blue,
                              ),
                              Gap.w12,
                              Text(
                                AppStrings.profileCheckUpdate,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeXl,
                                  color: widget.isDarkMode
                                      ? AppColors.white
                                      : AppColors.textDarkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
                    ),
                    // 登出按钮
                    Material(
                      color: AppColors.transparent,
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
                                color: AppColors.red,
                              ),
                              Gap.w12,
                              Text(
                                AppStrings.authLogout,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeXl,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 分割线
                    Container(
                      height: 1,
                      color: widget.isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
                    ),
                    // 版本号
                    MouseRegion(
                      cursor: DeviceUtils.isPC()
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      child: GestureDetector(
                        onTap: () async {
                                final url = Uri.parse(
                                  AppConfig.githubRepoUrl,
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Center(
                            child: Text(
                              _version.isEmpty ? AppConfig.defaultVersion : _version,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeMd,
                                color: widget.isDarkMode
                                    ? AppColors.gray400
                                    : AppColors.gray500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
