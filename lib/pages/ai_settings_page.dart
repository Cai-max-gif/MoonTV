
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../utils/font_utils.dart';
import '../utils/device_utils.dart';

class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.isDarkMode
              ? const Color(0xFF000000)
              : const Color(0xFFf5f5f5),
          appBar: AppBar(
            backgroundColor: themeService.isDarkMode
                ? const Color(0xFF1e1e1e)
                : Colors.white,
            elevation: 0,
            leading: MouseRegion(
              cursor: DeviceUtils.isPC()
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: themeService.isDarkMode
                        ? const Color(0xFFffffff)
                        : const Color(0xFF2c3e50),
                    size: 24,
                  ),
                ),
              ),
            ),
            title: Text(
              'AI 设置',
              style: FontUtils.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.isDarkMode
                    ? const Color(0xFFffffff)
                    : const Color(0xFF2c3e50),
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.settings,
                  size: 64,
                  color: themeService.isDarkMode
                      ? const Color(0xFF666666)
                      : const Color(0xFF95a5a6),
                ),
                const SizedBox(height: 24),
                Text(
                  'AI 设置页面',
                  style: FontUtils.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeService.isDarkMode
                        ? const Color(0xFFffffff)
                        : const Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '这里将显示 AI 相关的设置选项',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: themeService.isDarkMode
                        ? const Color(0xFFb0b0b0)
                        : const Color(0xFF7f8c8d),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
