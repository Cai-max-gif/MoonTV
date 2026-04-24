import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/font_utils.dart';
import '../screens/download_management_screen.dart';
import '../screens/download_settings_screen.dart';
import '../screens/playback_settings_screen.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DownloadManagementScreen(),
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
                      LucideIcons.folderOutput,
                      size: 20,
                      color: Color(0xFF10b981),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '下载管理',
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
                    builder: (context) => const DownloadSettingsScreen(),
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
                      LucideIcons.settings2,
                      size: 20,
                      color: Color(0xFF8b5cf6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '下载设置',
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
                    builder: (context) => const PlaybackSettingsScreen(),
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
                      LucideIcons.clapperboard,
                      size: 20,
                      color: Color(0xFFf59e0b),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '播放设置',
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