import '../constants/app_config.dart';

/// 安全工具类 - 防止注入攻击等安全相关功能
class SecurityUtils {
  SecurityUtils._();

  static String filterInjectionChars(String input) {
    String result = input;
    for (final char in AppConfig.injectionFilterChars) {
      result = result.replaceAll(char, '');
    }
    return result.trim();
  }

  static Map<String, String> filterQueryParameters(Map<String, String> parameters) {
    final filtered = <String, String>{};
    parameters.forEach((key, value) {
      filtered[key] = filterInjectionChars(value);
    });
    return filtered;
  }

  static Map<String, dynamic> filterRequestBody(Map<String, dynamic> body) {
    final filtered = <String, dynamic>{};
    body.forEach((key, value) {
      if (value is String) {
        filtered[key] = filterInjectionChars(value);
      } else if (value is Map) {
        filtered[key] = filterRequestBody(value as Map<String, dynamic>);
      } else if (value is List) {
        filtered[key] = _filterList(value);
      } else {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  static List<dynamic> _filterList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return filterInjectionChars(item);
      } else if (item is Map) {
        return filterRequestBody(item as Map<String, dynamic>);
      } else if (item is List) {
        return _filterList(item);
      }
      return item;
    }).toList();
  }
}
