import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_task.dart';
import '../utils/storage_utils.dart';
import 'download_engine.dart';

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

  final Map<String, DownloadEngine> _activeEngines = {};
  bool _queueProcessing = false;
  bool _restarting = false;

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

  List<DownloadTask> get retryingTasks =>
      _tasks.where((t) => t.status == DownloadStatus.retrying).toList();

  int get maxConcurrentDownloads => _maxConcurrentDownloads;
  int get concurrentThreads => _concurrentThreads;
  String get savePath => _savePath;

  Future<void> _ensureSavePath() async {
    if (_savePath.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _savePath = prefs.getString(_savePathKey) ?? '';
    if (_savePath.isEmpty) {
      final defaultDir = await StorageUtils.getDefaultDownloadDirectory();
      if (defaultDir != null) {
        _savePath = defaultDir.path;
        await prefs.setString(_savePathKey, _savePath);
      }
    }
    _maxConcurrentDownloads = prefs.getInt(_maxConcurrentKey) ?? 1;
    _concurrentThreads = prefs.getInt(_concurrentThreadsKey) ?? 4;
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_downloadTasksKey);
    _maxConcurrentDownloads = prefs.getInt(_maxConcurrentKey) ?? 1;
    _concurrentThreads = prefs.getInt(_concurrentThreadsKey) ?? 4;
    _savePath = prefs.getString(_savePathKey) ?? '';

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

        for (final task in _tasks) {
          if (task.status == DownloadStatus.downloading) {
            task.status = DownloadStatus.paused;
          }
          if (task.status == DownloadStatus.completed) {
            final originalFilePath = task.localFilePath;
            if (!await File(originalFilePath).exists()) {
              if (_savePath.isNotEmpty && task.savePath != _savePath) {
                final alternativePath =
                    _savePath + (Platform.pathSeparator) + task.localFileName;
                if (await File(alternativePath).exists()) {
                  task.savePath = _savePath;
                } else if (task.savePath.isEmpty && _savePath.isNotEmpty) {
                  task.savePath = _savePath;
                } else {
                  task.status = DownloadStatus.failed;
                  continue;
                }
              } else if (task.savePath.isEmpty && _savePath.isNotEmpty) {
                task.savePath = _savePath;
              } else {
                task.status = DownloadStatus.failed;
                continue;
              }
            }
            try {
              final tempDir = Directory('${task.localFilePath}_temp');
              if (await tempDir.exists()) {
                await tempDir.delete(recursive: true);
              }
            } catch (_) {}
          }
        }

        _normalizeRetryingTasks();

        await _scanLocalDownloads();

        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load download tasks: $e');
      }
    }

    _processQueue();
  }

  void _normalizeRetryingTasks() {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.retrying) {
        if (task.retryCount >= 5) {
          task.status = DownloadStatus.failed;
        } else {
          task.status = DownloadStatus.queued;
        }
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

  bool _isVideoUrlAlreadyInTasks(String videoUrl) {
    return _tasks.any((t) =>
        t.videoUrl == videoUrl &&
        (t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.queued ||
            t.status == DownloadStatus.paused ||
            t.status == DownloadStatus.retrying ||
            t.status == DownloadStatus.completed));
  }

  Future<void> addTask(DownloadTask task) async {
    if (_isVideoUrlAlreadyInTasks(task.videoUrl)) {
      return;
    }

    final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex >= 0) {
      return;
    }

    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();
    _processQueue();
  }

  Future<void> addTasks(List<DownloadTask> tasks) async {
    bool hasNew = false;
    for (final task in tasks) {
      if (_isVideoUrlAlreadyInTasks(task.videoUrl)) continue;
      final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (existingIndex >= 0) continue;
      _tasks.insert(0, task);
      hasNew = true;
    }
    if (hasNew) {
      await _saveTasks();
      notifyListeners();
      await _pauseAllAndRestartDownloads();
    }
  }

  Future<void> pauseTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _activeEngines[taskId]?.cancel();
    _activeEngines.remove(taskId);

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

    _swapQueueIfNeeded(taskId);
  }

  void _swapQueueIfNeeded(String targetTaskId) {
    final downloading =
        _tasks.where((t) => t.status == DownloadStatus.downloading).toList();

    if (downloading.length >= _maxConcurrentDownloads) {
      final excess = downloading.length - _maxConcurrentDownloads + 1;
      for (int i = 0; i < excess && i < downloading.length; i++) {
        final taskToPause = downloading[i];
        _activeEngines[taskToPause.id]?.cancel();
        _activeEngines.remove(taskToPause.id);
        taskToPause.status = DownloadStatus.paused;
      }
      notifyListeners();
      _saveTasks();
    }

    _processQueue();
  }

  Future<void> _pauseAllAndRestartDownloads() async {
    if (_restarting) return;
    _restarting = true;

    try {
      for (final engine in _activeEngines.values) {
        engine.cancel();
      }
      _activeEngines.clear();

      for (final task in _tasks) {
        if (task.status == DownloadStatus.downloading) {
          task.status = DownloadStatus.queued;
        }
      }

      notifyListeners();
      await _saveTasks();

      await Future.delayed(const Duration(seconds: 1));

      _queueProcessing = false;
      _processQueue();
    } finally {
      _restarting = false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    final task = _tasks[taskIndex];
    _activeEngines[taskId]?.cancel();
    _activeEngines.remove(taskId);

    await _cleanupTaskFiles(task);

    _tasks.removeAt(taskIndex);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> retryTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex < 0) return;

    _activeEngines[taskId]?.cancel();
    _activeEngines.remove(taskId);

    await _cleanupTaskFiles(_tasks[taskIndex]);

    _tasks[taskIndex].status = DownloadStatus.queued;
    _tasks[taskIndex].progress = 0.0;
    _tasks[taskIndex].downloadedBytes = 0;
    _tasks[taskIndex].totalBytes = 0;
    _tasks[taskIndex].retryCount = 0;
    await _saveTasks();
    notifyListeners();
    _processQueue();
  }

  Future<void> pauseAllDownloading() async {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.downloading) {
        _activeEngines[task.id]?.cancel();
        _activeEngines.remove(task.id);
        task.status = DownloadStatus.paused;
      }
    }
    await _saveTasks();
    notifyListeners();
  }

  Future<void> resumeAllPaused() async {
    for (final task in _tasks) {
      if (task.status == DownloadStatus.paused ||
          task.status == DownloadStatus.failed ||
          task.status == DownloadStatus.retrying) {
        task.status = DownloadStatus.queued;
        task.retryCount = 0;
        task.progress = 0.0;
        task.downloadedBytes = 0;
        task.totalBytes = 0;
      }
    }
    await _saveTasks();
    notifyListeners();
    await _pauseAllAndRestartDownloads();
  }

  Future<void> deleteAllCompleted() async {
    final completed =
        _tasks.where((t) => t.status == DownloadStatus.completed).toList();
    for (final task in completed) {
      await _cleanupTaskFiles(task);
    }
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

    notifyListeners();
  }

  void _processQueue() {
    if (_queueProcessing) return;
    _queueProcessing = true;

    Future.microtask(() async {
      try {
        await _processQueueInternal();
      } finally {
        _queueProcessing = false;
      }
    });
  }

  Future<void> _processQueueInternal() async {
    await _ensureSavePath();

    final currentlyDownloading =
        _tasks.where((t) => t.status == DownloadStatus.downloading).length;
    if (currentlyDownloading >= _maxConcurrentDownloads) return;

    final queued =
        _tasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (queued.isEmpty) return;

    queued.sort((a, b) => a.episodeIndex.compareTo(b.episodeIndex));

    final slotsAvailable = _maxConcurrentDownloads - currentlyDownloading;
    final tasksToStart = queued.take(slotsAvailable);

    for (final task in tasksToStart) {
      if (_activeEngines.containsKey(task.id)) continue;
      if (_savePath.isEmpty) {
        task.status = DownloadStatus.failed;
        await _saveTasks();
        notifyListeners();
        continue;
      }

      task.status = DownloadStatus.downloading;
      task.savePath = _savePath;
      await _saveTasks();
      notifyListeners();

      _startDownload(task);
    }
  }

  void _startDownload(DownloadTask task) {
    if (_activeEngines.containsKey(task.id)) return;

    final engine = DownloadEngine();
    _activeEngines[task.id] = engine;

    engine
        .download(
      m3u8Url: task.videoUrl,
      savePath: task.localFilePath,
      concurrentThreads: _concurrentThreads,
      onProgress: (progress, downloadedBytes, totalBytes) {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx < 0) return;

        _tasks[idx].progress = progress.clamp(0.0, 1.0);
        _tasks[idx].totalBytes = totalBytes;
        _tasks[idx].downloadedBytes = downloadedBytes;

        notifyListeners();
      },
    )
        .then((_) {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx >= 0) {
        _tasks[idx].status = DownloadStatus.completed;
        _tasks[idx].progress = 1.0;
        _tasks[idx].retryCount = 0;
        _tasks[idx].completedAt = DateTime.now();
        notifyListeners();
      }
      _activeEngines.remove(task.id);
      _saveTasks();
      _processQueue();
    }).catchError((e) {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx < 0) return;
      if (_tasks[idx].status == DownloadStatus.paused) return;
      if (_tasks[idx].status == DownloadStatus.queued) return;

      final currentRetry = _tasks[idx].retryCount;
      if (currentRetry < 5) {
        _tasks[idx].status = DownloadStatus.retrying;
        _tasks[idx].retryCount = currentRetry + 1;
        _activeEngines.remove(task.id);
        notifyListeners();
        _saveTasks();

        Future.delayed(const Duration(seconds: 2), () {
          final idx2 = _tasks.indexWhere((t) => t.id == task.id);
          if (idx2 >= 0 && _tasks[idx2].status == DownloadStatus.retrying) {
            _tasks[idx2].status = DownloadStatus.queued;
            notifyListeners();
            _saveTasks();
            _processQueue();
          }
        });
      } else {
        _tasks[idx].status = DownloadStatus.failed;
        _activeEngines.remove(task.id);
        notifyListeners();
        _saveTasks();
        _processQueue();
      }
    });
  }

  Future<void> _cleanupTaskFiles(DownloadTask task) async {
    try {
      final outputFile = File(task.localFilePath);
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
    } catch (_) {}

    try {
      final tempDir = Directory('${task.localFilePath}_temp');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _scanLocalDownloads() async {
    final existingFileNames = _tasks
        .where((t) => t.status == DownloadStatus.completed)
        .map((t) => t.localFileName)
        .toSet();

    bool hasNewTasks = false;

    if (_savePath.isNotEmpty) {
      hasNewTasks =
          await _scanDirectory(_savePath, existingFileNames) || hasNewTasks;
    }

    final defaultDir = await StorageUtils.getDefaultDownloadDirectory();
    if (defaultDir != null && defaultDir.path != _savePath) {
      hasNewTasks = await _scanDirectory(defaultDir.path, existingFileNames) ||
          hasNewTasks;
    }

    if (hasNewTasks) {
      await _saveTasks();
    }
  }

  Future<bool> _scanDirectory(
      String dirPath, Set<String> existingFileNames) async {
    final downloadDir = Directory(dirPath);
    if (!await downloadDir.exists()) {
      return false;
    }

    bool hasNewTasks = false;

    try {
      final files = (await downloadDir.list().toList()).where((entity) {
        return entity is File && entity.path.endsWith('.ts');
      }).cast<File>();

      for (final file in files) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        if (existingFileNames.contains(fileName)) {
          continue;
        }

        final task = _parseFileNameToTask(fileName, dirPath);
        if (task != null) {
          _tasks.add(task);
          existingFileNames.add(fileName);
          hasNewTasks = true;
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $dirPath: $e');
    }

    return hasNewTasks;
  }

  DownloadTask? _parseFileNameToTask(String fileName, String savePath) {
    final match = RegExp(r'^(.+)_第(\d+)集_(\d+)\.ts$').firstMatch(fileName);
    if (match != null) {
      final title = match.group(1) ?? '';
      final episodeNum = match.group(2) ?? '';
      final episodeIndex = int.tryParse(match.group(3) ?? '0') ?? 0;

      if (title.isNotEmpty) {
        return DownloadTask(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}',
          title: title,
          episodeTitle: '第$episodeNum集',
          episodeIndex: episodeIndex,
          cover: '',
          videoUrl: '',
          savePath: savePath,
          progress: 1.0,
          status: DownloadStatus.completed,
          totalBytes: 0,
          downloadedBytes: 0,
          localFileName: fileName,
        );
      }
    }

    final simpleMatch = RegExp(r'^(.+)_(\d+)\.ts$').firstMatch(fileName);
    if (simpleMatch != null) {
      final title = simpleMatch.group(1) ?? '';
      final episodeIndex = int.tryParse(simpleMatch.group(2) ?? '0') ?? 0;

      if (title.isNotEmpty) {
        return DownloadTask(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}_${fileName.hashCode}',
          title: title,
          episodeTitle: '第$episodeIndex集',
          episodeIndex: episodeIndex,
          cover: '',
          videoUrl: '',
          savePath: savePath,
          progress: 1.0,
          status: DownloadStatus.completed,
          totalBytes: 0,
          downloadedBytes: 0,
          localFileName: fileName,
        );
      }
    }

    return null;
  }

  @override
  void dispose() {
    for (final engine in _activeEngines.values) {
      engine.cancel();
      engine.dispose();
    }
    _activeEngines.clear();
    super.dispose();
  }
}
