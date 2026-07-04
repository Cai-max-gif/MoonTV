import 'package:flutter/material.dart';
import '../models/release_calendar_item.dart';
import 'api_service.dart';
import '../constants/app_config.dart';

/// 即将上映服务
class ReleaseCalendarService {
  // 缓存数据
  static List<ReleaseCalendarItem>? _cachedItems;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = AppConfig.releaseCalendarCache;

  /// 检查缓存是否有效
  static bool hasValidCache() {
    return _cachedItems != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  /// 清除缓存
  static void clearCache() {
    _cachedItems = null;
    _cacheTime = null;
  }

  /// 获取即将上映列表
  static Future<ApiResponse<List<ReleaseCalendarItem>>> getReleaseCalendar(
    BuildContext context, {
    String? type, // 'movie' 或 'tv'
    int? limit,
    bool forceRefresh = false,
  }) async {
    try {
      // 检查缓存是否有效
      if (!forceRefresh &&
          _cachedItems != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        // 使用缓存数据
        var items = _cachedItems!;
        if (type != null) {
          items = items.where((item) => item.type == type).toList();
        }
        if (limit != null && items.length > limit) {
          items = items.sublist(0, limit);
        }
        return ApiResponse.success(items);
      }

      // 构建查询参数
      final queryParams = <String, String>{};
      if (type != null) {
        queryParams['type'] = type;
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      
      final response = await ApiService.get<Map<String, dynamic>>(
        '/api/release-calendar',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final itemsData = response.data!['items'] as List<dynamic>? ?? [];
        final items = itemsData
            .map((item) =>
                ReleaseCalendarItem.fromJson(item as Map<String, dynamic>))
            .toList();

        // 更新缓存（无分类过滤时缓存完整数据）
        if (type == null) {
          _cachedItems = items;
          _cacheTime = DateTime.now();
        }

        return ApiResponse.success(items);
      } else {
        return ApiResponse.error(response.message ?? '获取即将上映数据失败');
      }
    } catch (e) {
      return ApiResponse.error('获取即将上映数据异常: ${e.toString()}');
    }
  }

  /// 获取即将上映的电影
  static Future<ApiResponse<List<ReleaseCalendarItem>>> getUpcomingMovies(
    BuildContext context, {
    int? limit,
    bool forceRefresh = false,
  }) async {
    return getReleaseCalendar(context, type: 'movie', limit: limit, forceRefresh: forceRefresh);
  }

  /// 获取即将上映的电视剧
  static Future<ApiResponse<List<ReleaseCalendarItem>>> getUpcomingTvShows(
    BuildContext context, {
    int? limit,
    bool forceRefresh = false,
  }) async {
    return getReleaseCalendar(context, type: 'tv', limit: limit, forceRefresh: forceRefresh);
  }
}
