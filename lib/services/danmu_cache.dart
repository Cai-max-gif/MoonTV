import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/danmu_item.dart';
import '../constants/app_config.dart';

class DanmuCache {
  static const _cachePrefix = 'danmu_cache_';
  static const _cacheDuration = AppConfig.danmuCacheDuration;

  static String _buildCacheKey(
      {String? title, String? doubanId, String? episode, String? episodeId}) {
    final parts = <String>[];
    if (title != null) parts.add('t=$title');
    if (doubanId != null) parts.add('d=$doubanId');
    if (episode != null) parts.add('e=$episode');
    if (episodeId != null) parts.add('ei=$episodeId');
    return _cachePrefix + parts.join('&');
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
      'time': DateTime.now().millisecondsSinceEpoch,
      'data': data.map((e) => e.toJson()).toList(),
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
    final time = DateTime.fromMillisecondsSinceEpoch(map['time'] as int);
    if (DateTime.now().difference(time) > _cacheDuration) {
      await prefs.remove(key);
      return null;
    }

    final dataList = map['data'] as List;
    return dataList
        .map((e) => DanmuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
