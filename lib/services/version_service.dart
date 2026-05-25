import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

enum AndroidArch { v7, v8, x86_64, universal }

enum UpdateType {
  force,
  optional,
}

enum UpdateDownloadStatus {
  idle,
  downloading,
  completed,
  failed,
}

class VersionService {
  static const String githubRepoUrl = 'https://github.com/Cai-max-gif/MoonTV';
  static const String githubApiUrl =
      'https://api.github.com/repos/Cai-max-gif/MoonTV/releases/latest';
  static const String _lastCheckKey = 'last_version_check';
  static const String _dismissedVersionKey = 'dismissed_version';

  static bool _isBackgroundDownloading = false;
  static double _backgroundDownloadProgress = 0.0;
  static String? _backgroundDownloadVersion;
  static String? _backgroundDownloadFilePath;
  static CancelToken? _downloadCancelToken;
  static Completer<String?>? _downloadCompleter;
  static final List<Function(double progress)> _progressListeners = [];
  static VersionInfo? _storedVersionInfo;

  static bool _isForegroundDownloading = false;
  static double _foregroundDownloadProgress = 0.0;
  static String? _foregroundDownloadVersion;

  static void setForegroundDownloading(bool isDownloading, String? version) {
    _isForegroundDownloading = isDownloading;
    _foregroundDownloadVersion = version;
  }

  static void updateForegroundProgress(double progress) {
    _foregroundDownloadProgress = progress;
    for (final listener in _progressListeners) {
      try {
        listener(progress);
      } catch (e) {
        debugPrint('Progress listener error: $e');
      }
    }
  }

  static bool get isForegroundDownloading => _isForegroundDownloading;
  static double get foregroundDownloadProgress => _foregroundDownloadProgress;
  static String? get foregroundDownloadVersion => _foregroundDownloadVersion;

  static void clearForegroundDownload() {
    _isForegroundDownloading = false;
    _foregroundDownloadProgress = 0.0;
    _foregroundDownloadVersion = null;
  }

  static Future<AndroidArch> getAndroidArchitecture() async {
    if (!Platform.isAndroid) return AndroidArch.universal;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final supportedAbis = androidInfo.supportedAbis;

    if (supportedAbis.contains('arm64-v8a')) {
      return AndroidArch.v8;
    } else if (supportedAbis.contains('armeabi-v7a')) {
      return AndroidArch.v7;
    } else if (supportedAbis.contains('x86_64')) {
      return AndroidArch.x86_64;
    } else {
      return AndroidArch.universal;
    }
  }

  static String getDownloadUrl(String version, AndroidArch arch) {
    final tag = version.startsWith('v') ? version : 'v$version';

    if (Platform.isAndroid) {
      switch (arch) {
        case AndroidArch.v7:
          return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV-v7.apk';
        case AndroidArch.v8:
          return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV-v8.apk';
        case AndroidArch.x86_64:
          return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV-x86_64.apk';
        case AndroidArch.universal:
          return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV-universal.apk';
      }
    } else if (Platform.isWindows) {
      return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV-Setup.exe';
    } else if (Platform.isMacOS) {
      return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV.dmg';
    } else if (Platform.isIOS) {
      return 'https://github.com/Cai-max-gif/MoonTV/releases/download/$tag/MoonTV.ipa';
    }

    return getReleaseUrl(version);
  }

  static Future<String> getFileName(String version, AndroidArch arch) {
    final tag = version.startsWith('v') ? version : 'v$version';

    if (Platform.isAndroid) {
      switch (arch) {
        case AndroidArch.v7:
          return Future.value('MoonTV-v7.apk');
        case AndroidArch.v8:
          return Future.value('MoonTV-v8.apk');
        case AndroidArch.x86_64:
          return Future.value('MoonTV-x86_64.apk');
        case AndroidArch.universal:
          return Future.value('MoonTV-universal.apk');
      }
    } else if (Platform.isWindows) {
      return Future.value('MoonTV-Setup.exe');
    } else if (Platform.isMacOS) {
      return Future.value('MoonTV.dmg');
    } else if (Platform.isIOS) {
      return Future.value('MoonTV.ipa');
    }

    return Future.value('MoonTV-$tag');
  }

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    // Android 13 (API 33+) 不需要传统的存储权限
    if (androidInfo.version.sdkInt >= 33) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }

  static CancelToken? _foregroundDownloadCancelToken;

  static Future<String?> downloadFile(
    String url,
    String fileName, {
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      _foregroundDownloadCancelToken = cancelToken ?? CancelToken();
      final dir = await getApplicationDocumentsDirectory();

      final savePath = '${dir.path}/$fileName';
      final dio = Dio();

      await dio.download(
        url,
        savePath,
        cancelToken: _foregroundDownloadCancelToken,
        onReceiveProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('Download cancelled');
      }
      return null;
    }
  }

  static void cancelForegroundDownload() {
    _foregroundDownloadCancelToken?.cancel();
    _foregroundDownloadCancelToken = null;
  }

  static Future<bool> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  static Future<VersionInfo?> checkForUpdate({bool isManualCheck = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String;
        final latestVersion =
            tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final releaseNotes = data['body'] as String? ?? '';

        if (_isNewerVersion(currentVersion, latestVersion)) {
          // 如果是手动检查，不检查是否被忽略
          if (!isManualCheck) {
            // 检查是否被用户忽略过这个版本
            final prefs = await SharedPreferences.getInstance();
            final dismissedVersion = prefs.getString(_dismissedVersionKey);
            if (dismissedVersion == latestVersion) {
              return null;
            }
          }

          AndroidArch arch = AndroidArch.universal;
          if (Platform.isAndroid) {
            arch = await getAndroidArchitecture();
          }

          final updateType = getUpdateType(currentVersion, latestVersion);

          return VersionInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            androidArch: arch,
            updateType: updateType,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static String getReleaseUrl(String version) {
    return '$githubRepoUrl/releases/tag/v$version';
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  static UpdateType getUpdateType(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    while (latestParts.length < 3) {
      latestParts.add(0);
    }

    final currentMajor = currentParts[0];
    final latestMajor = latestParts[0];

    if (latestMajor > currentMajor) {
      return UpdateType.force;
    }

    return UpdateType.optional;
  }

  static Future<bool> shouldShowUpdatePrompt(String version) async {
    final prefs = await SharedPreferences.getInstance();

    final dismissedVersion = prefs.getString(_dismissedVersionKey);
    if (dismissedVersion == version) {
      return false;
    }

    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const dayInMs = 24 * 60 * 60 * 1000;

    if (now - lastCheck < dayInMs) {
      return false;
    }

    await prefs.setInt(_lastCheckKey, now);
    return true;
  }

  static Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  static Future<void> clearDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedVersionKey);
  }

  static UpdateDownloadStatus get downloadStatus {
    if (_isBackgroundDownloading) return UpdateDownloadStatus.downloading;
    if (_backgroundDownloadFilePath != null) return UpdateDownloadStatus.completed;
    return UpdateDownloadStatus.idle;
  }

  static double get downloadProgress => _backgroundDownloadProgress;

  static String? get downloadingVersion => _backgroundDownloadVersion;

  static String? get downloadedFilePath => _backgroundDownloadFilePath;

  static void setDownloadedFilePath(String? filePath) {
    _backgroundDownloadFilePath = filePath;
  }

  static VersionInfo? get storedVersionInfo => _storedVersionInfo;

  static void setStoredVersionInfo(VersionInfo? versionInfo) {
    _storedVersionInfo = versionInfo;
  }

  static void addProgressListener(Function(double progress) listener) {
    if (!_progressListeners.contains(listener)) {
      _progressListeners.add(listener);
    }
  }

  static void removeProgressListener(Function(double progress) listener) {
    _progressListeners.remove(listener);
  }

  static void _notifyProgress(double progress) {
    _backgroundDownloadProgress = progress;
    for (final listener in _progressListeners) {
      try {
        listener(progress);
      } catch (e) {
        debugPrint('Progress listener error: $e');
      }
    }
  }

  static Future<String?> startBackgroundDownload(
    String version,
    AndroidArch arch, {
    Function(double progress)? onProgress,
    Function(String filePath)? onComplete,
    Function()? onFailed,
  }) async {
    if (_isBackgroundDownloading) {
      debugPrint('Already downloading in background');
      return null;
    }

    _isBackgroundDownloading = true;
    _backgroundDownloadProgress = 0.0;
    _backgroundDownloadVersion = version;
    _downloadCancelToken = CancelToken();
    _downloadCompleter = Completer<String?>();

    if (onProgress != null) {
      addProgressListener(onProgress);
    }

    try {
      if (Platform.isAndroid) {
        final hasInstallPermission = await requestInstallPermission();
        if (!hasInstallPermission) {
          if (onFailed != null) onFailed();
          _isBackgroundDownloading = false;
          _downloadCompleter?.complete(null);
          if (onProgress != null) {
            removeProgressListener(onProgress);
          }
          return null;
        }
      }

      final downloadUrl = getDownloadUrl(version, arch);
      final fileName = await getFileName(version, arch);
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      final dio = Dio();

      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            _notifyProgress(progress);
          }
        },
      );

      _backgroundDownloadFilePath = savePath;
      _isBackgroundDownloading = false;

      if (onComplete != null) {
        onComplete(savePath);
      }

      _downloadCompleter?.complete(savePath);
      if (onProgress != null) {
        removeProgressListener(onProgress);
      }

      return savePath;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('Download cancelled');
      } else {
        debugPrint('Background download failed: $e');
        if (onFailed != null) onFailed();
      }

      _isBackgroundDownloading = false;
      _downloadCompleter?.complete(null);
      if (onProgress != null) {
        removeProgressListener(onProgress);
      }

      return null;
    }
  }

  static void cancelBackgroundDownload() {
    _downloadCancelToken?.cancel();
    _isBackgroundDownloading = false;
    _backgroundDownloadProgress = 0.0;
    _downloadCompleter?.complete(null);
    _downloadCancelToken = null;
    _downloadCompleter = null;
  }

  static Future<void> clearDownloadedFile() async {
    if (_backgroundDownloadFilePath != null) {
      try {
        final file = File(_backgroundDownloadFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete downloaded file: $e');
      }
      _backgroundDownloadFilePath = null;
      _backgroundDownloadVersion = null;
      _backgroundDownloadProgress = 0.0;
    }
  }

  static Future<bool> hasCompletedDownload() async {
    if (_backgroundDownloadFilePath != null) {
      return await File(_backgroundDownloadFilePath!).exists();
    }
    return false;
  }
}

class VersionInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final AndroidArch? androidArch;
  final UpdateType updateType;

  VersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    this.androidArch,
    required this.updateType,
  });
}
