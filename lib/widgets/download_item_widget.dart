import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/download_task.dart';
import '../utils/font_utils.dart';

class DownloadItemWidget extends StatelessWidget {
  final DownloadTask task;
  final bool isDarkMode;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;
  final VoidCallback onPlay;
  final bool showDeleteButton;

  const DownloadItemWidget({
    super.key,
    required this.task,
    required this.isDarkMode,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
    required this.onPlay,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildCover(),
          const SizedBox(width: 12),
          Expanded(child: _buildInfo()),
          const SizedBox(width: 12),
          _buildProgressOrContinueButton(),
          if (!task.isCompleted || showDeleteButton) ...[
            const SizedBox(width: 4),
            _buildDeleteButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 80,
        color: isDarkMode ? const Color(0xFF2c2c2c) : const Color(0xFFf0f0f0),
        child: task.cover.isNotEmpty
            ? Image.network(
                task.cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
              )
            : _buildPlaceholderCover(),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: isDarkMode ? const Color(0xFF2c2c2c) : const Color(0xFFf0f0f0),
      child: Icon(
        LucideIcons.film,
        color: isDarkMode ? const Color(0xFF666666) : const Color(0xFF999999),
        size: 24,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: FontUtils.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          task.episodeTitle,
          style: FontUtils.poppins(
            fontSize: 12,
            color:
                isDarkMode ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (task.status == DownloadStatus.failed) ...[
          const SizedBox(height: 4),
          Text(
            '下载失败，点击重试',
            style: FontUtils.poppins(
              fontSize: 10,
              color: const Color(0xFFef4444),
            ),
          ),
        ],
        if (task.isRetrying) ...[
          const SizedBox(height: 4),
          Text(
            '重试中 (${task.retryCount}/5)',
            style: FontUtils.poppins(
              fontSize: 10,
              color: const Color(0xFFf59e0b),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressOrContinueButton() {
    const size = 48.0;
    const strokeWidth = 4.0;

    if (task.isCompleted) {
      return _buildActionButton(
        icon: LucideIcons.play,
        color: const Color(0xFF27AE60),
        onTap: onPlay,
        size: size,
      );
    }

    if (task.isDownloading) {
      return GestureDetector(
        onTap: onPause,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: task.progress,
                strokeWidth: strokeWidth,
                backgroundColor: isDarkMode
                    ? const Color(0xFF374151)
                    : const Color(0xFFe5e7eb),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF3b82f6)),
              ),
              Text(
                '${task.progressPercent}',
                style: FontUtils.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3b82f6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (task.isPaused) {
      return GestureDetector(
        onTap: onResume,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFf59e0b).withValues(alpha: 0.098),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFf59e0b),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '继续',
              style: FontUtils.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFf59e0b),
              ),
            ),
          ),
        ),
      );
    }

    if (task.isFailed) {
      return _buildActionButton(
        icon: LucideIcons.refreshCw,
        color: const Color(0xFFef4444),
        onTap: onResume,
        size: size,
      );
    }

    if (task.isRetrying) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFf59e0b).withValues(alpha: 0.098),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFf59e0b),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '重试${task.retryCount}/5',
            style: FontUtils.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFf59e0b),
            ),
          ),
        ),
      );
    }

    if (task.isQueued) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF6b7280).withValues(alpha: 0.098),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6b7280),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '队列',
            style: FontUtils.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6b7280),
            ),
          ),
        ),
      );
    }

    return const SizedBox(width: 48.0, height: 48.0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.098),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFef4444).withValues(alpha: 0.098),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            LucideIcons.trash2,
            color: Color(0xFFef4444),
            size: 18,
          ),
        ),
      ),
    );
  }
}
