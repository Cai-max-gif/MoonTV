import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

class AISettings {
  String provider;
  String apiKey;
  String model;
  String baseUrl;

  AISettings({
    this.provider = AppConfig.aiDefaultProvider,
    this.apiKey = '',
    this.model = AppConfig.aiDefaultModel,
    this.baseUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonProvider: provider,
      AppConfig.jsonModel: model,
      AppConfig.jsonBaseUrl: baseUrl,
    };
  }

  static AISettings fromJson(Map<String, dynamic> json) {
    return AISettings(
      provider: json[AppConfig.jsonProvider] as String? ?? AppConfig.aiDefaultProvider,
      model: json[AppConfig.jsonModel] as String? ?? AppConfig.aiDefaultModel,
      baseUrl: json[AppConfig.jsonBaseUrl] as String? ?? '',
    );
  }

  String get effectiveBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    switch (provider) {
      case AppConfig.aiProviderOpenai:
        return AppConfig.aiOpenaiBaseUrl;
      case AppConfig.aiProviderDeepseek:
        return AppConfig.aiDeepseekBaseUrl;
      case AppConfig.aiProviderZhipu:
        return AppConfig.aiZhipuBaseUrl;
      case AppConfig.aiProviderMoonshot:
        return AppConfig.aiMoonshotBaseUrl;
      case AppConfig.aiProviderMimo:
        return AppConfig.aiMimoBaseUrl;
      default:
        return AppConfig.aiOpenaiBaseUrl;
    }
  }

  bool get isValid => apiKey.isNotEmpty;
}

class AIService {

  static SharedPreferences? _prefsCache;
  static Future<SharedPreferences> get _prefs async =>
      _prefsCache ??= await SharedPreferences.getInstance();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _apiKeyPrefix = AppConfig.aiApiKeyPrefix;
  static const String _settingsKey = AppConfig.aiSettingsKey;
  static const String _chatHistoryKey = AppConfig.aiChatHistoryKey;

  static Duration get _timeout => AppConfig.aiRequestTimeout;

  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    final prefs = await _prefs;
    final historyJson = prefs.getString(_chatHistoryKey);
    if (historyJson != null) {
      try {
        final list = json.decode(historyJson) as List<dynamic>;
        return list
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static Future<void> saveChatHistory(
      List<Map<String, dynamic>> messages) async {
    final prefs = await _prefs;
    if (messages.isEmpty) {
      await prefs.remove(_chatHistoryKey);
      return;
    }
    final encoded = json.encode(messages);
    await prefs.setString(_chatHistoryKey, encoded);
  }

  static Future<void> clearChatHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_chatHistoryKey);
  }

  static Future<AISettings> loadSettings() async {
    final prefs = await _prefs;
    final settingsJson = prefs.getString(_settingsKey);
    AISettings settings;

    if (settingsJson != null) {
      try {
        settings = AISettings.fromJson(json.decode(settingsJson));
      } catch (e) {
        settings = AISettings();
      }
    } else {
      settings = AISettings();
    }

    final storedApiKey =
        await _secureStorage.read(key: '$_apiKeyPrefix${settings.provider}');
    if (storedApiKey != null && storedApiKey.isNotEmpty) {
      settings.apiKey = storedApiKey;
    }

    return settings;
  }

  static Future<void> saveSettings(AISettings settings) async {
    final prefs = await _prefs;

    if (settings.apiKey.isNotEmpty) {
      await _secureStorage.write(
        key: '$_apiKeyPrefix${settings.provider}',
        value: settings.apiKey,
      );
    } else {
      await _secureStorage.delete(
        key: '$_apiKeyPrefix${settings.provider}',
      );
    }

    final settingsJson = json.encode(settings.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }

  static Future<void> deleteApiKey(String provider) async {
    await _secureStorage.delete(key: '$_apiKeyPrefix$provider');
  }

  static Future<bool> testConnection(AISettings settings) async {
    if (!settings.isValid) {
      return false;
    }

    try {
      final baseUrl = settings.effectiveBaseUrl;
      final url = '$baseUrl${AppConfig.aiChatCompletionsEndpoint}';
      final uri = Uri.parse(url);

      final body = json.encode({
        AppConfig.jsonModel: settings.model,
        AppConfig.jsonMessages: [
          {AppConfig.jsonRole: AppConfig.aiRoleUser, AppConfig.jsonContent: 'Hi'},
        ],
      });

      final response = await http
          .post(
            uri,
            headers: {
              AppConfig.headerContentType: AppStrings.contentTypeJsonUtf8,
              AppConfig.headerAuthorization: '${AppStrings.authorizationBearer}${settings.apiKey}',
            },
            body: utf8.encode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 401) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getBalance(AISettings settings) async {
    if (!settings.isValid) {
      return null;
    }

    try {
      String url;
      if (settings.provider == AppConfig.aiProviderDeepseek) {
        url = '${settings.effectiveBaseUrl}${AppConfig.aiDeepseekBalanceEndpoint}';
      } else if (settings.provider == AppConfig.aiProviderMoonshot) {
        url = '${settings.effectiveBaseUrl}${AppConfig.aiMoonshotBalanceEndpoint}';
      } else {
        return null;
      }

      final uri = Uri.parse(url);

      final response = await http
          .get(
            uri,
            headers: {
              AppConfig.headerAccept: AppConfig.headerAcceptJson,
              AppConfig.headerAuthorization: '${AppStrings.authorizationBearer}${settings.apiKey}',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        return json.decode(responseBody) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> sendMessage({
    required AISettings settings,
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    String? systemPrompt,
  }) async {
    if (!settings.isValid) {
      throw Exception(AppStrings.errorConfigApiKey);
    }

    final baseUrl = settings.effectiveBaseUrl;
    final url = '$baseUrl${AppConfig.aiChatCompletionsEndpoint}';
    final uri = Uri.parse(url);

    final messages = _buildMessages(userMessage, conversationHistory, systemPrompt);

    final body = json.encode({
      AppConfig.jsonModel: settings.model,
      'messages': messages,
    });

    final response = await http
        .post(
          uri,
          headers: {
            AppConfig.headerContentType: AppStrings.contentTypeJsonUtf8,
            AppConfig.headerAuthorization: '${AppStrings.authorizationBearer}${settings.apiKey}',
          },
          body: utf8.encode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      try {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        final choices = data[AppConfig.jsonChoices] as List<dynamic>;
        if (choices.isNotEmpty) {
          final message = choices.first[AppConfig.jsonMessage] as Map<String, dynamic>;
          return message[AppConfig.jsonContent] as String? ?? '';
        }
        throw Exception(AppStrings.aiNoValidReply);
      } catch (e) {
        throw Exception(AppStrings.aiParseFailed);
      }
    }

    String errorMessage = AppStrings.aiRequestFailed;
    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(responseBody);
      if (errorData[AppConfig.jsonError] is Map) {
        errorMessage = errorData[AppConfig.jsonError][AppConfig.jsonMessage] ?? errorMessage;
      } else if (errorData[AppConfig.jsonError] is String) {
        errorMessage = errorData[AppConfig.jsonError];
      } else if (errorData[AppConfig.jsonMessage] != null) {
        errorMessage = errorData[AppConfig.jsonMessage].toString();
      }
    } catch (e) {
      // JSON 解析失败时使用默认错误消息
    }

    switch (response.statusCode) {
      case 401:
        throw Exception(AppStrings.aiInvalidApiKey);
      case 429:
        throw Exception(AppStrings.aiRateLimited);
      case 500:
        throw Exception(AppStrings.aiServerError);
      default:
        throw Exception('${AppStrings.aiRequestFailed} ($errorMessage)');
    }
  }

  /// 构建消息列表（系统提示 + 历史消息 + 当前消息）
  static List<Map<String, String>> _buildMessages(
    String userMessage,
    List<Map<String, String>> conversationHistory,
    String? systemPrompt,
  ) {
    final messages = <Map<String, String>>[];

    // 如果有系统提示，添加到消息列表开头
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({
        AppConfig.jsonRole: AppConfig.aiRoleSystem,
        AppConfig.jsonContent: systemPrompt,
      });
    }

    for (final msg in conversationHistory) {
      messages.add({
        AppConfig.jsonRole: msg[AppConfig.jsonRole]!,
        AppConfig.jsonContent: msg[AppConfig.jsonContent]!,
      });
    }
    messages.add({
      AppConfig.jsonRole: AppConfig.aiRoleUser,
      AppConfig.jsonContent: userMessage,
    });
    return messages;
  }

}
