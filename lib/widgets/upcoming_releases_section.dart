import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/release_calendar_item.dart';
import '../models/video_info.dart';
import '../services/release_calendar_service.dart';
import '../services/theme_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import 'recommendation_section.dart';
import 'video_menu_bottom_sheet.dart';
import 'shimmer_effect.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';

/// 用于通知所有 UpcomingReleasesSection 实例刷新数据的 StreamController
final _refreshStreamController = StreamController<void>.broadcast();

/// 活跃实例计数器，用于跟踪是否需要关闭 StreamController
int _instanceCount = 0;

/// 即将上映组件
class UpcomingReleasesSection extends StatefulWidget {
  final Function(VideoInfo)? onItemTap;
  final VoidCallback? onMoreTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;

  const UpcomingReleasesSection({
    super.key,
    this.onItemTap,
    this.onMoreTap,
    this.onGlobalMenuAction,
  });

  @override
  State<UpcomingReleasesSection> createState() => _UpcomingReleasesSectionState();

  /// 静态方法：通知所有实例刷新即将上映数据
  static void refreshUpcomingReleases() {
    if (!_refreshStreamController.isClosed) {
      _refreshStreamController.add(null);
    }
  }

  /// 静态方法：手动关闭 StreamController（用于应用退出时）
  static void disposeStream() {
    if (!_refreshStreamController.isClosed) {
      _refreshStreamController.close();
    }
  }
}

class _UpcomingReleasesSectionState extends State<UpcomingReleasesSection> {
  List<ReleaseCalendarItem> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedFilter = AppConfig.contentTypeAll; // 'all', 'movie', 'tv'

  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _instanceCount++;
    _loadUpcomingReleases();
    _refreshSubscription = _refreshStreamController.stream.listen((_) {
      _loadUpcomingReleases();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _instanceCount--;
    if (_instanceCount <= 0 && !_refreshStreamController.isClosed) {
      _refreshStreamController.close();
    }
    super.dispose();
  }

  /// 加载即将上映数据
  Future<void> _loadUpcomingReleases() async {
    try {
      if (!mounted) return;

      // 如果有有效缓存，直接使用缓存数据，不显示loading
      if (ReleaseCalendarService.hasValidCache()) {
        final result = await ReleaseCalendarService.getReleaseCalendar(
          context,
          limit: 100,
        );
        if (!mounted) return;
        if (result.success && result.data != null) {
          setState(() {
            _items = result.data!;
            _isLoading = false;
          });
        }
        return;
      }

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final result = await ReleaseCalendarService.getReleaseCalendar(
        context,
        limit: 100,
      );

      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _items = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// 获取过滤后的数据，并按上映时间排序（仅显示未上映的）
  List<ReleaseCalendarItem> get _filteredItems {
    // 先过滤出未上映的（距离上映天数 > 0）
    final upcomingItems = _items.where((item) => item.getDaysUntilRelease() > 0).toList();

    List<ReleaseCalendarItem> items;
    if (_selectedFilter == 'all') {
      items = upcomingItems;
    } else {
      items = upcomingItems.where((item) => item.type == _selectedFilter).toList();
    }

    // 按上映时间排序：先上映的排前面
    items.sort((a, b) {
      try {
        // 先比较日期字符串（YYYY-MM-DD 格式可以直接比较）
        return a.releaseDate.compareTo(b.releaseDate);
      } catch (e) {
        // 如果解析失败，保持原有顺序
        return 0;
      }
    });

    return items;
  }

  /// 转换为VideoInfo列表
  List<VideoInfo> _convertToVideoInfos() {
    return _filteredItems.map((item) {
      return VideoInfo(
        id: item.id,
        source: AppConfig.sourceIdManmankan, // 改为 'manmankan' 而不是 'upcoming_release'，这样图片请求头能正确工作
        title: item.title,
        sourceName: AppStrings.homeUpcoming,
        year: item.year,
        cover: item.cover ?? '',
        index: 0,
        totalEpisodes: item.episodes ?? (item.type == AppConfig.stypeTv ? 0 : 1),
        playTime: 0,
        totalTime: 0,
        saveTime: item.createdAt,
        searchTitle: item.title,
        releaseDate: item.releaseDate,
        releaseStatus: item.getReleaseStatusText(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有数据且不在加载中且没有错误，隐藏组件
    // 如果过滤后没有可显示的内容（所有内容都已上映），也隐藏组件
    if (!_isLoading && !_hasError && (_items.isEmpty || _filteredItems.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // 标题和查看更多按钮
          Padding(
            padding: AppDimens.horizontalLgPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return Row(
                      children: [
                        Text(
                          AppStrings.homeUpcoming,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXxl,
                            fontWeight: FontWeight.w600,
                            color: themeService.isDarkMode
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (widget.onMoreTap != null)
                  TextButton(
                    onPressed: widget.onMoreTap,
                    style: TextButton.styleFrom(
                      padding: AppDimens.paddingHorizontal8Vertical4,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: AppColors.transparent,
                    ),
                    child: Text(
                      AppStrings.homeViewMore,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeMd,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Gap.h12,
          // 筛选标签
          if (!_isLoading && !_hasError && _items.isNotEmpty)
            _buildFilterTabs(),
          // 内容区域
          if (_isLoading)
            _buildLoadingState()
          else if (_hasError)
            _buildErrorState()
          else if (_filteredItems.isNotEmpty)
            RecommendationSection(
              title: '', // 空标题，因为上面已经显示了
              videoInfos: _convertToVideoInfos(),
              onItemTap: null, // 即将上映没有视频源，点击不跳转
              onGlobalMenuAction: widget.onGlobalMenuAction,
              isLoading: false,
              hasError: false,
              cardCount: 2.75,
              from: AppConfig.sourceUpcoming,
            ),
        ],
      );
  }

  /// 构建筛选标签
  Widget _buildFilterTabs() {
    // 仅统计未上映的项目数量
    final upcomingItems = _items.where((item) => item.getDaysUntilRelease() > 0).toList();
    final movieCount = upcomingItems.where((item) => item.type == AppConfig.stypeMovie).length;
    final tvCount = upcomingItems.where((item) => item.type == AppConfig.stypeTv).length;

    return Padding(
      padding: AppDimens.horizontalLgPadding,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Row(
            children: [
              _buildFilterChip(AppStrings.all, 'all', upcomingItems.length, themeService),
              Gap.w8,
              _buildFilterChip(AppStrings.movie, AppConfig.stypeMovie, movieCount, themeService),
              Gap.w8,
              _buildFilterChip(AppStrings.navTv, AppConfig.stypeTv, tvCount, themeService),
            ],
          );
        },
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterChip(String label, String value, int count, ThemeService themeService) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: AppDimens.paddingHorizontal12Vertical6,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange
              : (themeService.isDarkMode
                  ? AppColors.gray750
                  : AppColors.gray50),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (themeService.isDarkMode
                    ? AppColors.gray600
                    : AppColors.slate200),
            width: AppDimens.dividerThicknessThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeSm,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.white
                    : (themeService.isDarkMode
                        ? AppColors.gray650
                        : AppColors.gray600),
              ),
            ),
            if (count > 0) ...[
              Gap.w4,
              Text(
                '($count)',
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSize3xs,
                  color: isSelected
                          ? AppColors.white70
                          : AppColors.textSlate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double visibleCards = DeviceUtils.getHorizontalVisibleCards(context, 2.75);
        final isTablet = DeviceUtils.isTablet(context);
        final int skeletonCount = isTablet ? visibleCards.ceil() : 3;

        final double screenWidth = constraints.maxWidth;
        final double padding = AppDimens.gridPaddingHorizontalDouble;
        final double spacing = AppDimens.gridSpacingMd;
        final double availableWidth = screenWidth - padding;
        final double minCardWidth = AppDimens.gridMinCardWidth;
        final double calculatedCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
        final double cardWidth = calculatedCardWidth > minCardWidth ? calculatedCardWidth : minCardWidth;

        return Container(
          height: (cardWidth * 1.5) + 50,
          padding: AppDimens.horizontalLgPadding,
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final double height = width * 1.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShimmerEffect(
              width: width,
              height: height,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            Gap.h6,
            Center(
              child: ShimmerEffect(
                width: width * 0.8,
                height: 14,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建错误状态
  Widget _buildErrorState() {
    return Container(
      height: 100,
      padding: AppDimens.horizontalLgPadding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.gray400,
              size: AppDimens.iconSize32,
            ),
            Gap.h8,
            Text(
              AppStrings.loadFailed,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                color: AppColors.gray600,
              ),
            ),
            Gap.h8,
            TextButton(
              onPressed: _loadUpcomingReleases,
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
}
