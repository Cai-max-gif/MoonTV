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

class _ShortDramaScreenState extends State<ShortDramaScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _shortDramas = [];
  int _page = 1;
  final int _pageLimit = 20;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<dynamic> _categories = [];
  int _selectedCategoryId = 2;
  String? _selectedCategoryName = '女频恋爱';

  final List<Map<String, dynamic>> _defaultCategories = [
    {'type_id': 2, 'type_name': '女频恋爱'},
    {'type_id': 3, 'type_name': '反转爽剧'},
    {'type_id': 4, 'type_name': '古装仙侠'},
    {'type_id': 5, 'type_name': '年代穿越'},
    {'type_id': 6, 'type_name': '脑洞悬疑'},
    {'type_id': 7, 'type_name': '现代都市'},
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
        final typeName = cat['type_name'] as String? ?? '';
        return typeName != '短剧' && typeName != '擦边短剧';
      }).toList();
      if (filtered.isNotEmpty) {
        final firstCategory = filtered.first;
        setState(() {
          _categories = filtered;
          _selectedCategoryId = firstCategory['type_id'] as int? ?? 2;
          _selectedCategoryName = firstCategory['type_name'] as String? ?? '女频恋爱';
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

    const double threshold = 50.0;
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
        final list = result.data!['list'] as List<dynamic>;
        if (isRefresh) {
          _shortDramas.clear();
        }
        _shortDramas.addAll(list.cast<Map<String, dynamic>>());
        _page++;
        _hasMore = list.length >= _pageLimit;
      } else {
        if (_shortDramas.isEmpty) {
          _errorMessage = result.message ?? '加载失败';
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
          final list = result.data!['list'] as List<dynamic>;
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
          title: shortDrama['name'] ?? '',
          stype: 'shortdrama',
          id: shortDrama['id'].toString(),
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
      (c) => c['type_name'] == categoryValue,
      orElse: () => {'type_id': 1, 'type_name': '全部'},
    );
    setState(() {
      _selectedCategoryId = category['type_id'] as int? ?? 1;
      _selectedCategoryName = category['type_name'] as String? ?? '全部';
      _shortDramas.clear();
      _isLoading = true;
    });
    _fetchShortDramas(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return StyledRefreshIndicator(
      onRefresh: _refreshShortDramasData,
      refreshText: '刷新短剧数据...',
      primaryColor: const Color(0xFF27AE60),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFilterSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                padding: EdgeInsets.all(16.0),
                child: PulsingDotsIndicator(),
              ),
            )
          else if (!_hasMore && _shortDramas.isNotEmpty && !_isLoading)
            SliverToBoxAdapter(child: _buildEndOfListIndicator())
          else
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '短剧',
            style: FontUtils.poppins(
              fontSize: 28,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildFilterRow(
        '类型',
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CapsuleTabSwitcher(
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
        ),
      ],
    );
  }

  Widget _buildEndOfListIndicator() {
    final themeService = Provider.of<ThemeService>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已经到底啦~',
            style: FontUtils.poppins(
              fontSize: 14,
              color: themeService.isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${_shortDramas.length} 部短剧',
            style: FontUtils.poppins(
              fontSize: 12,
              color: themeService.isDarkMode
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey[500],
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
