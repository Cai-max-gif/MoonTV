import '../constants/app_config.dart';

/// 直播源模型
class LiveSource {
  final String key;
  final String name;
  final String url;
  final String ua;
  final String epg;
  final String from;
  final bool disabled;

  LiveSource({
    required this.key,
    required this.name,
    required this.url,
    required this.ua,
    required this.epg,
    required this.from,
    required this.disabled,
  });

  factory LiveSource.fromJson(Map<String, dynamic> json) {
    return LiveSource(
      key: json[AppConfig.jsonKey] as String? ?? '',
      name: json[AppConfig.jsonName] as String? ?? '',
      url: json[AppConfig.jsonUrl] as String? ?? '',
      ua: json[AppConfig.jsonUa] as String? ?? '',
      epg: json[AppConfig.jsonEpg] as String? ?? '',
      from: json[AppConfig.jsonFrom] as String? ?? '',
      disabled: json[AppConfig.jsonDisabled] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonKey: key,
      AppConfig.jsonName: name,
      AppConfig.jsonUrl: url,
      AppConfig.jsonUa: ua,
      AppConfig.jsonEpg: epg,
      AppConfig.jsonFrom: from,
      AppConfig.jsonDisabled: disabled,
    };
  }
}
