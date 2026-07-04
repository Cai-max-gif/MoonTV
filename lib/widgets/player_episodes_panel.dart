import 'package:flutter/material.dart';
import '../utils/device_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';

class PlayerEpisodesPanel extends StatefulWidget {
  final ThemeData theme;
  final List<String> episodes;
  final List<String> episodesTitles;
  final int currentEpisodeIndex;
  final bool isReversed;
  final Function(int) onEpisodeTap;
  final VoidCallback onToggleOrder;
  final int crossAxisCount;
  final bool showCloseButton;

  const PlayerEpisodesPanel({
    super.key,
    required this.theme,
    required this.episodes,
    required this.episodesTitles,
    required this.currentEpisodeIndex,
    required this.isReversed,
    required this.onEpisodeTap,
    required this.onToggleOrder,
    this.crossAxisCount = 2,
    this.showCloseButton = true,
  });

  @override
  State<PlayerEpisodesPanel> createState() => _PlayerEpisodesPanelState();
}

class _PlayerEpisodesPanelState extends State<PlayerEpisodesPanel> {
  final GlobalKey _gridKey = GlobalKey();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrent();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (_gridKey.currentContext == null) return;

    final gridBox = _gridKey.currentContext!.findRenderObject() as RenderBox;

    final targetIndex = widget.isReversed
        ? widget.episodes.length - 1 - widget.currentEpisodeIndex
        : widget.currentEpisodeIndex;

    final crossAxisCount = widget.crossAxisCount;
    const mainAxisSpacing = 12.0;
    final childAspectRatio = widget.crossAxisCount == 4 
        ? 2.2 
        : (widget.crossAxisCount == 3 ? 2.0 : 3.0);

    final itemWidth =
        (gridBox.size.width - (crossAxisCount - 1) * 12) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;

    final row = (targetIndex / crossAxisCount).floor();
    final offset = row * (itemHeight + mainAxisSpacing);

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.white,
      ),
      child: Column(
        children: [
          // 标题和关闭按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.episodeCount.replaceAll('%d', '${widget.episodes.length}'),
                  style: widget.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),

          // 集数网格
          Expanded(
            child: GridView.builder(
              key: _gridKey,
              controller: _scrollController,
              padding: AppDimens.contentPadding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: widget.crossAxisCount == 4 
                    ? 2.2 
                    : (widget.crossAxisCount == 3 ? 2.0 : 3.0),
              ),
              itemCount: widget.episodes.length,
              itemBuilder: (context, index) {
                final episodeIndex = widget.isReversed
                    ? widget.episodes.length - 1 - index
                    : index;
                final isCurrentEpisode =
                    episodeIndex == widget.currentEpisodeIndex;

                String episodeTitle = '';
                if (widget.episodesTitles.isNotEmpty &&
                    episodeIndex < widget.episodesTitles.length) {
                  episodeTitle = widget.episodesTitles[episodeIndex];
                } else {
                  episodeTitle = AppStrings.playerEpisodeFormat.replaceAll('%d', '${episodeIndex + 1}');
                }

                return _EpisodePanelItemWithHover(
                  isCurrentEpisode: isCurrentEpisode,
                  isDarkMode: isDarkMode,
                  episodeTitle: episodeTitle,
                  onTap: isCurrentEpisode ? null : () => widget.onEpisodeTap(episodeIndex),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


/// 带 hover 效果的选集面板项（PC 端专用）
class _EpisodePanelItemWithHover extends StatefulWidget {
  final bool isCurrentEpisode;
  final bool isDarkMode;
  final String episodeTitle;
  final VoidCallback? onTap;

  const _EpisodePanelItemWithHover({
    required this.isCurrentEpisode,
    required this.isDarkMode,
    required this.episodeTitle,
    this.onTap,
  });

  @override
  State<_EpisodePanelItemWithHover> createState() => _EpisodePanelItemWithHoverState();
}

class _EpisodePanelItemWithHoverState extends State<_EpisodePanelItemWithHover> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: (DeviceUtils.isPC() && !widget.isCurrentEpisode) 
          ? SystemMouseCursors.click 
          : MouseCursor.defer,
      onEnter: (_) {
        if (DeviceUtils.isPC() && !widget.isCurrentEpisode) {
          setState(() => _isHovering = true);
        }
      },
      onExit: (_) {
        if (DeviceUtils.isPC()) {
          setState(() => _isHovering = false);
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isCurrentEpisode
                ? AppColors.green.withValues(alpha: 0.2)
                : (_isHovering && DeviceUtils.isPC()
                    ? (widget.isDarkMode 
                        ? AppColors.darkGreen  // 深色模式下的浅绿色
                        : AppColors.greenBg)  // 浅色模式下的浅绿色
                    : (widget.isDarkMode ? AppColors.gray800 : AppColors.gray200)),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: widget.isCurrentEpisode
                ? Border.all(color: AppColors.green, width: 2)
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                widget.episodeTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.isCurrentEpisode
                      ? AppColors.green
                      : (widget.isDarkMode
                          ? AppColors.white
                          : AppColors.black),
                  fontWeight: FontWeight.w500,
                  fontSize: AppDimens.fontSizeMd,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
