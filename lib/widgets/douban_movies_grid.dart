import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/douban_movie.dart';
import '../utils/device_utils.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';
import '../models/video_info.dart';
import '../utils/font_utils.dart';
import 'shimmer_effect.dart';
import '../constants/app_dimensions.dart';

class DoubanMoviesGrid extends StatelessWidget {
  final List<DoubanMovie>? movies;
  final bool isLoading;
  final String? errorMessage;
  final Function(VideoInfo) onVideoTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;
  final String contentType; // 'movie' 或 'tv'

  const DoubanMoviesGrid({
    super.key,
    this.movies,
    this.isLoading = false,
    this.errorMessage,
    required this.onVideoTap,
    this.onGlobalMenuAction,
    this.contentType = 'movie', // 默认为电影
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && (movies == null || movies!.isEmpty)) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (movies == null || movies!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMoviesGrid();
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final isTablet = DeviceUtils.isTablet(context);
        
        final double screenWidth = constraints.maxWidth;
        const double padding = 16.0;
        const double spacing = 12.0;
        final double availableWidth = screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
        const double minItemWidth = 80.0;
        final double calculatedItemWidth = availableWidth / crossAxisCount;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: isTablet ? 0 : 6,
          ),
          itemCount: isTablet ? crossAxisCount * 2 : 6, // 平板显示2行，手机显示6个骨架卡片
          itemBuilder: (context, index) {
            return _buildSkeletonCard(itemWidth);
          },
        );
      },
    );
  }

  /// 构建骨架卡片
  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 封面骨架
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        Gap.h4,
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 12,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.silver,
          ),
          Gap.h24,
          Text(
            AppStrings.loadFailed,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Gap.h12,
          Text(
            errorMessage ?? AppStrings.unknownError,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: AppColors.gray475,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isMovie = contentType == 'movie';
    final String contentName = isMovie ? AppStrings.movie : AppStrings.tvShow;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMovie ? Icons.movie_filter_outlined : Icons.tv_outlined,
            size: 80,
            color: AppColors.silver,
          ),
          Gap.h24,
          Text(
            AppStrings.noContentWithName(contentName),
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Gap.h12,
          Text(
            AppStrings.noContentTipWithName(contentName),
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: AppColors.gray475,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final isTablet = DeviceUtils.isTablet(context);
        
        final double screenWidth = constraints.maxWidth;
        const double padding = 16.0;
        const double spacing = 12.0;
        final double availableWidth = screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
        const double minItemWidth = 80.0;
        final double calculatedItemWidth = availableWidth / crossAxisCount;
        final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
        final double itemHeight = itemWidth * 2.0;
        
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: isTablet ? 0 : 6,
          ),
          itemCount: movies!.length,
          itemBuilder: (context, index) {
            final movie = movies![index];
            final videoInfo = movie.toVideoInfo();
            
            return VideoCard(
              videoInfo: videoInfo,
              onTap: () => onVideoTap(videoInfo),
              from: 'douban',
              cardWidth: itemWidth,
              onGlobalMenuAction: onGlobalMenuAction != null ? (action) => onGlobalMenuAction!(videoInfo, action) : null,
              isFavorited: false, 
            );
          },
        );
      },
    );
  }
}
