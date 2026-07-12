import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/douban_movie.dart';
import 'api_service.dart';
import 'douban_cache_service.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';

/// 豆瓣推荐数据请求参数
class DoubanRecommendsParams {
  final String kind;
  final String category;
  final String format;
  final String region;
  final String year;
  final String platform;
  final String sort;
  final String label;
  final int pageLimit;
  final int page;

  const DoubanRecommendsParams({
    required this.kind,
    this.category = 'all',
    this.format = 'all',
    this.region = 'all',
    this.year = 'all',
    this.platform = 'all',
    this.sort = 'T',
    this.label = 'all',
    this.pageLimit = 20,
    this.page = 0,
  });
}

/// 豆瓣数据请求参数（保持向后兼容）
class DoubanRequestParams {
  final String kind;
  final String category;
  final String type;
  final int pageLimit;
  final int page;

  const DoubanRequestParams({
    required this.kind,
    required this.category,
    required this.type,
    this.pageLimit = AppConfig.defaultPageLimit,
    this.page = 0,
  });

  /// 构建查询参数
  Map<String, String> toQueryParams() {
    return {
      AppConfig.queryKind: kind,
      AppConfig.queryCategory: category,
      AppConfig.queryType: type,
      AppConfig.queryPageLimit: pageLimit.toString(),
      AppConfig.queryPage: page.toString(),
    };
  }
}

/// 豆瓣数据请求服务
class DoubanService {
  static final DoubanCacheService _cacheService = DoubanCacheService();
  static bool _cacheInitialized = false;

  /// 初始化缓存服务
  static Future<void> _initCache() async {
    if (!_cacheInitialized) {
      await _cacheService.init();
      _cacheInitialized = true;
    }
  }

  /// 获取豆瓣分类数据
  ///
  /// 参数说明：
  /// - kind: 类型 (movie, tv)
  /// - category: 分类 (热门, tv, show 等)
  /// - type: 子类型 (全部, tv, show 等)
  /// - pageLimit: 每页数量，默认20
  /// - page: 起始页码，默认0
  static Future<ApiResponse<List<DoubanMovie>>> getCategoryData(
    BuildContext context, {
    required String kind,
    required String category,
    required String type,
    int pageLimit = AppConfig.defaultPageLimit,
    int page = 0,
  }) async {
    // 初始化缓存服务
    await _initCache();

    // 生成缓存键
    final cacheKey = _cacheService.generateDoubanCategoryCacheKey(
      kind: kind,
      category: category,
      type: type,
      pageLimit: pageLimit,
      page: page,
    );

    // 尝试从缓存获取数据（存取均为已处理后的 DoubanMovie 列表）
    try {
      final cachedData = await _cacheService.get<List<DoubanMovie>>(
        cacheKey,
        (raw) => (raw as List<dynamic>)
            .map((m) {
              final map = m as Map<String, dynamic>;
              return DoubanMovie(
                id: map[AppConfig.jsonId]?.toString() ?? '',
                title: map[AppConfig.jsonTitle]?.toString() ?? '',
                poster: map[AppConfig.jsonPoster]?.toString() ?? '',
                rate: map[AppConfig.jsonRate]?.toString(),
                year: map[AppConfig.jsonYear]?.toString() ?? '',
              );
            })
            .toList(),
      );

      if (cachedData != null) {
        return ApiResponse.success(cachedData);
      }
    } catch (e) {
      // 缓存读取失败，继续执行网络请求
    }
    // 直接使用默认的豆瓣数据源
    String apiUrl =
        '${AppConfig.doubanApiBase}/subject/recent_hot/$kind?start=${page * pageLimit}&limit=$pageLimit&category=$category&type=$type';

    try {
      final headers = {
        AppConfig.headerUserAgent: AppConfig.defaultUserAgent,
        AppConfig.headerReferer: AppConfig.doubanReferer,
        AppConfig.headerAccept: AppConfig.headerAcceptJsonTextPlain,
      };

      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: headers,
          )
          .timeout(AppDurations.networkTimeout);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          final doubanResponse = DoubanResponse.fromJson(data);

          // 缓存成功的结果（保存已处理后的 DoubanMovie 列表），缓存时间为1天
          try {
            await _cacheService.set(
              cacheKey,
              doubanResponse.items.map((e) => e.toJson()).toList(),
              AppConfig.doubanListCache,
            );
          } catch (cacheError) {
            // 缓存失败，静默处理
          }

          return ApiResponse.success(doubanResponse.items,
              statusCode: response.statusCode);
        } catch (parseError) {
          return ApiResponse.error('${AppStrings.doubanParseFailed}: ${parseError.toString()}');
        }
      } else {
        return ApiResponse.error(
          '${AppStrings.doubanFetchFailed}: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('${AppStrings.doubanRequestException}: ${e.toString()}');
    }
  }

  /// 获取热门电影数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotMovies(
    BuildContext context, {
    int pageLimit = AppConfig.defaultPageLimit,
    int page = 0,
  }) async {
    return getCategoryData(
      context,
      kind: AppConfig.stypeMovie,
      category: AppStrings.categoryHot,
      type: AppStrings.all,
      pageLimit: pageLimit,
      page: page,
    );
  }

  /// 获取热门剧集数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotTvShows(
    BuildContext context, {
    int pageLimit = AppConfig.defaultPageLimit,
    int page = 0,
  }) async {
    return getCategoryData(
      context,
      kind: AppConfig.stypeTv,
      category: AppStrings.filterValueRecentHot,
      type: AppConfig.stypeTv,
      pageLimit: pageLimit,
      page: page,
    );
  }

  /// 获取热门综艺数据
  static Future<ApiResponse<List<DoubanMovie>>> getHotShows(
    BuildContext context, {
    int pageLimit = AppConfig.defaultPageLimit,
    int page = 0,
  }) async {
    return getCategoryData(
      context,
      kind: AppConfig.stypeTv,
      category: AppConfig.categoryShow,
      type: AppConfig.stypeShow,
      pageLimit: pageLimit,
      page: page,
    );
  }

  /// 获取豆瓣推荐数据（新版筛选逻辑）
  static Future<ApiResponse<List<DoubanMovie>>> fetchDoubanRecommends(
    BuildContext context,
    DoubanRecommendsParams params, {
    String proxyUrl = '',
    bool useTencentCDN = false,
    bool useAliCDN = false,
  }) async {
    // 初始化缓存服务
    await _initCache();

    // 生成缓存键
    final cacheKey = _cacheService.generateDoubanRecommendsCacheKey(
      kind: params.kind,
      category: params.category,
      format: params.format,
      region: params.region,
      year: params.year,
      platform: params.platform,
      sort: params.sort,
      label: params.label,
      pageLimit: params.pageLimit,
      page: params.page,
    );

    // 尝试从缓存获取数据（存取均为已处理后的 DoubanMovie 列表）
    try {
      final cachedData = await _cacheService.get<List<DoubanMovie>>(
        cacheKey,
        (raw) => (raw as List<dynamic>)
            .map((m) {
              final map = m as Map<String, dynamic>;
              return DoubanMovie(
                id: map[AppConfig.jsonId]?.toString() ?? '',
                title: map[AppConfig.jsonTitle]?.toString() ?? '',
                poster: map[AppConfig.jsonPoster]?.toString() ?? '',
                rate: map[AppConfig.jsonRate]?.toString(),
                year: map[AppConfig.jsonYear]?.toString() ?? '',
              );
            })
            .toList(),
      );

      if (cachedData != null) {
        return ApiResponse.success(cachedData);
      }
    } catch (e) {
      // 缓存读取失败，继续执行网络请求
    }
    // 处理筛选参数，将 'all' 转换为空字符串
    String category = params.category == AppConfig.contentTypeAll ? '' : params.category;
    String format = params.format == AppConfig.contentTypeAll ? '' : params.format;
    String region = params.region == AppConfig.contentTypeAll ? '' : params.region;
    String year = params.year == AppConfig.contentTypeAll ? '' : params.year;
    String platform = params.platform == AppConfig.contentTypeAll ? '' : params.platform;
    String label = params.label == AppConfig.contentTypeAll ? '' : params.label;
    String sort = params.sort == 'T' ? '' : params.sort;

    // 构建 selected_categories
    Map<String, dynamic> selectedCategories = {AppStrings.filterType: category};
    if (format.isNotEmpty) {
      selectedCategories[AppStrings.filterFormat] = format;
    }
    if (region.isNotEmpty) {
      selectedCategories[AppStrings.filterRegion] = region;
    }

    // 构建 tags 数组
    List<String> tags = [];
    if (category.isNotEmpty) {
      tags.add(category);
    }
    if (category.isEmpty && format.isNotEmpty) {
      tags.add(format);
    }
    if (label.isNotEmpty) {
      tags.add(label);
    }
    if (region.isNotEmpty) {
      tags.add(region);
    }
    if (year.isNotEmpty) {
      tags.add(year);
    }
    if (platform.isNotEmpty) {
      tags.add(platform);
    }

    // 直接使用默认的豆瓣数据源
    String baseUrl =
        '${AppConfig.doubanApiBase}/${params.kind}/recommend';

    // 构建查询参数
    final queryParams = <String, String>{
      AppConfig.queryRefresh: '0',
      AppConfig.queryStart: (params.page * params.pageLimit).toString(),
      AppConfig.queryCount: params.pageLimit.toString(),
      AppConfig.querySelectedCategories: json.encode(selectedCategories),
      AppConfig.queryUncollect: 'false',
      AppConfig.queryScoreRange: '0,10',
      AppConfig.queryTags: tags.join(','),
    };

    if (sort.isNotEmpty) {
      queryParams[AppConfig.querySort] = sort;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    String target = uri.toString();

    try {
      final headers = {
        AppConfig.headerUserAgent: AppConfig.defaultUserAgent,
        AppConfig.headerReferer: AppConfig.doubanReferer,
        AppConfig.headerAccept: AppConfig.headerAcceptJsonTextPlain,
      };

      final response = await http
          .get(
            Uri.parse(target),
            headers: headers,
          )
          .timeout(AppDurations.networkTimeout);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);

          // 过滤并转换数据
          final itemsData = data[AppConfig.jsonItems] as List<dynamic>? ?? [];
          final filteredItems = itemsData
              .where((item) => item[AppConfig.jsonType] == AppConfig.stypeMovie || item[AppConfig.jsonType] == AppConfig.stypeTv)
              .map((item) => DoubanMovie.fromJson(item as Map<String, dynamic>))
              .toList();

          // 缓存成功的结果（保存已处理后的 DoubanMovie 列表），缓存时间为1天
          try {
            await _cacheService.set(
              cacheKey,
              filteredItems.map((e) => e.toJson()).toList(),
              AppConfig.doubanRecommendCache,
            );
          } catch (cacheError) {
            // 缓存失败，静默处理
          }

          return ApiResponse.success(filteredItems,
              statusCode: response.statusCode);
        } catch (parseError) {
          return ApiResponse.error('${AppStrings.doubanRecommendParseFailed}: ${parseError.toString()}');
        }
      } else {
        return ApiResponse.error(
          '${AppStrings.doubanRecommendFetchFailed}: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('${AppStrings.doubanRecommendRequestException}: ${e.toString()}');
    }
  }

  /// 获取豆瓣详情数据
  ///
  /// 参数说明：
  /// - doubanId: 豆瓣ID
  static Future<ApiResponse<DoubanMovieDetails>> getDoubanDetails(
    BuildContext context, {
    required String doubanId,
  }) async {
    // 初始化缓存服务
    await _initCache();

    // 生成缓存键
    final cacheKey = _cacheService.generateDoubanDetailsCacheKey(
      doubanId: doubanId,
    );

    // 尝试从缓存获取数据
    try {
      final cachedData = await _cacheService.get<DoubanMovieDetails>(
        cacheKey,
        (raw) {
          final map = raw as Map<String, dynamic>;

          // 处理推荐列表
          List<DoubanRecommendItem> recommends = [];
          if (map[AppConfig.jsonRecommends] != null) {
            final recommendsData = map[AppConfig.jsonRecommends] as List<dynamic>? ?? [];
            recommends = recommendsData
                .map((r) =>
                    DoubanRecommendItem.fromJson(r as Map<String, dynamic>))
                .toList();
          }

          return DoubanMovieDetails(
            id: map[AppConfig.jsonId]?.toString() ?? '',
            title: map[AppConfig.jsonTitle]?.toString() ?? '',
            poster: map[AppConfig.jsonPoster]?.toString() ?? '',
            rate: map[AppConfig.jsonRate]?.toString(),
            year: map[AppConfig.jsonYear]?.toString() ?? '',
            summary: map[AppConfig.jsonSummary]?.toString(),
            genres: (map[AppConfig.jsonGenres] as List<dynamic>? ?? [])
                .map((g) => g.toString())
                .toList(),
            directors: (map[AppConfig.jsonDirectors] as List<dynamic>? ?? [])
                .map((d) => d.toString())
                .toList(),
            screenwriters: (map[AppConfig.jsonScreenwriters] as List<dynamic>? ?? [])
                .map((s) => s.toString())
                .toList(),
            actors: (map[AppConfig.jsonActors] as List<dynamic>? ?? [])
                .map((a) => a.toString())
                .toList(),
            duration: map[AppConfig.jsonDuration]?.toString(),
            countries: (map[AppConfig.jsonCountries] as List<dynamic>? ?? [])
                .map((c) => c.toString())
                .toList(),
            languages: (map[AppConfig.jsonLanguages] as List<dynamic>? ?? [])
                .map((l) => l.toString())
                .toList(),
            releaseDate: map[AppConfig.jsonReleaseDateCamel]?.toString(),
            originalTitle: map[AppConfig.jsonOriginalTitleCamel]?.toString(),
            imdbId: map[AppConfig.jsonImdbId]?.toString(),
            totalEpisodes: map[AppConfig.jsonTotalEpisodesCamel] is int
                ? map[AppConfig.jsonTotalEpisodesCamel] as int
                : int.tryParse(map[AppConfig.jsonTotalEpisodesCamel]?.toString() ?? ''),
            recommends: recommends,
          );
        },
      );

      if (cachedData != null && cachedData.title.trim().isNotEmpty) {
        return ApiResponse.success(cachedData);
      } else if (cachedData != null) {
        await _cacheService.delete(cacheKey);
      }
    } catch (e) {
      // 缓存读取失败，继续执行网络请求
    }

    // 使用豆瓣 JSON API
    String apiUrl = '${AppConfig.doubanApiBase}/subject/$doubanId';

    try {
      final headers = {
        AppConfig.headerUserAgent: AppConfig.defaultUserAgent,
        AppConfig.headerReferer: AppConfig.doubanReferer,
        AppConfig.headerAccept: AppConfig.headerAcceptJsonTextPlain,
      };

      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: headers,
          )
          .timeout(AppDurations.networkTimeout);

      if (response.statusCode == 200) {
        try {
          // 解析 rexxar JSON 响应
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic>) {
            return ApiResponse.error(AppStrings.bangumiCacheFormatError);
          }

          final details = DoubanMovieDetails.fromJson(data);
          if (details.title.trim().isEmpty) {
            return ApiResponse.error(AppStrings.doubanDetailParseEmpty);
          }

          // 缓存成功的结果，缓存时间为1天
          try {
            await _cacheService.set(
              cacheKey,
              details.toJson(),
              AppConfig.doubanDetailCache,
            );
          } catch (cacheError) {
            // 缓存失败，静默处理
          }

          return ApiResponse.success(details, statusCode: response.statusCode);
        } catch (parseError) {
          return ApiResponse.error('${AppStrings.doubanDetailParseFailed}: ${parseError.toString()}');
        }
      } else {
        return ApiResponse.error(
          '${AppStrings.doubanDetailFetchFailed}: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('${AppStrings.doubanDetailRequestException}: ${e.toString()}');
    }
  }
}