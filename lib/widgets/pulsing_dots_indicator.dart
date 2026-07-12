import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_dimensions.dart';

class PulsingDotsIndicator extends StatefulWidget {
  const PulsingDotsIndicator({super.key});

  @override
  State<PulsingDotsIndicator> createState() => _PulsingDotsIndicatorState();
}

class _PulsingDotsIndicatorState extends State<PulsingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.oneSecond,
    );

    _animations = List.generate(3, (index) {
      final intervalStart = index * 0.2;
      return Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            intervalStart,
            intervalStart + 0.4,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: AppDimens.paddingHorizontal4,
                child: Transform.scale(
                  scale: _animations[index].value,
                  child: Container(
                    width: AppDimens.pulsingDotSize,
                    height: AppDimens.pulsingDotSize,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
