import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';
import '../models/search_resource.dart';
import 'api_service.dart';
import 'downstream_service.dart';
import 'user_data_service.dart';
import 'content_filter_service.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import '../constants/app_regex.dart';
import '../constants/app_strings.dart';
import '../utils/html_utils.dart';

/// 搜索服务
class SearchService {
  // 内存缓存
  static List<SearchResource>? _cachedResources;
  static bool _isRefreshing = false;

  /// 获取搜索资源列表（带缓存�?
  static Future<List<SearchResource>> _getSearchResourcesWithCache() async {
    // 如果有缓存，立即返回缓存数据
    if (_cachedResources != null) {
      // 异步刷新缓存（不等待�?
      if (!_isRefreshing) {
        _refreshCache();
      }
      return _cachedResources!;
    }

    // 如果没有缓存，同步获取并缓存
    return await _refreshCache();
  }

  /// 刷新缓存（仅用于服务器模式）
  static Completer<List<SearchResource>>? _refreshCacheCompleter;

  static Future<List<SearchResource>> _refreshCache() async {
    if (_isRefreshing) {
      // 如果正在刷新，等待当前刷新完�?
      if (_refreshCacheCompleter != null &&
          !_refreshCacheCompleter!.isCompleted) {
        return await _refreshCacheCompleter!.future;
      }
      return _cachedResources ?? [];
    }

    _isRefreshing = true;
    final completer = Completer<List<SearchResource>>();
    _refreshCacheCompleter = completer;

    try {
      final resources = await ApiService.getSearchResources();
      _cachedResources = resources;
      completer.complete(resources);
      return resources;
    } catch (e) {
      final result = _cachedResources ?? [];
      completer.complete(result);
      return result;
    } finally {
      _isRefreshing = false;
      _refreshCacheCompleter = null;
    }
  }

  /// 清除缓存（在需要强制刷新时调用�?
  static void clearCache() {
    _cachedResources = null;
  }

  /// 搜索推荐（只搜索第一个资源）
  /// 用于快速获取搜索建�?
  static Future<List<String>> searchRecommand(String query) async {
    try {
      // 获取搜索资源列表（使用缓存）
      final allResources = await _getSearchResourcesWithCache();

      // 过滤掉被禁用的资�?
      final resources =
          allResources.where((resource) => !resource.disabled).toList();

      if (resources.isEmpty) {
        return [];
      }

      // 只搜索第一个资源，设置 5 秒超�?
      final firstResource = resources.first;
      final results =
          await DownstreamService.searchFromApi(firstResource, query)
              .timeout(AppDurations.healthCheckTimeout)
              .catchError((error) {
        // 捕获错误，返回空列表
        return <SearchResult>[];
      });

      // 提取标题列表并去�?
      final titles = results.map((result) => result.title).toSet().toList();
      return titles;
    } catch (e) {
      return [];
    }
  }

  /// 同步搜索（本地搜索）
  /// 并发调用所有资源的搜索，返回所有结�?
  static Future<List<SearchResult>> searchSync(String query) async {
    try {
      // 获取搜索资源列表（使用缓存）
      final allResources = await _getSearchResourcesWithCache();

      // 过滤掉被禁用的资�?
      final resources =
          allResources.where((resource) => !resource.disabled).toList();

      if (resources.isEmpty) {
        return [];
      }

      // 并发调用所有资源的搜索，每个调用增�?20 秒超�?
      final searchFutures = resources.map((resource) {
        return DownstreamService.searchFromApi(resource, query)
            .timeout(AppDurations.networkTimeout)
            .catchError((error) {
          // 捕获错误，返回空列表
          return <SearchResult>[];
        });
      }).toList();

      // 等待所有搜索完�?
      final allResults = await Future.wait(searchFutures);

      // 按照 resources 的顺序合并结果（allResults 的顺序与 resources 一致）
      final results = <SearchResult>[];
      for (int i = 0; i < allResults.length; i++) {
        if (allResults[i].isNotEmpty) {
          results.addAll(allResults[i]);
        }
      }

      // 应用家庭模式过滤
      final familyMode = await UserDataService.getFamilyMode();
      final filteredResults = results
          .where((result) => !ContentFilterService.shouldFilter(
              result.sourceName,
              familyMode: familyMode,
              title: result.title))
          .toList();

      return filteredResults;
    } catch (e) {
      return [];
    }
  }

  /// 获取视频详情（本地直接调用下游API�?
  static Future<List<SearchResult>> getDetailSync(
      String source, String id) async {
    try {
      // 获取搜索资源列表（使用缓存）
      final allResources = await _getSearchResourcesWithCache();

      // 找到对应 source 的资�?
      final apiSite = allResources.firstWhere(
        (resource) => resource.key == source,
        orElse: () => throw Exception('${AppStrings.searchSourceNotFound}$source'),
      );

      // 如果 detail 不为空，使用特殊源处�?
      if (apiSite.detail.isNotEmpty) {
        final result = await _handleSpecialSourceDetail(id, apiSite);
        return [result];
      }

      // 构建详情请求 URL
      final detailUrl = '${apiSite.api}?${AppConfig.queryAc}=${AppConfig.apiValueVideolist}&${AppConfig.queryIds}=$id';

      // 发起请求，设�?10 秒超�?
      final response = await http.get(
        Uri.parse(detailUrl),
        headers: {
          AppConfig.headerUserAgent: AppConfig.defaultUserAgent,
          AppConfig.headerAccept: AppConfig.headerAcceptJson,
        },
      ).timeout(AppDurations.shortTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('${AppStrings.detailRequestFailed}${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data == null ||
          data[AppConfig.jsonList] == null ||
          data[AppConfig.jsonList] is! List ||
          (data[AppConfig.jsonList] as List).isEmpty) {
        throw Exception(AppStrings.searchDetailInvalid);
      }

      final videoDetail = data[AppConfig.jsonList][0];
      List<String> episodes = [];
      List<String> titles = [];

      // 处理播放源拆�?
      if (videoDetail[AppConfig.jsonVodPlayUrl] != null) {
        // 先用 $$$ 分割
        final vodPlayUrlArray =
            (videoDetail[AppConfig.jsonVodPlayUrl] as String).split('\$\$\$');

        // 分集之间 # 分割，标题和播放链接 $ 分割
        for (final url in vodPlayUrlArray) {
          List<String> matchEpisodes = [];
          List<String> matchTitles = [];

          final titleUrlArray = url.split('#');

          for (final titleUrl in titleUrlArray) {
            final episodeTitleUrl = titleUrl.split('\$');
            if (episodeTitleUrl.length == 2 &&
                episodeTitleUrl[1].endsWith('.m3u8')) {
              matchTitles.add(episodeTitleUrl[0]);
              matchEpisodes.add(episodeTitleUrl[1]);
            }
          }

          if (matchEpisodes.length > episodes.length) {
            episodes = matchEpisodes;
            titles = matchTitles;
          }
        }
      }

      // 如果播放源为空，则尝试从内容中解�?m3u8
      if (episodes.isEmpty && videoDetail[AppConfig.jsonVodContent] != null) {
        final m3u8Pattern = RegExp(AppRegex.m3u8Url);
        final matches =
            m3u8Pattern.allMatches(videoDetail[AppConfig.jsonVodContent] as String);
        episodes = matches.map((match) => match.group(0)!).toList();
      }

      // 解析年份
      String year = AppStrings.unknown;
      if (videoDetail[AppConfig.jsonVodYear] != null && videoDetail[AppConfig.jsonVodYear] != '') {
        final yearMatch =
            RegExp(AppRegex.yearPattern).firstMatch(videoDetail[AppConfig.jsonVodYear] as String);
        if (yearMatch != null) {
          year = yearMatch.group(0)!;
        }
      }

      final result = SearchResult(
        id: id,
        title: videoDetail[AppConfig.jsonVodName] ?? '',
        poster: videoDetail[AppConfig.jsonVodPic] ?? '',
        episodes: episodes,
        episodesTitles: titles,
        source: apiSite.key,
        sourceName: apiSite.name,
        class_: videoDetail[AppConfig.jsonVodClass],
        year: year,
        desc: _cleanHtmlTags(videoDetail[AppConfig.jsonVodContent] ?? ''),
        typeName: videoDetail[AppConfig.jsonTypeName],
        doubanId: videoDetail[AppConfig.jsonVodDoubanId],
      );

      return [result];
    } catch (e) {
      return [];
    }
  }

  /// 处理特殊源的详情（通过 HTML 页面解析�?
  static Future<SearchResult> _handleSpecialSourceDetail(
      String id, dynamic apiSite) async {
    final detailUrl = '${apiSite.detail}/index.php/vod/detail/id/$id.html';

    // 发起请求，设�?10 秒超�?
    final response = await http.get(
      Uri.parse(detailUrl),
      headers: {
        AppConfig.headerUserAgent: AppConfig.defaultUserAgent,
        AppConfig.headerAccept: AppConfig.headerAcceptTextHtml,
      },
    ).timeout(AppDurations.shortTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('${AppStrings.detailPageRequestFailed}${response.statusCode}');
    }

    final html = response.body;
    List<String> matches = [];

    // 如果�?ffzy 源，使用特殊的正则表达式
    if (apiSite.key == AppConfig.apiSiteKeyFfzy) {
      final ffzyPattern = RegExp(AppRegex.ffzySource);
      matches =
          ffzyPattern.allMatches(html).map((match) => match.group(0)!).toList();
    }

    // 如果没有匹配到，使用通用的正则表达式
    if (matches.isEmpty) {
      final generalPattern = RegExp(AppRegex.generalM3u8);
      matches = generalPattern
          .allMatches(html)
          .map((match) => match.group(0)!)
          .toList();
    }

    // 去重并清理链接前缀
    final uniqueMatches = matches.toSet().toList();
    final episodes = uniqueMatches.map((link) {
      // 去掉开头的 $
      link = link.substring(1);
      // 去掉可能的括号后缀
      final parenIndex = link.indexOf('(');
      return parenIndex > 0 ? link.substring(0, parenIndex) : link;
    }).toList();

    // 根据 episodes 数量生成剧集标题
    final episodesTitles =
        List.generate(episodes.length, (i) => (i + 1).toString());

    // 提取标题
    final titleMatch = RegExp(AppRegex.htmlTitle).firstMatch(html);
    final titleText = titleMatch != null ? titleMatch.group(1)!.trim() : '';

    // 提取描述
    final descMatch =
        RegExp(AppRegex.htmlDescription).firstMatch(html);
    final descText =
        descMatch != null ? _cleanHtmlTags(descMatch.group(1)!) : '';

    // 提取封面
    final coverMatches =
        RegExp(AppRegex.htmlCoverImage).allMatches(html);
    final coverUrl =
        coverMatches.isNotEmpty ? coverMatches.first.group(0)!.trim() : '';

    // 提取年份
    final yearMatch = RegExp(AppRegex.htmlYear).firstMatch(html);
    final yearText = yearMatch != null ? yearMatch.group(1)! : AppStrings.playerUnknown;

    return SearchResult(
      id: id,
      title: titleText,
      poster: coverUrl,
      episodes: episodes,
      episodesTitles: episodesTitles,
      source: apiSite.key,
      sourceName: apiSite.name,
      class_: '',
      year: yearText,
      desc: descText,
      typeName: '',
      doubanId: 0,
    );
  }

  /// 清理 HTML 标签
  static String _cleanHtmlTags(String text) {
    if (text.isEmpty) return '';

    String cleanedText = text
        .replaceAll(RegExp(AppRegex.htmlTag), '\n')
        .replaceAll(RegExp(AppRegex.newlines), '\n')
        .replaceAll(RegExp(AppRegex.whitespace), ' ')
        .replaceAll(RegExp(AppRegex.trimNewlines), '')
        .trim();

    return HtmlUtils.decodeEntities(cleanedText);
  }
}
