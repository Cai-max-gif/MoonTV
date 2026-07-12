import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../widgets/capsule_tab_switcher.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/douban_movies_grid.dart';
import '../services/douban_service.dart';
import '../services/bangumi_service.dart';
import '../models/douban_movie.dart';
import '../models/bangumi.dart';
import '../models/video_info.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/pulsing_dots_indicator.dart';
import '../widgets/bangumi_grid.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';
import '../widgets/simple_tab_switcher.dart';
import 'player_screen.dart';
import '../widgets/filter_pill_hover.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../widgets/filter_options_selector.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> with AutomaticKeepAliveClientMixin {
  // 动漫一级选择器选项
  final List<SelectorOption> _animePrimaryOptions = const [
    SelectorOption(label: AppStrings.animeDailyBroadcast, value: AppStrings.animeDailyBroadcast),
    SelectorOption(label: AppStrings.animeSeries, value: AppStrings.animeSeries),
    SelectorOption(label: AppStrings.animeMovie, value: AppStrings.animeMovie),
  ];

  // 星期选项
  final List<SelectorOption> _weekdayOptions = const [
    SelectorOption(label: AppStrings.weekMonday, value: '1'),
    SelectorOption(label: AppStrings.weekTuesday, value: '2'),
    SelectorOption(label: AppStrings.weekWednesday, value: '3'),
    SelectorOption(label: AppStrings.weekThursday, value: '4'),
    SelectorOption(label: AppStrings.weekFriday, value: '5'),
    SelectorOption(label: AppStrings.weekSaturday, value: '6'),
    SelectorOption(label: AppStrings.weekSunday, value: '7'),
  ];

  // 番剧类型选项
  final List<SelectorOption> _animeTypeOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.contentTypeAll),
    SelectorOption(label: AppStrings.typeHistory, value: AppConfig.contentTypeHistory),
    SelectorOption(label: AppStrings.typeMusical, value: AppConfig.contentTypeMusical),
    SelectorOption(label: AppStrings.typeDarkHumor, value: AppConfig.contentTypeDarkHumor),
    SelectorOption(label: AppStrings.typeInspirational, value: AppConfig.contentTypeInspirational),
    SelectorOption(label: AppStrings.typeParody, value: AppConfig.contentTypeParody),
    SelectorOption(label: AppStrings.typeHealing, value: AppConfig.contentTypeHealing),
    SelectorOption(label: AppStrings.typeSports, value: AppConfig.contentTypeSports),
    SelectorOption(label: AppStrings.typeHarem, value: AppConfig.contentTypeHarem),
    SelectorOption(label: AppStrings.typeErotic, value: AppConfig.contentTypeErotic),
    SelectorOption(label: AppStrings.typeChineseAnime, value: AppConfig.contentTypeChineseAnime),
    SelectorOption(label: AppStrings.typeHumanNature, value: AppConfig.contentTypeHumanNature),
    SelectorOption(label: AppStrings.typeSuspense, value: AppConfig.contentTypeSuspense),
    SelectorOption(label: AppStrings.typeLove, value: AppConfig.contentTypeLove),
    SelectorOption(label: AppStrings.typeFantasy, value: AppConfig.contentTypeFantasy),
    SelectorOption(label: AppStrings.typeSciFi, value: AppConfig.contentTypeSciFi),
  ];

  // 剧场版类型选项
  final List<SelectorOption> _movieTypeOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.contentTypeAll),
    SelectorOption(label: AppStrings.typeStopMotion, value: AppConfig.contentTypeStopMotion),
    SelectorOption(label: AppStrings.typeBiography, value: AppConfig.contentTypeBiography),
    SelectorOption(label: AppStrings.typeUsAnimation, value: AppConfig.contentTypeUsAnimation),
    SelectorOption(label: AppStrings.typeRomance, value: AppConfig.contentTypeRomance),
    SelectorOption(label: AppStrings.typeDarkHumor, value: AppConfig.contentTypeDarkHumor),
    SelectorOption(label: AppStrings.typeMusical, value: AppConfig.contentTypeMusical),
    SelectorOption(label: AppStrings.typeChildren, value: AppConfig.contentTypeChildren),
    SelectorOption(label: AppStrings.typeAnime, value: AppConfig.stypeAnime),
    SelectorOption(label: AppStrings.typeAnimal, value: AppConfig.contentTypeAnimal),
    SelectorOption(label: AppStrings.typeYouth, value: AppConfig.contentTypeYouth),
    SelectorOption(label: AppStrings.typeHistory, value: AppConfig.contentTypeHistory),
    SelectorOption(label: AppStrings.typeInspirational, value: AppConfig.contentTypeInspirational),
    SelectorOption(label: AppStrings.typeParody, value: AppConfig.contentTypeParody),
    SelectorOption(label: AppStrings.typeHealing, value: AppConfig.contentTypeHealing),
    SelectorOption(label: AppStrings.typeSports, value: AppConfig.contentTypeSports),
    SelectorOption(label: AppStrings.typeHarem, value: AppConfig.contentTypeHarem),
    SelectorOption(label: AppStrings.typeErotic, value: AppConfig.contentTypeErotic),
    SelectorOption(label: AppStrings.typeHumanNature, value: AppConfig.contentTypeHumanNature),
    SelectorOption(label: AppStrings.typeSuspense, value: AppConfig.contentTypeSuspense),
    SelectorOption(label: AppStrings.typeLove, value: AppConfig.contentTypeLove),
    SelectorOption(label: AppStrings.typeFantasy, value: AppConfig.contentTypeFantasy),
    SelectorOption(label: AppStrings.typeSciFi, value: AppConfig.contentTypeSciFi),
  ];

  // TV 地区选项（与 TV 一致）
  final List<SelectorOption> _regionOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.contentTypeAll),
    SelectorOption(label: AppStrings.filterValueChinese, value: AppConfig.filterRegionChinese),
    SelectorOption(label: AppStrings.filterValueWestern, value: AppConfig.filterRegionWestern),
    SelectorOption(label: AppStrings.regionForeign, value: AppConfig.filterRegionForeign),
    SelectorOption(label: AppStrings.filterValueKorean, value: AppConfig.filterRegionKorean),
    SelectorOption(label: AppStrings.filterValueJapanese, value: AppConfig.filterRegionJapanese),
    SelectorOption(label: AppStrings.regionMainlandChina, value: AppConfig.filterRegionMainlandChina),
    SelectorOption(label: AppStrings.regionHongKong, value: AppConfig.filterRegionHongKong),
    SelectorOption(label: AppStrings.regionUSA, value: AppConfig.filterRegionUSA),
    SelectorOption(label: AppStrings.regionUK, value: AppConfig.filterRegionUK),
    SelectorOption(label: AppStrings.regionThailand, value: AppConfig.filterRegionThailand),
    SelectorOption(label: AppStrings.regionTaiwan, value: AppConfig.filterRegionTaiwan),
    SelectorOption(label: AppStrings.regionItaly, value: AppConfig.filterRegionItaly),
    SelectorOption(label: AppStrings.regionFrance, value: AppConfig.filterRegionFrance),
    SelectorOption(label: AppStrings.regionGermany, value: AppConfig.filterRegionGermany),
    SelectorOption(label: AppStrings.regionSpain, value: AppConfig.filterRegionSpain),
    SelectorOption(label: AppStrings.regionRussia, value: AppConfig.filterRegionRussia),
    SelectorOption(label: AppStrings.regionSweden, value: AppConfig.filterRegionSweden),
    SelectorOption(label: AppStrings.regionBrazil, value: AppConfig.filterRegionBrazil),
    SelectorOption(label: AppStrings.regionDenmark, value: AppConfig.filterRegionDenmark),
    SelectorOption(label: AppStrings.regionIndia, value: AppConfig.filterRegionIndia),
    SelectorOption(label: AppStrings.regionCanada, value: AppConfig.filterRegionCanada),
    SelectorOption(label: AppStrings.regionIreland, value: AppConfig.filterRegionIreland),
    SelectorOption(label: AppStrings.regionAustralia, value: AppConfig.filterRegionAustralia),
  ];

  // 电影地区选项（与 Movie 一致）
  final List<SelectorOption> _movieRegionOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.contentTypeAll),
    SelectorOption(label: AppStrings.filterValueChinese, value: AppConfig.filterRegionChinese),
    SelectorOption(label: AppStrings.filterValueWestern, value: AppConfig.filterRegionWestern),
    SelectorOption(label: AppStrings.filterValueKorean, value: AppConfig.filterRegionKorean),
    SelectorOption(label: AppStrings.filterValueJapanese, value: AppConfig.filterRegionJapanese),
    SelectorOption(label: AppStrings.regionMainlandChina, value: AppConfig.filterRegionMainlandChina),
    SelectorOption(label: AppStrings.regionUSA, value: AppConfig.filterRegionUSA),
    SelectorOption(label: AppStrings.regionHongKong, value: AppConfig.filterRegionHongKong),
    SelectorOption(label: AppStrings.regionTaiwan, value: AppConfig.filterRegionTaiwan),
    SelectorOption(label: AppStrings.regionUK, value: AppConfig.filterRegionUK),
    SelectorOption(label: AppStrings.regionFrance, value: AppConfig.filterRegionFrance),
    SelectorOption(label: AppStrings.regionGermany, value: AppConfig.filterRegionGermany),
    SelectorOption(label: AppStrings.regionItaly, value: AppConfig.filterRegionItaly),
    SelectorOption(label: AppStrings.regionSpain, value: AppConfig.filterRegionSpain),
    SelectorOption(label: AppStrings.regionIndia, value: AppConfig.filterRegionIndia),
    SelectorOption(label: AppStrings.regionThailand, value: AppConfig.filterRegionThailand),
    SelectorOption(label: AppStrings.regionRussia, value: AppConfig.filterRegionRussia),
    SelectorOption(label: AppStrings.regionCanada, value: AppConfig.filterRegionCanada),
    SelectorOption(label: AppStrings.regionAustralia, value: AppConfig.filterRegionAustralia),
    SelectorOption(label: AppStrings.regionIreland, value: AppConfig.filterRegionIreland),
    SelectorOption(label: AppStrings.regionSweden, value: AppConfig.filterRegionSweden),
    SelectorOption(label: AppStrings.regionBrazil, value: AppConfig.filterRegionBrazil),
    SelectorOption(label: AppStrings.regionDenmark, value: AppConfig.filterRegionDenmark),
  ];

  // 年代选项（与 TV 一致）
  final List<SelectorOption> _yearOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.contentTypeAll),
    SelectorOption(label: AppStrings.year2020s, value: AppConfig.filterYear2020s),
    SelectorOption(label: AppStrings.year2025, value: AppConfig.filterYear2025),
    SelectorOption(label: AppStrings.year2024, value: AppConfig.filterYear2024),
    SelectorOption(label: AppStrings.year2023, value: AppConfig.filterYear2023),
    SelectorOption(label: AppStrings.year2022, value: AppConfig.filterYear2022),
    SelectorOption(label: AppStrings.year2021, value: AppConfig.filterYear2021),
    SelectorOption(label: AppStrings.year2020, value: AppConfig.filterYear2020),
    SelectorOption(label: AppStrings.year2019, value: AppConfig.filterYear2019),
    SelectorOption(label: AppStrings.year2010s, value: AppConfig.filterYear2010s),
    SelectorOption(label: AppStrings.year2000s, value: AppConfig.filterYear2000s),
    SelectorOption(label: AppStrings.year1990s, value: AppConfig.filterYear1990s),
    SelectorOption(label: AppStrings.year1980s, value: AppConfig.filterYear1980s),
    SelectorOption(label: AppStrings.year1970s, value: AppConfig.filterYear1970s),
    SelectorOption(label: AppStrings.year1960s, value: AppConfig.filterYear1960s),
    SelectorOption(label: AppStrings.yearEarlier, value: AppConfig.filterYearEarlier),
  ];

  // 平台选项（与 TV 一致）
  final List<SelectorOption> _platformOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.contentTypeAll),
    SelectorOption(label: AppStrings.platformTencent, value: AppConfig.filterPlatformTencent),
    SelectorOption(label: AppStrings.platformIqiyi, value: AppConfig.filterPlatformIqiyi),
    SelectorOption(label: AppStrings.platformYouku, value: AppConfig.filterPlatformYouku),
    SelectorOption(label: AppStrings.platformHunanTv, value: AppConfig.filterPlatformHunanTv),
    SelectorOption(label: AppStrings.platformNetflix, value: AppConfig.filterPlatformNetflix),
    SelectorOption(label: AppStrings.platformHBO, value: AppConfig.filterPlatformHBO),
    SelectorOption(label: AppStrings.platformBBC, value: AppConfig.filterPlatformBBC),
    SelectorOption(label: AppStrings.platformNHK, value: AppConfig.filterPlatformNHK),
    SelectorOption(label: AppStrings.platformCBS, value: AppConfig.filterPlatformCBS),
    SelectorOption(label: AppStrings.platformNBC, value: AppConfig.filterPlatformNBC),
    SelectorOption(label: AppStrings.platformTvN, value: AppConfig.filterPlatformTvN),
  ];

  // 排序选项（与 TV/Movie 一致）
  final List<SelectorOption> _sortOptions = const [
    SelectorOption(label: AppStrings.sortComprehensive, value: 'T'),
    SelectorOption(label: AppStrings.sortRecent, value: 'U'),
    SelectorOption(label: AppStrings.sortAiringTime, value: 'R'),
    SelectorOption(label: AppStrings.sortRating, value: 'S'),
  ];

  String _selectedCategoryValue = AppStrings.animeDailyBroadcast; // 默认选中每日放送
  String _selectedWeekday = DateTime.now().weekday.toString(); // 默认选中当前星期

  // 番剧筛选状态
  String _selectedAnimeType = AppConfig.contentTypeAll;
  String _selectedAnimeRegion = AppConfig.contentTypeAll;
  String _selectedAnimeYear = AppConfig.contentTypeAll;
  String _selectedAnimePlatform = AppConfig.contentTypeAll;
  String _selectedAnimeSort = AppStrings.sortDefault;

  // 剧场版筛选状态
  String _selectedMovieType = AppConfig.contentTypeAll;
  String _selectedMovieRegion = AppConfig.contentTypeAll;
  String _selectedMovieYear = AppConfig.contentTypeAll;
  String _selectedMovieSort = AppStrings.sortDefault;

  final ScrollController _scrollController = ScrollController();
  final List<DoubanMovie> _animeList = [];
  final List<BangumiItem> _bangumiList = [];
  int _page = 0;
  final int _pageLimit = AppConfig.defaultPageLimit;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnimeData(isRefresh: true);
    _scrollController.addListener(() {
      _handleScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;

      // 每日放送不需要加载更多
      if (_selectedCategoryValue == AppStrings.animeDailyBroadcast) {
        return;
      }

      // 如果内容不足以滚动（maxScrollExtent <= 0），直接尝试加载更多
      if (position.maxScrollExtent <= 0) {
        // 检查是否有更多数据且当前不在加载中
        if (_hasMore &&
            !_isLoading &&
            !_isLoadingMore &&
            _animeList.isNotEmpty) {
          _loadMoreAnimeData();
        }
        return;
      }

      // 正常滚动情况：当滚动到距离底部50像素内时触发加载
      const double threshold = AppDimens.scrollLoadMoreThreshold;
      if (position.pixels >= position.maxScrollExtent - threshold) {
        _loadMoreAnimeData();
      }
    }
  }

  Future<void> _loadMoreAnimeData() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (_selectedCategoryValue == AppStrings.animeDailyBroadcast) return; // Bangumi 数据不支持分页

    setState(() {
      _isLoadingMore = true;
    });

    // 获取豆瓣数据（与 _fetchAnimeData 中的逻辑相同）
    String categoryValue;
    String regionValue;
    String yearValue;
    String platformValue;
    String sortValue;
    String kind;
    String format;

    if (_selectedCategoryValue == AppStrings.animeSeries) {
      categoryValue = _selectedAnimeType;
      regionValue = _selectedAnimeRegion;
      yearValue = _selectedAnimeYear;
      platformValue = _selectedAnimePlatform;
      sortValue = _selectedAnimeSort;
      kind = AppConfig.stypeTv;
      format = AppStrings.navTv;
    } else {
      // 剧场版
      categoryValue = _selectedMovieType;
      regionValue = _selectedMovieRegion;
      yearValue = _selectedMovieYear;
      platformValue = AppConfig.contentTypeAll;
      sortValue = _selectedMovieSort;
      kind = AppConfig.stypeMovie;
      format = '';
    }

    // 转换参数为中文标签
    if (regionValue != AppConfig.contentTypeAll) {
      final regionOptions =
          _selectedCategoryValue == AppStrings.animeSeries ? _regionOptions : _movieRegionOptions;
      regionValue =
          regionOptions.firstWhere((e) => e.value == regionValue).label;
    }

    if (yearValue != AppConfig.contentTypeAll) {
      yearValue = _yearOptions.firstWhere((e) => e.value == yearValue).label;
    }

    if (categoryValue != AppConfig.contentTypeAll) {
      final typeOptions = _selectedCategoryValue == AppStrings.animeSeries
          ? _animeTypeOptions
          : _movieTypeOptions;
      categoryValue =
          typeOptions.firstWhere((e) => e.value == categoryValue).label;
    }

    if (_selectedCategoryValue == AppStrings.animeSeries && platformValue != AppConfig.contentTypeAll) {
      platformValue =
          _platformOptions.firstWhere((e) => e.value == platformValue).label;
    }

    final params = _selectedCategoryValue == AppStrings.animeSeries
        ? DoubanRecommendsParams(
            kind: kind,
            category: AppStrings.navAnime,
            label: categoryValue,
            format: format,
            region: regionValue,
            year: yearValue,
            platform: platformValue,
            sort: sortValue,
            pageLimit: _pageLimit,
            page: _page,
          )
        : DoubanRecommendsParams(
            kind: kind,
            category: AppStrings.navAnime,
            label: categoryValue,
            format: format,
            region: regionValue,
            year: yearValue,
            sort: sortValue,
            pageLimit: _pageLimit,
            page: _page,
          );

    final result = await DoubanService.fetchDoubanRecommends(
      context,
      params,
    );
    if (mounted) {
      setState(() {
        if (result.success && result.data != null) {
          _animeList.addAll(result.data!);
          _page++;
          if (result.data!.isEmpty) {
            _hasMore = false;
          }
        }
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _fetchAnimeData({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _animeList.clear();
        _bangumiList.clear();
        _page = 0;
        _hasMore = true;
      }
      _errorMessage = null;
    });

    if (_selectedCategoryValue == AppStrings.animeDailyBroadcast) {
      // 获取 Bangumi 数据
      final weekdayInt = int.parse(_selectedWeekday);
      final result =
          await BangumiService.getCalendarByWeekday(context, weekdayInt);
      if (mounted) {
        setState(() {
          if (result.success && result.data != null) {
            _bangumiList.clear();
            _bangumiList.addAll(result.data!
                .where((item) => item.images.bestImageUrl.isNotEmpty)
                .toList());
            _hasMore = false; // Bangumi 数据不支持分页
          } else {
            _errorMessage = result.message ?? AppStrings.loadFailed;
          }
          _isLoading = false;
        });
      }
    } else {
      // 获取豆瓣数据
      String categoryValue;
      String regionValue;
      String yearValue;
      String platformValue;
      String sortValue;
      String kind;
      String format;

      if (_selectedCategoryValue == AppStrings.animeSeries) {
        categoryValue = _selectedAnimeType;
        regionValue = _selectedAnimeRegion;
        yearValue = _selectedAnimeYear;
        platformValue = _selectedAnimePlatform;
        sortValue = _selectedAnimeSort;
        kind = AppConfig.stypeTv;
        format = AppStrings.navTv;
      } else {
        // 剧场版
        categoryValue = _selectedMovieType;
        regionValue = _selectedMovieRegion;
        yearValue = _selectedMovieYear;
        platformValue = AppConfig.contentTypeAll;
        sortValue = _selectedMovieSort;
        kind = AppConfig.stypeMovie;
        format = '';
      }

      // 转换地区参数为中文标签
      if (regionValue != AppConfig.contentTypeAll) {
        final regionOptions = _selectedCategoryValue == AppStrings.animeSeries
            ? _regionOptions
            : _movieRegionOptions;
        regionValue =
            regionOptions.firstWhere((e) => e.value == regionValue).label;
      }

      // 转换年代参数为中文标签
      if (yearValue != AppConfig.contentTypeAll) {
        yearValue = _yearOptions.firstWhere((e) => e.value == yearValue).label;
      }

      // 转换类型参数为中文标签
      if (categoryValue != AppConfig.contentTypeAll) {
        final typeOptions = _selectedCategoryValue == AppStrings.animeSeries
            ? _animeTypeOptions
            : _movieTypeOptions;
        categoryValue =
            typeOptions.firstWhere((e) => e.value == categoryValue).label;
      }

      // 转换平台参数为中文标签（仅番剧需要）
      if (_selectedCategoryValue == AppStrings.animeSeries && platformValue != AppConfig.contentTypeAll) {
        platformValue =
            _platformOptions.firstWhere((e) => e.value == platformValue).label;
      }

      final params = _selectedCategoryValue == AppStrings.animeSeries
          ? DoubanRecommendsParams(
              kind: kind,
              category: AppStrings.categoryAnimation,
              label: categoryValue,
              format: format,
              region: regionValue,
              year: yearValue,
              platform: platformValue,
              sort: sortValue,
              pageLimit: _pageLimit,
              page: _page,
            )
          : DoubanRecommendsParams(
              kind: kind,
              category: AppStrings.categoryAnimation,
              label: categoryValue,
              format: format,
              region: regionValue,
              year: yearValue,
              sort: sortValue,
              pageLimit: _pageLimit,
              page: _page,
            );

      final result = await DoubanService.fetchDoubanRecommends(
        context,
        params,
      );
      if (mounted) {
        setState(() {
          if (result.success && result.data != null) {
            _animeList.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            _errorMessage = result.message ?? AppStrings.loadFailed;
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAnimeData() async {
    await _fetchAnimeData(isRefresh: true);
  }

  void _onVideoTap(VideoInfo videoInfo) {
    if (_selectedCategoryValue == AppStrings.animeMovie) {
      // 剧场版，传递 title 和 stype=movie
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            title: videoInfo.title,
            stype: AppConfig.stypeMovie,
            year: videoInfo.year,
          ),
        ),
      );
    } else {
      // 每日放送或番剧，只传递 title
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            title: videoInfo.title,
            year: videoInfo.year,
          ),
        ),
      );
    }
  }

  void _handleMenuAction(VideoInfo videoInfo, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        _onVideoTap(videoInfo);
        break;
      case VideoMenuAction.doubanDetail:
        _launchURL('${AppConfig.doubanSubjectUrl}/${videoInfo.id}/');
        break;
      default:
        break;
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.couldNotLaunchUrl(url))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StyledRefreshIndicator(
      onRefresh: _refreshAnimeData,
      refreshText: AppStrings.refreshAnime,
      primaryColor: AppColors.accent,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterSection(),
            Gap.h16,
            _selectedCategoryValue == AppStrings.animeDailyBroadcast
                ? BangumiGrid(
                    bangumiItems: _bangumiList,
                    isLoading: _isLoading && _bangumiList.isEmpty,
                    errorMessage: _errorMessage,
                    onVideoTap: _onVideoTap,
                    onGlobalMenuAction: (videoInfo, action) {
                      _handleMenuAction(videoInfo, action);
                    },
                    contentType: AppConfig.stypeAnime,
                  )
                : DoubanMoviesGrid(
                    movies: _animeList,
                    isLoading: _isLoading && _animeList.isEmpty,
                    errorMessage: _errorMessage,
                    onVideoTap: _onVideoTap,
                    onGlobalMenuAction: (videoInfo, action) {
                      _handleMenuAction(videoInfo, action);
                    },
                    contentType: AppConfig.stypeAnime,
                  ),
            // 底部指示器 - 加载更多或到底提示
            if (_selectedCategoryValue == AppStrings.animeDailyBroadcast)
              // Bangumi 数据无需加载更多，直接显示底部指示器
              (_bangumiList.isNotEmpty && !_isLoading)
                  ? _buildEndOfListIndicator()
                  : Gap.h50
            else if (_isLoadingMore)
              const Padding(
                padding: AppDimens.contentPadding,
                child: PulsingDotsIndicator(),
              )
            else if (!_hasMore && _animeList.isNotEmpty && !_isLoading)
              _buildEndOfListIndicator()
            else
              Gap.h50, // 占位符保持间距
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppDimens.pageHeaderPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.navAnime,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeHeadline,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimens.spacingLg),
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? AppColors.white10
            : AppColors.white80,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(
            AppStrings.filterCategory,
            _animePrimaryOptions,
            _selectedCategoryValue,
            (newValue) {
              setState(() {
                _selectedCategoryValue = newValue;
                // 重置筛选为默认值
                _selectedWeekday = DateTime.now().weekday.toString();
                _selectedAnimeType = AppConfig.contentTypeAll;
                _selectedAnimeRegion = AppConfig.contentTypeAll;
                _selectedAnimeYear = AppConfig.contentTypeAll;
                _selectedAnimePlatform = AppConfig.contentTypeAll;
                _selectedAnimeSort = AppStrings.sortDefault;
                _selectedMovieType = AppConfig.contentTypeAll;
                _selectedMovieRegion = AppConfig.contentTypeAll;
                _selectedMovieYear = AppConfig.contentTypeAll;
                _selectedMovieSort = AppStrings.sortDefault;
              });
              _fetchAnimeData(isRefresh: true);
            },
          ),
          Gap.h16,
          SizedBox(
            height: AppDimens.filterSectionHeight,
            child: _buildSecondaryFilterSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryFilterSection() {
    if (_selectedCategoryValue == AppStrings.animeDailyBroadcast) {
      return _buildWeekdayFilterSection();
    } else if (_selectedCategoryValue == AppStrings.animeSeries) {
      return _buildAnimeFilterSection();
    } else {
      return _buildMovieFilterSection();
    }
  }

  Widget _buildWeekdayFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.weekTitle,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Gap.h6,
        Expanded(
          child: SimpleTabSwitcher(
            tabs: _weekdayOptions.map((e) => e.label).toList(),
            selectedTab: _weekdayOptions
                .firstWhere((e) => e.value == _selectedWeekday)
                .label,
            onTabChanged: (newLabel) {
              final newValue =
                  _weekdayOptions.firstWhere((e) => e.label == newLabel).value;
              setState(() {
                _selectedWeekday = newValue;
              });
              _fetchAnimeData(isRefresh: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.filterMore,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Gap.h6,
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(AppStrings.filterType, _animeTypeOptions, _selectedAnimeType,
                    (v) {
                  setState(() => _selectedAnimeType = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterRegion, _regionOptions, _selectedAnimeRegion,
                    (v) {
                  setState(() => _selectedAnimeRegion = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterYear, _yearOptions, _selectedAnimeYear, (v) {
                  setState(() => _selectedAnimeYear = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterPlatform, _platformOptions, _selectedAnimePlatform,
                    (v) {
                  setState(() => _selectedAnimePlatform = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterSort, _sortOptions, _selectedAnimeSort, (v) {
                  setState(() => _selectedAnimeSort = v);
                  _fetchAnimeData(isRefresh: true);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovieFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.filterMore,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Gap.h6,
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(AppStrings.filterType, _movieTypeOptions, _selectedMovieType,
                    (v) {
                  setState(() => _selectedMovieType = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(
                    AppStrings.filterRegion, _movieRegionOptions, _selectedMovieRegion, (v) {
                  setState(() => _selectedMovieRegion = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterYear, _yearOptions, _selectedMovieYear, (v) {
                  setState(() => _selectedMovieYear = v);
                  _fetchAnimeData(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterSort, _sortOptions, _selectedMovieSort, (v) {
                  setState(() => _selectedMovieSort = v);
                  _fetchAnimeData(isRefresh: true);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String title, List<SelectorOption> options,
      String selectedValue, ValueChanged<String> onSelected) {
    final selectedOption = options.firstWhere((e) => e.value == selectedValue,
        orElse: () => options.first);
    bool isDefault =
        selectedValue == AppConfig.contentTypeAll || (title == AppStrings.filterSort && selectedValue == AppStrings.sortDefault);

    return FilterPillHover(
      isPC: DeviceUtils.isPC(),
      isDefault: isDefault,
      title: title,
      selectedOption: selectedOption,
      onTap: () {
        _showFilterOptions(context, title, options, selectedValue, onSelected);
      },
    );
  }

  void _showFilterOptions(
      BuildContext context,
      String title,
      List<SelectorOption> options,
      String selectedValue,
      ValueChanged<String> onSelected) {
    showFilterOptionsSelector(
      context: context,
      title: title,
      options: options,
      selectedValue: selectedValue,
      onSelected: onSelected,
    );
  }

  Widget _buildFilterRow(
    String title,
    List<SelectorOption> items,
    String selectedValue,
    Function(String) onItemSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Gap.h8,
        CapsuleTabSwitcher(
          tabs: items.map((e) => e.label).toList(),
          selectedTab:
              items.firstWhere((e) => e.value == selectedValue).label,
          onTabChanged: (newLabel) {
            final newValue =
                items.firstWhere((e) => e.label == newLabel).value;
            onItemSelected(newValue);
          },
        ),
      ],
    );
  }

  Widget _buildEndOfListIndicator() {
    final themeService = Provider.of<ThemeService>(context);
    final totalCount = _selectedCategoryValue == AppStrings.animeDailyBroadcast
        ? _bangumiList.length
        : _animeList.length;
    final contentType = _selectedCategoryValue == AppStrings.animeDailyBroadcast
        ? AppStrings.countAnimeSeries
        : _selectedCategoryValue == AppStrings.animeSeries
            ? AppStrings.countAllAnime
            : AppStrings.countAnimeMovie;

    return Container(
      width: double.infinity,
      padding: AppDimens.paddingLeft16Right16Top8Bottom16,
      child: Column(
        children: [
          Container(
            width: AppDimens.videoCardCoverWidth,
            height: AppDimens.dividerThicknessMd,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? AppColors.white30
                  : AppColors.grey40,
              borderRadius: BorderRadius.circular(AppDimens.radiusXxs),
            ),
          ),
          Gap.h12,
          Text(
            AppStrings.noMoreData,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: themeService.isDarkMode
                  ? AppColors.white60
                  : AppColors.gray600,
              fontWeight: FontWeight.w400,
            ),
          ),
          Gap.h4,
          Text(
            AppStrings.totalCountWithName(totalCount, contentType),
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXs,
              color: themeService.isDarkMode
                  ? AppColors.white60
                  : AppColors.gray500,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
