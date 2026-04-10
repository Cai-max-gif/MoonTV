import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/announcement_service.dart';
import '../utils/font_utils.dart';

class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onClose;

  const AnnouncementDialog({
    Key? key,
    required this.announcement,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOut,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF374151)
                  : const Color(0xFFe5e7eb),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF10b981).withOpacity(0.2)
                                : const Color(0xFF10b981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            LucideIcons.messageCircle,
                            size: 18,
                            color: const Color(0xFF10b981),
                          ),
                        ),
                        Text(
                          '公告',
                          style: FontUtils.poppins(
                            fontSize: 16,
                            color: isDarkMode
                                ? const Color(0xFFffffff)
                                : const Color(0xFF1f2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: isDarkMode
                            ? const Color(0xFF9ca3af)
                            : const Color(0xFF6b7280),
                      ),
                      onPressed: onClose,
                      padding: const EdgeInsets.all(6),
                      hoverColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFf3f4f6),
                    ),
                  ],
                ),
              ),

              // 公告内容
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  announcement.content,
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFFd1d5db)
                        : const Color(0xFF4b5563),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context,
    Announcement announcement,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return AnnouncementDialog(
          announcement: announcement,
          onClose: () {
            // 不再标记公告为已查看，确保下次启动时仍然会显示
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
