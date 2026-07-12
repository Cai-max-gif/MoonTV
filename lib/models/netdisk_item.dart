import '../constants/app_config.dart';
import '../constants/app_strings.dart';

/// 单个网盘资源链接
class NetDiskLink {
  final String url;
  final String password;
  final String note;
  final String datetime;
  final String source;
  final List<String> images;

  NetDiskLink({
    required this.url,
    required this.password,
    required this.note,
    required this.datetime,
    required this.source,
    this.images = const [],
  });

  /// 从 JSON 构造
  factory NetDiskLink.fromJson(Map<String, dynamic> json) {
    return NetDiskLink(
      url: json[AppConfig.jsonUrl] as String? ?? '',
      password: json[AppConfig.jsonPassword] as String? ?? '',
      note: json[AppConfig.jsonNote] as String? ?? '',
      datetime: json[AppConfig.jsonDatetime] as String? ?? '',
      source: json[AppConfig.jsonSource] as String? ?? '',
      images: (json[AppConfig.jsonImages] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// 显示的标题（优先使用 note，为空时显示占位）
  String get displayTitle => note.isNotEmpty ? note : AppStrings.netdiskUnnamedResource;

  /// 是否有提取码
  bool get hasPassword => password.isNotEmpty;
}

/// 网盘搜索结果
class NetDiskSearchResult {
  final bool success;
  final String? error;
  final int total;
  final Map<String, List<NetDiskLink>> mergedByType;
  final String source;
  final String query;
  final String? timestamp;

  NetDiskSearchResult({
    required this.success,
    this.error,
    this.total = 0,
    this.mergedByType = const {},
    this.source = '',
    this.query = '',
    this.timestamp,
  });

  /// 从 JSON 构造
  factory NetDiskSearchResult.fromJson(Map<String, dynamic> json) {
    // 失败响应
    if (json[AppConfig.jsonSuccess] != true) {
      return NetDiskSearchResult(
        success: false,
        error: json[AppConfig.jsonError] as String? ?? AppStrings.msgUnknownError,
      );
    }

    // 成功响应
    final data = json[AppConfig.jsonData] as Map<String, dynamic>? ?? {};
    final rawMerged = data[AppConfig.jsonMergedByType] as Map<String, dynamic>? ?? {};

    final mergedByType = <String, List<NetDiskLink>>{};
    rawMerged.forEach((key, value) {
      if (value is List) {
        mergedByType[key] = value
            .map((e) => NetDiskLink.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });

    return NetDiskSearchResult(
      success: true,
      total: data[AppConfig.jsonTotal] as int? ?? 0,
      mergedByType: mergedByType,
      source: data[AppConfig.jsonSource] as String? ?? '',
      query: data[AppConfig.jsonQuery] as String? ?? '',
      timestamp: data[AppConfig.jsonTimestamp] as String?,
    );
  }
}
