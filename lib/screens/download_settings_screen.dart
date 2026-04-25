import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/download_service.dart';
import '../utils/font_utils.dart';

class HollowRoundSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const HollowRoundSliderThumbShape({this.thumbRadius = 10});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, thumbRadius, paint);
  }
}

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
                '保存路径已更新',
                style: FontUtils.poppins(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '选择路径失败: $e',
              style: FontUtils.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
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
          isDarkMode ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '下载设置',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
        ),
      ),
      body: ChangeNotifierProvider.value(
        value: _downloadService,
        child: Consumer<DownloadService>(
          builder: (context, downloadService, child) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
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
                            size: 24,
                            color: Color(0xFF10b981),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '同时下载任务数',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1f2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '1',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: isDarkMode
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF6b7280),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 20.0,
                                thumbShape: const HollowRoundSliderThumbShape(
                                    thumbRadius: 10),
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbColor: const Color(0xFF10b981),
                                activeTrackColor: const Color(0xFF10b981),
                                inactiveTrackColor: isDarkMode
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFe5e7eb),
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
                              fontSize: 14,
                              color: isDarkMode
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
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
                            size: 24,
                            color: Color(0xFF8b5cf6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '并发线程数',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1f2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '1',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: isDarkMode
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF6b7280),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 20.0,
                                thumbShape: const HollowRoundSliderThumbShape(
                                    thumbRadius: 10),
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbColor: const Color(0xFF8b5cf6),
                                activeTrackColor: const Color(0xFF8b5cf6),
                                inactiveTrackColor: isDarkMode
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFe5e7eb),
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
                              fontSize: 14,
                              color: isDarkMode
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
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
                            size: 24,
                            color: Color(0xFF3b82f6),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '保存路径',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1f2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF2c2c2c)
                                : const Color(0xFFf5f5f5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFe5e7eb),
                            ),
                          ),
                          child: Text(
                            _savePath.isEmpty ? '未设置保存路径' : _savePath,
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: isDarkMode
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF6b7280),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectPath,
                          icon: const Icon(
                            LucideIcons.folderOpen,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: Text(
                            '选择路径',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82f6),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf59e0b).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFf59e0b).withAlpha(76),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 20,
                        color: Color(0xFFf59e0b),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '提示：增加同时下载任务数和并发线程数可以加快下载速度，但也会消耗更多系统资源。请根据您的设备性能进行调整。',
                          style: FontUtils.poppins(
                            fontSize: 14,
                            color: isDarkMode
                                ? const Color(0xFFf59e0b)
                                : const Color(0xFF92400e),
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
