import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import 'package:provider/provider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../services/version_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../utils/font_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class UpdateDialog extends StatefulWidget {
  final VersionInfo versionInfo;

  const UpdateDialog({super.key, required this.versionInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();

  static Future<void> show(
    BuildContext context,
    VersionInfo versionInfo,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: versionInfo.updateType != UpdateType.force,
      builder: (context) => UpdateDialog(versionInfo: versionInfo),
    );
  }
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  bool _isInstalling = false;
  bool _isCancelled = false;
  bool _hasDownloadedFile = false;
  double _downloadProgress = 0.0;
  CancelToken? _cancelToken;
  String? _downloadedFilePath;

  final NotificationService _notificationService = NotificationService.instance;
  int _lastNotificationProgress = 0;

  @override
  void initState() {
    super.initState();
    _checkDownloadState();
    VersionService.addProgressListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    VersionService.removeProgressListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate(double progress) {
    if (mounted && VersionService.isForegroundDownloading) {
      setState(() {
        _downloadProgress = progress;
      });
    }
  }

  Future<void> _checkDownloadState() async {
    final hasDownload = await VersionService.hasCompletedDownload();
    if (mounted && hasDownload) {
      setState(() {
        _hasDownloadedFile = true;
        _downloadedFilePath = VersionService.downloadedFilePath;
      });
    }

    if (mounted && VersionService.isForegroundDownloading) {
      final version = VersionService.foregroundDownloadVersion;
      if (version == widget.versionInfo.latestVersion) {
        setState(() {
          _isDownloading = true;
          _downloadProgress = VersionService.foregroundDownloadProgress;
        });
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _isCancelled = false;
      _downloadProgress = 0.0;
      _lastNotificationProgress = 0;
      _cancelToken = CancelToken();
    });
    VersionService.setForegroundDownloading(true, widget.versionInfo.latestVersion);

    try {
      if (Platform.isAndroid) {
        final hasInstallPermission = await VersionService.requestInstallPermission();
        if (!hasInstallPermission) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
            });
            VersionService.clearForegroundDownload();
            _showErrorSnackBar(AppStrings.updateNeedPermission);
          }
          return;
        }
      }

      final arch = widget.versionInfo.androidArch ?? AndroidArch.universal;
      final downloadUrl = VersionService.getDownloadUrl(widget.versionInfo.latestVersion, arch);
      final fileName = await VersionService.getFileName(widget.versionInfo.latestVersion, arch);

      final filePath = await VersionService.downloadFile(
        downloadUrl,
        fileName,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            VersionService.updateForegroundProgress(progress);
            if (mounted) {
              setState(() {
                _downloadProgress = progress;
              });
            }

            final progressPercent = (progress * 100).round();
            if (progressPercent - _lastNotificationProgress >= 1 || progressPercent == 100) {
              _lastNotificationProgress = progressPercent;
              _notificationService.showUpdateProgress(
                progress: progressPercent,
                maxProgress: 100,
                version: widget.versionInfo.latestVersion,
              );
            }
          }
        },
      );

      if (_isCancelled) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
        return;
      }

      if (filePath == null) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          VersionService.clearForegroundDownload();
          _notificationService.showUpdateFailed(
            version: widget.versionInfo.latestVersion,
          );
          _showErrorSnackBar(AppStrings.downloadFailed);
        }
        return;
      }

      _notificationService.showUpdateCompleted(
        version: widget.versionInfo.latestVersion,
      );

      VersionService.clearForegroundDownload();
      VersionService.setDownloadedFilePath(filePath);
      setState(() {
        _downloadedFilePath = filePath;
      });

      if (Platform.isAndroid) {
        setState(() {
          _isInstalling = true;
        });

        final success = await VersionService.installApk(filePath);
        if (!success && mounted) {
          setState(() {
            _isInstalling = false;
            _isDownloading = false;
          });
          _showErrorSnackBar(AppStrings.updateInstallFailed);
        }
      } else if (Platform.isWindows) {
        setState(() {
          _isInstalling = true;
        });

        final success = await VersionService.openFile(filePath);
        if (!success && mounted) {
          setState(() {
            _isInstalling = false;
            _isDownloading = false;
          });
          _showErrorSnackBar(AppStrings.updateOpenFailed);
        }
      }
    } catch (e) {
      if (_isCancelled) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
        VersionService.clearForegroundDownload();
        return;
      }
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isInstalling = false;
        });
        VersionService.clearForegroundDownload();
        _notificationService.showUpdateFailed(
          version: widget.versionInfo.latestVersion,
        );
        _showErrorSnackBar(AppStrings.updateError);
      }
    }
  }

  void _cancelDownload() {
    setState(() {
      _isCancelled = true;
      _isDownloading = false;
    });
    _cancelToken?.cancel();
    VersionService.cancelForegroundDownload();
    VersionService.clearForegroundDownload();
    _showErrorSnackBar(AppStrings.updateCancelled);
  }

  Future<void> _startInstall() async {
    if (_downloadedFilePath == null) return;

    setState(() {
      _isInstalling = true;
    });

    if (Platform.isAndroid) {
      final success = await VersionService.installApk(_downloadedFilePath!);
      if (!success && mounted) {
        setState(() {
          _isInstalling = false;
          _isDownloading = false;
        });
        _showErrorSnackBar(AppStrings.updateInstallFailed);
      }
    } else if (Platform.isWindows) {
      final success = await VersionService.openFile(_downloadedFilePath!);
      if (!success && mounted) {
        setState(() {
          _isInstalling = false;
          _isDownloading = false;
        });
        _showErrorSnackBar(AppStrings.updateOpenFailed);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
          margin: const EdgeInsets.all(AppDimens.spacingLg),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onDialogClosed() {
    if (_isDownloading && !_isCancelled && !_isInstalling) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return PopScope(
          canPop: widget.versionInfo.updateType != UpdateType.force,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              _onDialogClosed();
            }
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
            ),
            elevation: AppDimens.elevationNone,
            backgroundColor: AppColors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? AppColors.inputBgDark
                    : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusXxxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black30,
                    blurRadius: AppDimens.shadowBlurMd,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode
                          ? AppColors.darkDivider
                          : AppColors.grayBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimens.spacingMd),
                          decoration: BoxDecoration(
                            color: widget.versionInfo.updateType == UpdateType.force
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.versionInfo.updateType == UpdateType.force
                                ? Icons.warning_amber_rounded
                                : Icons.rocket_launch_rounded,
                            size: 40,
                            color: widget.versionInfo.updateType == UpdateType.force
                                ? AppColors.error
                                : AppColors.accent,
                          ),
                        ),
                        Gap.h12,
                        Text(
                          widget.versionInfo.updateType == UpdateType.force
                              ? AppStrings.updateImportant
                              : AppStrings.updateNewVersion,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: themeService.isDarkMode
                                ? AppColors.white
                                : AppColors.inputBgDark,
                          ),
                        ),
                        if (widget.versionInfo.updateType == UpdateType.force) ...[
                          Gap.h8,
                          Text(
                            AppStrings.updateForceMsg,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimens.spacingLg),
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode
                                ? AppColors.darkDivider
                                : AppColors.grayBg,
                            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildVersionChip(
                                context,
                                themeService,
                                AppStrings.updateCurrentVersion,
                                widget.versionInfo.currentVersion,
                                Icons.info_outline_rounded,
                                themeService.isDarkMode
                                    ? AppColors.textHint
                                    : AppColors.textDarkHint,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: themeService.isDarkMode
                                    ? AppColors.grayDark
                                    : AppColors.gray275,
                              ),
                              _buildVersionChip(
                                context,
                                themeService,
                                AppStrings.updateLatestVersion,
                                widget.versionInfo.latestVersion,
                                Icons.new_releases_rounded,
                                widget.versionInfo.updateType == UpdateType.force
                                    ? AppColors.error
                                    : AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                        if (widget.versionInfo.releaseNotes.isNotEmpty) ...[
                          Gap.h16,
                          Row(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: AppDimens.iconMd,
                                color: widget.versionInfo.updateType == UpdateType.force
                                    ? AppColors.error
                                    : AppColors.accent,
                              ),
                              Gap.w6,
                              Text(
                                AppStrings.updateContent,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeXl,
                                  fontWeight: FontWeight.w600,
                                  color: themeService.isDarkMode
                                      ? AppColors.white
                                      : AppColors.inputBgDark,
                                ),
                              ),
                            ],
                          ),
                          Gap.h10,
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: themeService.isDarkMode
                                  ? AppColors.darkDivider
                                  : AppColors.grayBg,
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(AppDimens.spacingMd),
                                child: GptMarkdown(
                                  widget.versionInfo.releaseNotes,
                                  style: FontUtils.poppins(
                                    fontSize: AppDimens.fontSizeMd,
                                    height: 1.6,
                                    color: themeService.isDarkMode
                                        ? AppColors.gray325
                                        : AppColors.textDarkHint,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_isDownloading) ...[
                          Gap.h16,
                          Row(
                            children: [
                              Expanded(
                                flex: 75,
                                child: LinearProgressIndicator(
                                  value: _downloadProgress,
                                  backgroundColor: themeService.isDarkMode
                                      ? AppColors.grayDark
                                      : AppColors.gray275,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.versionInfo.updateType == UpdateType.force
                                        ? AppColors.error
                                        : AppColors.accent,
                                  ),
                                ),
                              ),
                              Gap.w8,
                              if (!_isInstalling) ...[
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                  style: FontUtils.poppins(
                                    fontSize: AppDimens.fontSizeMd,
                                    fontWeight: FontWeight.w600,
                                    color: widget.versionInfo.updateType == UpdateType.force
                                        ? AppColors.error
                                        : AppColors.accent,
                                  ),
                                ),
                                Gap.w4,
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    size: AppDimens.iconMd,
                                    color: AppColors.error,
                                  ),
                                  onPressed: _cancelDownload,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                  style: FontUtils.poppins(
                                    fontSize: AppDimens.fontSizeMd,
                                    fontWeight: FontWeight.w600,
                                    color: widget.versionInfo.updateType == UpdateType.force
                                        ? AppColors.error
                                        : AppColors.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        if (!_isDownloading && !_isInstalling)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _hasDownloadedFile ? _startInstall : _startDownload,
                              icon: Icon(_hasDownloadedFile ? Icons.install_desktop_rounded : Icons.download_rounded, size: AppDimens.iconMd),
                              label: Text(
                                _hasDownloadedFile ? AppStrings.updateInstallNow : AppStrings.updateNow,
                                style: FontUtils.poppins(
                                  fontSize: AppDimens.fontSizeLg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.versionInfo.updateType == UpdateType.force
                                    ? AppColors.error
                                    : AppColors.accent,
                                foregroundColor: AppColors.white,
                                elevation: AppDimens.elevationNone,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                ),
                              ),
                            ),
                          ),
                        if (!_isDownloading && !_isInstalling)
                          Gap.h8,
                        if (widget.versionInfo.updateType != UpdateType.force)
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    await VersionService.dismissVersion(
                                      widget.versionInfo.latestVersion,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: themeService.isDarkMode
                                        ? AppColors.textHint
                                        : AppColors.textDarkHint,
                                  ),
                                  child: Text(
                                    AppStrings.updateIgnore,
                                    style: FontUtils.poppins(fontSize: AppDimens.fontSizeMd),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  onPressed: _isDownloading
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: widget.versionInfo.updateType == UpdateType.force
                                        ? AppColors.error
                                        : AppColors.accent,
                                  ),
                                  child: Text(
                                    _isDownloading ? AppStrings.updatePleaseWait : AppStrings.updateLater,
                                    style: FontUtils.poppins(fontSize: AppDimens.fontSizeMd),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionChip(
    BuildContext context,
    ThemeService themeService,
    String label,
    String version,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: AppDimens.iconMd, color: color),
        Gap.h4,
        Text(
          label,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXs,
            color: themeService.isDarkMode
                ? AppColors.textHint
                : AppColors.textDarkHint,
          ),
        ),
        Gap.h2,
        Text(
          version,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeLg,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
