import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'dart:io' show Platform;
import 'package:macos_window_utils/macos_window_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // 当为系统模式时，需要根据当前系统主题判断
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // 每次启动都默认跟随系统主题，不保存用户的手动选择
    _themeMode = ThemeMode.system;
    notifyListeners();
    _updateMacOSWindowAppearance();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // 不再保存到 SharedPreferences，每次启动都重新遵循系统主题
    notifyListeners();
    _updateMacOSWindowAppearance();
  }

  // 更新 macOS 窗口外观
  Future<void> _updateMacOSWindowAppearance() async {
    if (!Platform.isMacOS) return;

    if (isDarkMode) {
      await WindowManipulator.overrideMacOSBrightness(dark: true);
    } else {
      await WindowManipulator.overrideMacOSBrightness(dark: false);
    }
  }

  Future<void> toggleTheme(BuildContext context) async {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        // 当为系统模式时，检测当前系统主题并切换到相反模式
        final brightness = MediaQuery.of(context).platformBrightness;
        if (brightness == Brightness.light) {
          setThemeMode(ThemeMode.dark);
        } else {
          setThemeMode(ThemeMode.light);
        }
        break;
    }
  }

  ThemeData get lightTheme {
    // Windows 下使用微软雅黑以获得更好的中文渲染
    final textTheme = Platform.isWindows
        ? ThemeData.light().textTheme.copyWith(
              bodyLarge: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w400,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              bodyMedium: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w400,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              bodySmall: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              titleLarge: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              titleMedium: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              titleSmall: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
            )
        : const TextTheme(
            bodyLarge: TextStyle(color: AppColors.primary),
            bodyMedium: TextStyle(color: AppColors.primary),
            bodySmall: TextStyle(color: AppColors.textSecondary),
            titleLarge: TextStyle(color: AppColors.primary),
            titleMedium: TextStyle(color: AppColors.primary),
            titleSmall: TextStyle(color: AppColors.primary),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
        scaffoldBackgroundColor: AppColors.scaffoldLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: AppDimens.elevationNone,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: AppDimens.elevationSm,
      ),
      textTheme: textTheme,
      fontFamily: Platform.isWindows ? AppConfig.fontFamilyWindows : null,
    );
  }

  ThemeData get darkTheme {
    // Windows 下使用微软雅黑以获得更好的中文渲染
    final textTheme = Platform.isWindows
        ? ThemeData.dark().textTheme.copyWith(
              bodyLarge: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w400,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              bodyMedium: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w400,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              bodySmall: const TextStyle(
                color: AppColors.textDarkSecondary,
                fontWeight: FontWeight.w400,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              titleLarge: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              titleMedium: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
              titleSmall: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontFamily: AppConfig.fontFamilyWindows,
              ),
            )
        : const TextTheme(
            bodyLarge: TextStyle(color: AppColors.white),
            bodyMedium: TextStyle(color: AppColors.white),
            bodySmall: TextStyle(color: AppColors.textDarkSecondary),
            titleLarge: TextStyle(color: AppColors.white),
            titleMedium: TextStyle(color: AppColors.white),
            titleSmall: TextStyle(color: AppColors.white),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
        scaffoldBackgroundColor: AppColors.scaffoldDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardDark,
        foregroundColor: AppColors.white,
        elevation: AppDimens.elevationNone,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardDark,
        elevation: AppDimens.elevationSm,
      ),
      textTheme: textTheme,
      fontFamily: Platform.isWindows ? AppConfig.fontFamilyWindows : null,
    );
  }
}
