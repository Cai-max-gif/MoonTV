enum DownloadStatus {
  downloading,
  queued,
  paused,
  completed,
  failed,
}

class DownloadTask {
  final String id;
  final String title;
  final String episodeTitle;
  final int episodeIndex;
  final String cover;
  final String videoUrl;
  final String savePath;
  double progress;
  DownloadStatus status;
  int totalBytes;
  int downloadedBytes;
  DateTime createdAt;

  DownloadTask({
    required this.id,
    required this.title,
    required this.episodeTitle,
    required this.episodeIndex,
    required this.cover,
    required this.videoUrl,
    required this.savePath,
    this.progress = 0.0,
    this.status = DownloadStatus.downloading,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => '$title $episodeTitle';

  int get progressPercent => (progress * 100).round();

  bool get isPaused => status == DownloadStatus.paused;
  bool get isQueued => status == DownloadStatus.queued;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;

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
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'],
      title: json['title'],
      episodeTitle: json['episode_title'],
      episodeIndex: json['episode_index'],
      cover: json['cover'],
      videoUrl: json['video_url'],
      savePath: json['save_path'],
      progress: (json['progress'] as num).toDouble(),
      status: DownloadStatus.values[json['status']],
      totalBytes: json['total_bytes'] ?? 0,
      downloadedBytes: json['downloaded_bytes'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
