import 'dart:io';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/download_service.dart';
import '../models/download_task.dart';
import '../widgets/download_item_widget.dart';
import '../utils/font_utils.dart';
import '../utils/device_utils.dart';
import '../constants/app_strings.dart';
import 'local_player_screen.dart';

enum DownloadTab {
  downloading,
  completed,
}

class DownloadManagementScreen extends StatefulWidget {
  final DownloadTab initialTab;

  const DownloadManagementScreen({super.key, this.initialTab = DownloadTab.downloading});

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
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == DownloadTab.completed ? 1 : 0,
    );
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
          isDarkMode ? AppColors.black : AppColors.grayBg,
      appBar: _buildAppBar(context, isDarkMode, isTablet),
      body: _buildBody(context, isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDarkMode, bool isTablet) {
    return AppBar(
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
        AppStrings.downloadManagement,
        style: FontUtils.poppins(
          fontSize: AppDimens.fontSizeXxl,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.accent,
        unselectedLabelColor:
            isDarkMode ? AppColors.gray400 : AppColors.gray500,
        indicatorColor: AppColors.accent,
        labelStyle: FontUtils.poppins(
          fontSize: AppDimens.fontSizeMd,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: FontUtils.poppins(
          fontSize: AppDimens.fontSizeMd,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: AppStrings.downloadDownloading),
          Tab(text: AppStrings.downloadCompleted),
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
          padding: AppDimens.horizontalMdVerticalSmPadding,
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
                  size: AppDimens.iconMd,
                ),
                label: Text(isPausedMode ? AppStrings.downloadResumeAll : AppStrings.downloadPauseAll),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isPausedMode
                      ? AppColors.accent
                      : (isDarkMode ? AppColors.white : AppColors.textDarkGray),
                  side: BorderSide(
                    color: isPausedMode
                        ? AppColors.accent
                        : (isDarkMode
                            ? AppColors.gray700
                            : AppColors.gray200),
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
      padding: AppDimens.horizontalMdVerticalSmPadding,
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
                AppStrings.cancel,
                style: FontUtils.poppins(
                  color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
                ),
              ),
            ),
            Gap.w8,
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
            icon: const Icon(LucideIcons.trash2, size: AppDimens.iconMd),
            label: Text(_isDeleteMode ? AppStrings.delete : AppStrings.downloadBatchDelete),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
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
            ? AppColors.cardDark
            : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusXl)),
        title: Text(
          AppStrings.downloadBatchDelete,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.textDarkGray,
          ),
        ),
        content: Text(
          AppStrings.downloadConfirmDeleteAll,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.gray400
                : AppColors.gray500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.gray400
                    : AppColors.gray500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadService.deleteAllCompleted();
            },
            child: Text(
              AppStrings.delete,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DownloadTask> _sortTasks(List<DownloadTask> tasks) {
    tasks.sort((a, b) {
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
      padding: AppDimens.verticalMdPadding,
      itemCount: titles.length,
      itemBuilder: (context, index) {
        final title = titles[index];
        final episodes = groupedTasks[title]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
          padding: AppDimens.paddingHorizontal8Vertical12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXl,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? AppColors.white : AppColors.textDarkGray,
                      ),
                    ),
                  ),
                  if (enableDeleteMode && _isDeleteMode)
                    GestureDetector(
                      onTap: () => _showDeleteGroupConfirmation(
                          context, title, episodes),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.spacingXs),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.098),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.trash2,
                          color: AppColors.red,
                          size: AppDimens.iconMd,
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
                  onDelete: () => enableDeleteMode
                      ? _showDeleteGroupConfirmation(context, title, episodes)
                      : _downloadService.deleteTask(task.id),
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
            ? AppColors.cardDark
            : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusXl)),
        title: Text(
          AppStrings.downloadDeleteGroup,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.textDarkGray,
          ),
        ),
        content: Text(
          AppStrings.downloadConfirmDeleteGroup.replaceAll('%s', title).replaceAll('%d', '${episodes.length}'),
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.gray400
                : AppColors.gray500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.gray400
                    : AppColors.gray500,
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
              AppStrings.delete,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
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
            size: AppDimens.iconSize64,
            color:
                isDarkMode ? AppColors.textDarkHint : AppColors.gray300,
          ),
          Gap.h16,
          Text(
            AppStrings.downloadNoContent,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXl,
              color: isDarkMode
                  ? AppColors.gray400
                  : AppColors.gray500,
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
            '${AppStrings.downloadFileNotFound}${task.displayName}',
            style: FontUtils.poppins(color: AppColors.white),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
          margin: const EdgeInsets.all(AppDimens.spacingLg),
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
