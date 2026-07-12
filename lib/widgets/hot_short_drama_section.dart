import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';
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
    _currentInstance?.refresh();
  }

  /// 获取当前已加载的短剧数据
  static List<Map<String, dynamic>>? getCurrentShortDramas() {
    return _currentInstance?._shortDramas;
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

  Future<void> refresh() async {
    await _loadHotShortDramas(forceRefresh: true);
  }

  /// 加载热门短剧
  Future<void> _loadHotShortDramas({bool forceRefresh = false}) async {
    try {
      setState(() {
        if (_shortDramas.isEmpty) {
          _isLoading = true;
        }
        _hasError = false;
      });

      // 使用推荐接口，服务端会自动选择有数据的分类
      final result = await ApiService.getRecommendedShortDramas(
        context,
        size: AppConfig.defaultRecommendSize,
      );

      if (result.success && result.data != null) {
        final list = result.data!;
        if (mounted) {
          setState(() {
            if (forceRefresh || _shortDramas.isEmpty) {
              _shortDramas.clear();
              _shortDramas.addAll(list.cast<Map<String, dynamic>>());
            }
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
          _hasError = _shortDramas.isEmpty;
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
      id: shortDrama[AppConfig.jsonId].toString(),
      title: shortDrama[AppConfig.jsonName] ?? '',
      year: shortDrama[AppConfig.jsonUpdateTime]?.toString().substring(0, 4) ?? '',
      cover: shortDrama[AppConfig.jsonCover] ?? '',
      source: AppConfig.sourceShortDrama,
      sourceName: AppStrings.shortDramaName,
      index: 1,
      totalEpisodes:
          int.tryParse(shortDrama[AppConfig.jsonEpisodeCount]?.toString() ?? '0') ?? 0,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: shortDrama[AppConfig.jsonName] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecommendationSection(
      title: AppStrings.homeHotShortDrama,
      moreText: AppStrings.homeViewMore,
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
      cardCount: 2.75,
      from: AppConfig.sourceShortDrama, // 传递from参数为AppConfig.sourceShortDrama，确保显示集数而不是链接图标
    );
  }
}
