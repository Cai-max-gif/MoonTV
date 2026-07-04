import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../widgets/capsule_tab_switcher.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/douban_movies_grid.dart';
import '../services/douban_service.dart';
import '../models/douban_movie.dart';
import '../models/video_info.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/pulsing_dots_indicator.dart';
import 'player_screen.dart';
import '../widgets/filter_pill_hover.dart';
import '../utils/device_utils.dart';
import '../constants/app_config.dart';
import '../utils/font_utils.dart';
import '../widgets/filter_options_selector.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  // 电影的一级选择器选项
  final List<SelectorOption> _moviePrimaryOptions = const [
    SelectorOption(label: AppStrings.catAll, value: '全部'),
    SelectorOption(label: AppStrings.catHotMovie, value: '热门'),
    SelectorOption(label: AppStrings.catLatestMovie, value: '最新'),
    SelectorOption(label: AppStrings.catDoubanHighRating, value: '豆瓣高分'),
    SelectorOption(label: AppStrings.catUnpopularGood, value: '冷门佳片'),
  ];

  // 电影的二级选择器选项 (旧版)
  final List<SelectorOption> _movieSecondaryOptions = const [
    SelectorOption(label: AppStrings.catAll, value: '全部'),
    SelectorOption(label: AppStrings.regionChinese, value: '华语'),
    SelectorOption(label: AppStrings.regionWestern, value: '欧美'),
    SelectorOption(label: AppStrings.regionKorean, value: '韩国'),
    SelectorOption(label: AppStrings.regionJapanese, value: '日本'),
  ];

  // 新的筛选选项
  final List<SelectorOption> _movieTypeOptions = const [
    SelectorOption(label: AppStrings.all, value: 'all'),
    SelectorOption(label: AppStrings.typeComedy, value: 'comedy'),
    SelectorOption(label: AppStrings.typeRomance, value: 'romance'),
    SelectorOption(label: AppStrings.typeAction, value: 'action'),
    SelectorOption(label: AppStrings.typeSciFi, value: 'sci-fi'),
    SelectorOption(label: AppStrings.typeSuspense, value: 'suspense'),
    SelectorOption(label: AppStrings.typeCrime, value: 'crime'),
    SelectorOption(label: AppStrings.typeThriller, value: 'thriller'),
    SelectorOption(label: AppStrings.typeAdventure, value: 'adventure'),
    SelectorOption(label: AppStrings.typeMusic, value: 'music'),
    SelectorOption(label: AppStrings.typeHistory, value: 'history'),
    SelectorOption(label: AppStrings.typeFantasy, value: 'fantasy'),
    SelectorOption(label: AppStrings.typeHorror, value: 'horror'),
    SelectorOption(label: AppStrings.typeWar, value: 'war'),
    SelectorOption(label: AppStrings.typeBiography, value: 'biography'),
    SelectorOption(label: AppStrings.typeMusical, value: 'musical'),
    SelectorOption(label: AppStrings.typeWuxia, value: 'wuxia'),
    SelectorOption(label: '情色', value: 'erotic'),
    SelectorOption(label: AppStrings.typeDisaster, value: 'disaster'),
    SelectorOption(label: '西部', value: 'western'),
    SelectorOption(label: AppStrings.typeDocumentary, value: 'documentary'),
    SelectorOption(label: '短片', value: 'short'),
  ];

  final List<SelectorOption> _movieRegionOptions = const [
    SelectorOption(label: AppStrings.all, value: 'all'),
    SelectorOption(label: AppStrings.regionChinese, value: 'chinese'),
    SelectorOption(label: AppStrings.regionWestern, value: 'western'),
    SelectorOption(label: AppStrings.regionKorean, value: 'korean'),
    SelectorOption(label: AppStrings.regionJapanese, value: 'japanese'),
    SelectorOption(label: AppStrings.regionMainlandChina, value: 'mainland_china'),
    SelectorOption(label: AppStrings.regionUSA, value: 'usa'),
    SelectorOption(label: AppStrings.regionHongKong, value: 'hong_kong'),
    SelectorOption(label: AppStrings.regionTaiwan, value: 'taiwan'),
    SelectorOption(label: AppStrings.regionUK, value: 'uk'),
    SelectorOption(label: AppStrings.regionFrance, value: 'france'),
    SelectorOption(label: AppStrings.regionGermany, value: 'germany'),
    SelectorOption(label: AppStrings.regionItaly, value: 'italy'),
    SelectorOption(label: AppStrings.regionSpain, value: 'spain'),
    SelectorOption(label: AppStrings.regionIndia, value: 'india'),
    SelectorOption(label: AppStrings.regionThailand, value: 'thailand'),
    SelectorOption(label: AppStrings.regionRussia, value: 'russia'),
    SelectorOption(label: AppStrings.regionCanada, value: 'canada'),
    SelectorOption(label: AppStrings.regionAustralia, value: 'australia'),
    SelectorOption(label: AppStrings.regionIreland, value: 'ireland'),
    SelectorOption(label: AppStrings.regionSweden, value: 'sweden'),
    SelectorOption(label: AppStrings.regionBrazil, value: 'brazil'),
    SelectorOption(label: AppStrings.regionDenmark, value: 'denmark'),
  ];

  final List<SelectorOption> _movieYearOptions = const [
    SelectorOption(label: AppStrings.catAll, value: 'all'),
    SelectorOption(label: '2020年代', value: '2020s'),
    SelectorOption(label: '2025', value: '2025'),
    SelectorOption(label: '2024', value: '2024'),
    SelectorOption(label: '2023', value: '2023'),
    SelectorOption(label: '2022', value: '2022'),
    SelectorOption(label: '2021', value: '2021'),
    SelectorOption(label: '2020', value: '2020'),
    SelectorOption(label: '2019', value: '2019'),
    SelectorOption(label: '2010年代', value: '2010s'),
    SelectorOption(label: '2000年代', value: '2000s'),
    SelectorOption(label: '90年代', value: '1990s'),
    SelectorOption(label: '80年代', value: '1980s'),
    SelectorOption(label: '70年代', value: '1970s'),
    SelectorOption(label: '60年代', value: '1960s'),
    SelectorOption(label: '更早', value: 'earlier'),
  ];

  final List<SelectorOption> _movieSortOptions = const [
    SelectorOption(label: AppStrings.sortComprehensive, value: 'T'),
    SelectorOption(label: AppStrings.sortRecent, value: 'U'),
    SelectorOption(label: AppStrings.sortAiringTime, value: 'R'),
    SelectorOption(label: AppStrings.sortRating, value: 'S'),
  ];

  String _selectedCategoryValue = '热门';
  String _selectedRegionValue = '全部'; // 旧版地区筛选

  // 新版筛选状态
  String _selectedMovieType = 'all';
  String _selectedMovieRegion = 'all';
  String _selectedMovieYear = 'all';
  String _selectedMovieSort = 'T';

  final ScrollController _scrollController = ScrollController();
  final List<DoubanMovie> _movies = [];
  int _page = 0;
  final int _pageLimit = AppConfig.defaultPageLimit;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  /// 获取当前筛选状态
  String _getCurrentFilterState() {
    return '$_selectedCategoryValue|$_selectedRegionValue|$_selectedMovieType|$_selectedMovieRegion|$_selectedMovieYear|$_selectedMovieSort';
  }

  @override
  void initState() {
    super.initState();
    _fetchMovies(isRefresh: true);
    _scrollController.addListener(() {
      _handleScroll();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 处理滚动事件，支持内容不足一屏时的加载更多
  void _handleScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;

      // 如果内容不足以滚动（maxScrollExtent <= 0），直接尝试加载更多
      if (position.maxScrollExtent <= 0) {
        // 检查是否有更多数据且当前不在加载中
        if (_hasMore && !_isLoading && !_isLoadingMore && _movies.isNotEmpty) {
          _loadMoreMovies();
        }
        return;
      }

      // 正常滚动情况：当滚动到距离底部50像素内时触发加载
      const double threshold = AppDimens.scrollLoadMoreThreshold;
      if (position.pixels >= position.maxScrollExtent - threshold) {
        _loadMoreMovies();
      }
    }
  }

  /// 检查内容是否不足一屏，如果是则自动加载更多
  void _checkAndLoadMoreIfNeeded() {
    if (!_scrollController.hasClients ||
        !_hasMore ||
        _isLoading ||
        _isLoadingMore) {
      return;
    }

    final position = _scrollController.position;

    // 如果内容不足以滚动，说明没有填满屏幕，自动加载更多
    if (position.maxScrollExtent <= 0 && _movies.isNotEmpty) {
      _loadMoreMovies();
    }
  }

  Future<void> _fetchMovies({bool isRefresh = false}) async {
    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _movies.clear();
        _page = 0;
        _hasMore = true;
      }
      _errorMessage = null;
    });

    if (_selectedCategoryValue == '全部') {
      // 将界面选项转换为豆瓣API参数
      String categoryValue = _selectedMovieType;
      String regionValue = _selectedMovieRegion;
      String yearValue = _selectedMovieYear;

      // 转换地区参数为中文标签
      if (regionValue != 'all') {
        regionValue =
            _movieRegionOptions.firstWhere((e) => e.value == regionValue).label;
      }

      // 转换年代参数为中文标签
      if (yearValue != 'all') {
        yearValue =
            _movieYearOptions.firstWhere((e) => e.value == yearValue).label;
      }

      // 转换类型参数为中文标签
      if (categoryValue != 'all') {
        categoryValue =
            _movieTypeOptions.firstWhere((e) => e.value == categoryValue).label;
      }

      final params = DoubanRecommendsParams(
        kind: 'movie',
        category: categoryValue,
        region: regionValue,
        year: yearValue,
        sort: _selectedMovieSort,
        pageLimit: _pageLimit,
        page: _page,
      );

      final result = await DoubanService.fetchDoubanRecommends(
        context,
        params,
      );
      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }

        setState(() {
          if (result.success && result.data != null) {
            _movies.addAll(result.data!);
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

        // 如果是刷新且内容不足一屏，尝试自动加载更多
        if (isRefresh && result.success && result.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndLoadMoreIfNeeded();
          });
        }
      }
    } else {
      final result = await DoubanService.getCategoryData(
        context,
        kind: 'movie',
        category: _selectedCategoryValue,
        type: _selectedRegionValue,
        page: _page,
        pageLimit: _pageLimit,
      );

      if (mounted) {
        if (requestFilterState != _getCurrentFilterState()) {
          return;
        }

        setState(() {
          if (result.success && result.data != null) {
            _movies.addAll(result.data!);
            _page++;
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            _errorMessage = result.message ?? AppStrings.loadFailed;
          }
          _isLoading = false;
        });

        if (isRefresh && result.success && result.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndLoadMoreIfNeeded();
          });
        }
      }
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoadingMore = true;
    });

    if (_selectedCategoryValue == '全部') {
      // 将界面选项转换为豆瓣API参数
      String categoryValue = _selectedMovieType;
      String regionValue = _selectedMovieRegion;
      String yearValue = _selectedMovieYear;

      // 转换地区参数为中文标签
      if (regionValue != 'all') {
        regionValue =
            _movieRegionOptions.firstWhere((e) => e.value == regionValue).label;
      }

      // 转换年代参数为中文标签
      if (yearValue != 'all') {
        yearValue =
            _movieYearOptions.firstWhere((e) => e.value == yearValue).label;
      }

      // 转换类型参数为中文标签
      if (categoryValue != 'all') {
        categoryValue =
            _movieTypeOptions.firstWhere((e) => e.value == categoryValue).label;
      }

      final params = DoubanRecommendsParams(
        kind: 'movie',
        category: categoryValue,
        region: regionValue,
        year: yearValue,
        sort: _selectedMovieSort,
        pageLimit: _pageLimit,
        page: _page,
      );

      final result = await DoubanService.fetchDoubanRecommends(
        context,
        params,
      );
      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }

        setState(() {
          if (result.success && result.data != null) {
            _movies.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            // Can show a toast or a small error indicator at the bottom
          }
          _isLoadingMore = false;
        });
      }
    } else {
      final result = await DoubanService.getCategoryData(
        context,
        kind: 'movie',
        category: _selectedCategoryValue,
        type: _selectedRegionValue,
        page: _page,
        pageLimit: _pageLimit,
      );

      if (mounted) {
        // 检查当前筛选状态是否仍然与发起请求时一致
        if (requestFilterState != _getCurrentFilterState()) {
          // 筛选状态已改变，忽略这个过期的响应
          return;
        }

        setState(() {
          if (result.success && result.data != null) {
            _movies.addAll(result.data!);
            _page++;
            // 只有当返回的数据为空时才停止分页
            if (result.data!.isEmpty) {
              _hasMore = false;
            }
          } else {
            // Can show a toast or a small error indicator at the bottom
          }
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshMoviesData() async {
    await _fetchMovies(isRefresh: true);
  }

  void _onVideoTap(VideoInfo videoInfo) {
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
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledRefreshIndicator(
      onRefresh: _refreshMoviesData,
      refreshText: AppStrings.refreshMovie,
      primaryColor: AppColors.accent,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterSection(),
            Gap.h16,
            DoubanMoviesGrid(
              movies: _movies,
              isLoading: _isLoading && _movies.isEmpty,
              errorMessage: _errorMessage,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: (videoInfo, action) {
                _handleMenuAction(videoInfo, action);
              },
              contentType: 'movie',
            ),
            // 底部指示器 - 加载更多或到底提示
            if (_isLoadingMore)
              const Padding(
                padding: AppDimens.contentPadding,
                child: PulsingDotsIndicator(),
              )
            else if (!_hasMore && _movies.isNotEmpty && !_isLoading)
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
            AppStrings.navMovie,
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
      width: double.infinity, // 设置为100%宽度
      margin: const EdgeInsets.all(AppDimens.spacingLg),
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(
            AppStrings.filterCategory,
            _moviePrimaryOptions,
            _selectedCategoryValue,
            (newValue) {
              setState(() {
                _selectedCategoryValue = newValue;
                // 重置二级筛选为默认值
                _selectedRegionValue = '全部'; // 胶囊筛选默认值
                _selectedMovieType = 'all'; // 多级筛选默认值
                _selectedMovieRegion = 'all';
                _selectedMovieYear = 'all';
                _selectedMovieSort = 'T';
              });
              _fetchMovies(isRefresh: true);
            },
          ),
          Gap.h16,
          // 使用固定高度的容器来避免高度跳跃
          SizedBox(
            height: 66, // 增加高度以避免Column底部溢出
            child: _selectedCategoryValue == '全部'
                ? _buildAdvancedFilterSection()
                : _buildSimpleFilterSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilterSection() {
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
                  _fetchMovies(isRefresh: true);
                }),
                _buildFilterPill(
                    '地区', _movieRegionOptions, _selectedMovieRegion, (v) {
                  setState(() => _selectedMovieRegion = v);
                  _fetchMovies(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterYear, _movieYearOptions, _selectedMovieYear,
                    (v) {
                  setState(() => _selectedMovieYear = v);
                  _fetchMovies(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterSort, _movieSortOptions, _selectedMovieSort,
                    (v) {
                  setState(() => _selectedMovieSort = v);
                  _fetchMovies(isRefresh: true);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.filterRegion,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Gap.h6, // 减少间距，与高级筛选保持一致
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
            tabs: _movieSecondaryOptions.map((e) => e.label).toList(),
            selectedTab: _movieSecondaryOptions
                .firstWhere((e) => e.value == _selectedRegionValue)
                .label,
            onTabChanged: (newLabel) {
              final newValue = _movieSecondaryOptions
                  .firstWhere((e) => e.label == newLabel)
                  .value;
              setState(() {
                _selectedRegionValue = newValue;
              });
              _fetchMovies(isRefresh: true);
            },
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
        selectedValue == 'all' || (title == '排序' && selectedValue == 'T');

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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
            tabs: items.map((e) => e.label).toList(),
            selectedTab:
                items.firstWhere((e) => e.value == selectedValue).label,
            onTabChanged: (newLabel) {
              final newValue =
                  items.firstWhere((e) => e.label == newLabel).value;
              onItemSelected(newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEndOfListIndicator() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, 16), // 减少顶部padding，保持底部padding与加载指示器一致
      child: Column(
        children: [
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppDimens.radiusXxs),
            ),
          ),
          Gap.h12,
          Text(
            AppStrings.noMoreData,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: themeService.isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppColors.gray600,
              fontWeight: FontWeight.w400,
            ),
          ),
          Gap.h4,
          Text(
            AppStrings.countMovie.replaceAll('%d', '${_movies.length}'),
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXs,
              color: themeService.isDarkMode
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppColors.gray500,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
