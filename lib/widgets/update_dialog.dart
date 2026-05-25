import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../services/version_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../utils/font_utils.dart';

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
            _showErrorSnackBar('需要安装权限才能安装应用');
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
          _showErrorSnackBar('下载失败');
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
          _showErrorSnackBar('安装失败');
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
          _showErrorSnackBar('打开安装文件失败');
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
        _showErrorSnackBar('发生错误');
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
    _showErrorSnackBar('下载已取消');
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
        _showErrorSnackBar('安装失败');
      }
    } else if (Platform.isWindows) {
      final success = await VersionService.openFile(_downloadedFilePath!);
      if (!success && mounted) {
        setState(() {
          _isInstalling = false;
          _isDownloading = false;
        });
        _showErrorSnackBar('打开安装文件失败');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
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
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? const Color(0xFF2C2C2C)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
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
                          ? const Color(0xFF333333)
                          : const Color(0xFFF5F5F5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.versionInfo.updateType == UpdateType.force
                                ? const Color(0xFFE74C3C).withValues(alpha: 0.1)
                                : const Color(0xFF27AE60).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.versionInfo.updateType == UpdateType.force
                                ? Icons.warning_amber_rounded
                                : Icons.rocket_launch_rounded,
                            size: 40,
                            color: widget.versionInfo.updateType == UpdateType.force
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFF27AE60),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.versionInfo.updateType == UpdateType.force
                              ? '重要更新'
                              : '发现新版本',
                          style: FontUtils.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeService.isDarkMode
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF2C2C2C),
                          ),
                        ),
                        if (widget.versionInfo.updateType == UpdateType.force) ...[
                          const SizedBox(height: 8),
                          Text(
                            '此更新为强制更新，请立即更新以继续使用',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: const Color(0xFFE74C3C),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode
                                ? const Color(0xFF333333)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildVersionChip(
                                context,
                                themeService,
                                '当前版本',
                                widget.versionInfo.currentVersion,
                                Icons.info_outline_rounded,
                                themeService.isDarkMode
                                    ? const Color(0xFF999999)
                                    : const Color(0xFF666666),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: themeService.isDarkMode
                                    ? const Color(0xFF444444)
                                    : const Color(0xFFDDDDDD),
                              ),
                              _buildVersionChip(
                                context,
                                themeService,
                                '最新版本',
                                widget.versionInfo.latestVersion,
                                Icons.new_releases_rounded,
                                widget.versionInfo.updateType == UpdateType.force
                                    ? const Color(0xFFE74C3C)
                                    : const Color(0xFF27AE60),
                              ),
                            ],
                          ),
                        ),
                        if (widget.versionInfo.releaseNotes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 18,
                                color: widget.versionInfo.updateType == UpdateType.force
                                    ? const Color(0xFFE74C3C)
                                    : const Color(0xFF27AE60),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '更新内容',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: themeService.isDarkMode
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF2C2C2C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: themeService.isDarkMode
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: GptMarkdown(
                                  widget.versionInfo.releaseNotes,
                                  style: FontUtils.poppins(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: themeService.isDarkMode
                                        ? const Color(0xFFCCCCCC)
                                        : const Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_isDownloading) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 75,
                                child: LinearProgressIndicator(
                                  value: _downloadProgress,
                                  backgroundColor: themeService.isDarkMode
                                      ? const Color(0xFF444444)
                                      : const Color(0xFFDDDDDD),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.versionInfo.updateType == UpdateType.force
                                        ? const Color(0xFFE74C3C)
                                        : const Color(0xFF27AE60),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!_isInstalling) ...[
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                  style: FontUtils.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: widget.versionInfo.updateType == UpdateType.force
                                        ? const Color(0xFFE74C3C)
                                        : const Color(0xFF27AE60),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    size: 18,
                                    color: Color(0xFFE74C3C),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: widget.versionInfo.updateType == UpdateType.force
                                        ? const Color(0xFFE74C3C)
                                        : const Color(0xFF27AE60),
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
                              icon: Icon(_hasDownloadedFile ? Icons.install_desktop_rounded : Icons.download_rounded, size: 18),
                              label: Text(
                                _hasDownloadedFile ? '立即安装' : '立即更新',
                                style: FontUtils.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.versionInfo.updateType == UpdateType.force
                                    ? const Color(0xFFE74C3C)
                                    : const Color(0xFF27AE60),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        if (!_isDownloading && !_isInstalling)
                          const SizedBox(height: 8),
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
                                        ? const Color(0xFF999999)
                                        : const Color(0xFF666666),
                                  ),
                                  child: Text(
                                    '忽略',
                                    style: FontUtils.poppins(fontSize: 14),
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
                                        ? const Color(0xFFE74C3C)
                                        : const Color(0xFF27AE60),
                                  ),
                                  child: Text(
                                    _isDownloading ? '请稍候' : '稍后',
                                    style: FontUtils.poppins(fontSize: 14),
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
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: FontUtils.poppins(
            fontSize: 12,
            color: themeService.isDarkMode
                ? const Color(0xFF999999)
                : const Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          version,
          style: FontUtils.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
