import 'dart:io' show Platform;

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
    String? localFileName,
  })  : localFileName = localFileName ??
            _generateLocalFileName(title, episodeTitle, episodeIndex),
        createdAt = createdAt ?? DateTime.now();

  static String _generateLocalFileName(
      String title, String episodeTitle, int episodeIndex) {
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final safeEpisode =
        episodeTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${safeTitle}_${safeEpisode}_$episodeIndex.ts';
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
      'id': id,
      'title': title,
      'episode_title': episodeTitle,
      'episode_index': episodeIndex,
      'cover': cover,
      'video_url': videoUrl,
      'save_path': savePath,
      'progress': progress,
      'status': status.index,
      'total_bytes': totalBytes,
      'downloaded_bytes': downloadedBytes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'local_file_name': localFileName,
      'retry_count': retryCount,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      episodeTitle: json['episode_title']?.toString() ?? '',
      episodeIndex: json['episode_index'] as int? ?? 0,
      cover: json['cover']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      savePath: json['save_path']?.toString() ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      totalBytes: json['total_bytes'] as int? ?? 0,
      downloadedBytes: json['downloaded_bytes'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
      localFileName: json['local_file_name']?.toString(),
      retryCount: json['retry_count'] as int? ?? 0,
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
      localFileName: localFileName ?? this.localFileName,
    );
  }
}
