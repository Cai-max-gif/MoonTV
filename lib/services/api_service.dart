import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'user_data_service.dart';
import 'content_filter_service.dart';
import '../screens/login_screen.dart';
import '../models/favorite_item.dart';
import '../models/search_result.dart';
import '../models/play_record.dart';
import '../models/search_resource.dart';
import '../models/live_source.dart';
import '../models/live_channel.dart';
import '../models/epg_program.dart';
import '../models/search_suggestion.dart';
import '../models/danmu_item.dart';
import '../models/netdisk_item.dart';

/// API响应结果类
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// 通用API请求服务
class ApiService {
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  // 账号状态缓存
  static DateTime? _lastAccountStatusCheck;
  static bool? _cachedAccountStatus;
  static const Duration _accountStatusCacheDuration = Duration(minutes: 1);

  // 内存级 cookie（绕过 SecureStorage 延迟，Telegram 登录专用）
  static String? _inMemoryCookies;

  // 内存级 X-User-Auth 值（传给自定义 header，绕过 dart:io Cookie 头限制）
  static String? _inMemoryUserAuth;

  // Telegram 登录保护：阻止所有跳回登录页的请求
  static bool _loginRedirectBlocked = false;

  static void setInMemoryCookies(String? cookies) {
    _inMemoryCookies = cookies;
  }

  static void setInMemoryUserAuth(String? authValue) {
    _inMemoryUserAuth = authValue;
  }

  static void blockLoginRedirects() {
    _loginRedirectBlocked = true;
  }

  static void allowLoginRedirects() {
    _loginRedirectBlocked = false;
  }

  static bool get isLoginRedirectBlocked => _loginRedirectBlocked;

  static bool _shouldNavigateToLogin() {
    return !_loginRedirectBlocked;
  }

  /// 获取基础URL
  static Future<String> _getBaseUrl() async {
    return await UserDataService.getServerUrlWithDefault();
  }

  /// 获取认证cookies（内存优先，回退 SecureStorage）
  static Future<String?> _getCookies() async {
    if (_inMemoryCookies != null && _inMemoryCookies!.isNotEmpty) {
      return _inMemoryCookies;
    }
    return await UserDataService.getCookies();
  }

  /// 构建完整URL
  static Future<String> _buildUrl(String endpoint) async {
    final baseUrl = await _getBaseUrl();

    // 确保使用HTTPS
    String secureBaseUrl = baseUrl.replaceAll(RegExp(r'^http://'), 'https://');

    // 确保baseUrl不以/结尾，endpoint以/开头
    String cleanBaseUrl = secureBaseUrl.endsWith('/')
        ? secureBaseUrl.substring(0, secureBaseUrl.length - 1)
        : secureBaseUrl;
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return '$cleanBaseUrl$cleanEndpoint';
  }

  /// 构建请求头
  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest', // 防止CSRF攻击
      'X-CSRF-TOKEN': await _getCsrfToken(), // 添加CSRF令牌
    };

    // 添加认证信息
    if (includeAuth) {
      // 优先使用令牌认证
      final token = await UserDataService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        //  fallback to cookies认证
        final cookies = await _getCookies();
        if (cookies != null && cookies.isNotEmpty) {
          headers['Cookie'] = cookies;
        }
      }

      // 额外发送 X-User-Auth header（绕过 dart:io Cookie 头限制）
      if (_inMemoryUserAuth != null && _inMemoryUserAuth!.isNotEmpty) {
        headers['X-User-Auth'] = _inMemoryUserAuth!;
      }
    }

    // 添加额外头部
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// 获取CSRF令牌
  static Future<String> _getCsrfToken() async {
    // 生成基于UUID的CSRF令牌
    const uuid = Uuid();
    return uuid.v4();
  }

  /// 处理响应
  static Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  ) async {
    // 处理401未授权
    if (response.statusCode == 401) {
      // 尝试解析响应体中的错误信息
      String errorMessage = '登录已过期，请重新登录';
      try {
        final errorData = json.decode(response.body);
        if (errorData.containsKey('message')) {
          errorMessage = errorData['message'] as String;
        } else if (errorData.containsKey('error')) {
          errorMessage = errorData['error'] as String;
        }
      } catch (e) {
        // 解析失败，使用默认错误信息
      }

      if (_shouldNavigateToLogin()) {
        // 清除用户认证数据
        await UserDataService.clearAuthData();

        // 跳转到登录页
        if (context != null && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }

      return ApiResponse.error(
        errorMessage,
        statusCode: 401,
      );
    }

    // 处理403权限不足
    if (response.statusCode == 403) {
      return ApiResponse.error(
        '权限不足，无法访问该资源',
        statusCode: 403,
      );
    }

    // 处理其他错误状态码
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = '请求失败';
      try {
        final errorData = json.decode(response.body);
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        // 如果解析失败，使用默认错误信息
        switch (response.statusCode) {
          case 400:
            errorMessage = '请求参数错误';
            break;
          case 403:
            errorMessage = '没有权限访问';
            break;
          case 404:
            errorMessage = '请求的资源不存在';
            break;
          case 500:
            errorMessage = '服务器内部错误';
            break;
          default:
            errorMessage = '网络请求失败 (${response.statusCode})';
        }
      }

      return ApiResponse.error(
        errorMessage,
        statusCode: response.statusCode,
      );
    }

    // 处理成功响应
    try {
      final responseData = json.decode(response.body);

      if (fromJson != null) {
        final data = fromJson(responseData);
        return ApiResponse.success(data, statusCode: response.statusCode);
      } else {
        return ApiResponse.success(responseData as T,
            statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error(
        '响应数据解析失败: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  /// 带重试机制的请求执行器
  static Future<http.Response> _retryRequest(
    Future<http.Response> Function() request,
  ) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        return await request();
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          rethrow;
        }
        // 等待一段时间后重试
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    throw Exception('网络请求异常: 重试次数过多');
  }

  /// GET请求
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    String url = await _buildUrl(endpoint);

    // 构建URI并添加查询参数
    Uri uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      // 对查询参数进行验证和过滤
      final filteredParams = _filterQueryParameters(queryParameters);
      uri = uri.replace(queryParameters: filteredParams);
    }

    final requestHeaders = await _buildHeaders(additionalHeaders: headers);

    try {
      final response = await _retryRequest(
        () => http
            .get(
              uri,
              headers: requestHeaders,
            )
            .timeout(_timeout),
      );

      // 检查context是否仍然挂载
      if (context != null && !context.mounted) {
        return await _handleResponse(response, fromJson, null);
      }
      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      // 记录详细错误信息供调试
      // 生产环境中应使用专业的日志库
      // print('GET请求错误: ${e.toString()}');
      // 向用户返回通用错误信息
      return ApiResponse.error('网络请求异常，请稍后重试');
    }
  }

  /// 过滤查询参数，防止注入攻击
  static Map<String, String> _filterQueryParameters(
      Map<String, String> parameters) {
    final filtered = <String, String>{};
    parameters.forEach((key, value) {
      // 移除可能的注入字符和危险字符
      String filteredValue = value
          .replaceAll("'", '')
          .replaceAll('"', '')
          .replaceAll(';', '')
          .replaceAll('--', '')
          .replaceAll('/*', '')
          .replaceAll('*/', '')
          .replaceAll('<', '')
          .replaceAll('>', '')
          .trim();
      filtered[key] = filteredValue;
    });
    return filtered;
  }

  /// POST请求
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    final url = await _buildUrl(endpoint);
    final requestHeaders = await _buildHeaders(additionalHeaders: headers);

    // 对请求体进行验证和过滤
    Map<String, dynamic>? filteredBody;
    if (body != null) {
      filteredBody = _filterRequestBody(body);
    }

    try {
      final response = await _retryRequest(
        () => http
            .post(
              Uri.parse(url),
              headers: requestHeaders,
              body: filteredBody != null ? json.encode(filteredBody) : null,
            )
            .timeout(_timeout),
      );

      // 检查context是否仍然挂载
      if (context != null && !context.mounted) {
        return await _handleResponse(response, fromJson, null);
      }
      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      // 记录详细错误信息供调试
      // 生产环境中应使用专业的日志库
      // print('POST请求错误: ${e.toString()}');
      // 向用户返回通用错误信息
      return ApiResponse.error('网络请求异常，请稍后重试');
    }
  }

  /// 过滤请求体，防止注入攻击
  static Map<String, dynamic> _filterRequestBody(Map<String, dynamic> body) {
    final filtered = <String, dynamic>{};
    body.forEach((key, value) {
      if (value is String) {
        // 对字符串值进行过滤
        String filteredValue = value
            .replaceAll("'", '')
            .replaceAll('"', '')
            .replaceAll(';', '')
            .replaceAll('--', '')
            .replaceAll('/*', '')
            .replaceAll('*/', '')
            .replaceAll('<', '')
            .replaceAll('>', '')
            .trim();
        filtered[key] = filteredValue;
      } else if (value is Map) {
        // 递归过滤嵌套的Map
        filtered[key] = _filterRequestBody(value as Map<String, dynamic>);
      } else if (value is List) {
        // 过滤列表中的字符串元素
        filtered[key] = value.map((item) {
          if (item is String) {
            return item
                .replaceAll("'", '')
                .replaceAll('"', '')
                .replaceAll(';', '')
                .replaceAll('--', '')
                .replaceAll('/*', '')
                .replaceAll('*/', '')
                .replaceAll('<', '')
                .replaceAll('>', '')
                .trim();
          } else if (item is Map) {
            return _filterRequestBody(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        // 其他类型保持不变
        filtered[key] = value;
      }
    });
    return filtered;
  }

  /// PUT请求
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    final url = await _buildUrl(endpoint);
    final requestHeaders = await _buildHeaders(additionalHeaders: headers);

    // 对请求体进行验证和过滤
    Map<String, dynamic>? filteredBody;
    if (body != null) {
      filteredBody = _filterRequestBody(body);
    }

    try {
      final response = await _retryRequest(
        () => http
            .put(
              Uri.parse(url),
              headers: requestHeaders,
              body: filteredBody != null ? json.encode(filteredBody) : null,
            )
            .timeout(_timeout),
      );

      // 检查context是否仍然挂载
      if (context != null && !context.mounted) {
        return await _handleResponse(response, fromJson, null);
      }
      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      // 记录详细错误信息供调试
      // 生产环境中应使用专业的日志库
      // print('PUT请求错误: ${e.toString()}');
      // 向用户返回通用错误信息
      return ApiResponse.error('网络请求异常，请稍后重试');
    }
  }

  /// DELETE请求
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    final url = await _buildUrl(endpoint);
    final requestHeaders = await _buildHeaders(additionalHeaders: headers);

    try {
      final response = await _retryRequest(
        () => http
            .delete(
              Uri.parse(url),
              headers: requestHeaders,
            )
            .timeout(_timeout),
      );

      // 检查context是否仍然挂载
      if (context != null && !context.mounted) {
        return await _handleResponse(response, fromJson, null);
      }
      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      // 记录详细错误信息供调试
      // 生产环境中应使用专业的日志库
      // print('DELETE请求错误: ${e.toString()}');
      // 向用户返回通用错误信息
      return ApiResponse.error('网络请求异常，请稍后重试');
    }
  }

  /// 上传文件请求
  static Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        final url = await _buildUrl(endpoint);
        final requestHeaders = await _buildHeaders(
          additionalHeaders: headers,
          includeAuth: true,
        );

        // 移除Content-Type，让http包自动设置multipart的Content-Type
        requestHeaders.remove('Content-Type');

        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll(requestHeaders);

        // 添加文件
        request.files.add(await http.MultipartFile.fromPath('file', filePath));

        // 添加其他字段（经过过滤）
        if (fields != null) {
          final filteredFields = _filterQueryParameters(fields);
          request.fields.addAll(filteredFields);
        }

        final streamedResponse = await request.send().timeout(_timeout);
        final response = await http.Response.fromStream(streamedResponse);

        // 检查context是否仍然挂载
        if (context != null && !context.mounted) {
          return await _handleResponse(response, fromJson, null);
        }
        return await _handleResponse(response, fromJson, context);
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          // 记录详细错误信息供调试
          // 生产环境中应使用专业的日志库
          // print('文件上传错误: ${e.toString()}');
          // 向用户返回通用错误信息
          return ApiResponse.error('文件上传异常，请稍后重试');
        }
        // 等待一段时间后重试
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    // 向用户返回通用错误信息
    return ApiResponse.error('文件上传异常，请稍后重试');
  }

  /// 获取收藏夹列表
  static Future<ApiResponse<List<FavoriteItem>>> getFavorites(
      BuildContext context) async {
    try {
      final baseUrl = await _getBaseUrl();

      final cookies = await _getCookies();
      if (cookies == null) {
        return ApiResponse.error('用户未登录');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites'),
        headers: {
          'Accept': 'application/json',
          'Cookie': cookies,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<FavoriteItem> favorites = [];

        // 将Map转换为List并按save_time降序排序
        data.forEach((id, itemData) {
          favorites.add(FavoriteItem.fromJson(id, itemData));
        });

        // 按save_time降序排序
        favorites.sort((a, b) => b.saveTime.compareTo(a.saveTime));

        return ApiResponse.success(favorites, statusCode: response.statusCode);
      } else if (response.statusCode == 401) {
        // 未授权，跳转到登录页面
        if (_shouldNavigateToLogin() && context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return ApiResponse.error('登录已过期，请重新登录',
            statusCode: response.statusCode);
      } else {
        return ApiResponse.error('获取收藏夹失败: ${response.statusCode}',
            statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('获取收藏夹异常: ${e.toString()}');
    }
  }

  /// 获取搜索历史
  static Future<ApiResponse<List<String>>> getSearchHistory(
      BuildContext context) async {
    try {
      final response = await get<List<String>>(
        '/api/searchhistory',
        context: context,
        fromJson: (data) => (data as List).cast<String>(),
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!,
            statusCode: response.statusCode);
      } else {
        return ApiResponse.error(response.message ?? '获取搜索历史失败');
      }
    } catch (e) {
      return ApiResponse.error('获取搜索历史异常: ${e.toString()}');
    }
  }

  /// 添加搜索历史
  static Future<ApiResponse<void>> addSearchHistory(
      String query, BuildContext context) async {
    try {
      final response = await post<void>(
        '/api/searchhistory',
        context: context,
        body: {'keyword': query},
      );

      return response;
    } catch (e) {
      return ApiResponse.error('添加搜索历史异常: ${e.toString()}');
    }
  }

  /// 清空搜索历史
  static Future<ApiResponse<void>> clearSearchHistory(
      BuildContext context) async {
    try {
      final response = await delete<void>(
        '/api/searchhistory',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('清空搜索历史异常: ${e.toString()}');
    }
  }

  /// 删除单个搜索历史
  static Future<ApiResponse<void>> deleteSearchHistory(
      String query, BuildContext context) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await delete<void>(
        '/api/searchhistory?keyword=$encodedQuery',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('删除搜索历史异常: ${e.toString()}');
    }
  }

  /// 保存播放记录
  static Future<ApiResponse<void>> savePlayRecord(
      PlayRecord playRecord, BuildContext context) async {
    try {
      // 构建正确的请求体格式
      final key = '${playRecord.source}+${playRecord.id}';
      final body = {
        'key': key,
        'record': playRecord.toJson(),
      };

      final response = await post<void>(
        '/api/playrecords',
        body: body,
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('保存播放记录异常: ${e.toString()}');
    }
  }

  /// 删除播放记录
  static Future<ApiResponse<void>> deletePlayRecord(
      String source, String id, BuildContext context) async {
    try {
      final key = '$source+$id';
      final encodedKey = Uri.encodeComponent(key);
      final response = await delete<void>(
        '/api/playrecords?key=$encodedKey',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('删除播放记录异常: ${e.toString()}');
    }
  }

  /// 清空播放记录
  static Future<ApiResponse<void>> clearPlayRecord(BuildContext context) async {
    try {
      final response = await delete<void>(
        '/api/playrecords',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('清空播放记录异常: ${e.toString()}');
    }
  }

  /// 添加收藏
  static Future<ApiResponse<void>> favorite(String source, String id,
      Map<String, dynamic> favoriteData, BuildContext context) async {
    try {
      final key = '$source+$id';
      final body = {
        'key': key,
        'favorite': favoriteData,
      };

      final response = await post<void>(
        '/api/favorites',
        body: body,
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('收藏异常: ${e.toString()}');
    }
  }

  /// 取消收藏
  static Future<ApiResponse<void>> unfavorite(
      String source, String id, BuildContext context) async {
    try {
      final key = '$source+$id';
      final encodedKey = Uri.encodeComponent(key);
      final response = await delete<void>(
        '/api/favorites?key=$encodedKey',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('取消收藏异常: ${e.toString()}');
    }
  }

  /// 检查网络连接状态
  static Future<bool> checkConnection() async {
    try {
      final baseUrl = await _getBaseUrl();

      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 检查账号状态
  static Future<ApiResponse<bool>> checkAccountStatus(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    try {
      // 检查缓存是否有效（除非强制刷新）
      final now = DateTime.now();
      if (!forceRefresh &&
          _lastAccountStatusCheck != null &&
          _cachedAccountStatus != null &&
          now.difference(_lastAccountStatusCheck!).inSeconds <
              _accountStatusCacheDuration.inSeconds) {
        // 使用缓存的状态
        return ApiResponse.success(_cachedAccountStatus!);
      }

      // 使用较短的超时时间，避免长时间阻塞
      final response = await Future.value(get<bool>(
        '/api/user/status',
        context: context,
        fromJson: (data) => data['status'] == 'active',
      )).timeout(const Duration(seconds: 5), onTimeout: () {
        return ApiResponse<bool>.error('检查账号状态超时');
      });

      // 更新缓存
      if (response.success) {
        _cachedAccountStatus = response.data;
        _lastAccountStatusCheck = now;
      }

      return response;
    } catch (e) {
      return ApiResponse.error('检查账号状态异常: ${e.toString()}');
    }
  }

  /// 清除账号状态缓存
  static void clearAccountStatusCache() {
    _lastAccountStatusCheck = null;
    _cachedAccountStatus = null;
  }

  /// 自动登录方法
  static Future<ApiResponse<String>> autoLogin() async {
    try {
      // 检查账户是否被锁定
      if (await UserDataService.isAccountLocked()) {
        return ApiResponse.error('账户已被锁定，请稍后再试');
      }

      // 获取用户数据
      final username = await UserDataService.getUsername();
      final token = await UserDataService.getAuthToken();
      final cookies = await UserDataService.getCookies();

      if (username == null) {
        return ApiResponse.error('缺少登录信息');
      }

      // 如果已有令牌或cookies，直接返回成功
      if ((token != null && token.isNotEmpty) ||
          (cookies != null && cookies.isNotEmpty)) {
        return ApiResponse.success('自动登录成功');
      }

      // 没有令牌或cookies，返回需要重新登录
      return ApiResponse.error('需要重新登录');
    } catch (e) {
      return ApiResponse.error('自动登录异常: ${e.toString()}');
    }
  }

  /// 获取视频详情
  static Future<List<SearchResult>> fetchSourceDetail(
      String source, String id) async {
    try {
      final response = await get<SearchResult>(
        '/api/detail',
        queryParameters: {
          'source': source,
          'id': id,
        },
        fromJson: (data) => SearchResult.fromJson(data as Map<String, dynamic>),
      );

      if (response.success && response.data != null) {
        return [response.data!];
      } else {
        // 生产环境中移除print语句
        return [];
      }
    } catch (e) {
      // 生产环境中移除print语句
      return [];
    }
  }

  /// 搜索视频源数据
  static Future<List<SearchResult>> fetchSourcesData(String query) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/api/search',
        queryParameters: {
          'q': query.trim(),
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final results = data['results'] as List<dynamic>? ?? [];

        // 应用家庭模式过滤
        final familyMode = await UserDataService.getFamilyMode();
        return results
            .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
            .where((result) => !ContentFilterService.shouldFilter(
                result.sourceName,
                familyMode: familyMode,
                title: result.title))
            .toList();
      } else {
        // 生产环境中移除print语句
        return [];
      }
    } catch (e) {
      // 生产环境中移除print语句
      return [];
    }
  }

  /// 获取搜索资源列表
  static Future<List<SearchResource>> getSearchResources() async {
    try {
      final response = await get<List<SearchResource>>(
        '/api/search/resources',
        fromJson: (data) {
          final list = data as List<dynamic>;
          return list
              .map((item) =>
                  SearchResource.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        // 生产环境中移除print语句
        return [];
      }
    } catch (e) {
      // 生产环境中移除print语句
      return [];
    }
  }

  /// 获取直播源列表
  static Future<List<LiveSource>> getLiveSources() async {
    try {
      final response = await get<List<LiveSource>>(
        '/api/live/sources',
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final list = responseData['data'] as List<dynamic>;
          return list
              .map((item) => LiveSource.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        // 生产环境中移除print语句
        return [];
      }
    } catch (e) {
      // 生产环境中移除print语句
      return [];
    }
  }

  /// 获取直播频道列表
  static Future<List<LiveChannel>> getLiveChannels(String source) async {
    try {
      final response = await get<List<LiveChannel>>(
        '/api/live/channels',
        queryParameters: {'source': source},
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final list = responseData['data'] as List<dynamic>;
          return list
              .map((item) => LiveChannel.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        // 生产环境中移除print语句
        return [];
      }
    } catch (e) {
      // 生产环境中移除print语句
      return [];
    }
  }

  /// 获取 EPG 节目单
  static Future<EpgData?> getLiveEpg(String tvgId, String source) async {
    try {
      final response = await get<EpgData>(
        '/api/live/epg',
        queryParameters: {
          'tvgId': tvgId,
          'source': source,
        },
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final epgData = responseData['data'] as Map<String, dynamic>;
          return EpgData.fromJson(epgData);
        },
      );

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        // 生产环境中移除print语句
        return null;
      }
    } catch (e) {
      // 生产环境中移除print语句
      return null;
    }
  }

  /// 获取搜索建议
  static Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await get<List<SearchSuggestion>>(
        '/api/search/suggestions',
        queryParameters: {'q': query.trim()},
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final list = responseData['suggestions'] as List<dynamic>;
          return list
              .map((item) =>
                  SearchSuggestion.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );

      if (response.success && response.data != null) {
        // 提取建议文本列表
        return response.data!.map((suggestion) => suggestion.text).toList();
      } else {
        // 生产环境中移除print语句
        return [];
      }
    } catch (e) {
      // 生产环境中移除print语句
      return [];
    }
  }

  // 短剧数据缓存
  static List<dynamic>? _cachedShortDramaCategories;
  static final Map<String, Map<String, dynamic>> _cachedShortDramaLists = {};
  static DateTime? _shortDramaCategoryCacheTime;
  static const Duration _shortDramaCacheDuration = Duration(minutes: 5);

  /// 清除短剧缓存
  static void clearShortDramaCache() {
    _cachedShortDramaCategories = null;
    _cachedShortDramaLists.clear();
    _shortDramaCategoryCacheTime = null;
  }

  /// 获取短剧分类列表（带缓存）
  static Future<ApiResponse<List<dynamic>>> getShortDramaCategories(
      BuildContext context) async {
    try {
      final now = DateTime.now();
      if (_cachedShortDramaCategories != null &&
          _shortDramaCategoryCacheTime != null &&
          now.difference(_shortDramaCategoryCacheTime!) <
              _shortDramaCacheDuration) {
        return ApiResponse.success(_cachedShortDramaCategories!);
      }

      final response = await get<List<dynamic>>(
        '/api/shortdrama/categories',
        context: context,
        fromJson: (data) => (data as List).toList(),
      );

      if (response.success && response.data != null) {
        _cachedShortDramaCategories = response.data;
        _shortDramaCategoryCacheTime = now;
      }

      return response;
    } catch (e) {
      if (e is SocketException || e is TimeoutException) {
        if (_cachedShortDramaCategories != null) {
          return ApiResponse.success(_cachedShortDramaCategories!);
        }
      }
      return ApiResponse.error('获取短剧分类失败: ${e.toString()}');
    }
  }

  /// 获取短剧列表（带缓存，15秒超时）
  static Future<ApiResponse<Map<String, dynamic>>> getShortDramaList(
      int categoryId, int page, int size, BuildContext context) async {
    try {
      // 首页热门短剧使用缓存
      if (categoryId == 1 && page == 1 && size == 25) {
        const cacheKey = 'hot_short_drama';
        final now = DateTime.now();
        if (_cachedShortDramaLists.containsKey(cacheKey)) {
          final cached = _cachedShortDramaLists[cacheKey]!;
          final cacheTime =
              DateTime.fromMillisecondsSinceEpoch(cached['_cacheTime'] as int);
          if (now.difference(cacheTime) < _shortDramaCacheDuration) {
            return ApiResponse.success(
                Map<String, dynamic>.from(cached)..remove('_cacheTime'));
          }
        }
      }

      final url = await _buildUrl('/api/shortdrama/list');
      final requestHeaders = await _buildHeaders();

      final queryParams = {
        'categoryId': categoryId.toString(),
        'page': page.toString(),
        'size': size.toString(),
      };
      final filteredParams = _filterQueryParameters(queryParams);
      final uri = Uri.parse(url).replace(queryParameters: filteredParams);

      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 15));

      final result = await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
        // ignore: use_build_context_synchronously
        context,
      );

      // 缓存首页热门短剧数据
      if (categoryId == 1 &&
          page == 1 &&
          size == 25 &&
          result.success &&
          result.data != null) {
        final cacheData = Map<String, dynamic>.from(result.data!);
        cacheData['_cacheTime'] = DateTime.now().millisecondsSinceEpoch;
        _cachedShortDramaLists['hot_short_drama'] = cacheData;
      }

      return result;
    } catch (e) {
      // 网络错误时尝试返回缓存
      if (categoryId == 1 && page == 1 && size == 25) {
        const cacheKey = 'hot_short_drama';
        if (_cachedShortDramaLists.containsKey(cacheKey)) {
          final cached = _cachedShortDramaLists[cacheKey]!;
          return ApiResponse.success(
              Map<String, dynamic>.from(cached)..remove('_cacheTime'));
        }
      }
      return ApiResponse.error('获取短剧列表失败: ${e.toString()}');
    }
  }

  /// 获取短剧详情
  static Future<ApiResponse<Map<String, dynamic>>> getShortDramaDetail(
      int id, int episode, String? name, BuildContext context) async {
    try {
      final queryParameters = {
        'id': id.toString(),
        'episode': episode.toString(),
      };
      if (name != null) {
        queryParameters['name'] = name;
      }

      final response = await get<Map<String, dynamic>>(
        '/api/shortdrama/detail',
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('获取短剧详情失败: ${e.toString()}');
    }
  }

  /// 解析短剧视频地址
  static Future<ApiResponse<Map<String, dynamic>>> parseShortDrama(
      int id, int episode, String? name, BuildContext context) async {
    try {
      final queryParameters = {
        'id': id.toString(),
        'episode': episode.toString(),
      };
      if (name != null) {
        queryParameters['name'] = name;
      }

      final response = await get<Map<String, dynamic>>(
        '/api/shortdrama/parse',
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('解析短剧视频地址失败: ${e.toString()}');
    }
  }

  /// 搜索短剧
  static Future<ApiResponse<Map<String, dynamic>>> searchShortDrama(
      String query, BuildContext context) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/api/shortdrama/search',
        queryParameters: {'q': query.trim()},
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('搜索短剧失败: ${e.toString()}');
    }
  }

  /// 获取推荐短剧
  static Future<ApiResponse<Map<String, dynamic>>> getRecommendedShortDramas(
      BuildContext context) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/api/shortdrama/recommend',
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('获取推荐短剧失败: ${e.toString()}');
    }
  }

  /// 获取短剧集数信息
  static Future<ApiResponse<Map<String, dynamic>>> getShortDramaEpisodeCount(
      int id, BuildContext context) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/api/shortdrama/episode-count',
        queryParameters: {'id': id.toString()},
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('获取短剧集数信息失败: ${e.toString()}');
    }
  }

  /// 获取外部弹幕数据
  static Future<ApiResponse<List<DanmuItem>>> fetchDanmuExternal({
    String? title,
    String? year,
    String? episode,
    String? doubanId,
    String? episodeId,
    BuildContext? context,
  }) async {
    try {
      final params = <String, String>{};
      if (title != null) params['title'] = title;
      if (year != null) params['year'] = year;
      if (episode != null) params['episode'] = episode;
      if (doubanId != null) params['douban_id'] = doubanId;
      if (episodeId != null) params['episode_id'] = episodeId;

      final response = await get<List<DanmuItem>>(
        '/api/danmu-external',
        queryParameters: params.isNotEmpty ? params : null,
        context: context,
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => DanmuItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          if (data is Map<String, dynamic>) {
            final danmuList = data['danmu'] as List?;
            if (danmuList != null) {
              return danmuList
                  .map((e) => DanmuItem.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
          return <DanmuItem>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('获取弹幕数据失败: ${e.toString()}');
    }
  }

  /// 搜索弹幕库中的动漫
  static Future<ApiResponse<Map<String, dynamic>>> searchDanmuAnime(
    String keyword, {
    BuildContext? context,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/api/danmu-external/search',
        queryParameters: {'keyword': keyword.trim()},
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('搜索弹幕库失败: ${e.toString()}');
    }
  }

  /// 搜索网盘资源
  static Future<ApiResponse<NetDiskSearchResult>> searchNetdisk(
    String query, {
    BuildContext? context,
  }) async {
    try {
      final response = await get<NetDiskSearchResult>(
        '/api/netdisk/search',
        queryParameters: {'q': query.trim()},
        context: context,
        fromJson: (data) =>
            NetDiskSearchResult.fromJson(data as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('搜索网盘资源失败: ${e.toString()}');
    }
  }
}
