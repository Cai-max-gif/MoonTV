import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';
import 'video_menu_bottom_sheet.dart';
import '../utils/image_url.dart';
import '../models/search_result.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_durations.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

/// 视频卡片组件
class VideoCard extends StatefulWidget {
  final VideoInfo videoInfo;
  final VoidCallback? onTap;
  final String from; // 场景值：AppConfig.sourceFavorite, AppConfig.sourcePlayrecord, AppConfig.sourceSearch, AppConfig.sourceAgg
  final double? cardWidth; // 卡片宽度，用于响应式布局
  final Function(VideoMenuAction)? onGlobalMenuAction; // 视频菜单操作回调
  final bool isFavorited; // 是否已收藏
  final List<SearchResult>? originalResults;
  final Function(SearchResult)? onSourceSelected;

  const VideoCard({
    super.key,
    required this.videoInfo,
    this.onTap,
    this.from = AppConfig.sourcePlayrecord,
    this.cardWidth,
    this.onGlobalMenuAction,
    this.isFavorited = false,
    this.originalResults,
    this.onSourceSelected,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _isHovered = false;
  bool _isPlayButtonHovered = false;
  bool _isDeleteButtonHovered = false;
  bool _isFavoriteButtonHovered = false;
  bool _isLinkButtonHovered = false;
  bool _isSourceCountBadgeHovered = false;
  bool? _localIsFavorited;

  bool get _isFavorited => _localIsFavorited ?? widget.isFavorited;

  @override
  void didUpdateWidget(covariant VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorited != widget.isFavorited) {
      _localIsFavorited = widget.isFavorited;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPC = DeviceUtils.isPC();

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // 使用传入的宽度或默认宽度
        final double width = widget.cardWidth ?? 120.0;
        final double height = width * 1.33; // 3:4 比例，与网格布局的0.75宽高比匹配

        // 缓存计算结果
        final bool shouldShowEpisodeInfo = _shouldShowEpisodeInfo();
        final bool shouldShowProgress = _shouldShowProgress();
        final String episodeText =
            shouldShowEpisodeInfo ? _getEpisodeText() : '';

        final String imageUrl = widget.videoInfo.cover;
        final headers =
            getImageRequestHeaders(imageUrl, widget.videoInfo.source);

        final cardContent = SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 封面图片和进度指示器
                  Stack(
                    children: [
                      // 封面图片
                      Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: AppDimens.shadowBlurSm,
                              offset: AppDimens.offset02,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            // 使用图片URL作为缓存key
                            cacheKey: imageUrl,
                            httpHeaders: headers,
                            // 添加缓存配置
                            memCacheWidth: (width *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
                            memCacheHeight: (height *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
                            // 占位符
                            placeholder: (context, url) => Container(
                              width: width,
                              height: height,
                              decoration: BoxDecoration(
                                color: themeService.isDarkMode
                                    ? AppColors.gray700
                                    : AppColors.gray300,
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                            ),
                            // 错误占位符
                            errorWidget: (context, url, error) => Container(
                              color: themeService.isDarkMode
                                  ? AppColors.gray700
                                  : AppColors.gray300,
                              child: Icon(
                                Icons.movie,
                                color: themeService.isDarkMode
                                    ? AppColors.gray600
                                    : AppColors.gray500,
                                size: AppDimens.iconSize40,
                              ),
                            ),
                            // 图片淡入动画
                            fadeInDuration: AppDurations.normal,
                            fadeOutDuration: AppDurations.fastest,
                          ),
                        ),
                      ),
                      // Hover 渐变蒙层（PC平台）
                      if (isPC)
                        AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: AppDurations.normal,
                          child: Container(
                            width: width,
                            height: height,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.transparent,
                                  AppColors.black.withValues(alpha: 0.6),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      // 年份徽章（搜索模式和聚合模式）
                      if ((widget.from == AppConfig.sourceSearch || widget.from == AppConfig.sourceAgg) &&
                          widget.videoInfo.year.isNotEmpty &&
                          widget.videoInfo.year != AppStrings.playerUnknown)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: AnimatedScale(
                            scale: isPC && _isHovered ? 1.05 : 1.0,
                            duration: AppDurations.normal,
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: AppDimens.paddingHorizontal7Vertical4,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                  widget.videoInfo.year,
                                  style: FontUtils.poppins(
                                    color: AppColors.white,
                                    fontSize: AppDimens.fontSizeXs,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ),
                          ),
                        ),
                      // 上映状态徽章（即将上映模式）
                      if (widget.from == AppConfig.sourceUpcoming &&
                          widget.videoInfo.releaseStatus != null &&
                          widget.videoInfo.releaseStatus!.isNotEmpty)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: AnimatedScale(
                            scale: isPC && _isHovered ? 1.1 : 1.0,
                            duration: AppDurations.normal,
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: AppDimens.paddingHorizontal6Vertical3,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                widget.videoInfo.releaseStatus!,
                                style: FontUtils.poppins(
                                  color: AppColors.white,
                                  fontSize: AppDimens.fontSize3xs,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      // 集数指示器或评分指示器
                      else if ((widget.from == AppConfig.sourceDouban ||
                              widget.from == AppConfig.sourceBangumi) &&
                          _shouldShowRating())
                        Positioned(
                          top: 4,
                          right: 4,
                          child: AnimatedScale(
                            scale: isPC && _isHovered ? 1.1 : 1.0,
                            duration: AppDurations.normal,
                            curve: Curves.easeInOut,
                            child: Container(
                              width: AppDimens.videoCardBadgeSize,
                              height: AppDimens.videoCardBadgeSize,
                              decoration: const BoxDecoration(
                                color: AppColors.pink, // 粉色圆形背景
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.videoInfo.rate!,
                                  style: FontUtils.poppins(
                                    color: AppColors.white,
                                    fontSize: AppDimens.fontSizeXs,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (shouldShowEpisodeInfo)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: AnimatedScale(
                            scale: isPC && _isHovered ? 1.1 : 1.0,
                            duration: AppDurations.normal,
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: AppDimens.paddingHorizontal7Vertical4,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                episodeText,
                                style: FontUtils.poppins(
                                  color: AppColors.white,
                                  fontSize: AppDimens.fontSizeXs,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // 进度条
                      if (shouldShowProgress)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.only(
                                bottomLeft: AppDimens.radius8,
                                bottomRight: AppDimens.radius8,
                              ),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: widget.videoInfo.progressPercentage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: AppDimens.radius8,
                                    bottomRight: AppDimens.radius8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // 中心播放按钮（PC平台）
                      if (isPC)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: widget.onTap,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _isHovered ? 1.0 : 0.0,
                                duration: AppDurations.normal,
                                child: MouseRegion(
                                  onEnter: (_) => setState(
                                      () => _isPlayButtonHovered = true),
                                  onExit: (_) => setState(
                                      () => _isPlayButtonHovered = false),
                                  child: AnimatedScale(
                                    scale: _isPlayButtonHovered ? 1.1 : 1.0,
                                    duration: AppDurations.normal,
                                    curve: Curves.easeInOut,
                                    child: AnimatedContainer(
                                      duration:
                                          AppDurations.normal,
                                      width: AppDimens.videoCardCoverWidth,
                                      height: AppDimens.videoCardCoverWidth,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isPlayButtonHovered
                                            ? (widget.from == AppConfig.sourceUpcoming
                                                ? AppColors.gold
                                                : AppColors.accent)
                                            : AppColors.transparent,
                                        border: Border.all(
                                          color: AppColors.white,
                                          width: AppDimens.videoCardBorderWidth,
                                        ),
                                      ),
                                      child: widget.from == AppConfig.sourceUpcoming
                                          ? const Icon(
                                              Icons.calendar_today,
                                              color: AppColors.white,
                                              size: AppDimens.iconSize28,
                                            )
                                          : CustomPaint(
                                              size: Size(AppDimens.videoCardPlayButtonSize, AppDimens.videoCardPlayButtonSize),
                                              painter: _PlayIconPainter(
                                                color: AppColors.white,
                                                strokeWidth: 2.0,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Hover 操作徽章（PC平台）
                      if (isPC) ...[
                        // 豆瓣和Bangumi模式：左上角链接徽章（即将上映不显示）
                        if ((widget.from == AppConfig.sourceDouban || widget.from == AppConfig.sourceBangumi) &&
                            widget.from != AppConfig.sourceUpcoming)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: AppDurations.normal,
                              child: MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _isLinkButtonHovered = true),
                                onExit: (_) => setState(
                                    () => _isLinkButtonHovered = false),
                                child: GestureDetector(
                                  onTap: () => _handleLinkButtonTap(),
                                  child: AnimatedScale(
                                    scale: _isLinkButtonHovered ? 1.05 : 1.0,
                                    duration: AppDurations.normal,
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      width: AppDimens.videoCardIconSize,
                                      height: AppDimens.videoCardIconSize,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.link,
                                        color: AppColors.white,
                                        size: AppDimens.iconMd,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // 聚合模式：右下角源数量徽章
                        if (widget.from == AppConfig.sourceAgg &&
                            widget.originalResults != null)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: AppDurations.normal,
                              child: MouseRegion(
                                onEnter: (_) => setState(
                                    () => _isSourceCountBadgeHovered = true),
                                onExit: (_) => setState(
                                    () => _isSourceCountBadgeHovered = false),
                                child: GestureDetector(
                                  onTap: () => _showSourcesDialog(context),
                                  child: AnimatedScale(
                                    scale:
                                        _isSourceCountBadgeHovered ? 1.1 : 1.0,
                                    duration: AppDurations.normal,
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      width: AppDimens.videoCardIconWidth,
                                      height: AppDimens.videoCardIconWidth,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.gray500.withValues(alpha: 0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${widget.originalResults!.length}',
                                          style: FontUtils.poppins(
                                            color: AppColors.white,
                                            fontSize: AppDimens.fontSizeXs,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // 播放记录模式：右下角垃圾桶和爱心
                        if (widget.from == AppConfig.sourcePlayrecord)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: AppDurations.normal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MouseRegion(
                                    onEnter: (_) => setState(
                                        () => _isDeleteButtonHovered = true),
                                    onExit: (_) => setState(
                                        () => _isDeleteButtonHovered = false),
                                    child: GestureDetector(
                                      onTap: () => _handleDeleteButtonTap(),
                                      child: AnimatedScale(
                                        scale:
                                            _isDeleteButtonHovered ? 1.05 : 1.0,
                                        duration:
                                            AppDurations.normal,
                                        curve: Curves.easeInOut,
                                        child: Icon(
                                          LucideIcons.trash2,
                                          color: _isDeleteButtonHovered
                                              ? AppColors.error
                                              : AppColors.white,
                                          size: AppDimens.iconLg,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Gap.w12,
                                  MouseRegion(
                                    onEnter: (_) => setState(
                                        () => _isFavoriteButtonHovered = true),
                                    onExit: (_) => setState(
                                        () => _isFavoriteButtonHovered = false),
                                    child: GestureDetector(
                                      onTap: () => _handleFavoriteButtonTap(),
                                      child: AnimatedScale(
                                        scale: _isFavoriteButtonHovered
                                            ? 1.05
                                            : 1.0,
                                        duration:
                                            AppDurations.normal,
                                        curve: Curves.easeInOut,
                                        child: Icon(
                                          _isFavorited ? Icons.star : Icons.star_border,
                                          color: _isFavorited
                                              ? AppColors.gold
                                              : (_isFavoriteButtonHovered
                                                  ? AppColors.gold
                                                  : AppColors.white),
                                          size: AppDimens.iconLg,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // 收藏夹、搜索模式：右下角爱心
                        if (widget.from == AppConfig.sourceFavorite ||
                            widget.from == AppConfig.sourceSearch)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: AppDurations.normal,
                              child: MouseRegion(
                                onEnter: (_) => setState(
                                    () => _isFavoriteButtonHovered = true),
                                onExit: (_) => setState(
                                    () => _isFavoriteButtonHovered = false),
                                child: GestureDetector(
                                  onTap: () => _handleFavoriteButtonTap(),
                                  child: AnimatedScale(
                                    scale:
                                        _isFavoriteButtonHovered ? 1.05 : 1.0,
                                    duration: AppDurations.normal,
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      _isFavorited ? Icons.star : Icons.star_border,
                                      color: _isFavorited
                                          ? AppColors.gold
                                          : (_isFavoriteButtonHovered
                                              ? AppColors.gold
                                              : AppColors.white),
                                      size: AppDimens.iconLg,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                  Gap.h2,
                  // 标题和源名称容器，确保居中对齐
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 标题
                        Text(
                          widget.videoInfo.title,
                          style: FontUtils.poppins(
                            fontSize: width < 100 ? AppDimens.fontSizeXs : AppDimens.fontSizeSm,
                            fontWeight: FontWeight.w500,
                            color: isPC && _isHovered
                                ? AppColors.accent
                                : (themeService.isDarkMode
                                    ? AppColors.white
                                    : AppColors.primary),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 豆瓣模式、Bangumi模式、聚合模式、即将上映模式、播放记录模式和短剧模式不显示来源信息
                        if (widget.from != AppConfig.sourceDouban &&
                            widget.from != AppConfig.sourceBangumi &&
                            widget.from != AppConfig.sourceAgg &&
                            widget.from != AppConfig.sourceUpcoming &&
                            widget.from != AppConfig.sourcePlayrecord &&
                            widget.from != AppConfig.sourceShortDrama) ...[
                          Gap.h4,
                          // 视频源名称
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width < 100 ? AppDimens.spacingXs : AppDimens.spacingSm,
                              vertical: AppDimens.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isPC && _isHovered
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                width: AppDimens.borderWidth08,
                              ),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            ),
                              child: Text(
                              widget.from == AppConfig.sourceAgg
                                  ? _getAggregatedSourceText(
                                      widget.videoInfo.sourceName)
                                  : widget.videoInfo.sourceName,
                              style: FontUtils.poppins(
                                fontSize: width < 100 ? AppDimens.fontSize3xs : AppDimens.fontSizeXs,
                                color: isPC && _isHovered
                                    ? AppColors.accent
                                    : (widget.from == AppConfig.sourceAgg
                                        ? AppColors.purple
                                        : AppColors.textSecondary),
                                height: AppDimens.lineHeightTighter,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            // 如果是PC平台，添加hover效果
            if (isPC) {
              return GestureDetector(
                onTap: widget.onTap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: AnimatedScale(
                    scale: _isHovered ? 1.05 : 1.0,
                    duration: AppDurations.normal,
                    curve: Curves.easeInOut,
                    child: cardContent,
                  ),
                ),
              );
            }

            // 非PC平台，添加GestureDetector
            return GestureDetector(
              onTap: widget.onTap,
              onLongPress: (widget.from == AppConfig.sourcePlayrecord ||
                      widget.from == AppConfig.sourceDouban ||
                      widget.from == AppConfig.sourceBangumi ||
                      widget.from == AppConfig.sourceFavorite ||
                      widget.from == AppConfig.sourceSearch ||
                      widget.from == AppConfig.sourceAgg)
                  ? () {
                      // 使用微任务延迟震动反馈，确保动画优先执行
                      Future.microtask(() {
                        try {
                          HapticFeedback.mediumImpact();
                        } catch (e) {
                          // 震动失败时静默处理，不影响菜单显示
                        }
                      });

                      // 使用延迟显示菜单，避免长按阻塞UI
                      Future.delayed(AppDurations.debounceInterval, () {
                        if (context.mounted) {
                          _showGlobalMenu(context);
                        }
                      });
                    }
                  : null,
              // 优化长按响应
              onLongPressStart: (widget.from == AppConfig.sourcePlayrecord ||
                      widget.from == AppConfig.sourceDouban ||
                      widget.from == AppConfig.sourceBangumi ||
                      widget.from == AppConfig.sourceFavorite ||
                      widget.from == AppConfig.sourceSearch ||
                      widget.from == AppConfig.sourceAgg)
                  ? (_) {
                      // 长按开始时的视觉反馈
                    }
                  : null,
              // 设置手势行为，确保长按优先级
              behavior: HitTestBehavior.opaque,
              child: cardContent,
            );
      },
    );
  }

  /// 根据场景判断是否显示集数信息
  bool _shouldShowEpisodeInfo() {
    // 豆瓣模式和Bangumi模式不显示集数信息
    if (widget.from == AppConfig.sourceDouban || widget.from == AppConfig.sourceBangumi) {
      return false;
    }

    // 总集数为1时永远不显示集数指示器
    if (widget.videoInfo.totalEpisodes <= 1) {
      return false;
    }

    switch (widget.from) {
      case AppConfig.sourceFavorite:
        return true; // 收藏夹中显示总集数
      case AppConfig.sourcePlayrecord:
        return true; // 播放记录中显示当前/总集数
      case AppConfig.sourceSearch:
        return true; // 搜索模式中显示总集数
      case AppConfig.sourceAgg:
        return true; // 聚合模式中显示总集数
      case AppConfig.sourceShortDrama:
        return true; // 短剧模式中显示总集数
      default:
        return true; // 默认显示当前/总集数
    }
  }

  /// 获取集数显示文本
  String _getEpisodeText() {
    switch (widget.from) {
      case AppConfig.sourceFavorite:
        // 收藏夹：如果有播放记录（index > 0）显示 x/y，否则只显示总集数
        return widget.videoInfo.index > 0
            ? '${widget.videoInfo.index}/${widget.videoInfo.totalEpisodes}'
            : '${widget.videoInfo.totalEpisodes}';
      case AppConfig.sourcePlayrecord:
        return '${widget.videoInfo.index}/${widget.videoInfo.totalEpisodes}'; // 播放记录显示当前/总集数
      case AppConfig.sourceSearch:
        return '${widget.videoInfo.totalEpisodes}'; // 搜索模式只显示总集数
      case AppConfig.sourceAgg:
        return '${widget.videoInfo.totalEpisodes}'; // 聚合模式只显示总集数
      case AppConfig.sourceShortDrama:
        return '${widget.videoInfo.totalEpisodes}'; // 短剧模式只显示总集数
      default:
        return '${widget.videoInfo.index}/${widget.videoInfo.totalEpisodes}'; // 默认显示当前/总集数
    }
  }

  /// 根据场景判断是否显示进度条
  bool _shouldShowProgress() {
    switch (widget.from) {
      case AppConfig.sourceFavorite:
        return false; // 收藏夹中不显示进度条
      case AppConfig.sourceDouban:
        return false; // 豆瓣模式不显示进度条
      case AppConfig.sourceBangumi:
        return false; // Bangumi模式不显示进度条
      case AppConfig.sourceSearch:
        return false; // 搜索模式不显示进度条
      case AppConfig.sourceAgg:
        return false; // 聚合模式不显示进度条
      case AppConfig.sourceShortDrama:
        return false; // 短剧模式不显示进度条
      case AppConfig.sourcePlayrecord:
      default:
        return true; // 播放记录中显示进度条
    }
  }

  /// 判断是否应该显示评分
  bool _shouldShowRating() {
    // 评分为空或null时不显示
    if (widget.videoInfo.rate == null || widget.videoInfo.rate!.isEmpty) {
      return false;
    }

    // 尝试解析评分为数字，如果为0或解析失败则不显示
    try {
      final rating = double.parse(widget.videoInfo.rate!);
      return rating > 0;
    } catch (e) {
      // 如果评分不是数字格式，则不显示
      return false;
    }
  }

  /// 获取聚合源文本显示
  String _getAggregatedSourceText(String sourceNames) {
    final sources = sourceNames.split(', ');
    if (sources.length <= 2) {
      return sourceNames;
    } else {
      return '${sources.take(2).join(', ')}${AppStrings.sourceCountSeparator}${sources.length}${AppStrings.sourceCountSuffix}';
    }
  }

  /// 处理删除按钮点击
  void _handleDeleteButtonTap() {
    if (widget.onGlobalMenuAction != null) {
      widget.onGlobalMenuAction!(VideoMenuAction.deleteRecord);
    }
  }

  /// 处理收藏按钮点击
  void _handleFavoriteButtonTap() {
    if (widget.onGlobalMenuAction != null) {
      setState(() {
        _localIsFavorited = !_isFavorited;
      });
      if (widget.isFavorited) {
        widget.onGlobalMenuAction!(VideoMenuAction.unfavorite);
      } else {
        widget.onGlobalMenuAction!(VideoMenuAction.favorite);
      }
    }
  }

  /// 处理链接按钮点击
  void _handleLinkButtonTap() async {
    try {
      String? url;
      if (widget.from == AppConfig.sourceDouban && widget.videoInfo.doubanId != null) {
        url = '${AppConfig.doubanSubjectUrl}/${widget.videoInfo.doubanId}';
      } else if (widget.from == AppConfig.sourceBangumi &&
          widget.videoInfo.bangumiId != null) {
        url = '${AppConfig.bgmSubjectUrl}/${widget.videoInfo.bangumiId}';
      }

      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  /// 显示播放源列表对话框
  void _showSourcesDialog(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final sources = widget.originalResults;
    if (sources == null || sources.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.transparent,
          elevation: AppDimens.elevationNone,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: 320,
            ),
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? AppColors.inputBgDark
                  : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: AppDimens.shadowBlurMd,
                  offset: AppDimens.offset04,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Padding(
                  padding: AppDimens.paddingFromLTRB20202016,
                  child: Text(
                    AppStrings.panelAvailableSources,
                    style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeXxl,
                      fontWeight: FontWeight.w600,
                      color: themeService.isDarkMode
                          ? AppColors.white
                          : AppColors.inputBgDark,
                    ),
                  ),
                ),
                // 播放源列表
                Flexible(
                  child: Container(
                    padding: AppDimens.horizontalLgPadding,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: sources.map((source) {
                          return Material(
                            color: AppColors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onSourceSelected?.call(source);
                              },
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              child: Padding(
                                padding:
                                    AppDimens.verticalMdPadding,
                                child: Row(
                                  children: [
                                    Text(
                                      source.sourceName,
                                      style: FontUtils.poppins(
                                        fontSize: AppDimens.fontSizeXl,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (source.episodes.length > 1)
                                      Text(
                                        AppStrings.episodesCount.replaceAll('%d', '${source.episodes.length}'),
                                        style: FontUtils.poppins(
                                          fontSize: AppDimens.fontSizeMd,
                                          color: themeService.isDarkMode
                                               ? AppColors.white70
                                               : AppColors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Gap.h16,
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示视频菜单
  void _showGlobalMenu(BuildContext context) {
    if (widget.onGlobalMenuAction != null) {
      VideoMenuBottomSheet.show(
        context,
        videoInfo: widget.videoInfo,
        isFavorited: widget.isFavorited,
        onActionSelected: widget.onGlobalMenuAction!,
        from: widget.from,
        originalResults: widget.originalResults,
        onSourceSelected: widget.onSourceSelected,
      );
    }
  }
}

/// 自定义播放图标绘制器
class _PlayIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PlayIconPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // 绘制播放三角形（中空）
    // 计算三角形尺寸和位置，使其在圆形中居中
    final double triangleWidth = size.width * 0.35;
    final double triangleHeight = size.height * 0.45;

    // 水平居中，但稍微向右偏移以视觉居中
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double leftX = centerX - triangleWidth / 3; // 左边点
    final double rightX = centerX + triangleWidth * 2 / 3; // 右边点（向右偏移）

    path.moveTo(leftX, centerY - triangleHeight / 2); // 左上角
    path.lineTo(rightX, centerY); // 右中
    path.lineTo(leftX, centerY + triangleHeight / 2); // 左下角
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlayIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
