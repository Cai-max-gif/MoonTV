import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
import '../constants/app_regex.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';
import '../utils/security_utils.dart';

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
  static const Duration _timeout = AppDurations.networkTimeout;
  static const int _maxRetries = AppConfig.maxRetries;
  static const Duration _retryDelay = AppConfig.retryDelay;

  // 账号状态缓存
  static DateTime? _lastAccountStatusCheck;
  static bool? _cachedAccountStatus;
  static const Duration _accountStatusCacheDuration = AppDurations.accountStatusCache;

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
    String secureBaseUrl = baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), 'https://');

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
      AppConfig.headerContentType: AppStrings.contentTypeJsonUtf8,
      AppConfig.headerAccept: AppConfig.headerAcceptJson,
      AppConfig.headerXRequestedWith: AppConfig.headerXmlHttpRequest,
    };

    final cookieParts = <String>[];

    // 添加认证信息
    if (includeAuth) {
      // 优先使用令牌认证
      final authToken = await UserDataService.getAuthToken();
      if (authToken != null && authToken.isNotEmpty) {
        headers[AppConfig.headerAuthorization] = '${AppStrings.authorizationBearer}$authToken';
      } else {
        // fallback to cookies认证
        final cookies = await _getCookies();
        if (cookies != null && cookies.isNotEmpty) {
          cookieParts.add(cookies);
        }
      }

      // 额外发送 X-User-Auth header（绕过 dart:io Cookie 头限制）
      if (_inMemoryUserAuth != null && _inMemoryUserAuth!.isNotEmpty) {
        headers[AppConfig.headerXUserAuth] = _inMemoryUserAuth!;
      }
    }

    if (cookieParts.isNotEmpty) {
      headers[AppConfig.headerCookie] = cookieParts.join('; ');
    }

    // 添加额外头部
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
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
      String errorMessage = AppStrings.authLoginFailed;
      try {
        final errorData = json.decode(response.body);
        if (errorData.containsKey(AppConfig.jsonMessage)) {
          errorMessage = errorData[AppConfig.jsonMessage] as String;
        } else if (errorData.containsKey(AppConfig.jsonError)) {
          errorMessage = errorData[AppConfig.jsonError] as String;
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

    

    // 处理其他错误状态码
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = AppStrings.errorRequestFailed;
      try {
        final errorData = json.decode(response.body);
        errorMessage =
            errorData[AppConfig.jsonMessage] ?? errorData[AppConfig.jsonError] ?? errorMessage;
      } catch (e) {
        // 如果解析失败，使用默认错误信息
        switch (response.statusCode) {
          case 400:
            errorMessage = AppStrings.errorRequestFailed;
            break;
          case 403:
            errorMessage = AppStrings.serverError;
            break;
          case 404:
            errorMessage = AppStrings.errorRequestFailed;
            break;
          case 500:
            errorMessage = AppStrings.serverError;
            break;
          default:
            errorMessage = '${AppStrings.networkError} (${response.statusCode})';
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
        '${AppStrings.errorException}${e.toString()}',
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
    throw Exception(AppStrings.networkRetryLater);
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
      return ApiResponse.error(AppStrings.errorNetworkRequest);
    }
  }

  /// 过滤查询参数，防止注入攻击
  static Map<String, String> _filterQueryParameters(
      Map<String, String> parameters) {
    return SecurityUtils.filterQueryParameters(parameters);
  }

  /// POST请求
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    // 对请求体进行验证和过滤
    Map<String, dynamic>? filteredBody;
    if (body != null) {
      filteredBody = _filterRequestBody(body);
    }

    Future<ApiResponse<T>> doRequest() async {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
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
    }

    try {
      return await doRequest();
    } catch (e) {
      return ApiResponse.error(AppStrings.errorNetworkRequest);
    }
  }

  /// 过滤请求体，防止注入攻击
  static Map<String, dynamic> _filterRequestBody(Map<String, dynamic> body) {
    return SecurityUtils.filterRequestBody(body);
  }

  /// PUT请求
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    // 对请求体进行验证和过滤
    Map<String, dynamic>? filteredBody;
    if (body != null) {
      filteredBody = _filterRequestBody(body);
    }

    Future<ApiResponse<T>> doRequest() async {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
      final response = await _retryRequest(
        () => http
            .put(
              Uri.parse(url),
              headers: requestHeaders,
              body: filteredBody != null ? json.encode(filteredBody) : null,
            )
            .timeout(_timeout),
      );

      if (context != null && !context.mounted) {
        return await _handleResponse(response, fromJson, null);
      }
      return await _handleResponse(response, fromJson, context);
    }

    try {
      return await doRequest();
    } catch (e) {
      return ApiResponse.error(AppStrings.errorNetworkRequest);
    }
  }

  /// DELETE请求
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    BuildContext? context,
  }) async {
    Future<ApiResponse<T>> doRequest() async {
      final url = await _buildUrl(endpoint);
      final requestHeaders = await _buildHeaders(additionalHeaders: headers);
      final response = await _retryRequest(
        () => http
            .delete(
              Uri.parse(url),
              headers: requestHeaders,
            )
            .timeout(_timeout),
      );

      if (context != null && !context.mounted) {
        return await _handleResponse(response, fromJson, null);
      }
      return await _handleResponse(response, fromJson, context);
    }

    try {
      return await doRequest();
    } catch (e) {
      return ApiResponse.error(AppStrings.errorNetworkRequest);
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
        requestHeaders.remove(AppConfig.headerContentType);

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
          return ApiResponse.error(AppStrings.errorNetworkRequest);
        }
        // 等待一段时间后重试
        await Future.delayed(_retryDelay * retryCount);
      }
    }
    // 向用户返回通用错误信息
    return ApiResponse.error(AppStrings.errorNetworkRequest);
  }

  /// 获取收藏夹列表
  static Future<ApiResponse<List<FavoriteItem>>> getFavorites(
      BuildContext context) async {
    try {
      final baseUrl = await _getBaseUrl();

      final cookies = await _getCookies();
      if (cookies == null) {
        return ApiResponse.error(AppStrings.authLoginFailed);
      }

      final response = await http.get(
        Uri.parse('$baseUrl${AppConfig.favoritesEndpoint}'),
        headers: {
          AppConfig.headerAccept: AppConfig.headerAcceptJson,
          AppConfig.headerCookie: cookies,
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
        return ApiResponse.error(AppStrings.authLoginFailed,
            statusCode: response.statusCode);
      } else {
        return ApiResponse.error('${AppStrings.errorGetFailed}: ${response.statusCode}',
            statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 获取搜索历史
  static Future<ApiResponse<List<String>>> getSearchHistory(
      BuildContext context) async {
    try {
      final response = await get<List<String>>(
        AppConfig.searchHistoryEndpoint,
        context: context,
        fromJson: (data) => (data as List).cast<String>(),
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!,
            statusCode: response.statusCode);
      } else {
        return ApiResponse.error(response.message ?? AppStrings.errorGetFailed);
      }
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 添加搜索历史
  static Future<ApiResponse<void>> addSearchHistory(
      String query, BuildContext context) async {
    try {
      final response = await post<void>(
        AppConfig.searchHistoryEndpoint,
        context: context,
        body: {AppConfig.jsonKeyword: query},
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorAddFailed}: ${e.toString()}');
    }
  }

  /// 清空搜索历史
  static Future<ApiResponse<void>> clearSearchHistory(
      BuildContext context) async {
    try {
      final response = await delete<void>(
        AppConfig.searchHistoryEndpoint,
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorException}${e.toString()}');
    }
  }

  /// 删除单个搜索历史
  static Future<ApiResponse<void>> deleteSearchHistory(
      String query, BuildContext context) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await delete<void>(
        '${AppConfig.searchHistoryEndpoint}?keyword=$encodedQuery',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorDeleteFailed}: ${e.toString()}');
    }
  }

  /// 保存播放记录
  static Future<ApiResponse<void>> savePlayRecord(
      PlayRecord playRecord, BuildContext context) async {
    try {
      // 构建正确的请求体格式
      final key = '${playRecord.source}+${playRecord.id}';
      final body = {
        AppConfig.jsonKey: key,
        AppConfig.jsonRecord: playRecord.toJson(),
      };

      final response = await post<void>(
        AppConfig.playRecordsEndpoint,
        body: body,
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorException}${e.toString()}');
    }
  }

  /// 删除播放记录
  static Future<ApiResponse<void>> deletePlayRecord(
      String source, String id, BuildContext context) async {
    try {
      final key = '$source+$id';
      final encodedKey = Uri.encodeComponent(key);
      final response = await delete<void>(
        '${AppConfig.playRecordsEndpoint}?key=$encodedKey',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorDeleteFailed}: ${e.toString()}');
    }
  }

  /// 清空播放记录
  static Future<ApiResponse<void>> clearPlayRecord(BuildContext context) async {
    try {
      final response = await delete<void>(
        AppConfig.playRecordsEndpoint,
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorException}${e.toString()}');
    }
  }

  /// 添加收藏
  static Future<ApiResponse<void>> favorite(String source, String id,
      Map<String, dynamic> favoriteData, BuildContext context) async {
    try {
      final key = '$source+$id';
      final body = {
        AppConfig.jsonKey: key,
        AppConfig.jsonFavorite: favoriteData,
      };

      final response = await post<void>(
        AppConfig.favoritesEndpoint,
        body: body,
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.favFailed}: ${e.toString()}');
    }
  }

  /// 取消收藏
  static Future<ApiResponse<void>> unfavorite(
      String source, String id, BuildContext context) async {
    try {
      final key = '$source+$id';
      final encodedKey = Uri.encodeComponent(key);
      final response = await delete<void>(
        '${AppConfig.favoritesEndpoint}?key=$encodedKey',
        context: context,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.favUnfavoriteFailed}: ${e.toString()}');
    }
  }

  /// 检查网络连接状态
  static Future<bool> checkConnection() async {
    try {
      final baseUrl = await _getBaseUrl();

      final response = await http.get(
        Uri.parse('$baseUrl${AppConfig.healthEndpoint}'),
        headers: {AppConfig.headerAccept: AppConfig.headerAcceptJson},
      ).timeout(AppDurations.healthCheckTimeout);

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
        AppConfig.userStatusEndpoint,
        context: context,
        fromJson: (data) => data[AppConfig.jsonStatus] == AppConfig.accountStatusActive,
      )).timeout(AppDurations.healthCheckTimeout, onTimeout: () {
        return ApiResponse<bool>.error(AppStrings.networkError);
      });

      // 更新缓存
      if (response.success) {
        _cachedAccountStatus = response.data;
        _lastAccountStatusCheck = now;
      }

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorException}${e.toString()}');
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
        return ApiResponse.error(AppStrings.authAccountLockedLater);
      }

      // 获取用户数据
      final username = await UserDataService.getUsername();
      final token = await UserDataService.getAuthToken();
      final cookies = await UserDataService.getCookies();

      if (username == null) {
        return ApiResponse.error(AppStrings.authLoginEmpty);
      }

      // 如果已有令牌或cookies，直接返回成功
      if ((token != null && token.isNotEmpty) ||
          (cookies != null && cookies.isNotEmpty)) {
        return ApiResponse.success(AppStrings.authLoginSuccess);
      }

      // 没有令牌或cookies，返回需要重新登录
      return ApiResponse.error(AppStrings.authLoginFailed);
    } catch (e) {
      return ApiResponse.error('${AppStrings.authLoginFailed}: ${e.toString()}');
    }
  }

  /// 获取视频详情
  static Future<List<SearchResult>> fetchSourceDetail(
      String source, String id) async {
    try {
      final response = await get<SearchResult>(
        AppConfig.detailEndpoint,
        queryParameters: {
          AppConfig.jsonSource: source,
          AppConfig.jsonId: id,
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
        AppConfig.searchEndpoint,
        queryParameters: {
          AppConfig.queryQ: query.trim(),
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final results = data[AppConfig.jsonResults] as List<dynamic>? ?? [];

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
        AppConfig.searchResourcesEndpoint,
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
        AppConfig.liveSourcesEndpoint,
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final list = responseData[AppConfig.jsonData] as List<dynamic>;
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
        AppConfig.liveChannelsEndpoint,
        queryParameters: {AppConfig.jsonSource: source},
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final list = responseData[AppConfig.jsonData] as List<dynamic>;
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
        AppConfig.epgEndpoint,
        queryParameters: {
          AppConfig.jsonTvgId: tvgId,
          AppConfig.jsonSource: source,
        },
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final epgData = responseData[AppConfig.jsonData] as Map<String, dynamic>;
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
        AppConfig.searchSuggestionsEndpoint,
        queryParameters: {AppConfig.queryQ: query.trim()},
        fromJson: (data) {
          final responseData = data as Map<String, dynamic>;
          final list = responseData[AppConfig.jsonSuggestions] as List<dynamic>;
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

  // 短剧数据缓存配置
  static const Duration _shortDramaCategoryCacheDuration = AppConfig.shortDramaCategoryCache;
  static const Duration _shortDramaListCacheDuration = AppConfig.shortDramaListCache;
  static const Duration _shortDramaRecommendCacheDuration = AppConfig.shortDramaRecommendCache;
  

  // 缓存数据
  static List<dynamic>? _cachedShortDramaCategories;
  static final Map<String, Map<String, dynamic>> _cachedShortDramaLists = {};
  static Map<String, Map<String, dynamic>>? _cachedShortDramaRecommends;
  static DateTime? _shortDramaCategoryCacheTime;

  // 请求去重：存储正在进行的请求
  static final Map<String, Future<ApiResponse<dynamic>>> _pendingShortDramaRequests = {};

  /// 清除所有短剧缓存
  static void clearShortDramaCache() {
    _cachedShortDramaCategories = null;
    _cachedShortDramaLists.clear();
    _cachedShortDramaRecommends = null;
    _shortDramaCategoryCacheTime = null;
  }

  /// 生成缓存键
  static String _getShortDramaCacheKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = params.keys
        .where((key) => params[key] != null)
        .toList()
        ..sort();
    final paramsStr = sortedParams.map((key) => '$key=${params[key]}').join(AppConfig.urlSeparatorAmpersand);
    return '${AppConfig.cacheKeyPrefixShortDrama}-$prefix-$paramsStr';
  }

  /// 获取短剧分类列表（带缓存和请求去重）
  static Future<ApiResponse<List<dynamic>>> getShortDramaCategories(
      BuildContext context) async {
    try {
      final now = DateTime.now();

      // 检查缓存
      if (_cachedShortDramaCategories != null &&
          _shortDramaCategoryCacheTime != null &&
          now.difference(_shortDramaCategoryCacheTime!) <
              _shortDramaCategoryCacheDuration) {
        return ApiResponse.success(_cachedShortDramaCategories!);
      }

      // 请求去重
      const cacheKey = AppConfig.cacheKeyShortDramaCategories;
      if (_pendingShortDramaRequests.containsKey(cacheKey)) {
        return _pendingShortDramaRequests[cacheKey] as Future<ApiResponse<List<dynamic>>>;
      }

      final requestPromise = _fetchShortDramaCategories(context);
      _pendingShortDramaRequests[cacheKey] = requestPromise;

      try {
        final response = await requestPromise;
        if (response.success && response.data != null && response.data!.isNotEmpty) {
          _cachedShortDramaCategories = response.data;
          _shortDramaCategoryCacheTime = now;
        }
        return response;
      } finally {
        _pendingShortDramaRequests.remove(cacheKey);
      }
    } catch (e) {
      if ((e is SocketException || e is TimeoutException) && _cachedShortDramaCategories != null) {
        return ApiResponse.success(_cachedShortDramaCategories!);
      }
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  static Future<ApiResponse<List<dynamic>>> _fetchShortDramaCategories(
      BuildContext context) async {
    final response = await get<List<dynamic>>(
      AppConfig.shortDramaCategoriesEndpoint,
      context: context,
      fromJson: (data) => (data as List).toList(),
    );
    return response;
  }

  /// 获取短剧列表（带缓存和请求去重，15秒超时）
  static Future<ApiResponse<Map<String, dynamic>>> getShortDramaList(
      int categoryId, int page, int size, BuildContext context) async {
    try {
      final cacheKey = _getShortDramaCacheKey(AppConfig.cacheKeyPrefixList, {
        AppConfig.queryCategoryId: categoryId,
        AppConfig.queryPage: page,
        AppConfig.queryPageLimit: size,
      });

      // 优先检查缓存
      if (_cachedShortDramaLists.containsKey(cacheKey)) {
        final cached = _cachedShortDramaLists[cacheKey]!;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cached[AppConfig.jsonCacheTime] as int);
        final duration = page == 1 ? _shortDramaListCacheDuration * 2 : _shortDramaListCacheDuration;
        
        // 如果缓存未过期，直接返回缓存
        if (DateTime.now().difference(cacheTime) < duration) {
          return ApiResponse.success(Map<String, dynamic>.from(cached)..remove(AppConfig.jsonCacheTime));
        }
        
        // 如果缓存已过期但有数据，先返回缓存，后台异步刷新
        final cachedData = Map<String, dynamic>.from(cached)..remove(AppConfig.jsonCacheTime);
        _refreshShortDramaListAsync(categoryId, page, size, context);
        return ApiResponse.success(cachedData);
      }

      // 请求去重
      if (_pendingShortDramaRequests.containsKey(cacheKey)) {
        return _pendingShortDramaRequests[cacheKey] as Future<ApiResponse<Map<String, dynamic>>>;
      }

      final requestPromise = _fetchShortDramaList(categoryId, page, size, context);
      _pendingShortDramaRequests[cacheKey] = requestPromise;

      try {
        final result = await requestPromise;
        if (result.success && result.data != null) {
          final list = result.data![AppConfig.jsonList] as List?;
          if (list != null && list.isNotEmpty) {
            final cacheData = Map<String, dynamic>.from(result.data!);
            cacheData[AppConfig.jsonCacheTime] = DateTime.now().millisecondsSinceEpoch;
            _cachedShortDramaLists[cacheKey] = cacheData;
          }
        }
        return result;
      } finally {
        _pendingShortDramaRequests.remove(cacheKey);
      }
    } catch (e) {
      // 网络错误时尝试返回缓存
      final cacheKey = _getShortDramaCacheKey(AppConfig.cacheKeyPrefixList, {
        AppConfig.queryCategoryId: categoryId,
        AppConfig.queryPage: page,
        AppConfig.queryPageLimit: size,
      });
      if (_cachedShortDramaLists.containsKey(cacheKey)) {
        final cached = _cachedShortDramaLists[cacheKey]!;
        return ApiResponse.success(Map<String, dynamic>.from(cached)..remove(AppConfig.jsonCacheTime));
      }
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 异步刷新短剧列表缓存（后台刷新，不阻塞UI）
  static Future<void> _refreshShortDramaListAsync(
      int categoryId, int page, int size, BuildContext context) async {
    try {
      final result = await _fetchShortDramaList(categoryId, page, size, context);
      if (result.success && result.data != null) {
        final list = result.data![AppConfig.jsonList] as List?;
        if (list != null && list.isNotEmpty) {
          final cacheKey = _getShortDramaCacheKey(AppConfig.cacheKeyPrefixList, {
            AppConfig.queryCategoryId: categoryId,
            AppConfig.queryPage: page,
            AppConfig.queryPageLimit: size,
          });
          final cacheData = Map<String, dynamic>.from(result.data!);
          cacheData[AppConfig.jsonCacheTime] = DateTime.now().millisecondsSinceEpoch;
          _cachedShortDramaLists[cacheKey] = cacheData;
        }
      }
    } catch (_) {
      // 忽略异步刷新错误
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> _fetchShortDramaList(
      int categoryId, int page, int size, BuildContext context) async {
    final url = await _buildUrl(AppConfig.shortDramaListEndpoint);
    final requestHeaders = await _buildHeaders();

    final queryParams = {
      AppConfig.queryCategoryId: categoryId.toString(),
      AppConfig.queryPage: page.toString(),
      AppConfig.queryPageLimit: size.toString(),
    };
    final filteredParams = _filterQueryParameters(queryParams);
    final uri = Uri.parse(url).replace(queryParameters: filteredParams);

    final response = await http
        .get(uri, headers: requestHeaders)
        .timeout(AppConfig.authRequestTimeout);

    if (!context.mounted) {
      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data as Map<String, dynamic>,
        null,
      );
    }

    return _handleResponse<Map<String, dynamic>>(
      response,
      (data) => data as Map<String, dynamic>,
      context,
    );
  }

  /// 获取短剧详情
  static Future<ApiResponse<Map<String, dynamic>>> getShortDramaDetail(
      int id, int episode, String? name, BuildContext context) async {
    try {
      final queryParameters = <String, String>{
        AppConfig.jsonId: id.toString(),
        AppConfig.jsonEpisode: episode.toString(),
      };
      if (name != null && name.isNotEmpty) {
        queryParameters[AppConfig.jsonName] = name;
      }

      final response = await get<Map<String, dynamic>>(
        AppConfig.shortDramaDetailEndpoint,
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 解析短剧视频地址（支持备用API fallback）
  static Future<ApiResponse<Map<String, dynamic>>> parseShortDrama(
      int id, int episode, String? name, BuildContext context) async {
    try {
      final queryParameters = <String, String>{
        AppConfig.jsonId: id.toString(),
        AppConfig.jsonEpisode: episode.toString(),
        AppConfig.jsonProxy: 'true',
      };
      if (name != null && name.isNotEmpty) {
        queryParameters[AppConfig.jsonName] = name;
      }

      final response = await get<Map<String, dynamic>>(
        AppConfig.shortDramaParseEndpoint,
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 批量解析短剧集数
  static Future<ApiResponse<List<dynamic>>> parseShortDramaBatch(
      int id, List<int> episodes, BuildContext context) async {
    try {
      final queryParameters = {
        AppConfig.jsonId: id.toString(),
        AppConfig.jsonEpisodes: episodes.join(','),
        AppConfig.jsonProxy: 'true',
      };

      final response = await get<List<dynamic>>(
        AppConfig.shortDramaParseEndpoint,
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) {
          if (data is Map && data.containsKey(AppConfig.jsonResults)) {
            return (data[AppConfig.jsonResults] as List).toList();
          }
          return (data as List).toList();
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 搜索短剧（支持分页）
  static Future<ApiResponse<Map<String, dynamic>>> searchShortDrama(
      String query, int page, int size, BuildContext context) async {
    try {
      final queryParameters = {
        AppConfig.queryQuery: query.trim(),
        AppConfig.queryPage: page.toString(),
        AppConfig.queryPageLimit: size.toString(),
      };

      final response = await get<Map<String, dynamic>>(
        AppConfig.shortDramaSearchEndpoint,
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 获取推荐短剧（支持分类和数量参数）
  static Future<ApiResponse<List<dynamic>>> getRecommendedShortDramas(
      BuildContext context, {int? category, int size = AppConfig.defaultRecommendSize}) async {
    try {
      final cacheKey = _getShortDramaCacheKey(AppConfig.cacheKeyPrefixRecommends, {
        AppConfig.queryCategory: category,
        AppConfig.queryPageLimit: size,
      });

      // 检查缓存
      if (_cachedShortDramaRecommends != null && _cachedShortDramaRecommends!.containsKey(cacheKey)) {
        final cached = _cachedShortDramaRecommends![cacheKey]!;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cached[AppConfig.jsonCacheTime] as int);
        if (DateTime.now().difference(cacheTime) < _shortDramaRecommendCacheDuration) {
          return ApiResponse.success(cached[AppConfig.jsonData] as List<dynamic>);
        }
      }

      final queryParameters = <String, String>{};
      if (category != null) {
        queryParameters[AppConfig.jsonCategory] = category.toString();
      }
      queryParameters[AppConfig.jsonSize] = size.toString();

      final response = await get<List<dynamic>>(
        AppConfig.shortDramaRecommendEndpoint,
        queryParameters: queryParameters,
        context: context,
        fromJson: (data) => (data as List).toList(),
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        _cachedShortDramaRecommends ??= {};
        _cachedShortDramaRecommends![cacheKey] = {
          AppConfig.jsonData: response.data,
          AppConfig.jsonCacheTime: DateTime.now().millisecondsSinceEpoch,
        };
      }

      return response;
    } catch (e) {
      // 网络错误时尝试返回缓存
      final cacheKey = _getShortDramaCacheKey(AppConfig.cacheKeyPrefixRecommends, {
        AppConfig.queryCategory: category,
        AppConfig.queryPageLimit: size,
      });
      if (_cachedShortDramaRecommends != null && _cachedShortDramaRecommends!.containsKey(cacheKey)) {
        final cached = _cachedShortDramaRecommends![cacheKey]!;
        return ApiResponse.success(cached[AppConfig.jsonData] as List<dynamic>);
      }
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 获取短剧集数信息
  static Future<ApiResponse<Map<String, dynamic>>> getShortDramaEpisodeCount(
      int id, BuildContext context) async {
    try {
      final response = await get<Map<String, dynamic>>(
        AppConfig.shortDramaEpisodeCountEndpoint,
        queryParameters: {AppConfig.jsonId: id.toString()},
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
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
      if (title != null) params[AppConfig.jsonTitle] = title;
      if (year != null) params[AppConfig.jsonYear] = year;
      if (episode != null) params[AppConfig.jsonEpisode] = episode;
      if (doubanId != null) params[AppConfig.jsonDoubanId] = doubanId;
      if (episodeId != null) params[AppConfig.jsonEpisodeId] = episodeId;

      final response = await get<List<DanmuItem>>(
        AppConfig.danmuExternalEndpoint,
        queryParameters: params.isNotEmpty ? params : null,
        context: context,
        fromJson: (data) {
          if (data is List) {
            return data
                .map((e) => DanmuItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          if (data is Map<String, dynamic>) {
            final danmuList = data[AppConfig.jsonDanmu] as List?;
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
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 搜索弹幕库中的动漫
  static Future<ApiResponse<Map<String, dynamic>>> searchDanmuAnime(
    String keyword, {
    BuildContext? context,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        AppConfig.danmuExternalSearchEndpoint,
        queryParameters: {AppConfig.queryKeyword: keyword.trim()},
        context: context,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }

  /// 搜索网盘资源
  static Future<ApiResponse<NetDiskSearchResult>> searchNetdisk(
    String query, {
    BuildContext? context,
  }) async {
    try {
      final response = await get<NetDiskSearchResult>(
        AppConfig.netdiskSearchEndpoint,
        queryParameters: {AppConfig.queryQ: query.trim()},
        context: context,
        fromJson: (data) =>
            NetDiskSearchResult.fromJson(data as Map<String, dynamic>),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('${AppStrings.errorGetFailed}: ${e.toString()}');
    }
  }
}
