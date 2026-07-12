import 'dart:async';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/upcoming_releases_section.dart';
import '../widgets/hot_movies_section.dart';
import '../widgets/hot_tv_section.dart';
import '../widgets/hot_show_section.dart';
import '../widgets/hot_short_drama_section.dart';

import '../widgets/bangumi_section.dart';
import '../widgets/main_layout.dart';
import '../widgets/favorites_grid.dart';
import '../widgets/history_grid.dart';
import 'search_screen.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../models/play_record.dart';
import '../models/video_info.dart';
import '../utils/font_utils.dart';
import '../services/page_cache_service.dart';
import '../services/version_service.dart';
import '../widgets/update_dialog.dart';
import 'movie_screen.dart';
import 'tv_screen.dart';
import 'anime_screen.dart';
import 'show_screen.dart';
import 'short_drama_screen.dart';
import 'player_screen.dart';
import 'live_screen.dart';
import 'profile_screen.dart';

// 自定义ScrollPhysics，用于限制PageView的滑动范围
class CustomPageViewPhysics extends ScrollPhysics {
  final int currentIndex;

  const CustomPageViewPhysics({
    required this.currentIndex,
    super.parent,
  });

  @override
  CustomPageViewPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewPhysics(
      currentIndex: currentIndex,
      parent: buildParent(ancestor),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // 第一个页面无法向右滑动
    if (currentIndex == 0 && position.pixels > position.minScrollExtent) {
      return false;
    }
    // 第七个页面无法向左滑动
    if (currentIndex == 6 && position.pixels < position.maxScrollExtent) {
      return false;
    }
    // 确保在顶部导航栏页面范围内，不允许滑动到播放历史和收藏夹页面
    if (currentIndex < 7) {
      // 计算当前页面的滚动范围
      double pageWidth = position.viewportDimension;
      double maxScrollExtent = pageWidth * 6; // 最大滚动到第7个页面（索引6）
      double minScrollExtent = 0; // 最小滚动到第1个页面（索引0）

      // 如果尝试滚动超出顶部导航栏页面范围，禁止滑动
      if (position.pixels < minScrollExtent ||
          position.pixels > maxScrollExtent) {
        return false;
      }
    }
    return super.shouldAcceptUserOffset(position);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  int _currentTopNavIndex = 0;
  int _lastTopNavIndex = 0; // 用于记忆最后点击的顶部导航栏标签
  int _currentPageIndex = 0; // 用于跟踪当前页面索引，控制滑动行为
  String _selectedTopTab = AppStrings.navHome;
  late PageController _pageController;
  late PageController _bottomNavPageController;
  Timer? _versionCheckTimer;

  @override
  void initState() {
    super.initState();
    // 初始化 PageController，默认显示首页（索引0）
    _pageController = PageController(initialPage: 0);
    // 初始化底栏 PageController
    _bottomNavPageController = PageController(initialPage: 0);
    // 进入首页时直接刷新播放记录和收藏夹缓存
    _refreshCacheOnHomeEnter();
    // 检查应用更新
    _checkForUpdates();
    // 启动定时检测
    _startVersionCheckTimer();
  }

  /// 启动定时检测
  void _startVersionCheckTimer() {
    _versionCheckTimer = Timer.periodic(AppDurations.versionCheckInterval, (timer) {
      _checkForUpdates();
    });
  }

  /// 检查应用更新
  void _checkForUpdates() async {
    try {
      final versionInfo = await VersionService.checkForUpdate();

      if (versionInfo != null && mounted) {
        // 显示更新弹窗，与个人中心的检查更新一样
        UpdateDialog.show(context, versionInfo);
      }
    } catch (e) {
      // 静默失败，不影响用户体验
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomNavPageController.dispose();
    _versionCheckTimer?.cancel();
    super.dispose();
  }

  /// 进入首页时刷新缓存
  Future<void> _refreshCacheOnHomeEnter() async {
    try {
      final cacheService = PageCacheService();

      // 异步刷新播放记录缓存
      cacheService.refreshPlayRecords(context).then((_) {
        // 刷新成功后通知继续观看组件和播放历史组件更新UI
        if (mounted) {
          ContinueWatchingSection.refreshPlayRecords();
          HistoryGrid.refreshHistory();
        }
      }).catchError((e) {
        // 静默处理错误
      });

      // 异步刷新收藏夹缓存
      cacheService.refreshFavorites(context).then((_) {
        // 刷新成功后通知收藏夹组件更新UI
        if (mounted) {
          FavoritesGrid.refreshFavorites();
        }
      }).catchError((e) {
        // 静默处理错误
      });

      // 异步刷新搜索历史缓存
      cacheService.refreshSearchHistory(context).catchError((e) {
        // 静默处理错误
      });
    } catch (e) {
      // 静默处理错误，不影响首页正常显示
    }
  }

  /// 刷新首页数据
  Future<void> _refreshHomeData() async {
    try {
      // 调用各个组件的刷新方法
      if (mounted) {
        // 刷新继续观看组件
        await ContinueWatchingSection.refreshPlayRecords();

        // 刷新播放历史组件
        await HistoryGrid.refreshHistory();

        // 刷新收藏夹组件
        await FavoritesGrid.refreshFavorites();

        // 刷新热门电影组件
        await HotMoviesSection.refreshHotMovies();

        // 刷新热门剧集组件
        await HotTvSection.refreshHotTvShows();

        // 刷新新番放送组件
        await BangumiSection.refreshBangumiCalendar();

        // 刷新热门综艺组件
        await HotShowSection.refreshHotShows();

        // 刷新热门短剧组件
        await HotShortDramaSection.refreshHotShortDramas();

        // 刷新即将上映组件
        UpcomingReleasesSection.refreshUpcomingReleases();

        // 强制重建页面
        setState(() {});
      }
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  /// 构建首页内容
  Widget _buildHomeContentWithPageView() {
    return _buildHomeTabContent();
  }

  /// 构建首页标签内容
  Widget _buildHomeTabContent() {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: AppStrings.refreshDot,
      primaryColor: AppColors.accent,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Gap.h8,
            // 继续观看组件
            ContinueWatchingSection(
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: _onGlobalMenuAction,
              onViewAll: () {
                // 切换到播放历史页面
                _onBottomNavChanged(1);
              },
            ),
            // 即将上映组件
            UpcomingReleasesSection(
              onItemTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerScreen(
                    title: videoInfo.title,
                    year: videoInfo.year,
                  ),
                );
              },
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerScreen(
                      title: videoInfo.title,
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 热门电影组件
            HotMoviesSection(
              onMovieTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerScreen(
                    title: videoInfo.title,
                    stype: AppConfig.stypeMovie,
                    year: videoInfo.year,
                  ),
                );
              },
              onMoreTap: () => _onTopCategoryChanged(1),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerScreen(
                      title: videoInfo.title,
                    stype: AppConfig.stypeMovie,
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 热门剧集组件
            HotTvSection(
              onTvTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerScreen(
                    title: videoInfo.title,
                    year: videoInfo.year,
                  ),
                );
              },
              onMoreTap: () => _onTopCategoryChanged(2),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerScreen(
                      title: videoInfo.title,
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 新番放送组件
            BangumiSection(
              onBangumiTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerScreen(
                    title: videoInfo.title,
                    year: videoInfo.year,
                  ),
                );
              },
              onMoreTap: () => _onTopCategoryChanged(3),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerScreen(
                      title: videoInfo.title,
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 热门综艺组件
            HotShowSection(
              onShowTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerScreen(
                    title: videoInfo.title,
                    year: videoInfo.year,
                  ),
                );
              },
              onMoreTap: () => _onTopCategoryChanged(4),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerScreen(
                      title: videoInfo.title,
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 热门短剧组件
            HotShortDramaSection(
              onShortDramaTap: (videoInfo) {
                _navigateToPlayer(
                  PlayerScreen(
                    title: videoInfo.title,
                    year: videoInfo.year,
                  ),
                );
              },
              onMoreTap: () => _onTopCategoryChanged(5),
              onGlobalMenuAction: (videoInfo, action) {
                if (action == VideoMenuAction.play) {
                  _navigateToPlayer(
                    PlayerScreen(
                      title: videoInfo.title,
                      year: videoInfo.year,
                    ),
                  );
                } else {
                  _onGlobalMenuActionFromVideoInfo(videoInfo, action);
                }
              },
            ),
            // 添加40的空白内容，避免导航栏遮挡内容
            Gap.h40,
          ],
        ),
      ),
    );
  }

  /// 构建播放历史标签内容
  Widget _buildHistoryTabContent() {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: AppStrings.refreshDot,
      primaryColor: AppColors.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Gap.h4,
                  HistoryGrid(
                    onVideoTap: _onVideoTap,
                    onGlobalMenuAction: _onGlobalMenuAction,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建收藏夹标签内容
  Widget _buildFavoritesTabContent() {
    return StyledRefreshIndicator(
      onRefresh: _refreshHomeData,
      refreshText: AppStrings.refreshDot,
      primaryColor: AppColors.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Gap.h4,
                  FavoritesGrid(
                    onVideoTap: _onVideoTap,
                    onGlobalMenuAction:
                        (VideoInfo videoInfo, VideoMenuAction action) {
                      // 将VideoInfo转换为PlayRecord用于统一处理
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
                      _onGlobalMenuAction(playRecord, action);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      content: _buildBottomNavContent(),
      currentBottomNavIndex: _currentBottomNavIndex,
      currentTopNavIndex: _currentTopNavIndex,
      onBottomNavChanged: _onBottomNavChanged,
      selectedTopTab: _selectedTopTab,
      onTopTabChanged: _onTopTabChanged,
      onTopCategoryChanged: _onTopCategoryChanged,
      onHomeTap: _onHomeTap,
      onSearchTap: _onSearchTap,
    );
  }

  int _getIndexedStackIndex() {
    if (_currentPageIndex < 7) {
      return 0;
    }
    switch (_currentPageIndex) {
      case 7:
        return 1;
      case 8:
        return 2;
      case 9:
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildBottomNavContent() {
    return IndexedStack(
      index: _getIndexedStackIndex(),
      children: [
        PageView(
          controller: _bottomNavPageController,
          onPageChanged: (index) {
            if (_currentPageIndex < 7) {
              setState(() {
                _currentPageIndex = index;
                _currentTopNavIndex = index;
              });
            }
          },
          physics: CustomPageViewPhysics(
            currentIndex: _currentPageIndex < 7 ? _currentPageIndex : 0,
          ),
          children: [
            _buildHomeContentWithPageView(),
            const MovieScreen(),
            const TvScreen(),
            const AnimeScreen(),
            const ShowScreen(),
            const ShortDramaScreen(),
            const LiveScreen(),
          ],
        ),
        _buildHistoryTabContent(),
        _buildFavoritesTabContent(),
        const ProfileScreen(),
      ],
    );
  }

  /// 处理底部导航栏切换
  void _onBottomNavChanged(int index) {
    if (_currentBottomNavIndex == index) {
      return;
    }

    int pageIndex;
    switch (index) {
      case 0:
        pageIndex = _lastTopNavIndex;
        break;
      case 1:
        pageIndex = 7;
        break;
      case 2:
        pageIndex = 8;
        break;
      case 3:
        pageIndex = 9;
        break;
      default:
        pageIndex = _lastTopNavIndex;
    }

    if (pageIndex < 7 && _bottomNavPageController.hasClients) {
      _bottomNavPageController.jumpToPage(pageIndex);
    }

    setState(() {
      _currentBottomNavIndex = index;
      _currentPageIndex = pageIndex;
      if (pageIndex < 7) {
        _currentTopNavIndex = pageIndex;
      }
    });
  }

  /// 处理顶部标签切换
  void _onTopTabChanged(String tab) {
    // 防止重复点击同一个标签
    if (_selectedTopTab == tab) {
      return;
    }

    setState(() {
      _selectedTopTab = tab;
    });

    // 同步 PageView 的页面切换
    int pageIndex;
    switch (tab) {
      case AppStrings.navHome:
        pageIndex = 0;
        break;
      case AppStrings.navHistory:
        pageIndex = 1;
        break;
      case AppStrings.navFavorites:
        pageIndex = 2;
        break;
      default:
        pageIndex = 0;
    }

    // 使用动画切换到对应页面
    _pageController.animateToPage(
      pageIndex,
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  /// 处理点击搜索按钮
  void _onSearchTap() {
    if (Platform.isIOS) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchScreen(),
        ),
      ).then((_) {
        // 从搜索页面返回时刷新数据
        _refreshOnResume();
      });
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SearchScreen(),
          transitionDuration: Duration.zero, // 无打开动画
          reverseTransitionDuration: Duration.zero, // 无关闭动画
        ),
      ).then((_) {
        // 从搜索页面返回时刷新数据
        _refreshOnResume();
      });
    }
  }

  /// 处理点击 MoonTV 标题跳转到首页
  void _onHomeTap() {
    // 使用动画切换到首页
    _bottomNavPageController.animateToPage(
      0,
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );

    setState(() {
      // 切换到首页
      _currentBottomNavIndex = 0;
      _currentTopNavIndex = 0;
      _currentPageIndex = 0;
      // 切换到首页标签
      _selectedTopTab = AppStrings.navHome;
    });

    // 同时切换顶部标签到首页
    _pageController.animateToPage(
      0,
      duration: AppDurations.slow,
      curve: Curves.easeInOut,
    );
  }

  /// 处理顶部导航栏分类切换
  void _onTopCategoryChanged(int index) {
    // 防止重复点击同一个标签
    if (_currentTopNavIndex == index) {
      return;
    }

    setState(() {
      _currentTopNavIndex = index;
      _lastTopNavIndex = index; // 记录最后点击的顶部导航栏标签
      _currentPageIndex = index; // 更新当前页面索引
      // 无论点击顶部导航栏的哪个标签，都将底部导航栏的选中状态切换回首页
      _currentBottomNavIndex = 0;
    });

    // 跳转到顶部导航栏的对应页面
    // 确保PageController已附加到PageView
    if (_bottomNavPageController.hasClients) {
      _bottomNavPageController.jumpToPage(index);
    }
  }

  /// 处理视频卡片点击
  void _onVideoTap(PlayRecord playRecord) {
    _navigateToPlayer(
      PlayerScreen(
        source: playRecord.source,
        id: playRecord.id,
        title: playRecord.title,
        year: playRecord.year,
      ),
    );
  }

  /// 处理来自VideoInfo的全局菜单操作
  void _onGlobalMenuActionFromVideoInfo(
      VideoInfo videoInfo, VideoMenuAction action) {
    // 将VideoInfo转换为PlayRecord用于统一处理
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
    _onGlobalMenuAction(playRecord, action);
  }

  /// 处理视频菜单操作
  void _onGlobalMenuAction(PlayRecord playRecord, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        _navigateToPlayer(
          PlayerScreen(
            source: playRecord.source,
            id: playRecord.id,
            title: playRecord.title,
            year: playRecord.year,
          ),
        );
        break;
      case VideoMenuAction.favorite:
        // 收藏
        _handleFavorite(playRecord);
        break;
      case VideoMenuAction.unfavorite:
        // 取消收藏
        _handleUnfavorite(playRecord);
        break;
      case VideoMenuAction.deleteRecord:
        // 删除记录
        _deletePlayRecord(playRecord);
        break;
      case VideoMenuAction.doubanDetail:
        // 豆瓣详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.openingDoubanDetail}${playRecord.title}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            margin: const EdgeInsets.all(AppDimens.spacingLg),
          ),
        );
        break;
      case VideoMenuAction.bangumiDetail:
        // Bangumi详情 - 已在组件内部处理URL跳转
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.openingBangumiDetail}${playRecord.title}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            margin: const EdgeInsets.all(AppDimens.spacingLg),
          ),
        );
        break;
    }
  }

  /// 从继续观看UI中移除播放记录
  void _removePlayRecordFromUI(PlayRecord playRecord) {
    // 调用继续观看组件和播放历史组件的静态移除方法
    ContinueWatchingSection.removePlayRecordFromUI(
        playRecord.source, playRecord.id);
    HistoryGrid.removeHistoryFromUI(playRecord.source, playRecord.id);
  }

  /// 删除播放记录
  Future<void> _deletePlayRecord(PlayRecord playRecord) async {
    try {
      // 先从UI中移除记录
      _removePlayRecordFromUI(playRecord);

      // 使用统一的删除方法（包含缓存操作和API调用）
      final cacheService = PageCacheService();
      final result = await cacheService.deletePlayRecord(
        playRecord.source,
        playRecord.id,
        context,
      );

      if (!result.success) {
        throw Exception(result.errorMessage ?? AppStrings.errorDeleteFailed);
      }
    } catch (e) {
      // 删除失败时显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.errorDeleteFailed}: ${e.toString()}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            margin: AppDimens.contentMargin,
          ),
        );
      }
    } finally {
      // 异步刷新播放记录缓存
      if (mounted) {
        _refreshPlayRecordsCache();
      }
    }
  }

  /// 异步刷新播放记录缓存
  Future<void> _refreshPlayRecordsCache() async {
    try {
      final cacheService = PageCacheService();
      await cacheService.refreshPlayRecords(context);
    } catch (e) {
      // 刷新缓存失败，静默处理
    }
  }

  /// 跳转到播放页的通用方法
  Future<void> _navigateToPlayer(Widget playerScreen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => playerScreen),
    );

    _refreshOnResume();
  }

  /// 从播放页返回时刷新播放记录
  Future<void> _refreshOnResume() async {
    try {
      // 通知继续观看组件和播放历史组件更新UI
      if (mounted) {
        ContinueWatchingSection.refreshPlayRecords();
        HistoryGrid.refreshHistory();
        FavoritesGrid.refreshFavorites();
      }
    } catch (e) {
      // 刷新失败，静默处理
    }
  }

  /// 处理收藏
  Future<void> _handleFavorite(PlayRecord playRecord) async {
    try {
      // 构建收藏数据
      final favoriteData = {
        AppConfig.jsonCover: playRecord.cover,
        AppConfig.jsonSaveTime: DateTime.now().millisecondsSinceEpoch,
        AppConfig.jsonSourceName: playRecord.sourceName,
        AppConfig.jsonTitle: playRecord.title,
        AppConfig.jsonTotalEpisodes: playRecord.totalEpisodes,
        AppConfig.jsonYear: playRecord.year,
      };

      // 使用统一的收藏方法（包含缓存操作和API调用）
      final cacheService = PageCacheService();
      final result = await cacheService.addFavorite(
          playRecord.source, playRecord.id, favoriteData, context);

      if (result.success) {
        // 通知UI刷新收藏状态
        if (mounted) {
          setState(() {});
        }
      } else {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? AppStrings.favFailed,
                style: FontUtils.poppins(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              margin: AppDimens.contentMargin,
            ),
          );
        }
        _refreshFavorites();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.favFailed}: ${e.toString()}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            margin: AppDimens.contentMargin,
          ),
        );
      }
      _refreshFavorites();
    }
  }

  /// 处理取消收藏
  Future<void> _handleUnfavorite(PlayRecord playRecord) async {
    try {
      // 先立即从UI中移除该项目
      FavoritesGrid.removeFavoriteFromUI(playRecord.source, playRecord.id);

      // 通知继续观看组件刷新收藏状态
      if (mounted) {
        setState(() {});
      }

      // 使用统一的取消收藏方法（包含缓存操作和API调用）
      final cacheService = PageCacheService();
      final result = await cacheService.removeFavorite(
          playRecord.source, playRecord.id, context);

      if (!result.success) {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ?? AppStrings.favUnfavoriteFailed,
                style: FontUtils.poppins(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              margin: AppDimens.contentMargin,
            ),
          );
        }
        // API失败时重新刷新缓存以恢复数据
        _refreshFavorites();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
               '${AppStrings.favUnfavoriteFailed}: ${e.toString()}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            margin: AppDimens.contentMargin,
          ),
        );
      }
      // 异常时重新刷新缓存以恢复数据
      _refreshFavorites();
    }
  }

  /// 异步刷新收藏夹数据
  Future<void> _refreshFavorites() async {
    try {
      // 刷新收藏夹缓存数据
      await PageCacheService().refreshFavorites(context);

      // 通知收藏夹组件刷新UI
      FavoritesGrid.refreshFavorites();
    } catch (e) {
      // 错误处理，静默处理
    }
  }
}
