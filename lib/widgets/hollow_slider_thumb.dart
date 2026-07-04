import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 空心圆形滑块拇指形状（用于设置页面的滑块）
class HollowRoundSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const HollowRoundSliderThumbShape({this.thumbRadius = 10});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.activeTrackColor ?? AppColors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, paint);

    final borderPaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? AppColors.gray500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
