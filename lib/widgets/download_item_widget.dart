import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/download_task.dart';
import '../utils/font_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';

class DownloadItemWidget extends StatelessWidget {
  final DownloadTask task;
  final bool isDarkMode;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  final VoidCallback onPlay;
  final bool showDeleteButton;

  const DownloadItemWidget({
    super.key,
    required this.task,
    required this.isDarkMode,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
    required this.onPlay,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppDimens.marginHorizontal16Vertical6,
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black30,
            blurRadius: AppDimens.shadowBlurSm,
            offset: AppDimens.offset02,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCover(),
          Gap.w12,
          Expanded(child: _buildInfo()),
          Gap.w12,
          _buildProgressOrContinueButton(),
          if (!task.isCompleted || showDeleteButton) ...[
            Gap.w4,
            _buildDeleteButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        width: AppDimens.videoCardCoverWidth,
        height: AppDimens.videoCardCoverHeight,
        color: isDarkMode ? AppColors.inputBgDark : AppColors.inputBgLight,
        child: task.cover.isNotEmpty
            ? Image.network(
                task.cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
              )
            : _buildPlaceholderCover(),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: isDarkMode ? AppColors.inputBgDark : AppColors.inputBgLight,
      child: Icon(
        LucideIcons.film,
        color: isDarkMode ? AppColors.textDarkHint : AppColors.textHint,
        size: AppDimens.iconLg,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Gap.h4,
        Text(
          task.episodeTitle,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXs,
            color:
                isDarkMode ? AppColors.gray400 : AppColors.gray500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (task.status == DownloadStatus.failed) ...[
          Gap.h4,
          Text(
            AppStrings.downloadFailedRetry,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSize2xs,
              color: AppColors.red,
            ),
          ),
        ],
        if (task.isRetrying) ...[
          Gap.h4,
          Text(
            '${AppStrings.downloadRetrying} (${task.retryCount}/${AppConfig.downloadMaxRetryCount})',
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSize2xs,
              color: AppColors.amber,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressOrContinueButton() {
    const size = AppDimens.downloadButtonSize;
    const strokeWidth = AppDimens.downloadProgressStrokeWidth;

    if (task.isCompleted) {
      return _buildActionButton(
        icon: LucideIcons.play,
        color: AppColors.accent,
        onTap: onPlay,
        size: size,
      );
    }

    if (task.isDownloading) {
      return GestureDetector(
        onTap: onPause,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: task.progress,
                strokeWidth: strokeWidth,
                backgroundColor: isDarkMode
                    ? AppColors.gray700
                    : AppColors.gray200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
              Text(
                '${task.progressPercent}',
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (task.isPaused) {
      return GestureDetector(
        onTap: onResume,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.098),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.amber,
              width: AppDimens.dividerThicknessMd,
            ),
          ),
          child: Center(
            child: Text(
              AppStrings.downloadContinue,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSize2xs,
                fontWeight: FontWeight.w600,
                color: AppColors.amber,
              ),
            ),
          ),
        ),
      );
    }

    if (task.isFailed) {
      return _buildActionButton(
        icon: LucideIcons.refreshCw,
        color: AppColors.red,
        onTap: onResume,
        size: size,
      );
    }

    if (task.isRetrying) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.098),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.amber,
            width: AppDimens.dividerThicknessMd,
          ),
        ),
        child: Center(
          child: Text(
            '${AppStrings.downloadRetrying}${task.retryCount}/${AppConfig.downloadMaxRetryCount}',
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSize2xs,
              fontWeight: FontWeight.w600,
              color: AppColors.amber,
            ),
          ),
        ),
      );
    }

    if (task.isQueued) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.gray500.withValues(alpha: 0.098),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.gray500,
            width: AppDimens.dividerThicknessMd,
          ),
        ),
        child: Center(
          child: Text(
            AppStrings.downloadQueueLabel,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSize2xs,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
        ),
      );
    }

    return const SizedBox(width: AppDimens.avatarMd, height: AppDimens.avatarMd);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.098),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: AppDimens.iconSize20,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: AppDimens.progressIndicatorWidth,
        height: AppDimens.progressIndicatorWidth,
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.098),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            LucideIcons.trash2,
            color: AppColors.red,
            size: AppDimens.iconMd,
          ),
        ),
      ),
    );
  }
}
