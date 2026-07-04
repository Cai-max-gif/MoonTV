import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/font_utils.dart';
import '../constants/app_colors.dart';

class SelectorOption {
  final String label;
  final String value;

  const SelectorOption({required this.label, required this.value});
}

// FilterPill hover widget for PC
class FilterPillHover extends StatefulWidget {
  final bool isPC;
  final bool isDefault;
  final String title;
  final SelectorOption selectedOption;
  final VoidCallback onTap;

  const FilterPillHover({
    super.key,
    required this.isPC,
    required this.isDefault,
    required this.title,
    required this.selectedOption,
    required this.onTap,
  });

  @override
  State<FilterPillHover> createState() => _FilterPillHoverState();
}

class _FilterPillHoverState extends State<FilterPillHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 计算颜色：如果是PC且isDefault且hover，显示绿色；否则按原逻辑
    Color textColor;
    if (widget.isPC && widget.isDefault && _isHovered) {
      textColor = AppColors.accent;
    } else if (widget.isDefault) {
      textColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.gray500;
    } else {
      textColor = AppColors.accent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          ),
          child: Row(
            children: [
              Text(
                widget.isDefault ? widget.title : widget.selectedOption.label,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeSm,
                  color: textColor,
                  fontWeight:
                      widget.isDefault ? FontWeight.normal : FontWeight.w500,
                ),
              ),
              Gap.w4,
              Icon(
                Icons.arrow_drop_down,
                size: AppDimens.iconMd,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// FilterOption hover widget for PC
class FilterOptionHover extends StatefulWidget {
  final bool isPC;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;
  final bool useCompactLayout;

  const FilterOptionHover({
    super.key,
    required this.isPC,
    required this.isSelected,
    required this.label,
    required this.onTap,
    this.useCompactLayout = false,
  });

  @override
  State<FilterOptionHover> createState() => _FilterOptionHoverState();
}

class _FilterOptionHoverState extends State<FilterOptionHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 计算颜色：如果选中显示白色，如果PC且未选中且hover显示绿色，否则默认
    Color textColor;
    if (widget.isSelected) {
      textColor = AppColors.white;
    } else if (widget.isPC && _isHovered) {
      textColor = AppColors.accent;
    } else {
      textColor = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.black;
    }

    // 根据 useCompactLayout 参数决定使用哪种布局
    final bool shouldUseCompactLayout = widget.isPC && widget.useCompactLayout;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          alignment: Alignment.center,
          padding: shouldUseCompactLayout
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : null,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent
                : Theme.of(context).chipTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Text(
            widget.label,
            textAlign: shouldUseCompactLayout ? TextAlign.center : null,
            maxLines: shouldUseCompactLayout ? 2 : null,
            overflow: shouldUseCompactLayout ? TextOverflow.ellipsis : null,
            style: TextStyle(
              color: textColor,
              fontSize: shouldUseCompactLayout ? 12 : null,
            ),
          ),
        ),
      ),
    );
  }
}
