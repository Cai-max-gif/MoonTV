import '../constants/app_config.dart';

/// 搜索资源模型
class SearchResource {
  final String key;
  final String name;
  final String api;
  final String detail;
  final String from;
  final bool disabled;

  SearchResource({
    required this.key,
    required this.name,
    required this.api,
    required this.detail,
    required this.from,
    required this.disabled,
  });

  factory SearchResource.fromJson(Map<String, dynamic> json) {
    return SearchResource(
      key: json[AppConfig.jsonKey] as String? ?? '',
      name: json[AppConfig.jsonName] as String? ?? '',
      api: json[AppConfig.jsonApi] as String? ?? '',
      detail: json[AppConfig.jsonDetail] as String? ?? '',
      from: json[AppConfig.jsonFrom] as String? ?? '',
      disabled: json[AppConfig.jsonDisabled] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonKey: key,
      AppConfig.jsonName: name,
      AppConfig.jsonApi: api,
      AppConfig.jsonDetail: detail,
      AppConfig.jsonFrom: from,
      AppConfig.jsonDisabled: disabled,
    };
  }
}
