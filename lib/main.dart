import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/user_data_service.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';
import 'services/douban_cache_service.dart';
import 'services/notification_service.dart';
import 'services/version_service.dart';
import 'services/announcement_service.dart';
import 'models/announcement.dart';
import 'widgets/announcement_dialog.dart';
import 'widgets/update_dialog.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'constants/app_dimensions.dart';
import 'constants/app_durations.dart';
import 'constants/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // Gal 库不需要显式初始化，直接使用即可

  // 初始化 macOS 窗口配置
  if (Platform.isMacOS) {
    await WindowManipulator.initialize(enableWindowDelegate: true);
    // 设置标题栏为透明，让菜单栏颜色跟随主题
    await WindowManipulator.makeTitlebarTransparent();
    await WindowManipulator.enableFullSizeContentView();
    // 隐藏标题栏中的 Title
    await WindowManipulator.hideTitle();
  }

  // 初始化豆瓣缓存服务
  final cacheService = DoubanCacheService();
  await cacheService.init();

  // 启动定期清理
  cacheService.startPeriodicCleanup();

  // 在原生启动画面期间检查自动登录，避免首帧闪烁
  bool canAutoLogin = false;
  try {
    canAutoLogin = await UserDataService.hasAutoLoginData();
    if (canAutoLogin) {
      final loginResult = await ApiService.autoLogin();
      canAutoLogin = loginResult.success;
    }
  } catch (e) {
    canAutoLogin = false;
  }

  runApp(MoonTVApp(canAutoLogin: canAutoLogin));

  // 初始化 Windows 窗口配置
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(AppDimens.windowDefaultWidth, AppDimens.windowDefaultHeight);
      const minSize = Size(AppDimens.windowMinWidth, AppDimens.windowMinHeight);
      win.minSize = minSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = AppConfig.appName;
      win.show();
    });
  }
}

class MoonTVApp extends StatelessWidget {
  final bool canAutoLogin;
  const MoonTVApp({super.key, required this.canAutoLogin});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: AppWrapper(canAutoLogin: canAutoLogin),
            builder: (context, child) {
              // 为 Windows 平台改善字体渲染
              if (Platform.isWindows) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(AppDimens.windowsTextScaleFactor),
                  ),
                  child: child!,
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  final bool canAutoLogin;
  const AppWrapper({super.key, required this.canAutoLogin});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  Timer? _accountStatusTimer;

  @override
  void initState() {
    super.initState();
    if (widget.canAutoLogin) {
      _executeStartupFlow();
    }
    _startAccountStatusCheck();
    UserDataService.initDanmakuEnabled();
    UserDataService.initDanmakuSettings();
  }

  @override
  void dispose() {
    _accountStatusTimer?.cancel();
    super.dispose();
  }

  void _startAccountStatusCheck() {
    // 初始检查间隔为30秒
    Duration checkInterval = AppDurations.accountCheckInterval;

    _accountStatusTimer = Timer.periodic(checkInterval, (timer) {
      _checkAccountStatus();
    });
  }

  void _checkAccountStatus() {
    // Telegram 登录保护期：禁止跳回登录页
    if (ApiService.isLoginRedirectBlocked) return;

    // 在后台执行检查，不阻塞主线程
    Future.microtask(() async {
      try {
        // 检查是否已登录
        final isLoggedIn = await UserDataService.isLoggedIn();
        if (!isLoggedIn) {
          _accountStatusTimer?.cancel();
          return;
        }

        // 检查账号状态 - 使用强制刷新以获取服务器最新状态
        if (!mounted) return;
        final statusResult = await ApiService.checkAccountStatus(
          context,
          forceRefresh: true,
        );

        if (!statusResult.success && statusResult.statusCode == 401) {
          // 账号被封禁或登录已过期
          if (!ApiService.isLoginRedirectBlocked) {
            await UserDataService.clearAuthData();

            // 跳转到登录页
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        } else if (statusResult.success && statusResult.data == false) {
          // 账号状态为非活跃（被封禁）
          if (!ApiService.isLoginRedirectBlocked) {
            await UserDataService.clearAuthData();

            // 跳转到登录页
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        } else if (statusResult.success && statusResult.data == true) {
          // 账号正常，首次成功请求后自动取消登录保护
          if (ApiService.isLoginRedirectBlocked) {
            ApiService.allowLoginRedirects();
          }
        }
      } catch (e) {
      }
    });
  }

  Future<void> checkLoginStatus() async {
    try {
      // 检查是否有自动登录所需的数据
      final hasAutoLoginData = await UserDataService.hasAutoLoginData();

      if (!hasAutoLoginData) {
        // 如果没有自动登录数据，直接留在登录页
        return;
      }

      // 尝试自动登录
      final loginResult = await ApiService.autoLogin();

      if (mounted) {
        if (loginResult.success) {
          // 自动登录成功，执行启动流程
          await _executeStartupFlow();
        }
        // 自动登录失败，留在登录页
      }
    } catch (e) {
      // 发生异常，留在登录页
    }
  }

  Future<void> _executeStartupFlow() async {
    // 并发获取版本更新和公告
    final results = await Future.wait([
      VersionService.checkForUpdate(),
      AnnouncementService.getAnnouncement(),
    ]);

    final versionInfo = results[0] as VersionInfo?;
    final announcement = results[1] as Announcement?;

    if (mounted) {
      // 先显示版本更新对话框
      if (versionInfo != null) {
        // 保存版本信息，供通知点击时使用
        VersionService.setStoredVersionInfo(versionInfo);
        
        // 检查是否为强制更新
        if (versionInfo.updateType == UpdateType.force) {
          // 强制更新，必须完成更新后才能继续
          // 显示更新对话框并等待用户操作
          await UpdateDialog.show(context, versionInfo);
        } else {
          // 非强制更新，显示更新对话框但不阻塞
          UpdateDialog.show(context, versionInfo);
          // 显示公告
          await _checkAndShowAnnouncement(announcement);
        }
      } else {
        // 无版本更新，显示公告
        await _checkAndShowAnnouncement(announcement);
      }
    }
  }

  Future<void> _checkAndShowAnnouncement(Announcement? announcement) async {
    try {
      if (mounted && announcement != null) {
        // 检查是否应该显示公告
        final shouldShow =
            await AnnouncementService.shouldShowAnnouncement(announcement);
        if (shouldShow && mounted) {
          // 显示公告
          await AnnouncementDialog.show(context, announcement);
        }
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.canAutoLogin) return const HomeScreen();
    return const LoginScreen();
  }
}