import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../constants/app_colors.dart';

class WindowsTitleBar extends StatefulWidget {
  final bool forceBlack;
  final Color? customBackgroundColor;
  final String? title;
  
  const WindowsTitleBar({
    super.key,
    this.forceBlack = false,
    this.customBackgroundColor,
    this.title,
  });

  @override
  State<WindowsTitleBar> createState() => _WindowsTitleBarState();
}

class _WindowsTitleBarState extends State<WindowsTitleBar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        
        // 优先使用自定义背景色，其次使用 forceBlack，最后使用默认颜色
        final backgroundColor = widget.customBackgroundColor ??
            (widget.forceBlack
                ? AppColors.transparent
                : (isDark 
                    ? AppColors.cardDark.withValues(alpha: 0.9)
                    : AppColors.white70));
        
        // Windows 11 风格的文字和图标颜色
        final foregroundColor = widget.forceBlack 
            ? AppColors.white
            : (isDark ? AppColors.white : AppColors.darkBg4);
        
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: Row(
            children: [
              // 左侧标题（可选）
              if (widget.title != null) ...[
                Gap.w12,
                Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeXs,
                    color: foregroundColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              // 可拖动区域
              Expanded(
                child: MoveWindow(),
              ),
              // 右侧 Windows 风格按钮
              _buildWindowsButton(
                onPressed: () {
                  appWindow.minimize();
                },
                icon: _MinimizeIcon(color: foregroundColor),
                isDark: isDark,
                isCloseButton: false,
              ),
              _buildWindowsButton(
                onPressed: () {
                  appWindow.maximizeOrRestore();
                },
                icon: _MaximizeIcon(color: foregroundColor),
                isDark: isDark,
                isCloseButton: false,
              ),
              _buildWindowsButton(
                onPressed: () {
                  appWindow.close();
                },
                icon: Icon(Icons.close, size: AppDimens.iconSm, color: foregroundColor),
                isDark: isDark,
                isCloseButton: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWindowsButton({
    required VoidCallback onPressed,
    required Widget icon,
    required bool isDark,
    required bool isCloseButton,
  }) {
    return SizedBox(
      width: 46,
      height: 40,
      child: _WindowsButtonHover(
        onPressed: onPressed,
        icon: icon,
        isDark: isDark,
        isCloseButton: isCloseButton,
      ),
    );
  }
}

// Windows 风格的按钮悬停效果
class _WindowsButtonHover extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final bool isDark;
  final bool isCloseButton;

  const _WindowsButtonHover({
    required this.onPressed,
    required this.icon,
    required this.isDark,
    required this.isCloseButton,
  });

  @override
  State<_WindowsButtonHover> createState() => _WindowsButtonHoverState();
}

class _WindowsButtonHoverState extends State<_WindowsButtonHover> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    
    if (_isPressed) {
      backgroundColor = widget.isCloseButton
          ? AppColors.darkRed // 深红色
          : (widget.isDark 
              ? AppColors.white10
              : AppColors.black30);
    } else if (_isHovered) {
      backgroundColor = widget.isCloseButton
          ? AppColors.winRed // Windows 11 红色
          : (widget.isDark 
              ? AppColors.white10
              : AppColors.black30);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          color: backgroundColor ?? AppColors.transparent,
          child: Center(
            child: widget.isCloseButton && _isHovered
                ? const Icon(
                    Icons.close,
                    size: AppDimens.iconSm,
                    color: AppColors.white,
                  )
                : widget.icon,
          ),
        ),
      ),
    );
  }
}

// 最小化图标
class _MinimizeIcon extends StatelessWidget {
  final Color color;

  const _MinimizeIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _MinimizePainter(color: color),
      ),
    );
  }
}

class _MinimizePainter extends CustomPainter {
  final Color color;

  _MinimizePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.3, y),
      Offset(size.width * 0.7, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 最大化/还原图标
class _MaximizeIcon extends StatelessWidget {
  final Color color;

  const _MaximizeIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _MaximizePainter(color: color),
      ),
    );
  }
}

class _MaximizePainter extends CustomPainter {
  final Color color;

  _MaximizePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.4,
      size.height * 0.4,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
