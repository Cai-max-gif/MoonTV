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

class ShowScreen extends StatefulWidget {
  const ShowScreen({super.key});

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> with AutomaticKeepAliveClientMixin {
  // 综艺一级选择器选项
  final List<SelectorOption> _showPrimaryOptions = const [
    SelectorOption(label: AppStrings.all, value: AppStrings.all),
    SelectorOption(label: AppStrings.filterValueRecentHot, value: AppStrings.filterValueRecentHot),
  ];

  // 综艺二级选择器选项（最近热门模式下的类型选项）
  final List<SelectorOption> _showSecondaryOptions = const [
    SelectorOption(label: AppStrings.all, value: AppConfig.stypeShow),
    SelectorOption(label: AppStrings.regionDomestic, value: 'show_domestic'),
    SelectorOption(label: AppStrings.regionForeign, value: 'show_foreign'),
  ];

  // 新的筛选选项 - 类型（全部模式下）
  final List<SelectorOption> _showTypeOptions = const [
    SelectorOption(label: AppStrings.all, value: 'all'),
    SelectorOption(label: AppStrings.typeReality, value: 'reality'),
    SelectorOption(label: AppStrings.typeTalkShow, value: 'talkshow'),
    SelectorOption(label: AppStrings.typeMusic, value: 'music'),
    SelectorOption(label: AppStrings.typeMusical, value: 'musical'),
  ];

  // 地区选项（与 TV 一致）
  final List<SelectorOption> _showRegionOptions = const [
    SelectorOption(label: AppStrings.all, value: 'all'),
    SelectorOption(label: AppStrings.filterValueChinese, value: 'chinese'),
    SelectorOption(label: AppStrings.filterValueWestern, value: 'western'),
    SelectorOption(label: AppStrings.regionForeign, value: 'foreign'),
    SelectorOption(label: AppStrings.filterValueKorean, value: 'korean'),
    SelectorOption(label: AppStrings.filterValueJapanese, value: 'japanese'),
    SelectorOption(label: AppStrings.regionMainlandChina, value: 'mainland_china'),
    SelectorOption(label: AppStrings.regionHongKong, value: 'hong_kong'),
    SelectorOption(label: AppStrings.regionUSA, value: 'usa'),
    SelectorOption(label: AppStrings.regionUK, value: 'uk'),
    SelectorOption(label: AppStrings.regionThailand, value: 'thailand'),
    SelectorOption(label: AppStrings.regionTaiwan, value: 'taiwan'),
    SelectorOption(label: AppStrings.regionItaly, value: 'italy'),
    SelectorOption(label: AppStrings.regionFrance, value: 'france'),
    SelectorOption(label: AppStrings.regionGermany, value: 'germany'),
    SelectorOption(label: AppStrings.regionSpain, value: 'spain'),
    SelectorOption(label: AppStrings.regionRussia, value: 'russia'),
    SelectorOption(label: AppStrings.regionSweden, value: 'sweden'),
    SelectorOption(label: AppStrings.regionBrazil, value: 'brazil'),
    SelectorOption(label: AppStrings.regionDenmark, value: 'denmark'),
    SelectorOption(label: AppStrings.regionIndia, value: 'india'),
    SelectorOption(label: AppStrings.regionCanada, value: 'canada'),
    SelectorOption(label: AppStrings.regionIreland, value: 'ireland'),
    SelectorOption(label: AppStrings.regionAustralia, value: 'australia'),
  ];

  // 年代选项（与 TV 一致）
  final List<SelectorOption> _showYearOptions = const [
    SelectorOption(label: AppStrings.all, value: 'all'),
    SelectorOption(label: AppStrings.year2020s, value: '2020s'),
    SelectorOption(label: AppStrings.year2025, value: '2025'),
    SelectorOption(label: AppStrings.year2024, value: '2024'),
    SelectorOption(label: AppStrings.year2023, value: '2023'),
    SelectorOption(label: AppStrings.year2022, value: '2022'),
    SelectorOption(label: AppStrings.year2021, value: '2021'),
    SelectorOption(label: AppStrings.year2020, value: '2020'),
    SelectorOption(label: AppStrings.year2019, value: '2019'),
    SelectorOption(label: AppStrings.year2010s, value: '2010s'),
    SelectorOption(label: AppStrings.year2000s, value: '2000s'),
    SelectorOption(label: AppStrings.year1990s, value: '1990s'),
    SelectorOption(label: AppStrings.year1980s, value: '1980s'),
    SelectorOption(label: AppStrings.year1970s, value: '1970s'),
    SelectorOption(label: AppStrings.year1960s, value: '1960s'),
    SelectorOption(label: AppStrings.yearEarlier, value: 'earlier'),
  ];

  // 平台选项（与 TV 一致）
  final List<SelectorOption> _showPlatformOptions = const [
    SelectorOption(label: AppStrings.all, value: 'all'),
    SelectorOption(label: AppStrings.platformTencent, value: 'tencent'),
    SelectorOption(label: AppStrings.platformIqiyi, value: 'iqiyi'),
    SelectorOption(label: AppStrings.platformYouku, value: 'youku'),
    SelectorOption(label: AppStrings.platformHunanTv, value: 'hunan_tv'),
    SelectorOption(label: AppStrings.platformNetflix, value: 'netflix'),
    SelectorOption(label: AppStrings.platformHBO, value: 'hbo'),
    SelectorOption(label: AppStrings.platformBBC, value: 'bbc'),
    SelectorOption(label: AppStrings.platformNHK, value: 'nhk'),
    SelectorOption(label: AppStrings.platformCBS, value: 'cbs'),
    SelectorOption(label: AppStrings.platformNBC, value: 'nbc'),
    SelectorOption(label: AppStrings.platformTvN, value: 'tvn'),
  ];

  // 排序选项（与 TV 一致）
  final List<SelectorOption> _showSortOptions = const [
    SelectorOption(label: AppStrings.sortComprehensive, value: AppStrings.sortDefault),
    SelectorOption(label: AppStrings.sortRecent, value: 'U'),
    SelectorOption(label: AppStrings.sortAiringTime, value: 'R'),
    SelectorOption(label: AppStrings.sortRating, value: 'S'),
  ];

  String _selectedCategoryValue = AppStrings.filterValueRecentHot; // 默认选中最近热门
  String _selectedRegionValue = AppConfig.stypeShow; // 二级筛选默认选中全部

  // 新版筛选状态
  String _selectedShowType = 'all';
  String _selectedShowRegion = 'all';
  String _selectedShowYear = 'all';
  String _selectedShowPlatform = 'all';
  String _selectedShowSort = 'T';

  final ScrollController _scrollController = ScrollController();
  final List<DoubanMovie> _shows = [];
  int _page = 0;
  final int _pageLimit = AppConfig.defaultPageLimit;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  /// 获取当前筛选状态
  String _getCurrentFilterState() {
    return '$_selectedCategoryValue|$_selectedRegionValue|$_selectedShowType|$_selectedShowRegion|$_selectedShowYear|$_selectedShowPlatform|$_selectedShowSort';
  }

  @override
  void initState() {
    super.initState();
    _fetchShows(isRefresh: true);
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
        if (_hasMore && !_isLoading && !_isLoadingMore && _shows.isNotEmpty) {
          _loadMoreShows();
        }
        return;
      }

      // 正常滚动情况：当滚动到距离底部50像素内时触发加载
      const double threshold = AppDimens.scrollLoadMoreThreshold;
      if (position.pixels >= position.maxScrollExtent - threshold) {
        _loadMoreShows();
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
    if (position.maxScrollExtent <= 0 && _shows.isNotEmpty) {
      _loadMoreShows();
    }
  }

  Future<void> _fetchShows({bool isRefresh = false}) async {
    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _shows.clear();
        _page = 0;
        _hasMore = true;
      }
      _errorMessage = null;
    });

    if (_selectedCategoryValue == AppStrings.all) {
      // 将界面选项转换为豆瓣API参数
      String categoryValue = _selectedShowType;
      String regionValue = _selectedShowRegion;
      String yearValue = _selectedShowYear;
      String platformValue = _selectedShowPlatform;

      // 转换地区参数为中文标签
      if (regionValue != 'all') {
        regionValue =
            _showRegionOptions.firstWhere((e) => e.value == regionValue).label;
      }

      // 转换年代参数为中文标签
      if (yearValue != 'all') {
        yearValue =
            _showYearOptions.firstWhere((e) => e.value == yearValue).label;
      }

      // 转换类型参数为中文标签
      if (categoryValue != 'all') {
        categoryValue =
            _showTypeOptions.firstWhere((e) => e.value == categoryValue).label;
      }
      // 转换平台参数为中文标签
      if (platformValue != 'all') {
        platformValue = _showPlatformOptions
            .firstWhere((e) => e.value == platformValue)
            .label;
      }

      final params = DoubanRecommendsParams(
        kind: AppConfig.stypeTv,
        category: categoryValue,
        format: AppStrings.navShow,
        region: regionValue,
        year: yearValue,
        platform: platformValue,
        sort: _selectedShowSort,
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
            _shows.addAll(result.data!);
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
        kind: AppConfig.stypeTv,
        category: AppConfig.categoryShow,
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
            _shows.addAll(result.data!);
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
    }
  }

  Future<void> _loadMoreShows() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoadingMore = true;
    });

    if (_selectedCategoryValue == AppStrings.all) {
      // 将界面选项转换为豆瓣API参数
      String categoryValue = _selectedShowType;
      String regionValue = _selectedShowRegion;
      String yearValue = _selectedShowYear;
      String platformValue = _selectedShowPlatform;

      // 转换地区参数为中文标签
      if (regionValue != 'all') {
        regionValue =
            _showRegionOptions.firstWhere((e) => e.value == regionValue).label;
      }

      // 转换年代参数为中文标签
      if (yearValue != 'all') {
        yearValue =
            _showYearOptions.firstWhere((e) => e.value == yearValue).label;
      }

      // 转换类型参数为中文标签
      if (categoryValue != 'all') {
        categoryValue =
            _showTypeOptions.firstWhere((e) => e.value == categoryValue).label;
      }
      // 转换平台参数为中文标签
      if (platformValue != 'all') {
        platformValue = _showPlatformOptions
            .firstWhere((e) => e.value == platformValue)
            .label;
      }

      final params = DoubanRecommendsParams(
        kind: AppConfig.stypeTv,
        category: categoryValue,
        format: AppStrings.navShow,
        region: regionValue,
        year: yearValue,
        platform: platformValue,
        sort: _selectedShowSort,
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
            _shows.addAll(result.data!);
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
        kind: AppConfig.stypeTv,
        category: AppConfig.categoryShow,
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
            _shows.addAll(result.data!);
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

  Future<void> _refreshShowsData() async {
    await _fetchShows(isRefresh: true);
  }

  void _onVideoTap(VideoInfo videoInfo) {
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
      onRefresh: _refreshShowsData,
      refreshText: AppStrings.refreshShow,
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
              movies: _shows,
              isLoading: _isLoading && _shows.isEmpty,
              errorMessage: _errorMessage,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: (videoInfo, action) {
                _handleMenuAction(videoInfo, action);
              },
              contentType: AppConfig.stypeShow,
            ),
            // 底部指示器 - 加载更多或到底提示
            if (_isLoadingMore)
              const Padding(
                padding: AppDimens.contentPadding,
                child: PulsingDotsIndicator(),
              )
            else if (!_hasMore && _shows.isNotEmpty && !_isLoading)
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
            AppStrings.navShow,
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
      padding: AppDimens.paddingHorizontal20Vertical16,
      clipBehavior: Clip.none,
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
            _showPrimaryOptions,
            _selectedCategoryValue,
            (newValue) {
              setState(() {
                _selectedCategoryValue = newValue;
                // 重置二级筛选为默认值
                _selectedRegionValue = AppConfig.stypeShow; // 胶囊筛选默认值
                _selectedShowType = 'all'; // 多级筛选默认值
                _selectedShowRegion = 'all';
                _selectedShowYear = 'all';
                _selectedShowPlatform = 'all';
                _selectedShowSort = 'T';
              });
              _fetchShows(isRefresh: true);
            },
          ),
          Gap.h16,
          // 使用固定高度的容器来避免高度跳跃
          SizedBox(
            height: AppDimens.filterSectionHeight, // 增加高度以避免Column底部溢出
            child: _selectedCategoryValue == AppStrings.all
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
                  _buildFilterPill(AppStrings.filterType, _showTypeOptions, _selectedShowType,
                    (v) {
                  setState(() => _selectedShowType = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterRegion, _showRegionOptions, _selectedShowRegion,
                    (v) {
                  setState(() => _selectedShowRegion = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterYear, _showYearOptions, _selectedShowYear,
                    (v) {
                  setState(() => _selectedShowYear = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill(
                    AppStrings.filterPlatform, _showPlatformOptions, _selectedShowPlatform, (v) {
                  setState(() => _selectedShowPlatform = v);
                  _fetchShows(isRefresh: true);
                }),
                _buildFilterPill(AppStrings.filterSort, _showSortOptions, _selectedShowSort,
                    (v) {
                  setState(() => _selectedShowSort = v);
                  _fetchShows(isRefresh: true);
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
          AppStrings.filterType,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Gap.h6,
        CapsuleTabSwitcher(
          tabs: _showSecondaryOptions.map((e) => e.label).toList(),
          selectedTab: _showSecondaryOptions
              .firstWhere((e) => e.value == _selectedRegionValue)
              .label,
          onTabChanged: (newLabel) {
            final newValue = _showSecondaryOptions
                .firstWhere((e) => e.label == newLabel)
                .value;
            setState(() {
              _selectedRegionValue = newValue;
            });
            _fetchShows(isRefresh: true);
          },
        ),
      ],
    );
  }

  Widget _buildFilterPill(String title, List<SelectorOption> options,
      String selectedValue, ValueChanged<String> onSelected) {
    final selectedOption = options.firstWhere((e) => e.value == selectedValue,
        orElse: () => options.first);
    bool isDefault =
        selectedValue == 'all' || (title == AppStrings.filterSort && selectedValue == 'T');

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
    return Container(
      width: double.infinity,
      padding: AppDimens.paddingFromLTRB1681616,
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
            AppStrings.countShow.replaceAll('%d', '${_shows.length}'),
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
