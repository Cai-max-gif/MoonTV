import 'dart:math' as math;
import '../constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import '../services/theme_service.dart';
import '../utils/device_utils.dart';
import 'video_card.dart';
import '../utils/image_url.dart';
import '../utils/font_utils.dart';
import 'video_menu_bottom_sheet.dart';
import 'shimmer_effect.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';

/// 继续观看组件
class ContinueWatchingSection extends StatefulWidget {
  final Function(PlayRecord)? onVideoTap;
  final Function(PlayRecord, VideoMenuAction)? onGlobalMenuAction;
  final VoidCallback? onViewAll;

  const ContinueWatchingSection({
    super.key,
    this.onVideoTap,
    this.onGlobalMenuAction,
    this.onViewAll,
  });

  @override
  State<ContinueWatchingSection> createState() =>
      _ContinueWatchingSectionState();

  /// 静态方法：从外部移除播放记录
  static void removePlayRecordFromUI(String source, String id) {
    _ContinueWatchingSectionState._currentInstance
        ?.removePlayRecordFromUI(source, id);
  }

  /// 静态方法：刷新播放记录
  static Future<void> refreshPlayRecords() async {
    await _ContinueWatchingSectionState._currentInstance?.refreshPlayRecords();
  }
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection>
    with TickerProviderStateMixin {
  List<PlayRecord> _playRecords = [];
  bool _isLoading = true;
  bool _hasError = false;
  final PageCacheService _cacheService = PageCacheService();

  // 静态变量存储当前实例
  static _ContinueWatchingSectionState? _currentInstance;

  // 滚动控制相关
  final ScrollController _scrollController = ScrollController();
  bool _showLeftScroll = false;
  bool _showRightScroll = false;
  bool _isHovered = false;

  // hover 状态
  bool _isClearButtonHovered = false;
  bool _isMoreButtonHovered = false;

  @override
  void initState() {
    super.initState();

    // 设置当前实例
    _currentInstance = this;

    // 添加滚动监听
    _scrollController.addListener(_checkScroll);

    // 延迟执行异步操作，确保 initState 完成后再访问 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlayRecords();
        _checkScroll();
      }
    });
  }

  @override
  void dispose() {
    // 清除当前实例引用
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    _scrollController.removeListener(_checkScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!mounted) return;

    if (!_scrollController.hasClients) {
      // 如果还没有客户端，但有播放记录数据，显示右侧按钮
      if (_playRecords.isNotEmpty && _playRecords.length > 3) {
        setState(() {
          _showLeftScroll = false;
          _showRightScroll = true;
        });
      }
      return;
    }

    final position = _scrollController.position;
    const threshold = 1.0; // 容差值，避免浮点误差

    setState(() {
      _showLeftScroll = position.pixels > threshold;
      _showRightScroll = position.pixels < position.maxScrollExtent - threshold;
    });
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;

    // 根据可见卡片数动态计算滚动距离
    final double visibleCards =
        DeviceUtils.getHorizontalVisibleCards(context, 2.75);
    final double screenWidth = MediaQuery.of(context).size.width;
    const double padding = 32.0;
    const double spacing = 12.0;
    final double availableWidth = screenWidth - padding;
    final double cardWidth =
        (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
    // 每次滚动约 5 个卡片的距离
    final double scrollDistance = (cardWidth + spacing) * 5;

    _scrollController.animateTo(
      math.max(0, _scrollController.offset - scrollDistance),
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;

    // 根据可见卡片数动态计算滚动距离
    final double visibleCards =
        DeviceUtils.getHorizontalVisibleCards(context, 2.75);
    final double screenWidth = MediaQuery.of(context).size.width;
    const double padding = 32.0;
    const double spacing = 12.0;
    final double availableWidth = screenWidth - padding;
    final double cardWidth =
        (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
    // 每次滚动约 5 个卡片的距离
    final double scrollDistance = (cardWidth + spacing) * 5;

    _scrollController.animateTo(
      math.min(
        _scrollController.position.maxScrollExtent,
        _scrollController.offset + scrollDistance,
      ),
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  /// 加载播放记录
  Future<void> _loadPlayRecords() async {
    if (!mounted) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      final cachedRecordsRes = await _cacheService.getPlayRecords(context);

      if (cachedRecordsRes.success && cachedRecordsRes.data != null) {
        final cachedRecords = cachedRecordsRes.data!;
        // 有缓存数据，立即显示
        if (mounted) {
          setState(() {
            _playRecords = cachedRecords;
            _isLoading = false;
          });
        }

        // 预加载图片
        if (mounted) {
          _preloadImages(cachedRecords);
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// 预加载图片
  Future<void> _preloadImages(List<PlayRecord> records) async {
    if (!mounted) return;

    // 只预加载前几个图片，避免过度预加载
    final int preloadCount = math.min(records.length, 5);
    for (int i = 0; i < preloadCount; i++) {
      if (!mounted) break;

      final record = records[i];
      final imageUrl = await getImageUrl(record.cover, record.source);
      if (imageUrl.isNotEmpty && mounted) {
        final headers = getImageRequestHeaders(imageUrl, record.source);
        final provider = NetworkImage(imageUrl, headers: headers);
        precacheImage(provider, context);
      }
    }
  }

  /// 显示清空确认弹窗
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return AlertDialog(
              backgroundColor: themeService.isDarkMode
                  ? AppColors.cardDark
                  : AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  Gap.h20,
                  // 标题
                  Text(
                    AppStrings.clearPlayRecords,
                    style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeXxl,
                      fontWeight: FontWeight.w600,
                      color: themeService.isDarkMode
                          ? AppColors.white
                          : AppColors.primary,
                    ),
                  ),
                  Gap.h12,
                  // 描述
                  Text(
                    AppStrings.clearPlayRecordsConfirm,
                    style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeMd,
                      color: themeService.isDarkMode
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Gap.h24,
                  // 按钮
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            ),
                          ),
                          child: Text(
                            AppStrings.cancel,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              fontWeight: FontWeight.w500,
                              color: themeService.isDarkMode
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Gap.w12,
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _clearPlayRecords();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            ),
                            elevation: AppDimens.elevationNone,
                          ),
                          child: Text(
                            AppStrings.clear,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 清空播放记录
  Future<void> _clearPlayRecords() async {
    try {
      final response = await PageCacheService().clearPlayRecord(context);

      if (response.success) {
        setState(() {
          _playRecords.clear();
        });
        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.clearPlayRecordsDone,
                style: FontUtils.poppins(color: AppColors.white),
              ),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              margin: const EdgeInsets.all(AppDimens.spacingLg),
            ),
          );
        }
      } else {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.clearFailed,
                style: FontUtils.poppins(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              margin: const EdgeInsets.all(AppDimens.spacingLg),
            ),
          );
        }
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.clearFailed}: ${e.toString()}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            margin: const EdgeInsets.all(AppDimens.spacingLg),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有数据且不在加载中，隐藏组件
    if (!_isLoading && _playRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final isPC = DeviceUtils.isPC();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题、清空按钮和查看更多按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧：标题和清空按钮
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Consumer<ThemeService>(
                      builder: (context, themeService, child) {
                        return Text(
                          AppStrings.homeContinueWatching,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXxl,
                            fontWeight: FontWeight.w600,
                            color: themeService.isDarkMode
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                        );
                      },
                    ),
                    if (_playRecords.isNotEmpty) ...[
                      Gap.w8,
                      MouseRegion(
                        cursor: DeviceUtils.isPC()
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        onEnter: DeviceUtils.isPC()
                            ? (_) {
                                setState(() {
                                  _isClearButtonHovered = true;
                                });
                              }
                            : null,
                        onExit: DeviceUtils.isPC()
                            ? (_) {
                                setState(() {
                                  _isClearButtonHovered = false;
                                });
                              }
                            : null,
                        child: TextButton(
                          onPressed: _showClearConfirmation,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            overlayColor: AppColors.transparent,
                          ),
                          child: Text(
                            AppStrings.clear,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: DeviceUtils.isPC() && _isClearButtonHovered
                                  ? AppColors.error // hover 时红色
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // 右侧：查看更多按钮
                if (_playRecords.isNotEmpty)
                  MouseRegion(
                    cursor: DeviceUtils.isPC()
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    onEnter: DeviceUtils.isPC()
                        ? (_) {
                            setState(() {
                              _isMoreButtonHovered = true;
                            });
                          }
                        : null,
                    onExit: DeviceUtils.isPC()
                        ? (_) {
                            setState(() {
                              _isMoreButtonHovered = false;
                            });
                          }
                        : null,
                    child: TextButton(
                      onPressed: widget.onViewAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: AppColors.transparent,
                      ),
                      child: Text(
                        AppStrings.homeViewMore,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          color: DeviceUtils.isPC() && _isMoreButtonHovered
                              ? AppColors.accent // hover 时绿色
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Gap.h12,
          // 内容区域
          if (_isLoading)
            _buildLoadingState()
          else if (_hasError)
            _buildErrorState()
          else
            isPC ? _buildContentWithScrollButtons() : _buildContent(),
        ],
      ),
    );
  }

  /// 构建带滚动按钮的内容区域（PC端）
  Widget _buildContentWithScrollButtons() {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        // 延迟检查以确保滚动控制器已初始化
        Future.delayed(AppDurations.debounceInterval, _checkScroll);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          _buildContent(),
          // 左侧滚动按钮 - 定位在可视区域内
          if (_showLeftScroll)
            Positioned(
              left: 0,
              top: 0,
              bottom: 60,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 80,
                  color: AppColors.transparent,
                  child: IgnorePointer(
                    ignoring: !_isHovered,
                    child: AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: AppDurations.normal,
                      child: Center(
                        child: _buildScrollButton(
                          icon: Icons.chevron_left,
                          onPressed: _scrollLeft,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 右侧滚动按钮 - 定位在可视区域内
          if (_showRightScroll)
            Positioned(
              right: 0,
              top: 0,
              bottom: 60,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 80,
                  color: AppColors.transparent,
                  child: IgnorePointer(
                    ignoring: !_isHovered,
                    child: AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: AppDurations.normal,
                      child: Center(
                        child: _buildScrollButton(
                          icon: Icons.chevron_right,
                          onPressed: _scrollRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建滚动按钮
  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? const Color(0xE61F2937)
                    : const Color(0xF2FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeService.isDarkMode
                      ? AppColors.gray600
                      : AppColors.borderLightGray,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black30,
                    blurRadius: AppDimens.shadowBlurSm,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: themeService.isDarkMode
                    ? AppColors.gray300
                    : AppColors.gray600,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据宽度动态展示卡片数：平板模式 5.75/6.75/7.75，手机模式 2.75
        final double visibleCards =
            DeviceUtils.getHorizontalVisibleCards(context, 2.75);

        // 计算卡片宽度
        final double screenWidth = constraints.maxWidth;
        const double padding = 32.0; // 左右padding (16 * 2)
        const double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        const double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        final double cardHeight = (cardWidth * 1.5) + 50; // 缓存高度计算

        return SizedBox(
          height: cardHeight, // 使用缓存的高度
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _playRecords.length,
            itemBuilder: (context, index) {
              final playRecord = _playRecords[index];
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < _playRecords.length - 1 ? spacing : 0,
                ),
                child: VideoCard(
                  videoInfo: VideoInfo.fromPlayRecord(playRecord),
                  onTap: () => widget.onVideoTap?.call(playRecord),
                  from: 'playrecord',
                  cardWidth: cardWidth, // 使用动态计算的宽度
                  onGlobalMenuAction: (action) =>
                      widget.onGlobalMenuAction?.call(playRecord, action),
                  isFavorited: _cacheService.isFavoritedSync(
                      playRecord.source, playRecord.id), // 同步检测收藏状态
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据宽度动态展示卡片数：平板模式 5.75/6.75/7.75，手机模式 2.75
        final double visibleCards =
            DeviceUtils.getHorizontalVisibleCards(context, 2.75);
        final isTablet = DeviceUtils.isTablet(context);
        final int skeletonCount = isTablet ? visibleCards.ceil() : 3; // 骨架卡片数量

        // 计算卡片宽度
        final double screenWidth = constraints.maxWidth;
        const double padding = 32.0; // 左右padding (16 * 2)
        const double spacing = 12.0; // 卡片间距
        final double availableWidth = screenWidth - padding;
        // 确保最小宽度，防止负宽度约束
        const double minCardWidth = 120.0; // 最小卡片宽度
        final double calculatedCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
        final double cardWidth = math.max(calculatedCardWidth, minCardWidth);
        final double cardHeight = (cardWidth * 1.5) + 50; // 缓存高度计算

        return Container(
          height: cardHeight, // 使用缓存的高度
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: skeletonCount,
            itemBuilder: (context, index) {
              return Container(
                width: cardWidth,
                margin: EdgeInsets.only(
                  right: index < skeletonCount - 1 ? spacing : 0,
                ),
                child: _buildSkeletonCard(cardWidth),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.4; // 保持与VideoCard相同的比例

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 封面骨架
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        Gap.h6,
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 14,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
        ),
        Gap.h4,
        // 源名称骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.6,
            height: 10,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
        ),
      ],
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.gray400,
              size: 32,
            ),
            Gap.h8,
            Text(
              AppStrings.loadPlayRecordsFailed,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                color: AppColors.gray600,
              ),
            ),
            Gap.h8,
            TextButton(
              onPressed: _loadPlayRecords,
              child: Text(
                AppStrings.retry,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXs,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 刷新播放记录列表（供外部调用）
  Future<void> refreshPlayRecords() async {
    if (!mounted) return;

    try {
      if (mounted) {
        final cachedRecordsResult =
            await _cacheService.getPlayRecordsDirect(context);
        if (cachedRecordsResult.success && cachedRecordsResult.data != null) {
          final cachedRecords = cachedRecordsResult.data!;
          setState(() {
            _playRecords = cachedRecords;
          });

          // 预加载新图片
          _preloadImages(cachedRecords);
        }
      }
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  /// 从UI中移除指定的播放记录（供外部调用）
  void removePlayRecordFromUI(String source, String id) {
    if (!mounted) return;

    setState(() {
      _playRecords
          .removeWhere((record) => record.source == source && record.id == id);
    });
  }
}
