import '../models/search_result.dart';
import '../models/aggregated_search_result.dart';
import '../constants/app_content_filter.dart';
import '../constants/app_config.dart';

/// 内容过滤服务
class ContentFilterService {
  /// 黄色内容过滤（基于 type_name，仅在家庭模式下生效）
  static bool isYellowContent(String? typeName, {bool familyMode = false}) {
    if (!familyMode) return false;
    if (typeName == null || typeName.isEmpty) {
      return false;
    }
    final lowerTypeName = typeName.toLowerCase();
    return blockedKeywords
        .any((word) => lowerTypeName.contains(word.toLowerCase()));
  }

  /// 屏蔽的播放源列表
  static const List<String> blockedSources = AppContentFilter.blockedSources;

  /// 屏蔽的关键词列表
  static const List<String> blockedKeywords = AppContentFilter.blockedKeywords;

  /// 检查播放源是否在屏蔽列表中
  static bool isSourceBlocked(String? sourceName) {
    if (sourceName == null || sourceName.isEmpty) {
      return false;
    }

    return blockedSources.any((source) => sourceName.contains(source));
  }

  /// 检查标题是否包含屏蔽关键词
  static bool containsBlockedKeyword(String? title) {
    if (title == null || title.isEmpty) {
      return false;
    }

    return blockedKeywords.any((keyword) => title.contains(keyword));
  }

  /// 批量过滤黄色内容（基于 type_name，仅在家庭模式下生效）
  static List<SearchResult> yellowFilter(List<SearchResult> results, {bool familyMode = false}) {
    if (!familyMode) return results;
    return results
        .where((result) => !isYellowContent(result.typeName, familyMode: familyMode))
        .toList();
  }

  /// 检查搜索结果是否应该被过滤
  static bool shouldFilter(String? sourceName,
      {bool familyMode = false, String? title}) {
    if (!familyMode) {
      return false;
    }

    // 检查播放源
    if (isSourceBlocked(sourceName)) {
      return true;
    }

    // 检查标题关键词
    if (containsBlockedKeyword(title)) {
      return true;
    }

    return false;
  }

  /// 过滤聚合搜索结果
  static List<dynamic> filterAggregatedResults(List<dynamic> results,
      {bool familyMode = false}) {
    if (!familyMode) {
      return results;
    }

    return results.where((result) {
      // 检查结果类型
      if (result is Map<String, dynamic>) {
        // 检查标题
        final title = result[AppConfig.jsonTitle] as String?;
        if (containsBlockedKeyword(title)) {
          return false;
        }

        // 检查播放源
        if (result.containsKey(AppConfig.jsonSourceName)) {
          final sourceName = result[AppConfig.jsonSourceName] as String?;
          if (isSourceBlocked(sourceName)) {
            return false;
          }
        } else if (result.containsKey(AppConfig.jsonSourceNames)) {
          // 聚合结果，检查所有源
          final sourceNames = result[AppConfig.jsonSourceNames] as List<dynamic>?;
          if (sourceNames != null) {
            // 如果所有源都被屏蔽，则过滤掉
            final allSourcesBlocked = sourceNames
                .every((sourceName) => isSourceBlocked(sourceName as String));
            if (allSourcesBlocked) {
              return false;
            }
          }
        }
      } else if (result is SearchResult) {
        // 检查搜索结果
        return !shouldFilter(result.sourceName,
            familyMode: familyMode, title: result.title);
      } else if (result is AggregatedSearchResult) {
        // 检查聚合结果
        if (containsBlockedKeyword(result.title)) {
          return false;
        }
        // 检查所有源
        final allSourcesBlocked = result.sourceNames
            .every((sourceName) => isSourceBlocked(sourceName));
        if (allSourcesBlocked) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
