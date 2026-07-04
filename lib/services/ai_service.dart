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
    this.provider = 'openai',
    this.apiKey = '',
    this.model = 'gpt-4o',
    this.baseUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'model': model,
      'baseUrl': baseUrl,
    };
  }

  static AISettings fromJson(Map<String, dynamic> json) {
    return AISettings(
      provider: json['provider'] as String? ?? 'openai',
      model: json['model'] as String? ?? 'gpt-4o',
      baseUrl: json['baseUrl'] as String? ?? '',
    );
  }

  String get effectiveBaseUrl {
    if (baseUrl.isNotEmpty) return baseUrl;
    switch (provider) {
      case 'openai':
        return AppConfig.aiOpenaiBaseUrl;
      case 'deepseek':
        return AppConfig.aiDeepseekBaseUrl;
      case 'zhipu':
        return AppConfig.aiZhipuBaseUrl;
      case 'moonshot':
        return AppConfig.aiMoonshotBaseUrl;
      case 'mimo':
        return AppConfig.aiMimoBaseUrl;
      default:
        return AppConfig.aiOpenaiBaseUrl;
    }
  }

  bool get isValid => apiKey.isNotEmpty;
}

class AIService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _apiKeyPrefix = 'ai_api_key_';
  static const String _settingsKey = 'ai_settings';
  static const String _chatHistoryKey = 'ai_chat_history';

  static Duration get _timeout => AppConfig.aiRequestTimeout;

  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    if (messages.isEmpty) {
      await prefs.remove(_chatHistoryKey);
      return;
    }
    final encoded = json.encode(messages);
    await prefs.setString(_chatHistoryKey, encoded);
  }

  static Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }

  static Future<AISettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();

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
      final url = '$baseUrl/chat/completions';
      final uri = Uri.parse(url);

      final body = json.encode({
        'model': settings.model,
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
      });

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${settings.apiKey}',
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
      if (settings.provider == 'deepseek') {
        url = '${settings.effectiveBaseUrl}/user/balance';
      } else if (settings.provider == 'moonshot') {
        url = '${settings.effectiveBaseUrl}/users/me/balance';
      } else {
        return null;
      }

      final uri = Uri.parse(url);

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer ${settings.apiKey}',
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
    final url = '$baseUrl/chat/completions';
    final uri = Uri.parse(url);

    final messages = _buildMessages(userMessage, conversationHistory, systemPrompt);

    final body = json.encode({
      'model': settings.model,
      'messages': messages,
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${settings.apiKey}',
          },
          body: utf8.encode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      try {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final message = choices.first['message'] as Map<String, dynamic>;
          return message['content'] as String? ?? '';
        }
        throw Exception('AI没有返回有效回复');
      } catch (e) {
        throw Exception('解析响应失败');
      }
    }

    String errorMessage = AppStrings.aiRequestFailed;
    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final errorData = json.decode(responseBody);
      if (errorData['error'] is Map) {
        errorMessage = errorData['error']['message'] ?? errorMessage;
      } else if (errorData['error'] is String) {
        errorMessage = errorData['error'];
      } else if (errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
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
        'role': 'system',
        'content': systemPrompt,
      });
    }

    for (final msg in conversationHistory) {
      messages.add({
        'role': msg['role']!,
        'content': msg['content']!,
      });
    }
    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    return messages;
  }

}
