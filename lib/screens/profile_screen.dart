import 'dart:convert';
import '../constants/app_dimensions.dart';
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
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

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
              AppStrings.profileCheckingUpdate,
              style: FontUtils.poppins(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : AppColors.white,
            duration: AppDurations.twoSeconds,
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
              AppStrings.profileAlreadyLatest,
              style: FontUtils.poppins(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.accent,
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
              '${AppStrings.profileCheckUpdateFailed}${e.toString()}',
              style: FontUtils.poppins(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.red,
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
              AppStrings.profileFetchingAnnouncement,
              style: FontUtils.poppins(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.white
                    : Colors.black,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : AppColors.white,
            duration: AppDurations.twoSeconds,
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
              AppStrings.profileNoAnnouncement,
              style: FontUtils.poppins(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.accent,
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
              '${AppStrings.profileFetchAnnouncementFailed}${e.toString()}',
              style: FontUtils.poppins(
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.red,
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
        label = AppStrings.profileRoleAdmin;
        color = AppColors.amber;
        break;
      case 'owner':
        label = AppStrings.profileRoleOwner;
        color = AppColors.violet;
        break;
      case 'user':
      default:
        label = AppStrings.profileRoleUser;
        color = AppColors.emerald;
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.borderDarkGray
          : AppColors.borderLightGray,
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
      color: AppColors.transparent,
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
              Gap.w12,
              Text(
                label,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.white
                      : AppColors.textDarkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              trailing ?? Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textDarkHint
                    : AppColors.gray400,
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
            ? AppColors.black
            : AppColors.grayBg,
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
                  ? AppColors.cardDark
                  : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: AppDimens.shadowBlurSm,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.profileCurrentUser,
                  textAlign: TextAlign.center,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXs,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.gray400
                        : AppColors.gray500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Gap.h8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _username ?? AppStrings.profileUnknownUser,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXxl,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.white
                            : AppColors.textDarkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap.w8,
                    _buildRoleTag(),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.cardDark
                  : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: AppDimens.shadowBlurSm,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: LucideIcons.folderOutput,
                  iconColor: AppColors.emerald,
                  label: AppStrings.profileDownloadManage,
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
                  iconColor: AppColors.violet,
                  label: AppStrings.profileDownloadSettings,
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
                  iconColor: AppColors.amber,
                  label: AppStrings.profilePlaybackSettings,
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
                  iconColor: AppColors.pinkAccent,
                  label: AppStrings.profileDanmakuSettings,
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
                  iconColor: AppColors.blue,
                  label: AppStrings.profileThemeSettings,
                  trailing: Row(
                    children: [
                      Icon(
                        themeService.isDarkMode ? LucideIcons.moon : LucideIcons.sun,
                        size: AppDimens.iconSm,
                        color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.gray400
                        : AppColors.gray500,
                      ),
                      Gap.w6,
                      Text(
                        themeService.isDarkMode ? AppStrings.profileThemeDark : AppStrings.profileThemeLight,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.gray400
                              : AppColors.gray500,
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
                  iconColor: AppColors.amber,
                  label: AppStrings.profileAnnouncement,
                  onTap: _handleViewAnnouncement,
                ),
                _buildDivider(),
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.white
                                : AppColors.textDarkGray,
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
                                  AppConfig.githubRepoUrl,
                                );
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Text(
                                _version.isEmpty ? AppConfig.defaultVersion : _version,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeMd,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.gray400
                                  : AppColors.gray500,
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
              ],
            ),
          ),
          SizedBox(height: DeviceUtils.isTablet(context) && !DeviceUtils.isPortraitTablet(context) ? 100 : 40),
        ],
      ),
    );
  }
}