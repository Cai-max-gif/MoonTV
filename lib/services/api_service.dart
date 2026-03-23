import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_data_service.dart';
import '../screens/login_screen.dart';
import '../models/favorite_item.dart';
import '../models/search_result.dart';
import '../models/play_record.dart';
import '../models/search_resource.dart';
import '../models/live_source.dart';
import '../models/live_channel.dart';
import '../models/epg_program.dart';
import '../models/search_suggestion.dart';

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

  /// 获取基础URL
  static Future<String> _getBaseUrl() async {
    return await UserDataService.getServerUrlWithDefault();
  }

  /// 获取认证cookies
  static Future<String?> _getCookies() async {
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
    }

    // 添加额外头部
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// 获取CSRF令牌
  static Future<String> _getCsrfToken() async {
    // 这里可以从安全存储中获取CSRF令牌
    // 或者生成一个基于时间和设备信息的令牌
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceId = await _getDeviceId();
    return '${timestamp}_${deviceId.hashCode}';
  }

  /// 获取设备ID
  static Future<String> _getDeviceId() async {
    // 这里可以使用设备唯一标识符
    // 为了简化，使用当前时间戳作为临时方案
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 处理响应
  static Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  ) async {
    // 处理401未授权
    if (response.statusCode == 401) {
      // 清除用户认证数据
      await UserDataService.clearAuthData();

      // 跳转到登录页
      if (context != null) {
        // 检查context是否仍然有效
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }

      return ApiResponse.error(
        '登录已过期，请重新登录',
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

  /// GET请求
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      String url = await _buildUrl(endpoint);

      // 构建URI并添加查询参数
      Uri uri = Uri.parse(url);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        // 对查询参数进行验证和过滤
        final filteredParams = _filterQueryParameters(queryParameters);
        uri = uri.replace(queryParameters: filteredParams);
      }

      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      final response = await http
          .get(
            uri,
            headers: requestHeaders,
          )
          .timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
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
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      // 对请求体进行验证和过滤
      Map<String, dynamic>? filteredBody;
      if (body != null) {
        filteredBody = _filterRequestBody(body);
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: requestHeaders,
            body: filteredBody != null ? json.encode(filteredBody) : null,
          )
          .timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
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
        filtered[key] = (value as List).map((item) {
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
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      // 对请求体进行验证和过滤
      Map<String, dynamic>? filteredBody;
      if (body != null) {
        filteredBody = _filterRequestBody(body);
      }

      final response = await http
          .put(
            Uri.parse(url),
            headers: requestHeaders,
            body: filteredBody != null ? json.encode(filteredBody) : null,
          )
          .timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
    }
  }

  /// DELETE请求
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    try {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);

      final response = await http
          .delete(
            Uri.parse(url),
            headers: requestHeaders,
          )
          .timeout(_timeout);

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('网络请求异常: ${e.toString()}');
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

      return await _handleResponse(response, fromJson, context);
    } catch (e) {
      return ApiResponse.error('文件上传异常: ${e.toString()}');
    }
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
        if (context.mounted) {
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

  /// 自动登录方法
  static Future<ApiResponse<String>> autoLogin() async {
    try {
      // 检查账户是否被锁定
      if (await UserDataService.isAccountLocked()) {
        return ApiResponse.error('账户已被锁定，请稍后再试');
      }

      // 获取用户数据
      final baseUrl = await UserDataService.getServerUrlWithDefault();
      final username = await UserDataService.getUsername();
      final token = await UserDataService.getAuthToken();
      final cookies = await UserDataService.getCookies();

      if (username == null) {
        return ApiResponse.error('缺少登录信息');
      }

      // 如果已有令牌或cookies，直接返回成功
      if ((token != null && token.isNotEmpty) || (cookies != null && cookies.isNotEmpty)) {
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

        // 直接返回所有搜索结果，不进行过滤
        return results
            .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
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

  /// 解析 Set-Cookie 头部
  static String _parseCookies(http.Response response) {
    List<String> cookies = [];

    // 获取所有 Set-Cookie 头部
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      // HTTP 头部通常是 String 类型
      final cookieParts = setCookieHeaders.split(';');
      if (cookieParts.isNotEmpty) {
        cookies.add(cookieParts[0].trim());
      }
    }

    return cookies.join('; ');
  }
}
