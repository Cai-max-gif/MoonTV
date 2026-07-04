import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/search_result.dart';
import '../models/douban_movie.dart';
import '../utils/image_url.dart';

class PlayerDetailsPanel extends StatelessWidget {
  final ThemeData theme;
  final DoubanMovieDetails? doubanDetails;
  final SearchResult? currentDetail;
  final bool showCloseButton;
  final bool showTitle;

  const PlayerDetailsPanel({
    super.key,
    required this.theme,
    this.doubanDetails,
    this.currentDetail,
    this.showCloseButton = true,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: showCloseButton 
            ? (isDarkMode ? AppColors.darkCard : AppColors.white)
            : AppColors.transparent,
      ),
      child: Column(
        children: [
          // 标题         if (showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '详情',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
          if (!showTitle)
            Gap.h8,
          Expanded(
            child: doubanDetails != null
                ? _buildDoubanDetailsPanel(context, isDarkMode)
                : _buildCurrentDetailPanel(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  /// 构建豆瓣详情面板
  Widget _buildDoubanDetailsPanel(BuildContext context, bool isDarkMode) {
    final String title = doubanDetails!.title;
    final String cover = doubanDetails!.poster;
    final String year = doubanDetails!.year;
    final String? rate = doubanDetails!.rate;
    final List<String> genres = doubanDetails!.genres;
    final List<String> directors = doubanDetails!.directors;
    final List<String> writers = doubanDetails!.screenwriters;
    final List<String> actors = doubanDetails!.actors;
    final String summary = doubanDetails!.summary ?? AppStrings.detailNoSummary;
    final List<String> countries = doubanDetails!.countries;
    final List<String> languages = doubanDetails!.languages;
    final String? duration = doubanDetails!.duration;
    final String? originalTitle = doubanDetails!.originalTitle;
    final int? totalEpisodes = doubanDetails!.totalEpisodes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主要信息区域
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧封面
              _buildCoverImage(context, cover, 'douban', isDarkMode),
              Gap.w16,
              // 右侧信息
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // 标题
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.white : AppColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // 原标题
                      if (originalTitle != null &&
                          originalTitle.isNotEmpty &&
                          originalTitle != title)
                        Text(
                          originalTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode
                                ? AppColors.gray400
                                : AppColors.gray600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // 底部信息区域
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (countries.isNotEmpty || languages.isNotEmpty)
                            Text(
                              [
                                if (countries.isNotEmpty) countries.join(' | '),
                                if (languages.isNotEmpty) languages.join(' | '),
                              ].join(' | '),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDarkMode
                                    ? AppColors.gray400
                                    : AppColors.gray600,
                              ),
                            ),
                          Gap.h4,
                          Text(
                            year,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray600,
                            ),
                          ),
                          Gap.h4,
                          if (duration != null && duration.isNotEmpty) ...[
                            Text(
                              duration,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDarkMode
                                    ? AppColors.gray400
                                    : AppColors.gray600,
                              ),
                            ),
                            Gap.h4,
                          ],
                          if (totalEpisodes != null && totalEpisodes > 1) ...[
                            Text(
                              '$totalEpisodes集',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDarkMode
                                    ? AppColors.gray400
                                    : AppColors.gray600,
                              ),
                            ),
                            Gap.h4,
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // 评分
              if (rate != null && rate.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rate,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStarRating(rate, isDarkMode),
                  ],
                ),
            ],
          ),
          Gap.h16,
          // 标签区域
          if (genres.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '风格',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
                Gap.h8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres
                      .map((genre) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.gray700
                                  : AppColors.gray200,
                              borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
                            ),
                            child: Text(
                              genre,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDarkMode
                                    ? AppColors.gray300
                                    : AppColors.gray700,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          Gap.h16,
          // 制作信息
          if (directors.isNotEmpty || writers.isNotEmpty || actors.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '制作信息',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
                Gap.h8,
                _buildProductionInfo(directors, writers, actors, isDarkMode),
              ],
            ),
          Gap.h16,
          // 简介
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '简介',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.white : AppColors.black,
                ),
              ),
              Gap.h8,
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.gray300 : AppColors.gray700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建当前详情面板（基于currentDetail）
  Widget _buildCurrentDetailPanel(BuildContext context, bool isDarkMode) {
    final String title = currentDetail?.title ?? AppStrings.detailNoTitle;
    final String cover = currentDetail?.poster ?? '';
    final String year = currentDetail?.year ?? '未知年份';
    final String summary = currentDetail?.desc ?? AppStrings.detailNoSummary;
    final String? sourceName = currentDetail?.sourceName;
    final String? class_ = currentDetail?.class_;
    final List<String> episodes = currentDetail?.episodes ?? [];
    final int totalEpisodes = episodes.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主要信息区域
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧封面
              _buildCoverImage(context, cover, currentDetail?.source, isDarkMode),
              Gap.w16,
              // 右侧信息
              Expanded(
                child: SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // 标题
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.white : AppColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // 底部信息区域
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sourceName != null && sourceName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: isDarkMode
                                        ? AppColors.gray600
                                        : AppColors.gray400),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                sourceName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDarkMode
                                      ? AppColors.gray300
                                      : AppColors.gray700,
                                ),
                              ),
                            ),
                            Gap.h4,
                          ],
                          Text(
                            year,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray600,
                            ),
                          ),
                          Gap.h4,
                          if (totalEpisodes > 1)
                            Text(
                              '$totalEpisodes集',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDarkMode
                                    ? AppColors.gray400
                                    : AppColors.gray600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Gap.h16,
          // 分类信息
          if (class_ != null && class_.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分类',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.white : AppColors.black,
                  ),
                ),
                Gap.h8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: class_
                      .split(',')
                      .map((category) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.gray700
                                  : AppColors.gray200,
                              borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
                            ),
                            child: Text(
                              category.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDarkMode
                                    ? AppColors.gray300
                                    : AppColors.gray700,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          Gap.h16,
          // 简介
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '简介',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.white : AppColors.black,
                ),
              ),
              Gap.h8,
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.gray300 : AppColors.gray700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context, String cover, String? source, bool isDarkMode) {
    return SizedBox(
      width: 120,
      height: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: cover.isNotEmpty
            ? FutureBuilder<String>(
                future: getImageUrl(cover, source),
                builder: (context, snapshot) {
                  final String imageUrl = snapshot.data ?? cover;
                  final headers = getImageRequestHeaders(imageUrl, source);

                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 160,
                    cacheKey: imageUrl,
                    httpHeaders: headers,
                    memCacheWidth: (120 * MediaQuery.of(context).devicePixelRatio).round(),
                    memCacheHeight: (160 * MediaQuery.of(context).devicePixelRatio).round(),
                    placeholder: (context, url) => Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.gray800 : AppColors.gray200,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 120,
                      height: 160,
                      color: isDarkMode ? AppColors.gray800 : AppColors.gray200,
                      child: const Icon(Icons.movie, size: 50),
                    ),
                    fadeInDuration: AppDurations.normal,
                    fadeOutDuration: AppDurations.fastest,
                  );
                },
              )
            : Container(
                width: 120,
                height: 160,
                color: isDarkMode ? AppColors.gray800 : AppColors.gray200,
                child: const Icon(Icons.movie, size: 50),
              ),
      ),
    );
  }

  Widget _buildStarRating(String rate, bool isDarkMode) {
    try {
      final rating = double.parse(rate);
      final double fiveStarRating = rating / 2.0;
      final int fullStars = fiveStarRating.floor();
      final bool hasHalfStar = (fiveStarRating - fullStars) >= 0.5;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          if (index < fullStars) {
            return const Icon(Icons.star, color: AppColors.orange, size: AppDimens.iconSm);
          } else if (index == fullStars && hasHalfStar) {
            return Icon(Icons.star_half, color: AppColors.gray400, size: AppDimens.iconSm);
          } else {
            return Icon(Icons.star, color: AppColors.gray400, size: AppDimens.iconSm);
          }
        }),
      );
    } catch (e) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(Icons.star, color: AppColors.gray400, size: AppDimens.iconSm),
        ),
      );
    }
  }

  Widget _buildProductionInfo(
    List<String> directors,
    List<String> writers,
    List<String> actors,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (directors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.gray300 : AppColors.gray700,
                ),
                children: [
                  const TextSpan(
                    text: '导演: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: directors.join(' / ')),
                ],
              ),
            ),
          ),
        if (writers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.gray300 : AppColors.gray700,
                ),
                children: [
                  const TextSpan(
                    text: '编剧: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: writers.join(' / ')),
                ],
              ),
            ),
          ),
        if (actors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.gray300 : AppColors.gray700,
                ),
                children: [
                  const TextSpan(
                    text: '主演: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: actors.join(' / ')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

