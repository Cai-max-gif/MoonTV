import 'dart:io' show Platform;
import '../constants/app_config.dart';

enum DownloadStatus {
  downloading,
  queued,
  paused,
  completed,
  failed,
  retrying,
}

class DownloadTask {
  final String id;
  final String title;
  final String episodeTitle;
  final int episodeIndex;
  final String cover;
  final String videoUrl;
  String savePath;
  double progress;
  DownloadStatus status;
  int totalBytes;
  int downloadedBytes;
  int retryCount;
  DateTime createdAt;
  DateTime? completedAt;

  final String localFileName;

  DownloadTask({
    required this.id,
    required this.title,
    required this.episodeTitle,
    required this.episodeIndex,
    required this.cover,
    required this.videoUrl,
    required this.savePath,
    this.progress = 0.0,
    this.status = DownloadStatus.queued,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.retryCount = 0,
    DateTime? createdAt,
    this.completedAt,
    String? localFileName,
  })  : localFileName = localFileName ??
            _generateLocalFileName(title, episodeTitle, episodeIndex),
        createdAt = createdAt ?? DateTime.now();

  static DownloadStatus _parseDownloadStatus(int index) {
    final values = DownloadStatus.values;
    return index >= 0 && index < values.length ? values[index] : DownloadStatus.failed;
  }

  static String _generateLocalFileName(
      String title, String episodeTitle, int episodeIndex) {
    final safeTitle = title.replaceAll(RegExp(AppConfig.invalidFilenameChars), '_').trim();
    final safeEpisode =
        episodeTitle.replaceAll(RegExp(AppConfig.invalidFilenameChars), '_').trim();
    return '${safeTitle}_${safeEpisode}_$episodeIndex${AppConfig.fileExtensionTs}';
  }

  String get localFilePath {
    if (savePath.isEmpty) return localFileName;
    final sep = Platform.pathSeparator;
    final dir = savePath.endsWith(sep) ? savePath : '$savePath$sep';
    return '$dir$localFileName';
  }

  String get displayName => '$title $episodeTitle';

  int get progressPercent => (progress * 100).round();

  bool get isPaused => status == DownloadStatus.paused;
  bool get isQueued => status == DownloadStatus.queued;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isRetrying => status == DownloadStatus.retrying;

  Map<String, dynamic> toJson() {
    return {
      AppConfig.jsonId: id,
      AppConfig.jsonTitle: title,
      AppConfig.jsonEpisodeTitle: episodeTitle,
      AppConfig.jsonEpisodeIndex: episodeIndex,
      AppConfig.jsonCover: cover,
      AppConfig.jsonVideoUrl: videoUrl,
      AppConfig.jsonSavePath: savePath,
      AppConfig.jsonProgress: progress,
      AppConfig.jsonStatus: status.index,
      AppConfig.jsonTotalBytes: totalBytes,
      AppConfig.jsonDownloadedBytes: downloadedBytes,
      AppConfig.jsonCreatedAt: createdAt.millisecondsSinceEpoch,
      AppConfig.jsonCompletedAt: completedAt?.millisecondsSinceEpoch,
      AppConfig.jsonLocalFileName: localFileName,
      AppConfig.jsonRetryCount: retryCount,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json[AppConfig.jsonId]?.toString() ?? '',
      title: json[AppConfig.jsonTitle]?.toString() ?? '',
      episodeTitle: json[AppConfig.jsonEpisodeTitle]?.toString() ?? '',
      episodeIndex: json[AppConfig.jsonEpisodeIndex] as int? ?? 0,
      cover: json[AppConfig.jsonCover]?.toString() ?? '',
      videoUrl: json[AppConfig.jsonVideoUrl]?.toString() ?? '',
      savePath: json[AppConfig.jsonSavePath]?.toString() ?? '',
      progress: (json[AppConfig.jsonProgress] as num?)?.toDouble() ?? 0.0,
      status: _parseDownloadStatus(json[AppConfig.jsonStatus] as int? ?? 0),
      totalBytes: json[AppConfig.jsonTotalBytes] as int? ?? 0,
      downloadedBytes: json[AppConfig.jsonDownloadedBytes] as int? ?? 0,
      createdAt: json[AppConfig.jsonCreatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(json[AppConfig.jsonCreatedAt] as int)
          : DateTime.now(),
      completedAt: json[AppConfig.jsonCompletedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(json[AppConfig.jsonCompletedAt] as int)
          : null,
      localFileName: json[AppConfig.jsonLocalFileName]?.toString(),
      retryCount: json[AppConfig.jsonRetryCount] as int? ?? 0,
    );
  }

  DownloadTask copyWith({
    String? id,
    String? title,
    String? episodeTitle,
    int? episodeIndex,
    String? cover,
    String? videoUrl,
    String? savePath,
    double? progress,
    DownloadStatus? status,
    int? totalBytes,
    int? downloadedBytes,
    int? retryCount,
    DateTime? createdAt,
    DateTime? completedAt,
    String? localFileName,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      title: title ?? this.title,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      cover: cover ?? this.cover,
      videoUrl: videoUrl ?? this.videoUrl,
      savePath: savePath ?? this.savePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      localFileName: localFileName ?? this.localFileName,
    );
  }
}
