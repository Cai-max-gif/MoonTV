import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
        return 'https://api.openai.com/v1';
      case 'deepseek':
        return 'https://api.deepseek.com/v1';
      case 'zhipu':
        return 'https://open.bigmodel.cn/api/paas/v4';
      case 'moonshot':
        return 'https://api.moonshot.cn/v1';
      default:
        return 'https://api.openai.com/v1';
    }
  }

  bool get isValid => apiKey.isNotEmpty;
}

class AIService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _apiKeyPrefix = 'ai_api_key_';
  static const String _settingsKey = 'ai_settings';
  static const String _chatHistoryKey = 'ai_chat_history';

  static const Duration _timeout = Duration(seconds: 60);

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
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${settings.apiKey}',
            },
            body: body,
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
        url = 'https://api.deepseek.com/user/balance';
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
        return json.decode(response.body) as Map<String, dynamic>;
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
  }) async {
    if (!settings.isValid) {
      throw Exception('请先在设置中配置API密钥');
    }

    final baseUrl = settings.effectiveBaseUrl;
    final url = '$baseUrl/chat/completions';
    final uri = Uri.parse(url);

    final messages = <Map<String, String>>[];

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

    final body = json.encode({
      'model': settings.model,
      'messages': messages,
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey}',
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        final message = choices.first['message'] as Map<String, dynamic>;
        return message['content'] as String? ?? '';
      }
      throw Exception('AI没有返回有效回复');
    }

    String errorMessage = '请求失败';
    try {
      final errorData = json.decode(response.body);
      if (errorData['error'] is Map) {
        errorMessage = errorData['error']['message'] ?? errorMessage;
      } else if (errorData['error'] is String) {
        errorMessage = errorData['error'];
      } else if (errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw Exception('API密钥无效，请检查设置');
      case 429:
        throw Exception('请求过于频繁，请稍后再试');
      case 500:
        throw Exception('服务器内部错误');
      default:
        throw Exception('请求失败 ($errorMessage)');
    }
  }
}
