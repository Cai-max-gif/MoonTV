import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isActive,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class AnnouncementService {
  static const String announcementApiUrl = '/api/announcement';

  static Future<Announcement?> getAnnouncement() async {
    try {
      // 直接从API获取公告，不使用缓存
      final response = await ApiService.get<Map<String, dynamic>>(
        announcementApiUrl,
        fromJson: (data) {
          return data as Map<String, dynamic>;
        },
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data!;
          // 检查API返回的格式
          if (data.containsKey('announcement') &&
              data['announcement'] is String) {
            // API返回的是简单格式，只有一个公告字符串
            final announcementContent = data['announcement'] as String;
            // 检查内容是否为空
            if (announcementContent.trim().isEmpty) {
              return null;
            }
            // 创建一个临时的Announcement对象
            final announcement = Announcement(
              id: DateTime.now().toString(), // 使用时间戳作为临时ID
              title: '系统公告', // 默认标题
              content: announcementContent,
              createdAt: DateTime.now(),
              isActive: true,
            );

            return announcement;
          } else if (data.containsKey('id') &&
              data.containsKey('title') &&
              data.containsKey('content')) {
            // API返回的是完整格式
            final announcement = Announcement.fromJson(data);
            // 检查内容是否为空
            if (announcement.content.trim().isEmpty) {
              return null;
            }

            return announcement;
          } else {
            // 数据格式不符合预期，返回null
            return null;
          }
        } catch (e) {
          // 解析失败，返回null
          return null;
        }
      } else {
        // API响应失败，返回null
        return null;
      }
    } catch (e) {
      // 发生错误，返回null
      return null;
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
