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
  String _selectedFilter = 'all'; // 'all', 'movie', 'tv'

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

  /// 获取过滤后的数据，并按上映时间排序
  List<ReleaseCalendarItem> get _filteredItems {
    List<ReleaseCalendarItem> items;
    if (_selectedFilter == 'all') {
      items = _items;
    } else {
      items = _items.where((item) => item.type == _selectedFilter).toList();
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
        source: 'manmankan', // 改为 'manmankan' 而不是 'upcoming_release'，这样图片请求头能正确工作
        title: item.title,
        sourceName: '即将上映',
        year: item.year,
        cover: item.cover ?? '',
        index: 0,
        totalEpisodes: item.episodes ?? (item.type == 'tv' ? 0 : 1),
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
    if (!_isLoading && _items.isEmpty && !_hasError) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // 标题和查看更多按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return Row(
                      children: [
                        Text(
                          '即将上映',
                          style: FontUtils.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: themeService.isDarkMode
                                ? const Color(0xFFffffff)
                                : const Color(0xFF2c3e50),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: Colors.transparent,
                    ),
                    child: Text(
                      '查看更多 >',
                      style: FontUtils.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7f8c8d),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
              onItemTap: widget.onItemTap,
              onGlobalMenuAction: widget.onGlobalMenuAction,
              isLoading: false,
              hasError: false,
              cardCount: 2.75,
              from: 'douban',
            ),
        ],
      );
  }

  /// 构建筛选标签
  Widget _buildFilterTabs() {
    final movieCount = _items.where((item) => item.type == 'movie').length;
    final tvCount = _items.where((item) => item.type == 'tv').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Row(
            children: [
              _buildFilterChip('全部', 'all', _items.length, themeService),
              const SizedBox(width: 8),
              _buildFilterChip('电影', 'movie', movieCount, themeService),
              const SizedBox(width: 8),
              _buildFilterChip('电视剧', 'tv', tvCount, themeService),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFf39c12)
              : (themeService.isDarkMode
                  ? const Color(0xFF2d3748)
                  : const Color(0xFFf7fafc)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFf39c12)
                : (themeService.isDarkMode
                    ? const Color(0xFF4a5568)
                    : const Color(0xFFe2e8f0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: FontUtils.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (themeService.isDarkMode
                        ? const Color(0xFFa0aec0)
                        : const Color(0xFF4a5568)),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: FontUtils.poppins(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white70
                      : (themeService.isDarkMode
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096)),
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
        const double padding = 32.0;
        const double spacing = 12.0;
        final double availableWidth = screenWidth - padding;
        const double minCardWidth = 120.0;
        final double calculatedCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;
        final double cardWidth = calculatedCardWidth > minCardWidth ? calculatedCardWidth : minCardWidth;

        return Container(
          height: (cardWidth * 1.5) + 50,
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final double height = width * 1.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShimmerEffect(
              width: width,
              height: height,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Center(
              child: ShimmerEffect(
                width: width * 0.8,
                height: 14,
                borderRadius: BorderRadius.circular(4),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: FontUtils.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadUpcomingReleases,
              child: Text(
                '重试',
                style: FontUtils.poppins(
                  fontSize: 12,
                  color: const Color(0xFF2c3e50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
