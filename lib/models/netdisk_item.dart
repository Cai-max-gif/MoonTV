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
      url: json['url'] as String? ?? '',
      password: json['password'] as String? ?? '',
      note: json['note'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
      source: json['source'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
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
    if (json['success'] != true) {
      return NetDiskSearchResult(
        success: false,
        error: json['error'] as String? ?? AppStrings.msgUnknownError,
      );
    }

    // 成功响应
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawMerged = data['merged_by_type'] as Map<String, dynamic>? ?? {};

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
      total: data['total'] as int? ?? 0,
      mergedByType: mergedByType,
      source: data['source'] as String? ?? '',
      query: data['query'] as String? ?? '',
      timestamp: data['timestamp'] as String?,
    );
  }
}
