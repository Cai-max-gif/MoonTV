import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../models/wechat_types.dart';

/// 微信CDN媒体服务
/// 处理媒体文件的下载/解密、上传/加密
class WeChatMediaService {
  static const int _uploadMaxRetries = 3;

  static const String _cdnBaseUrl = 'https://novac2c.cdn.weixin.qq.com/c2c';

  /// AES-128-ECB加密
  static Uint8List encryptAesEcb(Uint8List plaintext, Uint8List key) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.ecb),
    );
    final encrypted = encrypter.encryptBytes(plaintext);
    return encrypted.bytes;
  }

  /// AES-128-ECB解密
  static Uint8List decryptAesEcb(Uint8List ciphertext, Uint8List key) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.ecb),
    );
    final encrypted = encrypt.Encrypted(ciphertext);
    return Uint8List.fromList(encrypter.decryptBytes(encrypted));
  }

  /// 计算AES-128-ECB加密后的大小（PKCS7填充到16字节边界）
  static int aesEcbPaddedSize(int plaintextSize) {
    if (plaintextSize == 0) return 0;
    return ((plaintextSize + 15) ~/ 16) * 16;
  }

  /// 解析AES密钥
  /// 支持两种格式：
  /// - base64编码的原始16字节
  /// - base64编码的32字符hex字符串
  static Uint8List parseAesKey(String aesKeyBase64, {String label = ''}) {
    final decoded = base64.decode(aesKeyBase64);
    if (decoded.length == 16) {
      return decoded;
    }
    if (decoded.length == 32) {
      final hexStr = utf8.decode(decoded);
      if (RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(hexStr)) {
        return _hexDecode(hexStr);
      }
    }
    throw ArgumentError(
      '$label: aes_key must decode to 16 raw bytes or 32-char hex string, '
      'got ${decoded.length} bytes',
    );
  }

  /// 从CDN下载并解密媒体文件
  static Future<Uint8List> downloadAndDecrypt({
    required String encryptedQueryParam,
    required String aesKeyBase64,
    String? fullUrl,
    String label = '',
  }) async {
    final key = parseAesKey(aesKeyBase64, label: label);
    final url = fullUrl ?? _buildCdnDownloadUrl(encryptedQueryParam);

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('$label: CDN download failed ${response.statusCode}');
    }

    final encrypted = response.bodyBytes;
    return decryptAesEcb(encrypted, key);
  }

  /// 从CDN下载明文（未加密）媒体文件
  static Future<Uint8List> downloadPlain({
    required String encryptedQueryParam,
    String? fullUrl,
    String label = '',
  }) async {
    final url = fullUrl ?? _buildCdnDownloadUrl(encryptedQueryParam);

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('$label: CDN download failed ${response.statusCode}');
    }

    return response.bodyBytes;
  }

  /// 上传文件到CDN
  static Future<UploadedFileInfo> uploadFileToCdn({
    required String filePath,
    required String toUserId,
    required String baseUrl,
    required String token,
    required int mediaType,
  }) async {
    final file = File(filePath);
    final plaintext = await file.readAsBytes();
    final rawsize = plaintext.length;
    final rawfilemd5 = md5.convert(plaintext).toString();
    final filesize = aesEcbPaddedSize(rawsize);
    final filekey = _randomHex(16);
    final aeskey = _randomBytes(16);

    // 获取上传URL
    final uploadUrlResp = await _getUploadUrl(
      baseUrl: baseUrl,
      token: token,
      filekey: filekey,
      mediaType: mediaType,
      toUserId: toUserId,
      rawsize: rawsize,
      rawfilemd5: rawfilemd5,
      filesize: filesize,
      aeskey: _hexEncode(aeskey),
    );

    final uploadFullUrl = uploadUrlResp.uploadFullUrl?.trim();
    final uploadParam = uploadUrlResp.uploadParam;
    if (uploadFullUrl == null && uploadParam == null) {
      throw Exception('getUploadUrl returned no upload URL');
    }

    // 加密并上传
    final ciphertext = encryptAesEcb(plaintext, aeskey);
    final downloadParam = await _uploadBufferToCdn(
      buf: ciphertext,
      uploadFullUrl: uploadFullUrl,
      uploadParam: uploadParam,
      filekey: filekey,
      aeskey: aeskey,
    );

    return UploadedFileInfo(
      filekey: filekey,
      downloadEncryptedQueryParam: downloadParam,
      aeskey: _hexEncode(aeskey),
      fileSize: rawsize,
      fileSizeCiphertext: filesize,
    );
  }

  /// 构建CDN下载URL
  static String _buildCdnDownloadUrl(String encryptedQueryParam) {
    return '$_cdnBaseUrl/download?encrypted_query_param=${Uri.encodeComponent(encryptedQueryParam)}';
  }

  /// 构建CDN上传URL
  static String _buildCdnUploadUrl({
    required String uploadParam,
    required String filekey,
  }) {
    return '$_cdnBaseUrl/upload?encrypted_query_param=${Uri.encodeComponent(uploadParam)}&filekey=${Uri.encodeComponent(filekey)}';
  }

  /// 获取上传URL
  static Future<GetUploadUrlResponse> _getUploadUrl({
    required String baseUrl,
    required String token,
    required String filekey,
    required int mediaType,
    required String toUserId,
    required int rawsize,
    required String rawfilemd5,
    required int filesize,
    required String aeskey,
  }) async {
    final url = '$baseUrl/ilink/bot/getuploadurl';
    final body = {
      'filekey': filekey,
      'media_type': mediaType,
      'to_user_id': toUserId,
      'rawsize': rawsize,
      'rawfilemd5': rawfilemd5,
      'filesize': filesize,
      'no_need_thumb': true,
      'aeskey': aeskey,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: _buildHeaders(token: token),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('getUploadUrl failed ${response.statusCode}: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return GetUploadUrlResponse.fromJson(data);
  }

  /// 上传加密后的缓冲区到CDN
  static Future<String> _uploadBufferToCdn({
    required Uint8List buf,
    String? uploadFullUrl,
    String? uploadParam,
    required String filekey,
    required Uint8List aeskey,
  }) async {
    String cdnUrl;
    if (uploadFullUrl != null && uploadFullUrl.isNotEmpty) {
      cdnUrl = uploadFullUrl;
    } else if (uploadParam != null) {
      cdnUrl = _buildCdnUploadUrl(uploadParam: uploadParam, filekey: filekey);
    } else {
      throw Exception('CDN upload URL missing');
    }

    String? downloadParam;
    Exception? lastError;

    for (int attempt = 1; attempt <= _uploadMaxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(cdnUrl),
          headers: {'Content-Type': 'application/octet-stream'},
          body: buf,
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode >= 400 && response.statusCode < 500) {
          final errMsg = response.headers['x-error-message'] ?? response.body;
          throw Exception('CDN client error ${response.statusCode}: $errMsg');
        }

        if (response.statusCode != 200) {
          final errMsg = response.headers['x-error-message'] ?? 'status ${response.statusCode}';
          throw Exception('CDN server error: $errMsg');
        }

        downloadParam = response.headers['x-encrypted-param'];
        if (downloadParam == null || downloadParam.isEmpty) {
          throw Exception('CDN response missing x-encrypted-param header');
        }
        break;
      } catch (err) {
        lastError = err is Exception ? err : Exception(err.toString());
        if (err is Exception && err.toString().contains('client error')) rethrow;
        if (attempt < _uploadMaxRetries) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (downloadParam == null) {
      throw lastError ?? Exception('CDN upload failed after $_uploadMaxRetries attempts');
    }
    return downloadParam;
  }

  /// 保存媒体文件到本地
  static Future<String> saveMediaToFile({
    required Uint8List data,
    required String subdir,
    String? filename,
    String? extension,
  }) async {
    final dir = await _getMediaDir(subdir);
    final name = filename ?? '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    final ext = extension ?? '.bin';
    final filePath = p.join(dir, '$name$ext');
    final file = File(filePath);
    await file.writeAsBytes(data);
    return filePath;
  }

  /// 获取媒体存储目录
  static Future<String> _getMediaDir(String subdir) async {
    final appDir = await _getAppDir();
    final dir = Directory(p.join(appDir, 'media', subdir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// 获取应用目录
  static Future<String> _getAppDir() async {
    // 使用当前目录作为基础
    return Directory.current.path;
  }

  /// 构建请求头
  static Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'AuthorizationType': 'ilink_bot_token',
      'X-WECHAT-UIN': base64.encode(_randomUint32().toString().codeUnits),
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 生成随机uint32
  static int _randomUint32() {
    return Random().nextInt(0xFFFFFFFF);
  }

  /// 生成随机hex字符串
  static String _randomHex(int bytes) {
    return _hexEncode(_randomBytes(bytes));
  }

  /// 生成随机字节
  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  /// hex编码
  static String _hexEncode(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// hex解码
  static Uint8List _hexDecode(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}
