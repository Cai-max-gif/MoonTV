import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/search_result.dart';
import '../utils/device_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';

class SourceSpeed {
  String quality = '';
  String loadSpeed = '';
  String pingTime = '';

  SourceSpeed({
    required this.quality,
    required this.loadSpeed,
    required this.pingTime,
  });
}

class PlayerSourcesPanel extends StatefulWidget {
  final ThemeData theme;
  final List<SearchResult> sources;
  final String currentSource;
  final String currentId;
  final Map<String, SourceSpeed> sourcesSpeed;
  final Function(SearchResult) onSourceTap;
  final Future<void> Function() onRefresh;
  final String videoCover;
  final String videoTitle;

  const PlayerSourcesPanel({
    super.key,
    required this.theme,
    required this.sources,
    required this.currentSource,
    required this.currentId,
    required this.sourcesSpeed,
    required this.onSourceTap,
    required this.onRefresh,
    required this.videoCover,
    required this.videoTitle,
  });

  @override
  State<PlayerSourcesPanel> createState() => _PlayerSourcesPanelState();
}

class _PlayerSourcesPanelState extends State<PlayerSourcesPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isRefreshing = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: AppDurations.oneSecond,
      vsync: this,
    );
    _scrollController = ScrollController();

    // 延迟滚动到当前源
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentSource();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startRefreshAnimation() {
    _rotationController.repeat();
  }

  void _stopRefreshAnimation() {
    _rotationController.stop();
    _rotationController.reset();
  }

  void _scrollToCurrentSource() {
    if (!_scrollController.hasClients) return;

    // 找到当前源在列表中的索引
    final currentIndex = widget.sources.indexWhere((source) =>
        source.source == widget.currentSource && source.id == widget.currentId);

    if (currentIndex == -1) return;

    // 计算每个项目的高度（包括间距）
    const itemHeight = 100.0; // 每个卡片的高度
    const itemSpacing = 12.0; // 卡片间距
    const totalItemHeight = itemHeight + itemSpacing;

    // 计算目标位置
    final targetOffset = currentIndex * totalItemHeight;

    // 滚动到目标位置
    _scrollController.animateTo(
      targetOffset,
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });
    _startRefreshAnimation();

    try {
      await widget.onRefresh();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
      _stopRefreshAnimation();
    }
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '换源 (${widget.sources.length})',
                  style: widget.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    MouseRegion(
                      cursor: (!_isRefreshing)
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      child: IconButton(
                        icon: RotationTransition(
                          turns: _rotationController,
                          child: Icon(
                            Icons.refresh,
                            color: _isRefreshing
                                ? AppColors.green
                                : (isDarkMode
                                    ? AppColors.gray400
                                    : AppColors.gray600),
                          ),
                        ),
                        onPressed: _isRefreshing ? null : _handleRefresh,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: AppDimens.contentPadding,
              itemCount: widget.sources.length,
              itemBuilder: (context, index) {
                final source = widget.sources[index];
                final isCurrent = source.source == widget.currentSource &&
                    source.id == widget.currentId;
                final speedInfo =
                    widget.sourcesSpeed['${source.source}_${source.id}'];

                return _SourcePanelItemWithHover(
                  isCurrent: isCurrent,
                  isDarkMode: isDarkMode,
                  source: source,
                  speedInfo: speedInfo,
                  theme: widget.theme,
                  onTap: isCurrent ? null : () => widget.onSourceTap(source),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 带 hover 效果的换源面板项（PC 端专用）
class _SourcePanelItemWithHover extends StatefulWidget {
  final bool isCurrent;
  final bool isDarkMode;
  final SearchResult source;
  final SourceSpeed? speedInfo;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _SourcePanelItemWithHover({
    required this.isCurrent,
    required this.isDarkMode,
    required this.source,
    this.speedInfo,
    required this.theme,
    this.onTap,
  });

  @override
  State<_SourcePanelItemWithHover> createState() =>
      _SourcePanelItemWithHoverState();
}

class _SourcePanelItemWithHoverState extends State<_SourcePanelItemWithHover> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: (DeviceUtils.isPC() && !widget.isCurrent)
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) {
        if (DeviceUtils.isPC() && !widget.isCurrent) {
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? (widget.isDarkMode ? AppColors.gray850 : AppColors.gray200)
                : (_isHovering && DeviceUtils.isPC()
                    ? (widget.isDarkMode
                        ? AppColors.darkGreen // 深色模式下的浅绿色
                        : AppColors.greenBg) // 浅色模式下的浅绿色
                    : (widget.isDarkMode
                        ? AppColors.gray850
                        : AppColors.gray200)),
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: widget.isCurrent
                ? Border.all(color: AppColors.green, width: 2)
                : null,
          ),
          child: Padding(
            padding: AppDimens.smallPadding,
            child: SizedBox(
              height: 100,
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Left side: Cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: CachedNetworkImage(
                            imageUrl: widget.source.poster,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.gray300,
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.gray300,
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                              child: Icon(
                                Icons.movie,
                                color: widget.isDarkMode
                                    ? AppColors.textDarkHint
                                    : AppColors.gray500,
                                size: 40,
                              ),
                            ),
                            fadeInDuration: AppDurations.normal,
                            fadeOutDuration: AppDurations.fastest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right side: Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.source.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: widget.theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Gap.h8,
                            // Source Name
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: widget.isDarkMode
                                        ? AppColors.gray600
                                        : AppColors.gray400),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                widget.source.sourceName,
                                style: widget.theme.textTheme.bodyMedium,
                              ),
                            ),
                            const Spacer(),
                            // Bottom row
                            Row(
                              children: [
                                if (widget.speedInfo != null) ...[
                                  if (widget.speedInfo!.loadSpeed.isNotEmpty &&
                                      !widget.speedInfo!.loadSpeed
                                          .toLowerCase()
                                          .contains('超时'))
                                    Text(
                                      widget.speedInfo!.loadSpeed,
                                      style: widget.theme.textTheme.bodyMedium
                                          ?.copyWith(color: AppColors.green),
                                    ),
                                  if (widget.speedInfo!.loadSpeed.isNotEmpty &&
                                      !widget.speedInfo!.loadSpeed
                                          .toLowerCase()
                                          .contains('超时') &&
                                      widget.speedInfo!.pingTime.isNotEmpty &&
                                      !widget.speedInfo!.pingTime
                                          .toLowerCase()
                                          .contains('超时'))
                                    const SizedBox(width: 8),
                                  if (widget.speedInfo!.pingTime.isNotEmpty &&
                                      !widget.speedInfo!.pingTime
                                          .toLowerCase()
                                          .contains('超时'))
                                    Text(
                                      widget.speedInfo!.pingTime,
                                      style: widget.theme.textTheme.bodyMedium
                                          ?.copyWith(color: AppColors.orange),
                                    ),
                                ],
                                const Spacer(),
                                if (widget.source.episodes.length > 1)
                                  Text(
                                    '${widget.source.episodes.length} 集',
                                    style: widget.theme.textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Resolution tag in top right
                  if (widget.speedInfo != null &&
                      widget.speedInfo!.quality.isNotEmpty &&
                      widget.speedInfo!.quality.toLowerCase() != AppStrings.m3u8ResolutionUnknown.toLowerCase())
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        widget.speedInfo!.quality,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          color: widget.isDarkMode
                              ? AppColors.gray400
                              : AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
