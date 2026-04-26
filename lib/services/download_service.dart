import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_task.dart';
import '../utils/storage_utils.dart';

class DownloadService extends ChangeNotifier {
  static const String _downloadTasksKey = 'download_tasks';
  static const String _maxConcurrentKey = 'max_concurrent_downloads';
  static const String _concurrentThreadsKey = 'concurrent_threads';
  static const String _savePathKey = 'download_save_path';
  static final DownloadService _instance = DownloadService._internal();

  factory DownloadService() => _instance;

  DownloadService._internal();

  final List<DownloadTask> _tasks = [];
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

    // 如果保存路径为空，设置默认下载路径
    if (_savePath.isEmpty) {
      final defaultDir = await StorageUtils.getDefaultDownloadDirectory();
      if (defaultDir != null) {
        _savePath = defaultDir.path;
        await prefs.setString(_savePathKey, _savePath);
      }
    }

    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = json.decode(tasksJson);
        _tasks.clear();
        _tasks.addAll(decoded.map((e) => DownloadTask.fromJson(e)));
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load download tasks: $e');
      }
    }
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
    notifyListeners();
  }

  Future<void> pauseTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _tasks[taskIndex].status = DownloadStatus.paused;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> resumeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _tasks[taskIndex].status = DownloadStatus.queued;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> retryTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _tasks[taskIndex].status = DownloadStatus.queued;
    _tasks[taskIndex].progress = 0.0;
    _tasks[taskIndex].downloadedBytes = 0;
    await _saveTasks();
    notifyListeners();
  }

  Future<void> pauseAllDownloading() async {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.paused;
      }
    }
    await _saveTasks();
    notifyListeners();
  }

  Future<void> resumeAllPaused() async {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.failed) {
        task.status = DownloadStatus.queued;
        if (task.status == DownloadStatus.failed) {
          task.progress = 0.0;
          task.downloadedBytes = 0;
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
    }

    notifyListeners();
  }
}
