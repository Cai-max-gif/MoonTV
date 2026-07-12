import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/danmu_item.dart';
import '../constants/app_config.dart';

class DanmuCache {
  static const _cachePrefix = AppConfig.cacheKeyDanmu;
  static const _cacheDuration = AppConfig.danmuCacheDuration;

  static String _buildCacheKey(
      {String? title, String? doubanId, String? episode, String? episodeId}) {
    final parts = <String>[];
    if (title != null) parts.add('${AppConfig.danmuCacheKeyTitle}=$title');
    if (doubanId != null) parts.add('${AppConfig.danmuCacheKeyDoubanId}=$doubanId');
    if (episode != null) parts.add('${AppConfig.danmuCacheKeyEpisode}=$episode');
    if (episodeId != null) parts.add('${AppConfig.danmuCacheKeyEpisodeId}=$episodeId');
    return _cachePrefix + parts.join(AppConfig.urlSeparatorAmpersand);
  }

  static Future<void> save(
      {String? title,
      String? doubanId,
      String? episode,
      String? episodeId,
      required List<DanmuItem> data}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildCacheKey(
        title: title, doubanId: doubanId, episode: episode, episodeId: episodeId);
    final cacheData = json.encode({
      AppConfig.jsonTime: DateTime.now().millisecondsSinceEpoch,
      AppConfig.jsonData: data.map((e) => e.toJson()).toList(),
    });
    await prefs.setString(key, cacheData);
  }

  static Future<List<DanmuItem>?> load(
      {String? title,
      String? doubanId,
      String? episode,
      String? episodeId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildCacheKey(
        title: title, doubanId: doubanId, episode: episode, episodeId: episodeId);
    final cached = prefs.getString(key);
    if (cached == null) return null;

    final map = json.decode(cached) as Map<String, dynamic>;
    final time = DateTime.fromMillisecondsSinceEpoch(map[AppConfig.jsonTime] as int);
    if (DateTime.now().difference(time) > _cacheDuration) {
      await prefs.remove(key);
      return null;
    }

    final dataList = map[AppConfig.jsonData] as List;
    return dataList
        .map((e) => DanmuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
