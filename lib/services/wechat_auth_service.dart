import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/wechat_types.dart';

/// 微信 iLink API 扫码登录服务
class WeChatAuthService {
  static const String _baseUrl = 'https://ilinkai.weixin.qq.com';
  static const String _botType = '3';
  static const String _credentialsStorageKey = 'wechat_credentials';

  static const int _qrPollTimeoutMs = 35000;
  static const int _maxQrRefresh = 3;
  static const int _loginTimeoutMs = 3 * 60 * 1000; // 3 分钟
  static const int _pollIntervalMs = 1000;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// 获取二维码
  static Future<QRCodeResponse> fetchQRCode() async {
    final url = Uri.parse(
        '$_baseUrl/ilink/bot/get_bot_qrcode?bot_type=$_botType');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('获取二维码失败: ${response.statusCode}');
    }

    return QRCodeResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  /// 轮询二维码状态
  static Future<QRStatusResponse> pollQRStatus(String qrcodeStr) async {
    final url = Uri.parse(
        '$_baseUrl/ilink/bot/get_qrcode_status?qrcode=${Uri.encodeComponent(qrcodeStr)}');

    try {
      final response = await http
          .get(
            url,
            headers: {'iLink-App-ClientVersion': '1'},
          )
          .timeout(const Duration(milliseconds: _qrPollTimeoutMs));

      if (response.statusCode != 200) {
        throw Exception('轮询二维码状态失败: ${response.statusCode}');
      }

      return QRStatusResponse.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } on TimeoutException {
      return QRStatusResponse(status: QRStatus.wait);
    }
  }

  /// 执行扫码登录流程
  /// 返回 [LoginCredentials] 或抛出异常
  static Future<LoginCredentials> login({
    void Function(QRCodeResponse)? onQRCodeReady,
    void Function(QRStatus)? onStatusChanged,
  }) async {
    // 1. 检查是否有已保存的凭证
    final saved = await loadCredentials();
    if (saved != null) {
      return saved;
    }

    // 2. 获取二维码
    var qr = await fetchQRCode();
    onQRCodeReady?.call(qr);

    var refreshCount = 0;
    final deadline = DateTime.now().millisecondsSinceEpoch + _loginTimeoutMs;

    while (DateTime.now().millisecondsSinceEpoch < deadline) {
      final statusResp = await pollQRStatus(qr.qrcode);
      onStatusChanged?.call(statusResp.status);

      switch (statusResp.status) {
        case QRStatus.wait:
          break;
        case QRStatus.scaned:
          break;
        case QRStatus.expired:
          refreshCount++;
          if (refreshCount >= _maxQrRefresh) {
            throw Exception('二维码多次过期，请重试');
          }
          qr = await fetchQRCode();
          onQRCodeReady?.call(qr);
          break;
        case QRStatus.confirmed:
          final token = statusResp.botToken;
          final botId = statusResp.ilinkBotId;
          if (token == null || botId == null) {
            throw Exception('登录确认但未返回 token 或 bot_id');
          }
          final creds = LoginCredentials(
            token: token,
            baseUrl: statusResp.baseurl ?? _baseUrl,
            accountId: botId,
            userId: statusResp.ilinkUserId,
          );
          await saveCredentials(creds);
          return creds;
      }

      await Future.delayed(const Duration(milliseconds: _pollIntervalMs));
    }

    throw Exception('登录超时');
  }

  /// 保存凭证到安全存储
  static Future<void> saveCredentials(LoginCredentials creds) async {
    await _secureStorage.write(
      key: _credentialsStorageKey,
      value: json.encode(creds.toJson()),
    );
  }

  /// 从安全存储加载凭证
  static Future<LoginCredentials?> loadCredentials() async {
    final raw = await _secureStorage.read(key: _credentialsStorageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final creds = LoginCredentials.fromJson(data);
      if (creds.token.isNotEmpty &&
          creds.baseUrl.isNotEmpty &&
          creds.accountId.isNotEmpty) {
        return creds;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 清除凭证
  static Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _credentialsStorageKey);
  }
}
