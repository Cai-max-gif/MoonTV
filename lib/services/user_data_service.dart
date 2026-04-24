import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserDataService {
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _tokenKey = 'auth_token';
  static const String _cookiesKey = 'cookies';
  static const String _localSearchKey = 'local_search';
  static const String _defaultPlaybackSpeedKey = 'default_playback_speed';
  static const String _autoEnterPictureInPictureKey =
      'auto_enter_picture_in_picture';
  static const String _incognitoModeKey = 'incognito_mode';

  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _accountLockedUntilKey = 'account_locked_until';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const int _maxLoginAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 15);

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

  // 保存默认倍速设置
  static Future<void> saveDefaultPlaybackSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_defaultPlaybackSpeedKey, speed);
  }

  // 获取默认倍速设置（默认为 1.0）
  static Future<double> getDefaultPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_defaultPlaybackSpeedKey) ?? 1.0;
  }

  // 保存自动进入画中画设置
  static Future<void> saveAutoEnterPictureInPicture(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoEnterPictureInPictureKey, enabled);
  }

  // 获取自动进入画中画设置（默认为 false）
  static Future<bool> getAutoEnterPictureInPicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoEnterPictureInPictureKey) ?? false;
  }

  // 保存隐身模式设置
  static Future<void> saveIncognitoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_incognitoModeKey, enabled);
  }

  // 获取隐身模式设置（默认为 false）
  static Future<bool> getIncognitoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_incognitoModeKey) ?? false;
  }
}
