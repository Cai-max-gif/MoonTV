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

  runApp(const MoonTVApp());

  // 初始化 Windows 窗口配置
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(1024, 600);
      const minSize = Size(1024, 600);
      win.minSize = minSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "MoonTV";
      win.show();
    });
  }
}

class MoonTVApp extends StatelessWidget {
  const MoonTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'MoonTV',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const AppWrapper(),
            builder: (context, child) {
              // 为 Windows 平台改善字体渲染
              if (Platform.isWindows) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
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
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  Timer? _accountStatusTimer;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
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
    Duration checkInterval = const Duration(seconds: 30);

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
        // 检查失败，忽略错误
      }
    });
  }

  void _checkLoginStatus() async {
    try {
      // 检查是否有自动登录所需的数据
      final hasAutoLoginData = await UserDataService.hasAutoLoginData();

      if (!hasAutoLoginData) {
        // 如果没有自动登录数据，直接进入登录页
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 尝试自动登录
      final loginResult = await ApiService.autoLogin();

      if (mounted) {
        if (loginResult.success) {
          // 自动登录成功，执行启动流程
          await _executeStartupFlow();
        } else {
          // 自动登录失败，进入登录页
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // 发生异常，进入登录页
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

      // 进入首页
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
      // 公告显示失败，不影响主流程
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? const Color(0xFF000000) // 深色模式纯黑色
                    : null,
                gradient: themeService.isDarkMode
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFe6f3fb),
                          Color(0xFFeaf3f7),
                          Color(0xFFf7f7f3),
                          Color(0xFFe9ecef),
                          Color(0xFFdbe3ea),
                          Color(0xFFd3dde6),
                        ],
                        stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
                      ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          themeService.isDarkMode
                              ? const Color(0xFFffffff)
                              : const Color(0xFF2c3e50)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '正在检查登录状态...',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeService.isDarkMode
                            ? const Color(0xFFffffff)
                            : const Color(0xFF2c3e50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return const LoginScreen();
  }
}