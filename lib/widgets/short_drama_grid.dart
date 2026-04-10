import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/device_utils.dart';
import 'video_card.dart';
import 'video_menu_bottom_sheet.dart';
import '../models/video_info.dart';
import '../utils/font_utils.dart';
import 'shimmer_effect.dart';

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
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final isTablet = DeviceUtils.isTablet(context);

        final double screenWidth = constraints.maxWidth;
        const double padding = 16.0;
        const double spacing = 12.0;
        final double availableWidth =
            screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
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
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 4),
        // 标题骨架
        Center(
          child: ShimmerEffect(
            width: width * 0.8,
            height: 12,
            borderRadius: BorderRadius.circular(4),
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
            color: Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '加载失败',
            style: FontUtils.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? '未知错误',
            style: FontUtils.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
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
          Icon(
            Icons.tv_outlined,
            size: 80,
            color: const Color(0xFFbdc3c7),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无短剧',
            style: FontUtils.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '当前分类下没有短剧',
            style: FontUtils.poppins(
              fontSize: 14,
              color: const Color(0xFF95a5a6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortDramasGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板模式根据宽度动态展示6～9列，手机模式3列
        final int crossAxisCount = DeviceUtils.getTabletColumnCount(context);
        final isTablet = DeviceUtils.isTablet(context);

        final double screenWidth = constraints.maxWidth;
        const double padding = 16.0;
        const double spacing = 12.0;
        final double availableWidth =
            screenWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
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
          itemCount: shortDramas!.length,
          itemBuilder: (context, index) {
            final shortDrama = shortDramas![index];
            final videoInfo = _convertToVideoInfo(shortDrama);

            return VideoCard(
              videoInfo: videoInfo,
              onTap: () => onVideoTap(shortDrama),
              from: 'shortdrama', // 使用shortdrama模式，显示集数信息
              cardWidth: itemWidth,
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

  /// 将短剧数据转换为VideoInfo对象
  VideoInfo _convertToVideoInfo(Map<String, dynamic> shortDrama) {
    return VideoInfo(
      id: shortDrama['id'].toString(),
      title: shortDrama['name'] ?? '',
      year: shortDrama['update_time']?.toString().substring(0, 4) ?? '',
      cover: shortDrama['cover'] ?? '',
      source: 'shortdrama',
      sourceName: '短剧',
      index: 1,
      totalEpisodes:
          int.tryParse(shortDrama['episode_count']?.toString() ?? '0') ?? 0,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: shortDrama['name'] ?? '',
    );
  }
}
