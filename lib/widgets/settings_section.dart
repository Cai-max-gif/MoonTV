import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/font_utils.dart';

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
          // 下载管理按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '下载管理功能开发中',
                      style: FontUtils.poppins(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF3b82f6),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
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
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
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
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : const Color(0xFFe5e7eb),
          ),
          // 下载设置按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '下载设置功能开发中',
                      style: FontUtils.poppins(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF3b82f6),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
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
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
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
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : const Color(0xFFe5e7eb),
          ),
          // 播放设置按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '播放设置功能开发中',
                      style: FontUtils.poppins(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF3b82f6),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
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
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? const Color(0xFFffffff)
                            : const Color(0xFF1f2937),
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
    );
  }
}