import 'dart:io';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/download_service.dart';
import '../utils/font_utils.dart';
import '../widgets/hollow_slider_thumb.dart';

class DownloadSettingsScreen extends StatefulWidget {
  const DownloadSettingsScreen({super.key});

  @override
  State<DownloadSettingsScreen> createState() => _DownloadSettingsScreenState();
}

class _DownloadSettingsScreenState extends State<DownloadSettingsScreen> {
  final DownloadService _downloadService = DownloadService();
  double _maxConcurrentDownloads = 1;
  double _concurrentThreads = 4;
  String _savePath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _downloadService.loadTasks();
    if (mounted) {
      setState(() {
        _maxConcurrentDownloads =
            _downloadService.maxConcurrentDownloads.toDouble();
        _concurrentThreads = _downloadService.concurrentThreads.toDouble();
        _savePath = _downloadService.savePath;
      });
    }
  }

  Future<void> _selectPath() async {
    if (_downloadService.downloadingTasks.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '有正在下载的任务，无法修改保存路径',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
            margin: const EdgeInsets.all(AppDimens.spacingLg),
          ),
        );
      }
      return;
    }

    try {
      final result = await FilePicker.getDirectoryPath();

      if (result != null) {
        final newPath = result;

        final dir = Directory(newPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        await _downloadService.setSavePath(newPath);

        if (mounted) {
          setState(() {
            _savePath = newPath;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.downloadPathUpdated,
                style: FontUtils.poppins(color: AppColors.white),
              ),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
              margin: const EdgeInsets.all(AppDimens.spacingLg),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.downloadSelectPathFailed}$e',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
            margin: const EdgeInsets.all(AppDimens.spacingLg),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.black : AppColors.grayBg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.cardDark : AppColors.white,
        elevation: AppDimens.elevationNone,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '下载设置',
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
          ),
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _downloadService,
        child: Consumer<DownloadService>(
          builder: (context, downloadService, child) {
            return ListView(
              padding: const EdgeInsets.all(AppDimens.spacingMd),
              children: [
                Container(
                  padding:
                      AppDimens.listTilePadding,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.cardDark : AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.098),
                        blurRadius: AppDimens.shadowBlurSm,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.download,
                            size: AppDimens.iconLg,
                            color: AppColors.emerald,
                          ),
                          Gap.w12,
                          Text(
                            '同时下载任务数',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXl,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.white
                                  : AppColors.textDarkGray,
                            ),
                          ),
                        ],
                      ),
                      Gap.h12,
                      Row(
                        children: [
                          Text(
                            '1',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 20.0,
                                thumbShape: const HollowRoundSliderThumbShape(
                                    thumbRadius: 10),
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbColor: AppColors.emerald,
                                activeTrackColor: AppColors.emerald,
                                inactiveTrackColor: isDarkMode
                                    ? AppColors.borderDarkGray
                                    : AppColors.borderLightGray,
                              ),
                              child: Slider(
                                value: _maxConcurrentDownloads,
                                min: 1,
                                max: 3,
                                divisions: 2,
                                onChanged: (value) async {
                                  setState(() {
                                    _maxConcurrentDownloads = value;
                                  });
                                  await _downloadService
                                      .setMaxConcurrentDownloads(value.toInt());
                                },
                                label: '${_maxConcurrentDownloads.toInt()}',
                              ),
                            ),
                          ),
                          Text(
                            '3',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.h12,
                Container(
                  padding:
                      AppDimens.listTilePadding,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.cardDark : AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.098),
                        blurRadius: AppDimens.shadowBlurSm,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.zap,
                            size: AppDimens.iconLg,
                            color: AppColors.violet,
                          ),
                          Gap.w12,
                          Text(
                            '并发线程数',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXl,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.white
                                  : AppColors.textDarkGray,
                            ),
                          ),
                        ],
                      ),
                      Gap.h12,
                      Row(
                        children: [
                          Text(
                            '1',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 20.0,
                                thumbShape: const HollowRoundSliderThumbShape(
                                    thumbRadius: 10),
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbColor: AppColors.violet,
                                activeTrackColor: AppColors.violet,
                                inactiveTrackColor: isDarkMode
                                    ? AppColors.borderDarkGray
                                    : AppColors.borderLightGray,
                              ),
                              child: Slider(
                                value: _concurrentThreads,
                                min: 1,
                                max: 16,
                                divisions: 15,
                                onChanged: (value) async {
                                  setState(() {
                                    _concurrentThreads = value;
                                  });
                                  await _downloadService
                                      .setConcurrentThreads(value.toInt());
                                },
                                label: '${_concurrentThreads.toInt()}',
                              ),
                            ),
                          ),
                          Text(
                            '16',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap.h12,
                Container(
                  padding:
                      AppDimens.listTilePadding,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.cardDark : AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.098),
                        blurRadius: AppDimens.shadowBlurSm,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.folder,
                            size: AppDimens.iconLg,
                            color: AppColors.blue,
                          ),
                          Gap.w12,
                          Text(
                            AppStrings.downloadSavePath,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXl,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.white
                                  : AppColors.textDarkGray,
                            ),
                          ),
                        ],
                      ),
                      Gap.h16,
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimens.spacingMd),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.inputBgDark
                                : AppColors.grayBg,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.borderDarkGray
                                  : AppColors.borderLightGray,
                            ),
                          ),
                          child: Text(
                            _savePath.isEmpty ? AppStrings.downloadNoPath : _savePath,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeMd,
                              color: isDarkMode
                                  ? AppColors.gray400
                                  : AppColors.gray500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Gap.h10,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: downloadService.downloadingTasks.isNotEmpty
                              ? null
                              : _selectPath,
                          icon: Icon(
                            LucideIcons.folderOpen,
                            size: 20,
                            color: downloadService.downloadingTasks.isNotEmpty
                                ? AppColors.gray400
                                : AppColors.white,
                          ),
                          label: Text(
                            '选择路径',
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXl,
                              fontWeight: FontWeight.w600,
                              color: downloadService.downloadingTasks.isNotEmpty
                                  ? AppColors.gray400
                                  : AppColors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.h16,
                Container(
                  padding:
                      AppDimens.listTilePadding,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.098),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.298),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 20,
                        color: AppColors.amber,
                      ),
                      Gap.w12,
                      Expanded(
                        child: Text(
                          AppStrings.downloadSettingsTip,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeMd,
                            color: isDarkMode
                                ? AppColors.amber
                                : AppColors.amber800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
