import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/download_service.dart';
import '../models/download_task.dart';
import '../widgets/download_item_widget.dart';
import '../utils/font_utils.dart';
import '../utils/device_utils.dart';
import 'local_player_screen.dart';

class DownloadManagementScreen extends StatefulWidget {
  const DownloadManagementScreen({super.key});

  @override
  State<DownloadManagementScreen> createState() =>
      _DownloadManagementScreenState();
}

class _DownloadManagementScreenState extends State<DownloadManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DownloadService _downloadService = DownloadService();
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _downloadService.loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet = DeviceUtils.isTablet(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
      appBar: _buildAppBar(context, isDarkMode, isTablet),
      body: _buildBody(context, isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDarkMode, bool isTablet) {
    return AppBar(
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
        '下载管理',
        style: FontUtils.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF27AE60),
        unselectedLabelColor:
            isDarkMode ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
        indicatorColor: const Color(0xFF27AE60),
        labelStyle: FontUtils.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: FontUtils.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: '下载中'),
          Tab(text: '已完成'),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    return ChangeNotifierProvider.value(
      value: _downloadService,
      child: Consumer<DownloadService>(
        builder: (context, downloadService, child) {
          final downloadingTasks = _sortTasks(downloadService.downloadingTasks +
              downloadService.queuedTasks +
              downloadService.pausedTasks +
              downloadService.failedTasks +
              downloadService.retryingTasks);
          final completedTasks =
              _deduplicateTasks(_sortTasks(downloadService.completedTasks));

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDownloadingTab(
                  downloadingTasks, isDarkMode, downloadService),
              _buildCompletedTab(completedTasks, isDarkMode, downloadService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadingTab(List<DownloadTask> tasks, bool isDarkMode,
      DownloadService downloadService) {
    if (tasks.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return Column(
      children: [
        _buildBatchActionBar(isDarkMode),
        Expanded(child: _buildGroupedTaskList(tasks, isDarkMode)),
      ],
    );
  }

  Widget _buildBatchActionBar(bool isDarkMode) {
    return Consumer<DownloadService>(
      builder: (context, downloadService, child) {
        final hasDownloading = downloadService.downloadingTasks.isNotEmpty;
        final hasPaused = downloadService.pausedTasks.isNotEmpty;
        final hasFailed = downloadService.failedTasks.isNotEmpty;
        final hasRetrying = downloadService.retryingTasks.isNotEmpty;
        final isPausedMode =
            !hasDownloading && (hasPaused || hasFailed || hasRetrying);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  if (isPausedMode) {
                    _downloadService.resumeAllPaused();
                  } else {
                    _downloadService.pauseAllDownloading();
                  }
                },
                icon: Icon(
                  isPausedMode ? LucideIcons.play : LucideIcons.pause,
                  size: 18,
                ),
                label: Text(isPausedMode ? '全部继续' : '全部暂停'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isPausedMode
                      ? const Color(0xFF27AE60)
                      : (isDarkMode ? Colors.white : const Color(0xFF1f2937)),
                  side: BorderSide(
                    color: isPausedMode
                        ? const Color(0xFF27AE60)
                        : (isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(List<DownloadTask> tasks, bool isDarkMode,
      DownloadService downloadService) {
    if (tasks.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return Column(
      children: [
        _buildCompletedBatchActionBar(isDarkMode),
        Expanded(
            child: _buildGroupedTaskList(tasks, isDarkMode,
                enableDeleteMode: true)),
      ],
    );
  }

  Widget _buildCompletedBatchActionBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isDeleteMode) ...[
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isDeleteMode = false;
                });
              },
              child: Text(
                '取消',
                style: FontUtils.poppins(
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: () {
              if (_isDeleteMode) {
                _showDeleteAllCompletedConfirmation(context);
              } else {
                setState(() {
                  _isDeleteMode = true;
                });
              }
            },
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text(_isDeleteMode ? '删除全部' : '批量删除'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFef4444),
              side: const BorderSide(color: Color(0xFFef4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllCompletedConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1e1e1e)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '批量删除',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1f2937),
          ),
        ),
        content: Text(
          '确定要删除所有已完成的下载任务吗？',
          style: FontUtils.poppins(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9ca3af)
                : const Color(0xFF6b7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: FontUtils.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadService.deleteAllCompleted();
            },
            child: Text(
              '删除',
              style: FontUtils.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFef4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DownloadTask> _sortTasks(List<DownloadTask> tasks) {
    tasks.sort((a, b) {
      final aCompleted = a.completedAt;
      final bCompleted = b.completedAt;

      if (aCompleted != null && bCompleted != null) {
        return bCompleted.compareTo(aCompleted);
      }

      if (aCompleted != null) {
        return -1;
      }

      if (bCompleted != null) {
        return 1;
      }

      final titleCompare = a.title.compareTo(b.title);
      if (titleCompare != 0) return titleCompare;
      return a.episodeIndex.compareTo(b.episodeIndex);
    });
    return tasks;
  }

  List<DownloadTask> _deduplicateTasks(List<DownloadTask> tasks) {
    final seen = <String>{};
    final uniqueTasks = <DownloadTask>[];

    for (final task in tasks) {
      final key = '${task.title}|${task.episodeIndex}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueTasks.add(task);
      }
    }

    return uniqueTasks;
  }

  Widget _buildGroupedTaskList(List<DownloadTask> tasks, bool isDarkMode,
      {bool enableDeleteMode = false}) {
    final groupedTasks = <String, List<DownloadTask>>{};
    for (final task in tasks) {
      groupedTasks.putIfAbsent(task.title, () => []).add(task);
    }

    final titles = groupedTasks.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: titles.length,
      itemBuilder: (context, index) {
        final title = titles[index];
        final episodes = groupedTasks[title]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1f2937),
                      ),
                    ),
                  ),
                  if (enableDeleteMode && _isDeleteMode)
                    GestureDetector(
                      onTap: () => _showDeleteGroupConfirmation(
                          context, title, episodes),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444).withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.trash2,
                          color: Color(0xFFef4444),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...episodes.map((task) => DownloadItemWidget(
                  task: task,
                  isDarkMode: isDarkMode,
                  onPause: () => _downloadService.pauseTask(task.id),
                  onResume: () => _downloadService.resumeTask(task.id),
                  onDelete: () => _showDeleteConfirmation(context, task),
                  onPlay: () => _playDownloadedVideo(task),
                  showDeleteButton: enableDeleteMode && _isDeleteMode,
                )),
          ],
        );
      },
    );
  }

  void _showDeleteGroupConfirmation(
      BuildContext context, String title, List<DownloadTask> episodes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1e1e1e)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '删除分组',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1f2937),
          ),
        ),
        content: Text(
          '确定要删除"$title"的${episodes.length}个任务吗？',
          style: FontUtils.poppins(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9ca3af)
                : const Color(0xFF6b7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: FontUtils.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (final task in episodes) {
                _downloadService.deleteTask(task.id);
              }
            },
            child: Text(
              '删除',
              style: FontUtils.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFef4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.download,
            size: 64,
            color:
                isDarkMode ? const Color(0xFF666666) : const Color(0xFFd1d5db),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无下载内容',
            style: FontUtils.poppins(
              fontSize: 16,
              color: isDarkMode
                  ? const Color(0xFF9ca3af)
                  : const Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1e1e1e)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '删除下载',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1f2937),
          ),
        ),
        content: Text(
          '确定要删除 "${task.displayName}" 吗？',
          style: FontUtils.poppins(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9ca3af)
                : const Color(0xFF6b7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: FontUtils.poppins(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadService.deleteTask(task.id);
            },
            child: Text(
              '删除',
              style: FontUtils.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFef4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playDownloadedVideo(DownloadTask task) {
    final filePath = task.localFilePath;
    final file = File(filePath);

    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '文件不存在: ${task.displayName}',
            style: FontUtils.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalPlayerScreen(
          filePath: filePath,
          title: task.displayName,
        ),
      ),
    );
  }
}
