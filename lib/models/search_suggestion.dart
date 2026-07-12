import '../constants/app_config.dart';

/// 搜索建议模型
class SearchSuggestion {
  final String text;
  final String type;
  final double score;

  SearchSuggestion({
    required this.text,
    required this.type,
    required this.score,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: (json[AppConfig.jsonText] as String?) ?? '',
      type: (json[AppConfig.jsonType] as String?) ?? '',
      score: ((json[AppConfig.jsonScore] as num?) ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonText: text,
      AppConfig.jsonType: type,
      AppConfig.jsonScore: score,
    };
  }
}
