import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../models/search_result.dart';
import '../models/video_info.dart';
import '../services/page_cache_service.dart';
import '../services/theme_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';

/// 搜索结果网格组件
class SearchResultsGrid extends StatefulWidget {
  final List<SearchResult> results;
  final ThemeService themeService;
  final Function(VideoInfo)? onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final bool hasReceivedStart;

  const SearchResultsGrid({
    super.key,
    required this.results,
    required this.themeService,
    this.onVideoTap,
    this.onGlobalMenuAction,
    required this.hasReceivedStart,
  });

  @override
  State<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<SearchResultsGrid>
    with AutomaticKeepAliveClientMixin {
  final PageCacheService _cacheService = PageCacheService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持 AutomaticKeepAliveClientMixin

    if (widget.results.isEmpty && widget.hasReceivedStart) {
      return _buildEmptyState();
    }

    if (widget.results.isEmpty && !widget.hasReceivedStart) {
      return const SizedBox.shrink(); // 搜索开始但未收到start消息时，不显示任何内容
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final bool isTablet = DeviceUtils.isTablet(context);
        final double mainAxisSpacing = isTablet ? AppDimens.gridMainAxisSpacingTablet : AppDimens.gridMainAxisSpacingMobile;
        
        // 计算每列的宽度
        final double screenWidth = constraints.maxWidth;
        final double padding = AppDimens.gridPaddingHorizontal;
        final double spacing = AppDimens.gridSpacingMd;
        final double availableWidth = screenWidth -
            (padding * 2) -
            (spacing * (crossAxisCount - 1));
        final double minItemWidth = AppDimens.gridMinItemWidth;
        final double calculatedItemWidth = availableWidth / crossAxisCount;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0; // 增加高度比例，确保有足够空间避免溢出

        return GridView.builder(
          padding: AppDimens.horizontalMdVerticalLgPadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight, // 精确计算宽高比
            crossAxisSpacing: spacing, // 列间距
            mainAxisSpacing: mainAxisSpacing, // 行间距
          ),
          itemCount: widget.results.length,
          itemBuilder: (context, index) {
            final result = widget.results[index];
            final videoInfo = result.toVideoInfo();

            return AnimatedContainer(
              duration: AppDurations.slow,
              curve: Curves.easeOut,
              child: VideoCard(
                key: ValueKey(
                    '${result.id}_${result.source}'), // 为每个卡片添加唯一key
                videoInfo: videoInfo,
                onTap: widget.onVideoTap != null
                    ? () => widget.onVideoTap!(videoInfo)
                    : null,
                from: AppConfig.sourceSearch,
                cardWidth: itemWidth, // 传递计算出的宽度
                onGlobalMenuAction: widget.onGlobalMenuAction != null
                    ? (action) => widget.onGlobalMenuAction!(videoInfo, action)
                    : null,
                isFavorited: _cacheService.isFavoritedSync(
                    videoInfo.source, videoInfo.id), // 同步检查收藏状态
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: AppDimens.iconSize80,
            color: AppColors.silver,
          ),
          Gap.h24,
          Text(
            AppStrings.searchNoResults,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Gap.h12,
          Text(
            AppStrings.searchTryOther,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: AppColors.gray475,
            ),
          ),
        ],
      ),
    );
  }
}
