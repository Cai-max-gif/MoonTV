import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserDataService {
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _tokenKey = 'auth_token';
  static const String _cookiesKey = 'cookies';
  static const String _doubanDataSourceKey = 'douban_data_source';
  static const String _doubanImageSourceKey = 'douban_image_source';
  static const String _m3u8ProxyUrlKey = 'm3u8_proxy_url';
  static const String _preferSpeedTestKey = 'prefer_speed_test';
  static const String _localSearchKey = 'local_search';
  static const String _isLocalModeKey = 'is_local_mode';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _accountLockedUntilKey = 'account_locked_until';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const int _maxLoginAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 15);

  // 内存缓存
  static bool? _isLocalModeCache;

  // 保存用户登录信息（支持令牌认证）
  static Future<void> saveUserData({
    required String username,
    String? password, // 密码仅用于当前登录，不再存储
    String? token,
    String? cookies,
  }) async {
    // 将用户名存储在安全存储中
    await _secureStorage.write(key: _usernameKey, value: username);

    // 不再存储密码，只在需要时使用

    // 存储令牌（如果提供）
    if (token != null && token.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: token);
    }

    // 存储cookies（如果提供）
    if (cookies != null && cookies.isNotEmpty) {
      await _secureStorage.write(key: _cookiesKey, value: cookies);
    }

    // 登录成功后重置登录尝试计数
    await resetLoginAttempts();
  }

  // 获取默认服务器地址
  static String getDefaultServerUrl() {
    return 'https://moontv.cc.cd';
  }

  // 获取服务器地址（固定返回默认值）
  static Future<String> getServerUrlWithDefault() async {
    return getDefaultServerUrl();
  }

  // 获取用户名
  static Future<String?> getUsername() async {
    return await _secureStorage.read(key: _usernameKey);
  }

  // 获取密码 - 不再存储密码，始终返回null
  static Future<String?> getPassword() async {
    return null;
  }

  // 获取认证令牌
  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // 获取cookies
  static Future<String?> getCookies() async {
    return await _secureStorage.read(key: _cookiesKey);
  }

  // 检查是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    final cookies = await getCookies();
    return (token != null && token.isNotEmpty) ||
        (cookies != null && cookies.isNotEmpty);
  }

  // 清除用户数据
  static Future<void> clearUserData() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _cookiesKey);
    await resetLoginAttempts();
  }

  // 只清除认证信息，保留服务器地址和用户名
  static Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _cookiesKey);
  }

  // 获取所有用户数据
  static Future<Map<String, String?>> getAllUserData() async {
    return {
      'serverUrl': getDefaultServerUrl(),
      'username': await getUsername(),
      'password': await getPassword(),
      'token': await getAuthToken(),
      'cookies': await getCookies(),
    };
  }

  // 检查是否具有自动登录所需的所有字段
  static Future<bool> hasAutoLoginData() async {
    final username = await getUsername();
    final token = await getAuthToken();
    final cookies = await getCookies();

    return username != null &&
        username.isNotEmpty &&
        (token != null && token.isNotEmpty ||
            cookies != null && cookies.isNotEmpty);
  }

  // ==================== 防暴力破解措施 ====================

  // 检查账户是否被锁定
  static Future<bool> isAccountLocked() async {
    final lockedUntil = await _secureStorage.read(key: _accountLockedUntilKey);

    if (lockedUntil == null) {
      return false;
    }

    final lockTime = int.tryParse(lockedUntil) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < lockTime;
  }

  // 获取账户锁定剩余时间
  static Future<Duration?> getAccountLockRemainingTime() async {
    final lockedUntil = await _secureStorage.read(key: _accountLockedUntilKey);

    if (lockedUntil == null) {
      return null;
    }

    final lockTime = int.tryParse(lockedUntil) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= lockTime) {
      await _secureStorage.delete(key: _accountLockedUntilKey);
      return null;
    }

    return Duration(milliseconds: lockTime - now);
  }

  // 记录登录失败
  static Future<void> recordLoginFailure() async {
    // 获取当前尝试次数
    final attemptsStr = await _secureStorage.read(key: _loginAttemptsKey);
    int attempts = int.tryParse(attemptsStr ?? '') ?? 0;
    attempts++;

    // 更新尝试次数和最后尝试时间
    await _secureStorage.write(
        key: _loginAttemptsKey, value: attempts.toString());
    await _secureStorage.write(
        key: _lastLoginAttemptKey,
        value: DateTime.now().millisecondsSinceEpoch.toString());

    // 检查是否达到最大尝试次数
    if (attempts >= _maxLoginAttempts) {
      final lockUntil =
          DateTime.now().add(_lockDuration).millisecondsSinceEpoch;
      await _secureStorage.write(
          key: _accountLockedUntilKey, value: lockUntil.toString());
    }
  }

  // 重置登录尝试计数
  static Future<void> resetLoginAttempts() async {
    await _secureStorage.delete(key: _loginAttemptsKey);
    await _secureStorage.delete(key: _lastLoginAttemptKey);
    await _secureStorage.delete(key: _accountLockedUntilKey);
  }

  // 获取当前登录尝试次数
  static Future<int> getLoginAttempts() async {
    final attemptsStr = await _secureStorage.read(key: _loginAttemptsKey);
    return int.tryParse(attemptsStr ?? '') ?? 0;
  }

  // 保存豆瓣数据源设置（存储key值）
  static Future<void> saveDoubanDataSource(String dataSourceDisplayName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDoubanDataSourceKeyFromDisplayName(dataSourceDisplayName);
    await prefs.setString(_doubanDataSourceKey, key);
  }

  // 获取豆瓣数据源设置（返回key值）
  static Future<String> getDoubanDataSourceKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doubanDataSourceKey) ?? 'direct';
  }

  // 获取豆瓣数据源显示名称
  static Future<String> getDoubanDataSourceDisplayName() async {
    final key = await getDoubanDataSourceKey();
    return _getDoubanDataSourceDisplayNameFromKey(key);
  }

  // 保存豆瓣图片源设置（存储key值）
  static Future<void> saveDoubanImageSource(
      String imageSourceDisplayName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDoubanImageSourceKeyFromDisplayName(imageSourceDisplayName);
    await prefs.setString(_doubanImageSourceKey, key);
  }

  // 获取豆瓣图片源设置（返回key值）
  static Future<String> getDoubanImageSourceKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doubanImageSourceKey) ?? 'direct';
  }

  // 获取豆瓣图片源显示名称
  static Future<String> getDoubanImageSourceDisplayName() async {
    final key = await getDoubanImageSourceKey();
    return _getDoubanImageSourceDisplayNameFromKey(key);
  }

  // 根据显示名称获取豆瓣数据源的key值（私有方法）
  static String _getDoubanDataSourceKeyFromDisplayName(String dataSource) {
    switch (dataSource) {
      case '直连':
        return 'direct';
      case 'Cors Proxy By Zwei':
        return 'cors_proxy';
      case '豆瓣 CDN By CMLiussss（腾讯云）':
        return 'cdn_tencent';
      case '豆瓣 CDN By CMLiussss（阿里云）':
        return 'cdn_aliyun';
      default:
        return 'direct';
    }
  }

  // 根据显示名称获取豆瓣图片源的key值（私有方法）
  static String _getDoubanImageSourceKeyFromDisplayName(String imageSource) {
    switch (imageSource) {
      case '直连':
        return 'direct';
      case '豆瓣官方精品 CDN':
        return 'official_cdn';
      case '豆瓣 CDN By CMLiussss（腾讯云）':
        return 'cdn_tencent';
      case '豆瓣 CDN By CMLiussss（阿里云）':
        return 'cdn_aliyun';
      default:
        return 'direct';
    }
  }

  // 根据key值获取豆瓣数据源显示名称（私有方法）
  static String _getDoubanDataSourceDisplayNameFromKey(String key) {
    switch (key) {
      case 'direct':
        return '直连';
      case 'cors_proxy':
        return 'Cors Proxy By Zwei';
      case 'cdn_tencent':
        return '豆瓣 CDN By CMLiussss（腾讯云）';
      case 'cdn_aliyun':
        return '豆瓣 CDN By CMLiussss（阿里云）';
      default:
        return '直连';
    }
  }

  // 根据key值获取豆瓣图片源显示名称（私有方法）
  static String _getDoubanImageSourceDisplayNameFromKey(String key) {
    switch (key) {
      case 'direct':
        return '直连';
      case 'official_cdn':
        return '豆瓣官方精品 CDN';
      case 'cdn_tencent':
        return '豆瓣 CDN By CMLiussss（腾讯云）';
      case 'cdn_aliyun':
        return '豆瓣 CDN By CMLiussss（阿里云）';
      default:
        return '直连';
    }
  }

  // 保存 M3U8 代理 URL
  static Future<void> saveM3u8ProxyUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_m3u8ProxyUrlKey, url);
  }

  // 获取 M3U8 代理 URL
  static Future<String> getM3u8ProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_m3u8ProxyUrlKey) ?? '';
  }

  // 保存优选测速设置
  static Future<void> savePreferSpeedTest(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferSpeedTestKey, enabled);
  }

  // 获取优选测速设置（默认为 true）
  static Future<bool> getPreferSpeedTest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preferSpeedTestKey) ?? true;
  }

  // 保存本地搜索设置
  static Future<void> saveLocalSearch(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localSearchKey, enabled);
  }

  // 获取本地搜索设置（默认为 false）
  static Future<bool> getLocalSearch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localSearchKey) ?? false;
  }

  // 保存本地模式设置
  static Future<void> saveIsLocalMode(bool isLocalMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLocalModeKey, isLocalMode);
    _isLocalModeCache = isLocalMode; // 同步更新内存缓存
  }

  // 获取本地模式设置（默认为 false）
  static Future<bool> getIsLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_isLocalModeKey) ?? false;
    _isLocalModeCache = value; // 缓存到内存
    return value;
  }

  // 同步获取本地模式设置（从内存缓存读取）
  static bool getIsLocalModeSync() {
    return _isLocalModeCache ?? false;
  }
}
