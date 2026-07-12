import '../constants/app_config.dart';

// 直播频道数据模型
class LiveChannel {
  final String id; // 频道ID
  final String tvgId; // TVG ID
  final String name; // 频道名称
  final String logo; // 频道图标
  final String group; // 分组名称
  final String url; // 视频源地址
  bool isFavorite; // 是否收藏

  LiveChannel({
    required this.id,
    required this.tvgId,
    required this.name,
    required this.logo,
    required this.group,
    required this.url,
    this.isFavorite = false,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      id: json[AppConfig.jsonId] as String? ?? '',
      tvgId: json[AppConfig.jsonTvgId] as String? ?? '',
      name: json[AppConfig.jsonName] as String? ?? '',
      logo: json[AppConfig.jsonLogo] as String? ?? '',
      group: json[AppConfig.jsonGroup] as String? ?? '',
      url: json[AppConfig.jsonUrl] as String? ?? '',
      isFavorite: json[AppConfig.jsonIsFavorite] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTvgId: tvgId,
      AppConfig.jsonName: name,
      AppConfig.jsonLogo: logo,
      AppConfig.jsonGroup: group,
      AppConfig.jsonUrl: url,
      AppConfig.jsonIsFavorite: isFavorite,
    };
  }

  LiveChannel copyWith({
    String? id,
    String? tvgId,
    String? name,
    String? logo,
    String? group,
    String? url,
    bool? isFavorite,
  }) {
    return LiveChannel(
      id: id ?? this.id,
      tvgId: tvgId ?? this.tvgId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      group: group ?? this.group,
      url: url ?? this.url,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// 直播频道分组
class LiveChannelGroup {
  final String name;
  final List<LiveChannel> channels;

  LiveChannelGroup({
    required this.name,
    required this.channels,
  });
}
