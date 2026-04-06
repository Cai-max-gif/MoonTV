import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:io';
import '../services/version_service.dart';
import '../services/theme_service.dart';
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
  double _downloadProgress = 0.0;
  String? _errorMessage;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      if (Platform.isAndroid) {
        final hasInstallPermission = await VersionService.requestInstallPermission();
        if (!hasInstallPermission) {
          if (mounted) {
            setState(() {
              _errorMessage = '需要安装权限才能安装应用';
              _isDownloading = false;
            });
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
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (filePath == null) {
        if (mounted) {
          setState(() {
            _errorMessage = '下载失败';
            _isDownloading = false;
          });
        }
        return;
      }

      if (Platform.isAndroid) {
        setState(() {
          _isInstalling = true;
        });

        final success = await VersionService.installApk(filePath);
        if (!success && mounted) {
          setState(() {
            _errorMessage = '安装失败';
            _isInstalling = false;
            _isDownloading = false;
          });
        }
      } else if (Platform.isWindows) {
        setState(() {
          _isInstalling = true;
        });

        final success = await VersionService.openFile(filePath);
        if (!success && mounted) {
          setState(() {
            _errorMessage = '打开安装文件失败';
            _isInstalling = false;
            _isDownloading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '发生错误: $e';
          _isDownloading = false;
          _isInstalling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return PopScope(
          canPop: widget.versionInfo.updateType != UpdateType.force,
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
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isInstalling ? '正在安装...' : '正在下载...',
                                    style: FontUtils.poppins(
                                      fontSize: 14,
                                      color: themeService.isDarkMode
                                          ? const Color(0xFFCCCCCC)
                                          : const Color(0xFF666666),
                                    ),
                                  ),
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
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
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
                            ],
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: FontUtils.poppins(
                                fontSize: 14,
                                color: const Color(0xFFE74C3C),
                              ),
                            ),
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
                              onPressed: _startDownload,
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(
                                '立即更新',
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
                              if (!_isDownloading && !_isInstalling)
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
