import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'user_data_service.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';

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
      onStatusChanged?.call(AppStrings.telegramRequesting);

      final requestUrl = _buildUrl('${AppConfig.apiPrefix}/telegram/mobile-auth/request');
      final requestResponse = await http
          .post(Uri.parse(requestUrl))
          .timeout(AppDurations.shortTimeout);

      if (requestResponse.statusCode != 200) {
        final body = json.decode(requestResponse.body);
        return TelegramAuthResult(
          success: false,
          error: body[AppConfig.jsonError] ?? AppStrings.telegramRequestFailed,
        );
      }

      final requestData = json.decode(requestResponse.body);
      final token = requestData[AppConfig.jsonToken] as String;
      final deepLink = requestData[AppConfig.jsonDeepLink] as String;

      onStatusChanged?.call(AppStrings.telegramOpening);
      final uri = Uri.parse(deepLink);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final tgUri = Uri.parse(
            'tg://resolve?domain=${requestData[AppConfig.jsonBotUsername]}&start=$token');
        final tgLaunched = await canLaunchUrl(tgUri)
            ? await launchUrl(tgUri, mode: LaunchMode.externalApplication)
            : false;

        if (!tgLaunched) {
          return TelegramAuthResult(
            success: false,
            error: AppStrings.telegramNotInstalled,
          );
        }
      }

      onStatusChanged?.call(AppStrings.telegramWaiting);
      final pollUrl = _buildUrl('${AppConfig.apiPrefix}/telegram/mobile-auth/poll?token=$token');
      final startTime = DateTime.now();
      const maxDuration = AppConfig.telegramPollTimeout;
      const pollInterval = AppDurations.twoSeconds;

      while (DateTime.now().difference(startTime) < maxDuration) {
        await Future.delayed(pollInterval);

        if (!isMounted()) {
          return TelegramAuthResult(
            success: false,
            error: AppStrings.telegramComponentDestroyed,
          );
        }

        try {
          final pollResponse = await http
              .get(Uri.parse(pollUrl))
              .timeout(AppDurations.shortTimeout);

          if (pollResponse.statusCode == 200) {
            final pollData = json.decode(pollResponse.body);
            return TelegramAuthResult(
              success: true,
              username: pollData[AppConfig.jsonUsername] as String?,
              token: pollData[AppConfig.jsonToken] as String?,
              isNewUser: pollData[AppConfig.jsonIsNewUser] as bool? ?? false,
            );
          }
        } catch (_) {
          // 忽略轮询错误，继续重试
        }
      }

      return TelegramAuthResult(
        success: false,
        error: AppStrings.telegramTimeout,
      );
    } catch (e) {
      onStatusChanged?.call(AppStrings.telegramError);
      return TelegramAuthResult(
        success: false,
        error: '${AppStrings.telegramError}: $e',
      );
    }
  }
}
