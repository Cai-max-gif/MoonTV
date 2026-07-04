import '../constants/app_config.dart';

// 通用图片地址处理工具

/// 根据来源处理图片 URL（例如豆瓣域名替换）。
/// - [originalUrl]: 原始图片地址
/// - [source]: 数据来源（如 'douban'、'bangumi'、'manmankan' 等）
/// 返回可直接用于加载的图片地址。
Future<String> getImageUrl(String originalUrl, String? source) async {
  // 直接返回原始图片URL
  return originalUrl;
}

/// 返回加载网络图片所需的 HTTP 头（主要用于绕过特定站点的反盗链）。
/// 注意：只有当 [source] 为 'douban' 或 URL 指向 douban 域名时才添加 Referer/UA。其他来源返回空头。
Map<String, String>? getImageRequestHeaders(String imageUrl, String? source) {
  // 检查是否是 manmankan 来源
  final bool isManmankanSource = (source == 'manmankan') || (source == 'upcoming_release') ||
      RegExp('https?://([^/]+\\.)?${AppConfig.manmankanDomain}', caseSensitive: false)
          .hasMatch(imageUrl);
  
  if (isManmankanSource) {
    return <String, String>{
      'Referer': AppConfig.manmankanReferer,
      'User-Agent': AppConfig.manmankanUserAgent,
      'Accept': AppConfig.imageAcceptHeader,
    };
  }

  // 检查是否是 douban 来源
  final bool isDoubanSource = (source == 'douban') ||
      RegExp('https?://([^/]+\\.)?${AppConfig.doubanDomainPattern}', caseSensitive: false)
          .hasMatch(imageUrl);

  if (isDoubanSource) {
    return <String, String>{
      'Referer': AppConfig.doubanReferer,
      'User-Agent': AppConfig.doubanMobileUserAgent,
      'Accept': AppConfig.imageAcceptHeader,
    };
  }
  return null;
}


