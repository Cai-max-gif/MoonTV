import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../utils/device_utils.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';
import '../models/video_info.dart';
import '../utils/font_utils.dart';
import 'shimmer_effect.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';

class ShortDramaGrid extends StatelessWidget {
  final List<Map<String, dynamic>>? shortDramas;
  final bool isLoading;
  final String? errorMessage;
  final Function(Map<String, dynamic>) onVideoTap;
  final Function(Map<String, dynamic>, VideoMenuAction)? onGlobalMenuAction;

  const ShortDramaGrid({
    super.key,
    this.shortDramas,
    this.isLoading = false,
    this.errorMessage,
    required this.onVideoTap,
    this.onGlobalMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && (shortDramas == null || shortDramas!.isEmpty)) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (shortDramas == null || shortDramas!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildShortDramasGrid();
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final params = _computeGridParams(context, constraints.maxWidth);
        final int skeletonCount = params.isTablet ? params.crossAxisCount * 2 : 6;

        return GridView.builder(
          padding: AppDimens.gridContentPadding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: params.crossAxisCount,
            childAspectRatio: params.itemWidth / params.itemHeight,
            crossAxisSpacing: params.spacing,
            mainAxisSpacing: params.isTablet ? 0 : 6,
          ),
          itemCount: skeletonCount,
          itemBuilder: (context, index) {
            return _buildSkeletonCard(params.itemWidth);
          },
        );
      },
    );
  }

  Widget _buildSkeletonCard(double width) {
    final double height = width * 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShimmerEffect(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        Gap.h4,
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
            size: AppDimens.iconSize80,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.tv_outlined,
            size: AppDimens.iconSize80,
            color: AppColors.silver,
          ),
          Gap.h24,
          Text(
            AppStrings.noContentWithName(AppStrings.navShortDrama),
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXxl,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap.h12,
          Text(
            AppStrings.comingSoonMore,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortDramasGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final params = _computeGridParams(context, constraints.maxWidth);

        return GridView.builder(
          padding: AppDimens.gridContentPadding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: params.crossAxisCount,
            childAspectRatio: params.itemWidth / params.itemHeight,
            crossAxisSpacing: params.spacing,
            mainAxisSpacing: params.isTablet ? 0 : 6,
          ),
          itemCount: shortDramas!.length,
          itemBuilder: (context, index) {
            final shortDrama = shortDramas![index];
            final videoInfo = _convertToVideoInfo(shortDrama);

            return VideoCard(
              videoInfo: videoInfo,
              onTap: () => onVideoTap(shortDrama),
              from: AppConfig.sourceShortDrama,
              cardWidth: params.itemWidth,
              onGlobalMenuAction: onGlobalMenuAction != null
                  ? (action) => onGlobalMenuAction!(shortDrama, action)
                  : null,
              isFavorited: false,
            );
          },
        );
      },
    );
  }

  Widget buildSliver() {
    if (isLoading && (shortDramas == null || shortDramas!.isEmpty)) {
      return _buildLoadingSliver();
    }

    if (errorMessage != null) {
      return SliverToBoxAdapter(child: _buildErrorState());
    }

    if (shortDramas == null || shortDramas!.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: AppDimens.gridContentPadding,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          // SliverPadding 已减去 padding，此处加回以匹配 _computeGridParams 的 padding 计算
          final params = _computeGridParams(context, constraints.crossAxisExtent + 32.0);

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: params.crossAxisCount,
              childAspectRatio: params.itemWidth / params.itemHeight,
              crossAxisSpacing: params.spacing,
              mainAxisSpacing: params.isTablet ? 0 : 6,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final shortDrama = shortDramas![index];
                final videoInfo = _convertToVideoInfo(shortDrama);
                return VideoCard(
                  videoInfo: videoInfo,
                  onTap: () => onVideoTap(shortDrama),
                  from: AppConfig.sourceShortDrama,
                  cardWidth: params.itemWidth,
                  onGlobalMenuAction: onGlobalMenuAction != null
                      ? (action) => onGlobalMenuAction!(shortDrama, action)
                      : null,
                  isFavorited: false,
                );
              },
              childCount: shortDramas!.length,
            ),
          );
        },
      ),
    );
  }

  static _GridParams _computeGridParams(BuildContext context, double screenWidth) {
    final double padding = AppDimens.gridPaddingHorizontal;
    final double spacing = AppDimens.gridSpacingMd;
    // 使用 DeviceUtils.getTabletColumnCount(context) 与电影页面保持一致，
    // 基于 MediaQuery.of(context).size.width 判断列数
    final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
    final bool isTablet = screenWidth >= 600;
    final double availableWidth = screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
    final double minItemWidth = AppDimens.gridMinItemWidth;
    final double calculatedItemWidth = availableWidth / crossAxisCount;
    final double itemWidth = math.max(calculatedItemWidth, minItemWidth);
    final double itemHeight = itemWidth * 2.0;
    return _GridParams(crossAxisCount: crossAxisCount, spacing: spacing, itemWidth: itemWidth, itemHeight: itemHeight, isTablet: isTablet);
  }

  Widget _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // SliverToBoxAdapter 不裁切 padding，constraints 即完整宽度
          final params = _computeGridParams(context, constraints.maxWidth);
          final int skeletonCount = params.isTablet ? params.crossAxisCount * 2 : 6;
          return SizedBox(
            height: (params.itemHeight + 6) * (skeletonCount / params.crossAxisCount).ceil(),
            child: GridView.builder(
              padding: AppDimens.gridContentPadding,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: params.crossAxisCount,
                childAspectRatio: params.itemWidth / params.itemHeight,
                crossAxisSpacing: params.spacing,
                mainAxisSpacing: params.isTablet ? 0 : 6,
              ),
              itemCount: skeletonCount,
              itemBuilder: (context, index) {
                return _buildSkeletonCard(params.itemWidth);
              },
            ),
          );
        },
      ),
    );
  }

  VideoInfo _convertToVideoInfo(Map<String, dynamic> shortDrama) {
    return VideoInfo(
      id: shortDrama[AppConfig.jsonId].toString(),
      title: shortDrama[AppConfig.jsonName] ?? '',
      year: shortDrama[AppConfig.jsonUpdateTime]?.toString().substring(0, 4) ?? '',
      cover: shortDrama[AppConfig.jsonCover] ?? shortDrama[AppConfig.jsonBackdrop] ?? '',
      source: AppConfig.sourceShortDrama,
      sourceName: AppStrings.shortDramaName,
      index: 1,
      totalEpisodes:
          int.tryParse(shortDrama[AppConfig.jsonEpisodeCount]?.toString() ?? '0') ?? 0,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: shortDrama[AppConfig.jsonName] ?? '',
      rate: shortDrama[AppConfig.jsonScore]?.toString() ?? shortDrama[AppConfig.jsonVoteAverage]?.toString() ?? '',
    );
  }
}

class _GridParams {
  final int crossAxisCount;
  final double spacing;
  final double itemWidth;
  final double itemHeight;
  final bool isTablet;
  const _GridParams({required this.crossAxisCount, required this.spacing, required this.itemWidth, required this.itemHeight, required this.isTablet});
}
