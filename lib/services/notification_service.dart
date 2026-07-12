import 'dart:io';
import '../constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../screens/download_management_screen.dart';
import '../services/download_service.dart';
import '../services/version_service.dart';
import '../models/download_task.dart';
import '../widgets/update_dialog.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionRequested = false;

  static const int downloadNotificationIdBase = AppConfig.notificationIdBase;
  static const int updateNotificationId = AppConfig.notificationIdMax;

  Future<void> initialize() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      const androidSettings = AndroidInitializationSettings(AppConfig.notificationIcon);
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } else if (Platform.isIOS) {
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(iOS: iosSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } else if (Platform.isMacOS) {
      const macosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(macOS: macosSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } else if (Platform.isWindows || Platform.isLinux) {
      // 本地通知不支持此平台
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == AppConfig.notificationPayloadUpdate) {
      _handleUpdateNotificationTap();
    } else if (response.payload != null && response.payload!.startsWith(AppConfig.notificationPayloadDownloadPrefix)) {
      _handleDownloadNotificationTap(response.payload!);
    }
  }

  Future<void> _handleDownloadNotificationTap(String payload) async {
    final taskIdStr = payload.replaceFirst(AppConfig.notificationPayloadDownloadPrefix, '');
    final taskIdHash = int.tryParse(taskIdStr);
    
    if (taskIdHash == null) {
      return;
    }

    final downloadService = DownloadService.instance;
    
    DownloadTab targetTab = DownloadTab.downloading;
    
    for (final task in downloadService.tasks) {
      if (task.id.hashCode == taskIdHash) {
        if (task.status == DownloadStatus.completed) {
          targetTab = DownloadTab.completed;
        }
        break;
      }
    }

    _navigateToDownloadManagement(targetTab);
  }

  void _navigateToDownloadManagement(DownloadTab tab) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DownloadManagementScreen(initialTab: tab),
        ),
      );
    }
  }

  void _showUpdateDialog(VersionInfo versionInfo) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      UpdateDialog.show(context, versionInfo);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          UpdateDialog.show(ctx, versionInfo);
        }
      });
    }
  }

  Future<void> _handleUpdateNotificationTap() async {
    try {
      await _notifications.cancel(updateNotificationId);
      
      var versionInfo = VersionService.storedVersionInfo;
      
      if (versionInfo == null) {
        versionInfo = await VersionService.checkForUpdate();
        
        if (versionInfo != null) {
          VersionService.setStoredVersionInfo(versionInfo);
        }
      }
      
      if (versionInfo != null) {
        _showUpdateDialog(versionInfo);
      } else {
        final downloadStatus = VersionService.downloadStatus;
        if (downloadStatus == UpdateDownloadStatus.completed) {
          final filePath = VersionService.downloadedFilePath;
          if (filePath != null) {
            await _openUpdateFile(filePath);
          } else {
            _showWaitingSnackBar(AppStrings.notifUpdateFileNotExist);
          }
        } else if (downloadStatus == UpdateDownloadStatus.downloading) {
          _showWaitingSnackBar(AppStrings.notifWaitDownload);
        } else {
          _showWaitingSnackBar(AppStrings.notifVersionUnavailable);
        }
      }
    } catch (_) {
      _showWaitingSnackBar(AppStrings.notifUpdateError);
    }
  }

  void _showWaitingSnackBar([String? message]) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? AppStrings.notifWaitDownload),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(AppDimens.radiusMd)),
          margin: const EdgeInsets.all(AppDimens.spacingLg),
          duration: AppDurations.toastDuration,
        ),
      );
    }
  }

  Future<void> _openUpdateFile(String filePath) async {
    if (Platform.isAndroid) {
      await OpenFilex.open(filePath);
    } else if (Platform.isWindows) {
      await OpenFilex.open(filePath);
    } else if (Platform.isMacOS) {
      await OpenFilex.open(filePath);
    }
  }

  Future<void> requestPermissions() async {
    if (_permissionRequested) return;
    _permissionRequested = true;

    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isMacOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      // Android 13+ 需要请求 POST_NOTIFICATIONS 权限
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _ensurePermissions() async {
    if ((Platform.isIOS || Platform.isMacOS || Platform.isAndroid) && !_permissionRequested) {
      await requestPermissions();
    }
  }

  Future<void> showDownloadProgress({
    required int taskId,
    required String title,
    required String episodeTitle,
    required int progress,
    required int maxProgress,
  }) async {
    if (!_initialized || Platform.isWindows || Platform.isLinux) return;
    _ensurePermissions();

    final notificationId = downloadNotificationIdBase + (taskId.hashCode % AppConfig.notificationIdModulo);

    final androidDetails = AndroidNotificationDetails(
      AppConfig.downloadChannelId,
      AppStrings.notifDownloadChannel,
      channelDescription: AppStrings.notifDownloadChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      icon: AppConfig.notificationIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final progressPercent = maxProgress > 0 ? ((progress / maxProgress) * 100).round() : 0;
    final contentTitle = '$title $episodeTitle';
    final contentText = '${AppStrings.downloadDownloading} $progressPercent%';

    await _notifications.show(
      notificationId,
      contentTitle,
      contentText,
      details,
      payload: '${AppConfig.notificationPayloadDownloadPrefix}$taskId',
    );
  }

  Future<void> showDownloadCompleted({
    required int taskId,
    required String title,
    required String episodeTitle,
  }) async {
    if (!_initialized || Platform.isWindows || Platform.isLinux) return;
    _ensurePermissions();

    final notificationId = downloadNotificationIdBase + (taskId.hashCode % AppConfig.notificationIdModulo);

    const androidDetails = AndroidNotificationDetails(
      AppConfig.downloadChannelId,
      AppStrings.notifDownloadChannel,
      channelDescription: AppStrings.notifDownloadChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
      ongoing: false,
      icon: AppConfig.notificationIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final contentTitle = '$title $episodeTitle';
    final contentText = AppStrings.notifDownloadComplete;

    await _notifications.show(
      notificationId,
      contentTitle,
      contentText,
      details,
      payload: '${AppConfig.notificationPayloadDownloadPrefix}$taskId',
    );
  }

  Future<void> showDownloadFailed({
    required int taskId,
    required String title,
    required String episodeTitle,
  }) async {
    if (!_initialized || Platform.isWindows || Platform.isLinux) return;
    _ensurePermissions();

    final notificationId = downloadNotificationIdBase + (taskId.hashCode % AppConfig.notificationIdModulo);

    const androidDetails = AndroidNotificationDetails(
      AppConfig.downloadChannelId,
      AppStrings.notifDownloadChannel,
      channelDescription: AppStrings.notifDownloadChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
      ongoing: false,
      icon: AppConfig.notificationIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final contentTitle = '$title $episodeTitle';
    const contentText = AppStrings.downloadFailed;

    await _notifications.show(
      notificationId,
      contentTitle,
      contentText,
      details,
      payload: '${AppConfig.notificationPayloadDownloadPrefix}$taskId',
    );
  }

  Future<void> cancelDownloadNotification(int taskId) async {
    final notificationId = downloadNotificationIdBase + (taskId.hashCode % AppConfig.notificationIdModulo);
    await _notifications.cancel(notificationId);
  }

  Future<void> showUpdateProgress({
    required int progress,
    required int maxProgress,
    required String version,
  }) async {
    if (!_initialized || Platform.isWindows || Platform.isLinux) return;
    _ensurePermissions();

    final androidDetails = AndroidNotificationDetails(
      AppConfig.updateChannelId,
      AppStrings.notifUpdateChannel,
      channelDescription: AppStrings.notifUpdateChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      ongoing: true,
      icon: AppConfig.notificationIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final progressPercent = maxProgress > 0 ? ((progress / maxProgress) * 100).round() : 0;
    final contentTitle = '${AppStrings.notifUpdating} v$version';
    final contentText = '${AppStrings.downloadDownloading} $progressPercent%';

    await _notifications.show(
      updateNotificationId,
      contentTitle,
      contentText,
      details,
      payload: AppConfig.notificationPayloadUpdate,
    );
  }

  Future<void> showUpdateCompleted({required String version}) async {
    if (!_initialized || Platform.isWindows || Platform.isLinux) return;
    _ensurePermissions();

    const androidDetails = AndroidNotificationDetails(
      AppConfig.updateChannelId,
      AppStrings.notifUpdateChannel,
      channelDescription: AppStrings.notifUpdateChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
      ongoing: false,
      icon: AppConfig.notificationIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final contentTitle = 'v$version ${AppStrings.notifDownloadComplete}';
    final contentText = AppStrings.notifClickToInstall;

    await _notifications.show(
      updateNotificationId,
      contentTitle,
      contentText,
      details,
      payload: AppConfig.notificationPayloadUpdate,
    );
  }

  Future<void> showUpdateFailed({required String version}) async {
    if (!_initialized || Platform.isWindows || Platform.isLinux) return;
    _ensurePermissions();

    const androidDetails = AndroidNotificationDetails(
      AppConfig.updateChannelId,
      AppStrings.notifUpdateChannel,
      channelDescription: AppStrings.notifUpdateChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showProgress: false,
      ongoing: false,
      icon: AppConfig.notificationIcon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final contentTitle = 'v$version ${AppStrings.notifDownloadFailed}';
    final contentText = AppStrings.retry;

    await _notifications.show(
      updateNotificationId,
      contentTitle,
      contentText,
      details,
      payload: AppConfig.notificationPayloadUpdate,
    );
  }

  Future<void> cancelUpdateNotification() async {
    await _notifications.cancel(updateNotificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
