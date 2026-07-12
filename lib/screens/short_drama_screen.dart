import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../widgets/capsule_tab_switcher.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/short_drama_grid.dart';
import '../services/api_service.dart';
import '../widgets/video_menu_bottom_sheet.dart';
import '../widgets/pulsing_dots_indicator.dart';
import '../widgets/hot_short_drama_section.dart';
import 'player_screen.dart';
import '../utils/font_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';
import '../constants/app_dimensions.dart';

class ShortDramaScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const ShortDramaScreen({super.key, this.initialData});

  @override
  State<ShortDramaScreen> createState() => _ShortDramaScreenState();
}

class SelectorOption {
  final String label;
  final String value;

  const SelectorOption({required this.label, required this.value});
}

class _ShortDramaScreenState extends State<ShortDramaScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _shortDramas = [];
  int _page = 1;
  final int _pageLimit = AppConfig.shortDramaPageLimit;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<dynamic> _categories = [];
  int _selectedCategoryId = 2;
  String? _selectedCategoryName = AppStrings.shortDramaFemaleLove;

  final List<Map<String, dynamic>> _defaultCategories = [
    {AppConfig.jsonTypeId: 2, AppConfig.jsonTypeName: AppStrings.shortDramaFemaleLove},
    {AppConfig.jsonTypeId: 3, AppConfig.jsonTypeName: AppStrings.shortDramaReverseCool},
    {AppConfig.jsonTypeId: 4, AppConfig.jsonTypeName: AppStrings.shortDramaCostumeXianxia},
    {AppConfig.jsonTypeId: 5, AppConfig.jsonTypeName: AppStrings.shortDramaEraTravel},
    {AppConfig.jsonTypeId: 6, AppConfig.jsonTypeName: AppStrings.shortDramaBrainSuspense},
    {AppConfig.jsonTypeId: 7, AppConfig.jsonTypeName: AppStrings.shortDramaModernCity},
  ];

  @override
  void initState() {
    super.initState();
    _categories = _defaultCategories;

    final hotDramas = HotShortDramaSection.getCurrentShortDramas();
    if (hotDramas != null && hotDramas.isNotEmpty) {
      _shortDramas.addAll(hotDramas);
      _isLoading = false;
    } else if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _shortDramas.addAll(widget.initialData!);
      _isLoading = false;
    } else {
      _isLoading = true;
    }

    _syncCategoriesAndLoad();
    _scrollController.addListener(_handleScroll);
  }

  Future<void> _syncCategoriesAndLoad() async {
    final categoriesResult = await ApiService.getShortDramaCategories(context);
    if (!mounted) return;
    if (categoriesResult.success && categoriesResult.data != null) {
      final newCategories = categoriesResult.data!;
      final filtered = newCategories.where((cat) {
        final typeName = cat[AppConfig.jsonTypeName] as String? ?? '';
        return typeName != AppStrings.shortDramaName && typeName != AppStrings.shortDramaEdge;
      }).toList();
      if (filtered.isNotEmpty) {
        final firstCategory = filtered.first;
        setState(() {
          _categories = filtered;
          _selectedCategoryId = firstCategory[AppConfig.jsonTypeId] as int? ?? 2;
          _selectedCategoryName = firstCategory[AppConfig.jsonTypeName] as String? ?? AppStrings.shortDramaFemaleLove;
        });
      }
    }

    if (mounted) {
      _fetchShortDramas(isRefresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) {
      if (_hasMore && !_isLoading && !_isLoadingMore && _shortDramas.isNotEmpty) {
        _loadMoreShortDramas();
      }
      return;
    }

    const double threshold = AppDimens.scrollLoadMoreThreshold;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadMoreShortDramas();
    }
  }

  void _checkAndLoadMoreIfNeeded() {
    if (!_scrollController.hasClients || !_hasMore || _isLoading || _isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0 && _shortDramas.isNotEmpty) {
      _loadMoreShortDramas();
    }
  }

  Future<void> _fetchShortDramas({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getShortDramaList(
      _selectedCategoryId,
      isRefresh ? 1 : _page,
      _pageLimit,
      context,
    );

    if (!mounted) return;

    setState(() {
      if (result.success && result.data != null) {
        final list = result.data![AppConfig.jsonList] as List<dynamic>;
        if (isRefresh) {
          _shortDramas.clear();
        }
        _shortDramas.addAll(list.cast<Map<String, dynamic>>());
        _page++;
        _hasMore = list.length >= _pageLimit;
      } else {
        if (_shortDramas.isEmpty) {
          _errorMessage = result.message ?? AppStrings.loadFailed;
        }
      }
      _isLoading = false;
    });

    if (isRefresh && result.success && result.data != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAndLoadMoreIfNeeded();
        }
      });
    }
  }

  Future<void> _loadMoreShortDramas() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final result = await ApiService.getShortDramaList(
      _selectedCategoryId,
      _page,
      _pageLimit,
      context,
    );

    if (mounted) {
      setState(() {
        if (result.success && result.data != null) {
          final list = result.data![AppConfig.jsonList] as List<dynamic>;
          _shortDramas.addAll(list.cast<Map<String, dynamic>>());
          _page++;
          _hasMore = list.length >= _pageLimit;
        }
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshShortDramasData() async {
    await _fetchShortDramas(isRefresh: true);
  }

  void _onVideoTap(Map<String, dynamic> shortDrama) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          title: shortDrama[AppConfig.jsonName] ?? '',
          stype: AppConfig.stypeShortDrama,
          id: shortDrama[AppConfig.jsonId].toString(),
        ),
      ),
    );
  }

  void _handleMenuAction(Map<String, dynamic> shortDrama, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        _onVideoTap(shortDrama);
        break;
      default:
        break;
    }
  }

  void _onCategorySelected(String categoryValue) {
    final category = _categories.firstWhere(
      (c) => c[AppConfig.jsonTypeName] == categoryValue,
      orElse: () => {AppConfig.jsonTypeId: 1, AppConfig.jsonTypeName: AppStrings.all},
    );
    setState(() {
      _selectedCategoryId = category[AppConfig.jsonTypeId] as int? ?? 1;
      _selectedCategoryName = category[AppConfig.jsonTypeName] as String? ?? AppStrings.all;
      _shortDramas.clear();
      _isLoading = true;
    });
    _fetchShortDramas(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StyledRefreshIndicator(
      onRefresh: _refreshShortDramasData,
      refreshText: AppStrings.refreshShortDrama,
      primaryColor: AppColors.accent,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFilterSection()),
          SliverToBoxAdapter(child: Gap.h16),
          ShortDramaGrid(
            shortDramas: _shortDramas,
            isLoading: _isLoading && _shortDramas.isEmpty,
            errorMessage: _errorMessage,
            onVideoTap: _onVideoTap,
            onGlobalMenuAction: _handleMenuAction,
          ).buildSliver(),
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: AppDimens.contentPadding,
                child: PulsingDotsIndicator(),
              ),
            )
          else if (!_hasMore && _shortDramas.isNotEmpty && !_isLoading)
            SliverToBoxAdapter(child: _buildEndOfListIndicator())
          else
            const SliverToBoxAdapter(child: Gap.h50),
        ],
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
            AppStrings.navShortDrama,
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
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? AppColors.white10
            : AppColors.white80,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
      child: _buildFilterRow(
        AppStrings.filterCategory,
        _categories
            .map((c) => SelectorOption(
                  label: c['type_name'] as String,
                  value: c['type_name'] as String,
                ))
            .toList(),
        _selectedCategoryName ?? '',
        _onCategorySelected,
      ),
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
          selectedTab: selectedValue.isNotEmpty
              ? items.firstWhere((e) => e.value == selectedValue).label
              : items.first.label,
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
            AppStrings.countShortDrama.replaceAll('%d', '${_shortDramas.length}'),
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
