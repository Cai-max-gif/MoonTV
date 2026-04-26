import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class StorageUtils {
  /// 获取Android平台的Download目录
  static Future<Directory?> getAndroidDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        // 尝试获取外部存储的Download目录
        // 在Android 10+上，使用getExternalStorageDirectories
        final directories = await getExternalStorageDirectories(
            type: StorageDirectory.downloads);
        if (directories != null && directories.isNotEmpty) {
          final downloadDir = directories.first;
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
        // 如果获取外部存储失败，尝试使用应用文档目录
        final documentsDir = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${documentsDir.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      } catch (e) {
        debugPrint('Error getting Download directory: $e');
        //  fallback to应用文档目录
        final documentsDir = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${documentsDir.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
    }
    return null;
  }

  /// 获取Android平台的MoonTV下载目录
  static Future<Directory?> getAndroidMoonTVDownloadDirectory() async {
    final downloadDir = await getAndroidDownloadDirectory();
    if (downloadDir != null) {
      final moonTVDir = Directory('${downloadDir.path}/MoonTV');
      if (!await moonTVDir.exists()) {
        await moonTVDir.create(recursive: true);
      }
      return moonTVDir;
    }
    return null;
  }

  /// 获取默认下载目录
  static Future<Directory?> getDefaultDownloadDirectory() async {
    if (Platform.isAndroid) {
      return await getAndroidMoonTVDownloadDirectory();
    } else if (Platform.isIOS) {
      // iOS平台使用应用文档目录
      final documentsDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${documentsDir.path}/Downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      // 创建MoonTV子文件夹
      final moonTVDir = Directory('${downloadDir.path}/MoonTV');
      if (!await moonTVDir.exists()) {
        await moonTVDir.create(recursive: true);
      }
      return moonTVDir;
    } else if (Platform.isWindows) {
      // Windows平台使用用户下载目录
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final downloadsDir = Directory('$userProfile/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        // 创建MoonTV子文件夹
        final moonTVDir = Directory('${downloadsDir.path}/MoonTV');
        if (!await moonTVDir.exists()) {
          await moonTVDir.create(recursive: true);
        }
        return moonTVDir;
      }
    } else if (Platform.isMacOS) {
      // macOS平台使用用户下载目录
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final downloadsDir = Directory('$homeDir/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        // 创建MoonTV子文件夹
        final moonTVDir = Directory('${downloadsDir.path}/MoonTV');
        if (!await moonTVDir.exists()) {
          await moonTVDir.create(recursive: true);
        }
        return moonTVDir;
      }
    }

    //  fallback to应用文档目录
    final documentsDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${documentsDir.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    // 创建MoonTV子文件夹
    final moonTVDir = Directory('${downloadDir.path}/MoonTV');
    if (!await moonTVDir.exists()) {
      await moonTVDir.create(recursive: true);
    }
    return moonTVDir;
  }
}
