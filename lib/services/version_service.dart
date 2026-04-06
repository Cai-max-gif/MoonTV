import 'dart:convert';
import 'dart:io';
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

class VersionService {
  static const String githubRepoUrl = 'https://github.com/Cai-max-gif/MoonTV';
  static const String githubApiUrl =
      'https://api.github.com/repos/Cai-max-gif/MoonTV/releases/latest';
  static const String _lastCheckKey = 'last_version_check';
  static const String _dismissedVersionKey = 'dismissed_version';

  static const List<String> testUrls = [
    'https://www.google.com',
    'https://www.baidu.com',
    'https://github.com',
  ];

  static Future<bool> checkNetworkConnection() async {
    for (final url in testUrls) {
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
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

  static Future<String?> downloadFile(
    String url,
    String fileName, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      final savePath = '${dir.path}/$fileName';
      final dio = Dio();

      await dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      return null;
    }
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

  static Future<VersionInfo?> checkForUpdate() async {
    try {
      final hasNetwork = await checkNetworkConnection();
      if (!hasNetwork) return null;

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

    while (currentParts.length < 3) currentParts.add(0);
    while (latestParts.length < 3) latestParts.add(0);

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
    final dayInMs = 24 * 60 * 60 * 1000;

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
