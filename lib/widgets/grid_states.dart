import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../utils/font_utils.dart';

/// 网格加载/错误/空状态的共享组件
class GridErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const GridErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: AppDimens.iconSize80, color: AppColors.silver),
          Gap.h24,
          Text(
            AppStrings.loadFailed,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Gap.h12,
          Text(
            message ?? AppStrings.msgUnknownError,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            Gap.h16,
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: AppDimens.iconMd),
              label: Text(AppStrings.retry),
            ),
          ],
        ],
      ),
    );
  }
}

class GridEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const GridEmptyState({
    super.key,
    this.icon = Icons.movie_filter_outlined,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimens.iconSize80, color: AppColors.silver),
          Gap.h24,
          Text(
            message,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            Gap.h8,
            Padding(
              padding: AppDimens.paddingHorizontal32,
              child: Text(
                subtitle!,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
