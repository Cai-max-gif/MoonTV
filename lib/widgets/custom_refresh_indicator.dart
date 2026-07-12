import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'package:provider/provider.dart';
import '../utils/font_utils.dart';
import '../services/theme_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// 自定义下拉刷新指示器
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshText;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.accent, // 绿色主题
          backgroundColor: themeService.isDarkMode 
              ? AppColors.cardDark 
              : AppColors.white,
          strokeWidth: 2.5,
          displacement: 40,
          child: this.child,
        );
      },
    );
  }
}

/// 自定义刷新指示器内容
class CustomRefreshIndicatorContent extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color? color;

  const CustomRefreshIndicatorContent({
    super.key,
    this.text,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final indicatorColor = color ?? AppColors.accent; // 绿色主题
        
        return Container(
          padding: AppDimens.paddingHorizontal20Vertical12,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            boxShadow: [
              BoxShadow(
                color: indicatorColor.withValues(alpha: 0.3),
                blurRadius: AppDimens.shadowBlurSm,
                offset: AppDimens.offset02,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.white,
                  size: AppDimens.iconSize20,
                ),
                Gap.w8,
              ],
              Text(
                text ?? AppStrings.pullToRefresh,
                style: FontUtils.poppins(
                  color: AppColors.white,
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 带自定义样式的刷新指示器
class StyledRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshText;
  final Color? primaryColor;
  final Color? backgroundColor;

  const StyledRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshText,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: primaryColor ?? AppColors.accent, // 默认绿色主题
          backgroundColor: backgroundColor ?? (themeService.isDarkMode 
              ? AppColors.cardDark 
               : AppColors.white),
          strokeWidth: 2.5,
          displacement: 40,
          child: this.child,
        );
      },
    );
  }
}
