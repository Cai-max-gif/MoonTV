import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../utils/font_utils.dart';
import '../services/theme_service.dart';
import '../screens/sync_settings_screen.dart';

class AppearanceSyncSettingsSection extends StatelessWidget {
  const AppearanceSyncSettingsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Container(
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                themeService.toggleTheme(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.palette,
                      size: 20,
                      color: Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '主题设置',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      themeService.isDarkMode
                          ? LucideIcons.moon
                          : LucideIcons.sun,
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
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : const Color(0xFFe5e7eb),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SyncSettingsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: Color(0xFF10b981),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '同步设置',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
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
          ),
        ],
      ),
    );
  }
}
