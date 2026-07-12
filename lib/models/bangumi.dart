import 'video_info.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';
import '../utils/html_utils.dart';

/// Bangumi 评分数据模型
class BangumiRating {
  final int total;
  final Map<String, int> count;
  final double score;

  const BangumiRating({
    required this.total,
    required this.count,
    required this.score,
  });

  factory BangumiRating.fromJson(Map<String, dynamic> json) {
    final countData = json[AppConfig.jsonCount] ?? {};
    final Map<String, int> safeCount = {};
    if (countData is Map) {
      countData.forEach((key, value) {
        safeCount[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }
    
    return BangumiRating(
      total: json[AppConfig.jsonTotal] is int ? json[AppConfig.jsonTotal] : int.tryParse(json[AppConfig.jsonTotal]?.toString() ?? '0') ?? 0,
      count: safeCount,
      score: (json[AppConfig.jsonScore] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonTotal: total,
      AppConfig.jsonCount: count,
      AppConfig.jsonScore: score,
    };
  }
}

/// Bangumi 图片数据模型
class BangumiImages {
  final String large;
  final String common;
  final String medium;
  final String small;
  final String grid;

  const BangumiImages({
    required this.large,
    required this.common,
    required this.medium,
    required this.small,
    required this.grid,
  });

  factory BangumiImages.fromJson(Map<String, dynamic> json) {
    return BangumiImages(
      large: json[AppConfig.jsonLarge]?.toString() ?? '',
      common: json[AppConfig.jsonCommon]?.toString() ?? '',
      medium: json[AppConfig.jsonMedium]?.toString() ?? '',
      small: json[AppConfig.jsonSmall]?.toString() ?? '',
      grid: json[AppConfig.jsonGrid]?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonLarge: large,
      AppConfig.jsonCommon: common,
      AppConfig.jsonMedium: medium,
      AppConfig.jsonSmall: small,
      AppConfig.jsonGrid: grid,
    };
  }

  /// 获取最佳图片URL，优先使用large，其次使用common
  String get bestImageUrl {
    if (large.isNotEmpty) {
      return large;
    } else if (common.isNotEmpty) {
      return common;
    } else if (medium.isNotEmpty) {
      return medium;
    } else if (small.isNotEmpty) {
      return small;
    } else if (grid.isNotEmpty) {
      return grid;
    }
    return '';
  }
}

/// Bangumi 收藏数据模型
class BangumiCollection {
  final int doing;
  final int onHold;
  final int dropped;
  final int wish;
  final int collect;

  const BangumiCollection({
    required this.doing,
    this.onHold = 0,
    this.dropped = 0,
    this.wish = 0,
    this.collect = 0,
  });

  factory BangumiCollection.fromJson(Map<String, dynamic> json) {
    return BangumiCollection(
      doing: json[AppConfig.jsonDoing] ?? 0,
      onHold: json[AppConfig.jsonOnHold] ?? 0,
      dropped: json[AppConfig.jsonDropped] ?? 0,
      wish: json[AppConfig.jsonWish] ?? 0,
      collect: json[AppConfig.jsonCollect] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonDoing: doing,
      AppConfig.jsonOnHold: onHold,
      AppConfig.jsonDropped: dropped,
      AppConfig.jsonWish: wish,
      AppConfig.jsonCollect: collect,
    };
  }
}

/// Bangumi 星期数据模型
class BangumiWeekday {
  final String en;
  final String cn;
  final String ja;
  final int id;

  const BangumiWeekday({
    required this.en,
    required this.cn,
    required this.ja,
    required this.id,
  });

  factory BangumiWeekday.fromJson(Map<String, dynamic> json) {
    return BangumiWeekday(
      en: json[AppConfig.jsonEn]?.toString() ?? '',
      cn: json[AppConfig.jsonCn]?.toString() ?? '',
      ja: json[AppConfig.jsonJa]?.toString() ?? '',
      id: json[AppConfig.jsonId] ?? 0,
    );
  }
}

/// Bangumi 项目数据模型
class BangumiItem {
  final int id;
  final String url;
  final int type;
  final String name;
  final String? nameCn;
  final String summary;
  final String airDate;
  final int airWeekday;
  final BangumiRating rating;
  final int rank;
  final BangumiImages images;
  final BangumiCollection collection;

  const BangumiItem({
    required this.id,
    required this.url,
    required this.type,
    required this.name,
    this.nameCn,
    required this.summary,
    required this.airDate,
    required this.airWeekday,
    required this.rating,
    required this.rank,
    required this.images,
    required this.collection,
  });

  factory BangumiItem.fromJson(Map<String, dynamic> json) {
    return BangumiItem(
      id: json[AppConfig.jsonId] ?? 0,
      url: json[AppConfig.jsonUrl]?.toString() ?? '',
      type: json[AppConfig.jsonType] ?? 0,
      name: HtmlUtils.decodeEntities(json[AppConfig.jsonName]?.toString() ?? ''),
      nameCn: json[AppConfig.jsonNameCn]?.toString() != null 
          ? HtmlUtils.decodeEntities(json[AppConfig.jsonNameCn]!.toString())
          : null,
      summary: HtmlUtils.decodeEntities(json[AppConfig.jsonSummary]?.toString() ?? ''),
      airDate: json[AppConfig.jsonAirDate]?.toString() ?? '',
      airWeekday: json[AppConfig.jsonAirWeekday] ?? 0,
      rating: BangumiRating.fromJson(json[AppConfig.jsonRating] ?? {}),
      rank: json[AppConfig.jsonRank] ?? 0,
      images: BangumiImages.fromJson(json[AppConfig.jsonImages] ?? {}),
      collection: BangumiCollection.fromJson(json[AppConfig.jsonCollection] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonUrl: url,
      AppConfig.jsonType: type,
      AppConfig.jsonName: name,
      AppConfig.jsonNameCn: nameCn,
      AppConfig.jsonSummary: summary,
      AppConfig.jsonAirDate: airDate,
      AppConfig.jsonAirWeekday: airWeekday,
      AppConfig.jsonRating: rating.toJson(),
      AppConfig.jsonRank: rank,
      AppConfig.jsonImages: images.toJson(),
      AppConfig.jsonCollection: collection.toJson(),
    };
  }

  /// 转换为VideoInfo格式，用于VideoCard显示
  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id.toString(),
      source: AppConfig.sourceBangumi,
      title: nameCn?.isNotEmpty == true ? nameCn! : name,
      sourceName: AppStrings.bangumiSourceName,
      year: airDate.split('-').first,
      cover: images.bestImageUrl,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: nameCn?.isNotEmpty == true ? nameCn! : name,
      bangumiId: id,
      rate: rating.score > 0 ? rating.score.toStringAsFixed(1) : null,
    );
  }

}

/// Bangumi 详情数据模型
class BangumiDetails {
  final int id;
  final int type;
  final String name;
  final String? nameCn;
  final String summary;
  final bool nsfw;
  final bool locked;
  final String? date;
  final String? platform;
  final BangumiImages images;
  final List<String> infobox;
  final int volumes;
  final int eps;
  final int totalEpisodes;
  final BangumiRating rating;
  final BangumiCollection collection;
  final List<String> tags;
  final List<String> metaTags;
  final bool series;

  const BangumiDetails({
    required this.id,
    required this.type,
    required this.name,
    this.nameCn,
    required this.summary,
    required this.nsfw,
    required this.locked,
    this.date,
    this.platform,
    required this.images,
    required this.infobox,
    required this.volumes,
    required this.eps,
    required this.totalEpisodes,
    required this.rating,
    required this.collection,
    required this.tags,
    required this.metaTags,
    required this.series,
  });

  factory BangumiDetails.fromJson(Map<String, dynamic> json) {
    return BangumiDetails(
      id: json[AppConfig.jsonId] ?? 0,
      type: json[AppConfig.jsonType] ?? 0,
      name: HtmlUtils.decodeEntities(json[AppConfig.jsonName]?.toString() ?? ''),
      nameCn: json[AppConfig.jsonNameCn]?.toString() != null 
          ? HtmlUtils.decodeEntities(json[AppConfig.jsonNameCn]!.toString())
          : null,
      summary: HtmlUtils.decodeEntities(json[AppConfig.jsonSummary]?.toString() ?? ''),
      nsfw: json[AppConfig.jsonNsfw] ?? false,
      locked: json[AppConfig.jsonLocked] ?? false,
      date: json[AppConfig.jsonDate]?.toString(),
      platform: json[AppConfig.jsonPlatform]?.toString(),
      images: BangumiImages.fromJson(json[AppConfig.jsonImages] ?? {}),
      infobox: (json[AppConfig.jsonInfobox] as List<dynamic>? ?? [])
          .map((item) {
            if (item is Map<String, dynamic>) {
              final value = item[AppConfig.jsonValue];
              if (value is List) {
                final valueList = value.map((v) => v[AppConfig.jsonV]?.toString() ?? '').join(', ');
                return '${item[AppConfig.jsonKey]}: $valueList';
              }
              return '${item[AppConfig.jsonKey]}: ${value?.toString() ?? ''}';
            }
            return item.toString();
          })
          .toList(),
      volumes: json[AppConfig.jsonVolumes] ?? 0,
      eps: json[AppConfig.jsonEps] ?? 0,
      totalEpisodes: json[AppConfig.jsonTotalEpisodes] ?? 0,
      rating: BangumiRating.fromJson(json[AppConfig.jsonRating] ?? {}),
      collection: BangumiCollection.fromJson(json[AppConfig.jsonCollection] ?? {}),
      tags: (json[AppConfig.jsonTags] as List<dynamic>? ?? [])
          .map((tag) {
            if (tag is Map<String, dynamic>) {
              return tag[AppConfig.jsonName]?.toString() ?? '';
            } else {
              return tag.toString();
            }
          })
          .where((name) => name.isNotEmpty)
          .toList(),
      metaTags: (json[AppConfig.jsonMetaTags] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      series: json[AppConfig.jsonSeries] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonType: type,
      AppConfig.jsonName: name,
      AppConfig.jsonNameCn: nameCn,
      AppConfig.jsonSummary: summary,
      AppConfig.jsonNsfw: nsfw,
      AppConfig.jsonLocked: locked,
      AppConfig.jsonDate: date,
      AppConfig.jsonPlatform: platform,
      AppConfig.jsonImages: images.toJson(),
      AppConfig.jsonInfobox: infobox,
      AppConfig.jsonVolumes: volumes,
      AppConfig.jsonEps: eps,
      AppConfig.jsonTotalEpisodes: totalEpisodes,
      AppConfig.jsonRating: rating.toJson(),
      AppConfig.jsonCollection: collection.toJson(),
      AppConfig.jsonTags: tags,
      AppConfig.jsonMetaTags: metaTags,
      AppConfig.jsonSeries: series,
    };
  }
}

/// Bangumi 日历响应数据模型
class BangumiCalendarResponse {
  final BangumiWeekday weekday;
  final List<BangumiItem> items;

  const BangumiCalendarResponse({
    required this.weekday,
    required this.items,
  });

  factory BangumiCalendarResponse.fromJson(Map<String, dynamic> json) {
    return BangumiCalendarResponse(
      weekday: BangumiWeekday.fromJson(json[AppConfig.jsonWeekday] ?? {}),
      items: (json[AppConfig.jsonItems] as List<dynamic>? ?? [])
          .map((item) => BangumiItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
