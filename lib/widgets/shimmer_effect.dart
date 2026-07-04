import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: AppDurations.loadingCycle,
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: themeService.isDarkMode
                      ? [
                          AppColors.darkDivider,
                          AppColors.darkBg3,
                          AppColors.darkDivider,
                        ]
                      : [
                          AppColors.gray300,
                          AppColors.gray100,
                          AppColors.gray300,
                        ],
                  stops: [
                    0.0,
                    _shimmerAnimation.value,
                    1.0,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

