import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class UserDataService {
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _tokenKey = 'auth_token';
  static const String _cookiesKey = 'cookies';
  static const String _localSearchKey = 'local_search';
  static const String _defaultPlaybackSpeedKey = 'default_playback_speed';
  static const String _autoEnterPictureInPictureKey =
      'auto_enter_picture_in_picture';
  static const String _autoSkipOpeningEndingKey = 'auto_skip_opening_ending';
  static const String _skipOpeningDurationKey = 'skip_opening_duration';
  static const String _skipEndingDurationKey = 'skip_ending_duration';
  static const String _autoPlayNextKey = 'auto_play_next';
  static const String _familyModeKey = 'family_mode';

  static const String _danmakuEnabledKey = 'danmaku_enabled';
  static const String _danmakuSpeedKey = 'danmaku_speed';
  static const String _danmakuOpacityKey = 'danmaku_opacity';
  static const String _danmakuFontSizeKey = 'danmaku_font_size';
  static const String _danmakuDisplayAreaKey = 'danmaku_display_area';
  static const String _danmakuAntiBlockKey = 'danmaku_anti_block';
  static const String _danmakuSyncSpeedKey = 'danmaku_sync_speed';

  static const String _syncPlaybackProgressKey = 'sync_playback_progress';
  static const String _syncFavoritesKey = 'sync_favorites';
  static const String _syncWatchHistoryKey = 'sync_watch_history';
  static const String _syncSettingsKey = 'sync_settings';

  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastLoginAttemptKey = 'last_login_attempt';
  static const String _accountLockedUntilKey = 'account_locked_until';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const int _maxLoginAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 15);

  static final ValueNotifier<bool> danmakuEnabledNotifier =
      ValueNotifier<bool>(false);
  static final ValueNotifier<int> danmakuSpeedNotifier = ValueNotifier<int>(2);
  static final ValueNotifier<int> danmakuOpacityNotifier =
      ValueNotifier<int>(100);
  static final ValueNotifier<double> danmakuFontSizeNotifier =
      ValueNotifier<double>(1.0);
  static final ValueNotifier<double> danmakuDisplayAreaNotifier =
      ValueNotifier<double>(1.0);
  static final ValueNotifier<bool> danmakuAntiBlockNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<bool> danmakuSyncSpeedNotifier =
      ValueNotifier<bool>(true);

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

    // 存储令牌（如果提供），否则清除旧令牌
    if (token != null && token.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: token);
    } else {
      await _secureStorage.delete(key: _tokenKey);
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

  // 保存自动跳过片头片尾设置
  static Future<void> saveAutoSkipOpeningEnding(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSkipOpeningEndingKey, enabled);
  }

  // 获取自动跳过片头片尾设置（默认为 false）
  static Future<bool> getAutoSkipOpeningEnding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSkipOpeningEndingKey) ?? false;
  }

  // 保存片头跳过时长设置
  static Future<void> saveSkipOpeningDuration(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_skipOpeningDurationKey, duration);
  }

  // 获取片头跳过时长设置（默认为 90）
  static Future<int> getSkipOpeningDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_skipOpeningDurationKey) ?? 90;
  }

  // 保存片尾跳过时长设置
  static Future<void> saveSkipEndingDuration(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_skipEndingDurationKey, duration);
  }

  // 获取片尾跳过时长设置（默认为 180）
  static Future<int> getSkipEndingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_skipEndingDurationKey) ?? 180;
  }

  // 保存自动连播设置
  static Future<void> saveAutoPlayNext(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPlayNextKey, enabled);
  }

  // 获取自动连播设置（默认为 false）
  static Future<bool> getAutoPlayNext() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPlayNextKey) ?? false;
  }

  // 保存家庭模式设置
  static Future<void> saveFamilyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_familyModeKey, enabled);
  }

  // 获取家庭模式设置（默认为 true）
  static Future<bool> getFamilyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_familyModeKey) ?? true;
  }

  // ==================== 弹幕设置 ====================

  static Future<void> initDanmakuEnabled() async {
    final enabled = await getDanmakuEnabled();
    danmakuEnabledNotifier.value = enabled;
  }

  static Future<void> initDanmakuSettings() async {
    danmakuSpeedNotifier.value = await getDanmakuSpeed();
    danmakuOpacityNotifier.value = await getDanmakuOpacity();
    danmakuFontSizeNotifier.value = await getDanmakuFontSize();
    danmakuDisplayAreaNotifier.value = await getDanmakuDisplayArea();
    danmakuAntiBlockNotifier.value = await getDanmakuAntiBlock();
    danmakuSyncSpeedNotifier.value = await getDanmakuSyncSpeed();
  }

  static Future<void> saveDanmakuEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_danmakuEnabledKey, enabled);
    danmakuEnabledNotifier.value = enabled;
  }

  // 获取弹幕启用状态（默认为 false）
  static Future<bool> getDanmakuEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_danmakuEnabledKey) ?? false;
  }

  static Future<void> saveDanmakuSpeed(int speedIndex) async {
    final clamped = speedIndex.clamp(0, 4);
    danmakuSpeedNotifier.value = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_danmakuSpeedKey, clamped);
  }

  static Future<int> getDanmakuSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return prefs.getInt(_danmakuSpeedKey)?.clamp(0, 4) ?? 2;
    } catch (_) {
      return (prefs.getDouble(_danmakuSpeedKey) ?? 2).toInt().clamp(0, 4);
    }
  }

  static Future<void> saveDanmakuOpacity(int opacity) async {
    final clamped = opacity.clamp(0, 100);
    danmakuOpacityNotifier.value = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_danmakuOpacityKey, clamped);
  }

  static Future<int> getDanmakuOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return prefs.getInt(_danmakuOpacityKey)?.clamp(0, 100) ?? 100;
    } catch (_) {
      return (prefs.getDouble(_danmakuOpacityKey) ?? 100).toInt().clamp(0, 100);
    }
  }

  static Future<void> saveDanmakuFontSize(double fontSize) async {
    final clamped = fontSize.clamp(0.5, 2.0);
    danmakuFontSizeNotifier.value = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_danmakuFontSizeKey, clamped);
  }

  static Future<double> getDanmakuFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_danmakuFontSizeKey) ?? 1.0).clamp(0.5, 2.0);
  }

  static Future<void> saveDanmakuDisplayArea(double area) async {
    final clamped = area.clamp(0.25, 1.0);
    danmakuDisplayAreaNotifier.value = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_danmakuDisplayAreaKey, clamped);
  }

  static Future<double> getDanmakuDisplayArea() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_danmakuDisplayAreaKey) ?? 1.0).clamp(0.25, 1.0);
  }

  static Future<void> saveDanmakuAntiBlock(bool enabled) async {
    danmakuAntiBlockNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_danmakuAntiBlockKey, enabled);
  }

  static Future<bool> getDanmakuAntiBlock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_danmakuAntiBlockKey) ?? true;
  }

  static Future<void> saveDanmakuSyncSpeed(bool enabled) async {
    danmakuSyncSpeedNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_danmakuSyncSpeedKey, enabled);
  }

  static Future<bool> getDanmakuSyncSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_danmakuSyncSpeedKey) ?? true;
  }

  // ==================== 同步设置 ====================

  static Future<void> saveSyncPlaybackProgress(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncPlaybackProgressKey, enabled);
  }

  static Future<bool> getSyncPlaybackProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncPlaybackProgressKey) ?? true;
  }

  static Future<void> saveSyncFavorites(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncFavoritesKey, enabled);
  }

  static Future<bool> getSyncFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncFavoritesKey) ?? true;
  }

  static Future<void> saveSyncWatchHistory(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncWatchHistoryKey, enabled);
  }

  static Future<bool> getSyncWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncWatchHistoryKey) ?? true;
  }

  static Future<void> saveSyncSettings(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncSettingsKey, enabled);
  }

  static Future<bool> getSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncSettingsKey) ?? true;
  }
}
