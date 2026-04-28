import 'package:flutter/material.dart';
import '../utils/device_utils.dart';

class PlayerDownloadPanel extends StatefulWidget {
  final ThemeData theme;
  final List<String> episodes;
  final List<String> episodesTitles;
  final int currentEpisodeIndex;
  final bool isReversed;
  final Function(int) onSingleEpisodeTap;
  final Function(List<int>) onBatchDownload;
  final VoidCallback onToggleOrder;

  const PlayerDownloadPanel({
    super.key,
    required this.theme,
    required this.episodes,
    required this.episodesTitles,
    required this.currentEpisodeIndex,
    required this.isReversed,
    required this.onSingleEpisodeTap,
    required this.onBatchDownload,
    required this.onToggleOrder,
  });

  @override
  State<PlayerDownloadPanel> createState() => _PlayerDownloadPanelState();
}

class _PlayerDownloadPanelState extends State<PlayerDownloadPanel> {
  final GlobalKey _gridKey = GlobalKey();
  late final ScrollController _scrollController;
  List<bool> _selectedEpisodes = [];
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedEpisodes = List<bool>.filled(widget.episodes.length, false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrent();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (_gridKey.currentContext == null) return;

    final gridBox = _gridKey.currentContext!.findRenderObject() as RenderBox;

    final targetIndex = widget.isReversed
        ? widget.episodes.length - 1 - widget.currentEpisodeIndex
        : widget.currentEpisodeIndex;

    const crossAxisCount = 3;
    const mainAxisSpacing = 12.0;
    const childAspectRatio = 2.0;

    final itemWidth =
        (gridBox.size.width - (crossAxisCount - 1) * 12) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;

    final row = (targetIndex / crossAxisCount).floor();
    final offset = row * (itemHeight + mainAxisSpacing);

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 1),
      curve: Curves.linear,
    );
  }

  void _toggleEpisodeSelection(int index) {
    setState(() {
      _selectedEpisodes[index] = !_selectedEpisodes[index];
      _updateSelectAllStatus();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (int i = 0; i < _selectedEpisodes.length; i++) {
        _selectedEpisodes[i] = _selectAll;
      }
    });
  }

  void _updateSelectAllStatus() {
    _selectAll = _selectedEpisodes.every((selected) => selected);
  }

  void _downloadSelected() async {
    List<int> selectedIndices = [];
    for (int i = 0; i < _selectedEpisodes.length; i++) {
      if (_selectedEpisodes[i]) {
        final episodeIndex =
            widget.isReversed ? widget.episodes.length - 1 - i : i;
        selectedIndices.add(episodeIndex + 1); // 转换为从1开始的索引
      }
    }
    if (selectedIndices.isNotEmpty) {
      await widget.onBatchDownload(selectedIndices);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1c1c1e) : Colors.white,
      ),
      child: Column(
        children: [
          // 标题、关闭按钮和批量操作
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '下载 (${widget.episodes.length})',
                  style: widget.theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleSelectAll,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (_) => _toggleSelectAll(),
                            activeColor: Colors.green,
                          ),
                          Text(
                            '全选',
                            style: widget.theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 集数网格
          Expanded(
            child: GridView.builder(
              key: _gridKey,
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.0,
              ),
              itemCount: widget.episodes.length,
              itemBuilder: (context, index) {
                final episodeIndex = widget.isReversed
                    ? widget.episodes.length - 1 - index
                    : index;
                final isCurrentEpisode =
                    episodeIndex == widget.currentEpisodeIndex;

                String episodeTitle = '';
                if (widget.episodesTitles.isNotEmpty &&
                    episodeIndex < widget.episodesTitles.length) {
                  episodeTitle = widget.episodesTitles[episodeIndex];
                } else {
                  episodeTitle = '第${episodeIndex + 1}集';
                }

                return _DownloadEpisodeItem(
                  isCurrentEpisode: isCurrentEpisode,
                  isDarkMode: isDarkMode,
                  episodeTitle: episodeTitle,
                  isSelected: _selectedEpisodes[index],
                  onTap: () => _toggleEpisodeSelection(index),
                  onDoubleTap: () {
                    widget.onSingleEpisodeTap(episodeIndex);
                  },
                );
              },
            ),
          ),

          // 底部下载按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _downloadSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '下载 (${_selectedEpisodes.where((selected) => selected).length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadEpisodeItem extends StatefulWidget {
  final bool isCurrentEpisode;
  final bool isDarkMode;
  final String episodeTitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _DownloadEpisodeItem({
    required this.isCurrentEpisode,
    required this.isDarkMode,
    required this.episodeTitle,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  State<_DownloadEpisodeItem> createState() => _DownloadEpisodeItemState();
}

class _DownloadEpisodeItemState extends State<_DownloadEpisodeItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (DeviceUtils.isPC()) {
          setState(() => _isHovering = true);
        }
      },
      onExit: (_) {
        if (DeviceUtils.isPC()) {
          setState(() => _isHovering = false);
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.green.withValues(alpha: 0.2)
                : (widget.isCurrentEpisode
                    ? Colors.blue.withValues(alpha: 0.2)
                    : (_isHovering && DeviceUtils.isPC()
                        ? (widget.isDarkMode
                            ? const Color(0xFF1A3D2E)
                            : const Color(0xFFE8F5E9))
                        : (widget.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200]))),
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: Colors.green, width: 2)
                : (widget.isCurrentEpisode
                    ? Border.all(color: Colors.blue, width: 2)
                    : null),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    widget.episodeTitle,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isSelected
                          ? Colors.green
                          : (widget.isCurrentEpisode
                              ? Colors.blue
                              : (widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black)),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Checkbox(
                    value: widget.isSelected,
                    onChanged: (_) => widget.onTap(),
                    activeColor: Colors.green,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
