import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/announcement.dart';
import '../utils/font_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onClose;

  const AnnouncementDialog({
    super.key,
    required this.announcement,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final routeAnimation = ModalRoute.of(context)?.animation;
    return Dialog(
      backgroundColor: AppColors.transparent,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: routeAnimation ?? const AlwaysStoppedAnimation(1.0),
          curve: Curves.easeOut,
        ),
        child: Container(
          margin: AppDimens.paddingHorizontal24Vertical40,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.black30,
                blurRadius: AppDimens.shadowBlurLg,
                offset: AppDimens.offset08,
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? AppColors.gray700
                  : AppColors.gray200,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: AppDimens.paddingHorizontal20Vertical8,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? AppColors.gray700
                          : AppColors.gray200,
                      width: AppDimens.dividerThicknessThin,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          margin: AppDimens.paddingRight10,
                          padding: AppDimens.paddingAll6,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.emerald.withValues(alpha: 0.2)
                                : AppColors.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          child: const Icon(
                            LucideIcons.messageCircle,
                            size: AppDimens.iconMd,
                            color: AppColors.emerald,
                          ),
                        ),
                        Text(
                          AppStrings.profileAnnouncement,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXl,
                            color: isDarkMode
                                ? AppColors.white
                                : AppColors.textDarkGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        size: AppDimens.iconMd,
                        color: isDarkMode
                            ? AppColors.gray400
                            : AppColors.gray500,
                      ),
                      onPressed: onClose,
                      padding: AppDimens.paddingAll6,
                      hoverColor: isDarkMode
                          ? AppColors.gray700
                          : AppColors.gray100,
                    ),
                  ],
                ),
              ),

              // 公告内容
              Padding(
                padding: AppDimens.paddingAll20,
                child: Text(
                  announcement.content,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    color: isDarkMode
                        ? AppColors.gray300
                        : AppColors.gray600,
                    fontWeight: FontWeight.w400,
                    height: AppDimens.lineHeightLoose,
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
      barrierColor: AppColors.overlayMedium,
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
