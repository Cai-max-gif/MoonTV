import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/device_utils.dart';
import '../constants/app_colors.dart';

/// 切换播放源/集数时的加载蒙版组件
class SwitchLoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final String message;
  final AnimationController animationController;
  final VoidCallback? onBackPressed;

  const SwitchLoadingOverlay({
    super.key,
    required this.isVisible,
    required this.message,
    required this.animationController,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: AppColors.black,
        child: Stack(
          children: [
            // 左上角返回按钮
            if (onBackPressed != null)
              Positioned(
                top: 4,
                left: 8.0,
                child: DeviceUtils.isPC()
                    ? _HoverBackButton(
                        onTap: onBackPressed!,
                        iconColor: AppColors.white,
                      )
                    : GestureDetector(
                        onTap: onBackPressed,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimens.spacingSm),
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppColors.white,
                            size: AppDimens.iconSize20,
                          ),
                        ),
                      ),
              ),
            // 中心加载内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 加载动画 - 与页面加载蒙版保持一致
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 旋转的背景方块（半透明绿色）
                      RotationTransition(
                        turns: animationController,
                        child: Container(
                          width: AppDimens.loadingAnimationSize,
                          height: AppDimens.loadingAnimationSize,
                          decoration: BoxDecoration(
                            color:
                                AppColors.green.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          ),
                        ),
                      ),
                      // 中间的图标容器
                      Container(
                        width: AppDimens.iconSize80,
                        height: AppDimens.iconSize80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.green, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
                        ),
                        child: const Center(
                          child: Text(
                            '🎬',
                            style: TextStyle(fontSize: AppDimens.iconLg),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap.h24,
                  // 加载文案
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 带 hover 效果的返回按钮（PC 端专用）
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color iconColor;

  const _HoverBackButton({
    required this.onTap,
    required this.iconColor,
  });

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.spacingSm),
          decoration: _isHovering
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hoverOverlay,
                )
              : null,
          child: Icon(
            Icons.arrow_back,
            color: widget.iconColor,
            size: AppDimens.iconSize20,
          ),
        ),
      ),
    );
  }
}
