import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';
import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {

  static SharedPreferences? _prefsCache;
  static Future<SharedPreferences> get _prefs async =>
      _prefsCache ??= await SharedPreferences.getInstance();
  static String get announcementApiUrl => AppConfig.announcementEndpoint;
  static const String _cacheKey = AppConfig.cacheKeyAnnouncement;
  static const String _cacheTimeKey = AppConfig.cacheKeyAnnouncementTime;
  static Duration get _cacheDuration => AppConfig.announcementCacheDuration;

  static Announcement? _cachedAnnouncement;
  static DateTime? _lastFetchTime;

  static Future<Announcement?> getAnnouncement() async {
    try {
      // 检查内存缓存
      if (_cachedAnnouncement != null && _lastFetchTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastFetchTime!);
        if (difference < _cacheDuration) {
          return _cachedAnnouncement;
        }
      }

      // 检查本地缓存
      final cachedAnnouncement = await _getCachedAnnouncement();
      if (cachedAnnouncement != null && await _isCacheValid()) {
        _cachedAnnouncement = cachedAnnouncement;
        _lastFetchTime = DateTime.now();
        return cachedAnnouncement;
      }

      // 从API获取公告
      final response = await ApiService.get<Map<String, dynamic>>(
        announcementApiUrl,
        fromJson: (data) {
          return data as Map<String, dynamic>;
        },
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data!;
          Announcement? announcement;

          // 检查API返回的格式
          if (data.containsKey(AppConfig.jsonAnnouncement) &&
              data[AppConfig.jsonAnnouncement] is String) {
            // API返回的是简单格式，只有一个公告字符串
            final announcementContent = data[AppConfig.jsonAnnouncement] as String;
            // 检查内容是否为空
            if (announcementContent.trim().isNotEmpty) {
              announcement = Announcement(
                id: DateTime.now().toString(), // 使用时间戳作为临时ID
                title: AppStrings.announcementDefaultTitle,
                content: announcementContent,
                createdAt: DateTime.now(),
                isActive: true,
              );
            }
          } else if (data.containsKey(AppConfig.jsonId) &&
              data.containsKey(AppConfig.jsonTitle) &&
              data.containsKey(AppConfig.jsonContent)) {
            // API返回的是完整格式
            announcement = Announcement.fromJson(data);
            // 检查内容是否为空
            if (announcement.content.trim().isEmpty) {
              announcement = null;
            }
          }

          // 如果获取到公告，保存到缓存
          if (announcement != null) {
            await _saveAnnouncementToCache(announcement);
            _cachedAnnouncement = announcement;
            _lastFetchTime = DateTime.now();
          }

          return announcement;
        } catch (e) {
          // 解析失败，返回缓存或null
          final cached = await _getCachedAnnouncement();
          return cached;
        }
      } else {
        // API响应失败，返回缓存或null
        final cached = await _getCachedAnnouncement();
        return cached;
      }
    } catch (e) {
      // 发生错误，返回缓存或null
      final cachedAnnouncement = await _getCachedAnnouncement();
      return cachedAnnouncement;
    }
  }

  static Future<Announcement?> _getCachedAnnouncement() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return Announcement.fromJson(json);
      }
    } catch (e) {
      // 缓存读取失败
    }
    return null;
  }

  static Future<void> _saveAnnouncementToCache(Announcement announcement) async {
    try {
      final prefs = await _prefs;
      final jsonString = jsonEncode(announcement.toJson());
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // 缓存保存失败
    }
  }

  static Future<bool> _isCacheValid() async {
    try {
      final prefs = await _prefs;
      final cacheTime = prefs.getInt(_cacheTimeKey);
      if (cacheTime == null) return false;

      final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      final difference = now.difference(cacheDateTime);

      return difference < _cacheDuration;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shouldShowAnnouncement(Announcement? announcement) async {
    // 只要有公告就显示
    return announcement != null;
  }

  static Future<void> markAnnouncementViewed() async {
    // 保留此方法，保持向后兼容性
  }
}
