import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_task.dart';

class DownloadService extends ChangeNotifier {
  static const String _downloadTasksKey = 'download_tasks';
  static const String _maxConcurrentKey = 'max_concurrent_downloads';
  static const String _concurrentThreadsKey = 'concurrent_threads';
  static const String _savePathKey = 'download_save_path';
  static final DownloadService _instance = DownloadService._internal();

  factory DownloadService() => _instance;

  DownloadService._internal();

  final List<DownloadTask> _tasks = [];
  final Map<String, Timer> _simulatedProgressTimers = {};
  int _maxConcurrentDownloads = 1;
  int _concurrentThreads = 4;
  String _savePath = '';

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  List<DownloadTask> get downloadingTasks =>
      _tasks.where((t) => t.status == DownloadStatus.downloading).toList();

  List<DownloadTask> get queuedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.queued).toList();

  List<DownloadTask> get pausedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.paused).toList();

  List<DownloadTask> get completedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.completed).toList();

  List<DownloadTask> get failedTasks =>
      _tasks.where((t) => t.status == DownloadStatus.failed).toList();

  int get maxConcurrentDownloads => _maxConcurrentDownloads;
  int get concurrentThreads => _concurrentThreads;
  String get savePath => _savePath;

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_downloadTasksKey);
    _maxConcurrentDownloads = prefs.getInt(_maxConcurrentKey) ?? 1;
    _concurrentThreads = prefs.getInt(_concurrentThreadsKey) ?? 4;
    _savePath = prefs.getString(_savePathKey) ?? '';

    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = json.decode(tasksJson);
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => DownloadTask.fromJson(e)));
        _restoreQueueState();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load download tasks: $e');
      }
    }
  }

  void _restoreQueueState() {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.downloading) {
        _startDownload(task.id);
      }
    }
    _processQueue();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_downloadTasksKey, tasksJson);
    await prefs.setInt(_maxConcurrentKey, _maxConcurrentDownloads);
    await prefs.setInt(_concurrentThreadsKey, _concurrentThreads);
    await prefs.setString(_savePathKey, _savePath);
  }

  Future<void> setMaxConcurrentDownloads(int max) async {
    if (max < 1) max = 1;
    if (max > 3) max = 3;
    _maxConcurrentDownloads = max;
    await _saveTasks();
    _processQueue();
    notifyListeners();
  }

  Future<void> setConcurrentThreads(int threads) async {
    if (threads < 1) threads = 1;
    if (threads > 16) threads = 16;
    _concurrentThreads = threads;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> setSavePath(String path) async {
    _savePath = path;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> addTask(DownloadTask task) async {
    final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex >= 0) {
      return;
    }

    _tasks.insert(0, task);
    await _saveTasks();
    _processQueue();
    notifyListeners();
  }

  void _processQueue() {
    final currentlyDownloading = downloadingTasks.length;
    final slotsAvailable = _maxConcurrentDownloads - currentlyDownloading;

    if (slotsAvailable <= 0) return;

    final queuedList =
        _tasks.where((t) => t.status == DownloadStatus.queued).toList();

    for (int i = 0; i < slotsAvailable && i < queuedList.length; i++) {
      final task = queuedList[i];
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex >= 0) {
        _tasks[taskIndex].status = DownloadStatus.downloading;
        _startDownload(task.id);
      }
    }
  }

  void _startDownload(String taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    final task = _tasks[taskIndex];

    _simulatedProgressTimers[taskId]?.cancel();

    _simulatedProgressTimers[taskId] = Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        final currentTask = _tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => task,
        );

        if (currentTask.status != DownloadStatus.downloading) {
          timer.cancel();
          return;
        }

        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex < 0) {
          timer.cancel();
          return;
        }

        if (currentTask.progress < 1.0) {
          _tasks[taskIndex].progress += 0.02;
          _tasks[taskIndex].downloadedBytes =
              (_tasks[taskIndex].totalBytes * _tasks[taskIndex].progress)
                  .round();

          if (_tasks[taskIndex].progress >= 1.0) {
            _tasks[taskIndex].progress = 1.0;
            _tasks[taskIndex].status = DownloadStatus.completed;
            _tasks[taskIndex].downloadedBytes = _tasks[taskIndex].totalBytes;
            timer.cancel();
            _simulatedProgressTimers.remove(taskId);
            _saveTasks();
            _processQueue();
          }

          notifyListeners();
        }
      },
    );
  }

  Future<void> pauseTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _simulatedProgressTimers[taskId]?.cancel();
    _simulatedProgressTimers.remove(taskId);

    _tasks[taskIndex].status = DownloadStatus.paused;
    await _saveTasks();
    _processQueue();
    notifyListeners();
  }

  Future<void> resumeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    final currentDownloading = downloadingTasks.length;
    if (currentDownloading < _maxConcurrentDownloads) {
      _tasks[taskIndex].status = DownloadStatus.downloading;
      await _saveTasks();
      _startDownload(taskId);
    } else {
      _tasks[taskIndex].status = DownloadStatus.queued;
      await _saveTasks();
    }
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _simulatedProgressTimers[taskId]?.cancel();
    _simulatedProgressTimers.remove(taskId);

    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    _processQueue();
    notifyListeners();
  }

  Future<void> retryTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    final currentDownloading = downloadingTasks.length;
    if (currentDownloading < _maxConcurrentDownloads) {
      _tasks[taskIndex].status = DownloadStatus.downloading;
      _tasks[taskIndex].progress = 0.0;
      _tasks[taskIndex].downloadedBytes = 0;
      await _saveTasks();
      _startDownload(taskId);
    } else {
      _tasks[taskIndex].status = DownloadStatus.queued;
      _tasks[taskIndex].progress = 0.0;
      _tasks[taskIndex].downloadedBytes = 0;
      await _saveTasks();
    }
    _processQueue();
    notifyListeners();
  }

  Future<void> pauseAllDownloading() async {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.downloading) {
        _simulatedProgressTimers[task.id]?.cancel();
        _simulatedProgressTimers.remove(task.id);
        task.status = DownloadStatus.paused;
      }
    }
    await _saveTasks();
    notifyListeners();
  }

  Future<void> resumeAllPaused() async {
    final currentDownloadingCount = downloadingTasks.length;
    int slotsRemaining = _maxConcurrentDownloads - currentDownloadingCount;

    final tasksToProcess = _tasks
        .where((t) =>
            t.status == DownloadStatus.paused ||
            t.status == DownloadStatus.failed)
        .toList();

    for (final task in tasksToProcess) {
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex < 0) continue;

      final wasFailed = task.status == DownloadStatus.failed;

      if (slotsRemaining > 0) {
        _tasks[taskIndex].status = DownloadStatus.downloading;
        if (wasFailed) {
          _tasks[taskIndex].progress = 0.0;
          _tasks[taskIndex].downloadedBytes = 0;
        }
        _startDownload(task.id);
        slotsRemaining--;
      } else {
        _tasks[taskIndex].status = DownloadStatus.queued;
        if (wasFailed) {
          _tasks[taskIndex].progress = 0.0;
          _tasks[taskIndex].downloadedBytes = 0;
        }
      }
    }

    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteAllCompleted() async {
    _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
    await _saveTasks();
    notifyListeners();
  }

  void updateTaskProgress(String taskId, double progress) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _tasks[taskIndex].progress = progress.clamp(0.0, 1.0);
    _tasks[taskIndex].downloadedBytes =
        (_tasks[taskIndex].totalBytes * progress).round();

    if (progress >= 1.0) {
      _tasks[taskIndex].status = DownloadStatus.completed;
      _tasks[taskIndex].downloadedBytes = _tasks[taskIndex].totalBytes;
      _processQueue();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _simulatedProgressTimers.values) {
      timer.cancel();
    }
    _simulatedProgressTimers.clear();
    super.dispose();
  }
}
