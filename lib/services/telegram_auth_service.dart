import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'user_data_service.dart';
import 'api_service.dart';

class TelegramAuthResult {
  final bool success;
  final String? username;
  final String? token;
  final bool isNewUser;
  final String? error;

  TelegramAuthResult({
    required this.success,
    this.username,
    this.token,
    this.isNewUser = false,
    this.error,
  });
}

class TelegramAuthService {
  static String _buildUrl(String path) {
    final baseUrl = UserDataService.getDefaultServerUrl();
    return '$baseUrl$path';
  }

  static Future<TelegramAuthResult> authenticate({
    required bool Function() isMounted,
    ValueChanged<String>? onStatusChanged,
  }) async {
    try {
      onStatusChanged?.call('正在请求 Telegram 认证...');

      final requestUrl = _buildUrl('/api/telegram/mobile-auth/request');
      final requestResponse = await http
          .post(Uri.parse(requestUrl))
          .timeout(const Duration(seconds: 10));

      if (requestResponse.statusCode != 200) {
        final body = json.decode(requestResponse.body);
        return TelegramAuthResult(
          success: false,
          error: body['error'] ?? '请求 Telegram 认证失败',
        );
      }

      final requestData = json.decode(requestResponse.body);
      final token = requestData['token'] as String;
      final deepLink = requestData['deepLink'] as String;

      onStatusChanged?.call('正在打开 Telegram...');
      final uri = Uri.parse(deepLink);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final tgUri = Uri.parse(
            'tg://resolve?domain=${requestData['botUsername']}&start=$token');
        final tgLaunched = await canLaunchUrl(tgUri)
            ? await launchUrl(tgUri, mode: LaunchMode.externalApplication)
            : false;

        if (!tgLaunched) {
          return TelegramAuthResult(
            success: false,
            error: '无法打开 Telegram，请确保已安装 Telegram 客户端',
          );
        }
      }

      onStatusChanged?.call('等待 Telegram 验证...');
      final pollUrl = _buildUrl('/api/telegram/mobile-auth/poll?token=$token');
      final startTime = DateTime.now();
      const maxDuration = Duration(minutes: 5);
      const pollInterval = Duration(seconds: 2);

      while (DateTime.now().difference(startTime) < maxDuration) {
        await Future.delayed(pollInterval);

        if (!isMounted()) {
          return TelegramAuthResult(
            success: false,
            error: '组件已销毁',
          );
        }

        try {
          final pollResponse = await http
              .get(Uri.parse(pollUrl))
              .timeout(const Duration(seconds: 10));

          if (pollResponse.statusCode == 200) {
            final pollData = json.decode(pollResponse.body);

            if (pollData['status'] == 'verified') {
              final username = pollData['username'] as String;
              final isNewUser = pollData['isNewUser'] as bool? ?? false;
              final cookieValue = pollData['token'] as String? ?? '';

              onStatusChanged?.call('登录成功，正在保存...');

              final cookies = 'user_auth=$cookieValue';

              ApiService.setInMemoryUserAuth(cookieValue);
              ApiService.setInMemoryCookies(cookies);
              ApiService.blockLoginRedirects();

              await UserDataService.saveUserData(
                username: username,
                token: null,
                cookies: cookies,
              );

              return TelegramAuthResult(
                success: true,
                username: username,
                token: null,
                isNewUser: isNewUser,
              );
            }

            if (pollData['status'] == 'expired' || pollData['error'] != null) {
              return TelegramAuthResult(
                success: false,
                error: pollData['error'] ?? 'Token 已过期，请重试',
              );
            }
          } else if (pollResponse.statusCode == 404) {
            return TelegramAuthResult(
              success: false,
              error: 'Token 已过期，请重试',
            );
          }
        } catch (e) {
          // 网络错误时继续轮询，不中断认证流程
        }
      }

      return TelegramAuthResult(
        success: false,
        error: '认证超时，请重试',
      );
    } catch (e) {
      return TelegramAuthResult(
        success: false,
        error: '认证失败：${e.toString()}',
      );
    }
  }
}
