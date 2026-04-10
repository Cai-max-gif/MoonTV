import 'package:flutter/material.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import 'recommendation_section.dart';

/// 热门短剧组件
class HotShortDramaSection extends StatefulWidget {
  final Function(PlayRecord)? onShortDramaTap;
  final Function()? onMoreTap;
  final Function(VideoInfo, VideoMenuAction)? onGlobalMenuAction;

  const HotShortDramaSection({
    super.key,
    this.onShortDramaTap,
    this.onMoreTap,
    this.onGlobalMenuAction,
  });

  @override
  State<HotShortDramaSection> createState() => _HotShortDramaSectionState();

  /// 刷新热门短剧数据
  static Future<void> refreshHotShortDramas() async {
    _currentInstance?._loadHotShortDramas();
  }

  // 静态实例引用，用于触发刷新
  static _HotShortDramaSectionState? _currentInstance;
}

class _HotShortDramaSectionState extends State<HotShortDramaSection> {
  final List<Map<String, dynamic>> _shortDramas = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // 更新静态实例引用
    HotShortDramaSection._currentInstance = this;
    _loadHotShortDramas();
  }

  @override
  void dispose() {
    // 清除当前实例引用
    if (HotShortDramaSection._currentInstance == this) {
      HotShortDramaSection._currentInstance = null;
    }
    super.dispose();
  }

  /// 加载热门短剧（显示短剧页面的前25个）
  Future<void> _loadHotShortDramas() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // 调用短剧列表API，获取前25个数据
      final result = await ApiService.getShortDramaList(
        1, // 默认分类ID
        1, // 第1页
        25, // 每页25个，即前25个
        context,
      );

      if (result.success && result.data != null) {
        final list = result.data!['list'] as List<dynamic>;
        if (mounted) {
          setState(() {
            _shortDramas.clear();
            _shortDramas.addAll(list.cast<Map<String, dynamic>>());
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// 转换为VideoInfo列表
  List<VideoInfo> _convertToVideoInfos() {
    return _shortDramas
        .map((shortDrama) => _convertToVideoInfo(shortDrama))
        .toList();
  }

  /// 转换单个短剧为VideoInfo
  VideoInfo _convertToVideoInfo(Map<String, dynamic> shortDrama) {
    return VideoInfo(
      id: shortDrama['id'].toString(),
      title: shortDrama['name'] ?? '',
      year: shortDrama['update_time']?.toString().substring(0, 4) ?? '',
      cover: shortDrama['cover'] ?? '',
      source: 'shortdrama',
      sourceName: '短剧',
      index: 1,
      totalEpisodes: int.tryParse(shortDrama['episode_count']?.toString() ?? '0') ?? 0,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: shortDrama['name'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecommendationSection(
      title: '热门短剧',
      moreText: '查看更多',
      onMoreTap: widget.onMoreTap,
      videoInfos: _convertToVideoInfos(),
      onItemTap: (videoInfo) {
        final playRecord = PlayRecord(
          id: videoInfo.id,
          source: videoInfo.source,
          title: videoInfo.title,
          sourceName: videoInfo.sourceName,
          year: videoInfo.year,
          cover: videoInfo.cover,
          index: videoInfo.index,
          totalEpisodes: videoInfo.totalEpisodes,
          playTime: videoInfo.playTime,
          totalTime: videoInfo.totalTime,
          saveTime: videoInfo.saveTime,
          searchTitle: videoInfo.searchTitle,
        );
        widget.onShortDramaTap?.call(playRecord);
      },
      onGlobalMenuAction: widget.onGlobalMenuAction,
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _loadHotShortDramas,
    );
  }
}