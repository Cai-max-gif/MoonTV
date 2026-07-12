import '../constants/app_config.dart';

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
      id: json[AppConfig.jsonId]?.toString() ?? '',
      title: json[AppConfig.jsonTitle]?.toString() ?? '',
      content: json[AppConfig.jsonContent]?.toString() ?? '',
      createdAt: json[AppConfig.jsonCreatedAt] != null
          ? DateTime.parse(json[AppConfig.jsonCreatedAt] as String)
          : DateTime.now(),
      isActive: (json[AppConfig.jsonIsActive] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTitle: title,
      AppConfig.jsonContent: content,
      AppConfig.jsonCreatedAt: createdAt.toIso8601String(),
      AppConfig.jsonIsActive: isActive,
    };
  }
}
