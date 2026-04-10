import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../widgets/capsule_tab_switcher.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/short_drama_grid.dart';
import '../services/api_service.dart';

import '../widgets/video_menu_bottom_sheet.dart';
import '../widgets/pulsing_dots_indicator.dart';
import 'player_screen.dart';
import '../utils/font_utils.dart';
import '../widgets/filter_pill_hover.dart';

class ShortDramaScreen extends StatefulWidget {
  const ShortDramaScreen({super.key});

  @override
  State<ShortDramaScreen> createState() => _ShortDramaScreenState();
}

class _ShortDramaScreenState extends State<ShortDramaScreen> {
  // 短剧的一级选择器选项
  final List<SelectorOption> _shortDramaPrimaryOptions = const [
    SelectorOption(label: '全部', value: '全部'),
    SelectorOption(label: '热门短剧', value: '热门'),
    SelectorOption(label: '最新短剧', value: '最新'),
    SelectorOption(label: '高分短剧', value: '高分'),
  ];

  String _selectedCategoryValue = '热门';

  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _shortDramas = [];
  int _page = 1;
  final int _pageLimit = 25;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  List<dynamic> _categories = [];
  int _selectedCategoryId = 1;

  /// 获取当前筛选状态
  String _getCurrentFilterState() {
    return '$_selectedCategoryValue|$_selectedCategoryId';
  }

  @override
  void initState() {
    super.initState();
    _fetchShortDramas(isRefresh: true);
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
        if (_hasMore &&
            !_isLoading &&
            !_isLoadingMore &&
            _shortDramas.isNotEmpty) {
          _loadMoreShortDramas();
        }
        return;
      }

      // 正常滚动情况：当滚动到距离底部50像素内时触发加载
      const double threshold = 50.0;
      if (position.pixels >= position.maxScrollExtent - threshold) {
        _loadMoreShortDramas();
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
    if (position.maxScrollExtent <= 0 && _shortDramas.isNotEmpty) {
      _loadMoreShortDramas();
    }
  }

  Future<void> _fetchShortDramas({bool isRefresh = false}) async {
    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _shortDramas.clear();
        _page = 1;
        _hasMore = true;
      }
      _errorMessage = null;
    });

    // 首先加载分类列表
    if (_categories.isEmpty) {
      final categoriesResult =
          await ApiService.getShortDramaCategories(context);
      if (mounted &&
          categoriesResult.success &&
          categoriesResult.data != null) {
        setState(() {
          _categories = categoriesResult.data!;
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories[0]['type_id'] ?? 1;
          }
        });
      }
    }

    // 获取短剧列表
    final result = await ApiService.getShortDramaList(
      _selectedCategoryId,
      isRefresh ? 1 : _page,
      _pageLimit,
      context,
    );

    if (mounted) {
      // 检查当前筛选状态是否仍然与发起请求时一致
      if (requestFilterState != _getCurrentFilterState()) {
        // 筛选状态已改变，忽略这个过期的响应
        return;
      }

      setState(() {
        if (result.success && result.data != null) {
          final list = result.data!['list'] as List<dynamic>;
          _shortDramas.addAll(list.cast<Map<String, dynamic>>());
          _page++;
          // 只有当返回的数据为空时才停止分页
          if (list.isEmpty) {
            _hasMore = false;
          }
        } else {
          _errorMessage = result.message ?? '加载失败';
        }
        _isLoading = false;
      });

      // 如果是刷新且内容不足一屏，尝试自动加载更多
      if (isRefresh && result.success && result.data != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAndLoadMoreIfNeeded();
          }
        });
      }
    }
  }

  Future<void> _loadMoreShortDramas() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    // 记录发起请求时的筛选状态
    final requestFilterState = _getCurrentFilterState();

    setState(() {
      _isLoadingMore = true;
    });

    // 获取短剧列表
    final result = await ApiService.getShortDramaList(
      _selectedCategoryId,
      _page,
      _pageLimit,
      context,
    );

    if (mounted) {
      // 检查当前筛选状态是否仍然与发起请求时一致
      if (requestFilterState != _getCurrentFilterState()) {
        // 筛选状态已改变，忽略这个过期的响应
        return;
      }

      setState(() {
        if (result.success && result.data != null) {
          final list = result.data!['list'] as List<dynamic>;
          _shortDramas.addAll(list.cast<Map<String, dynamic>>());
          _page++;
          // 只有当返回的数据为空时才停止分页
          if (list.isEmpty) {
            _hasMore = false;
          }
        } else {
          // Can show a toast or a small error indicator at the bottom
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

  void _handleMenuAction(
      Map<String, dynamic> shortDrama, VideoMenuAction action) {
    switch (action) {
      case VideoMenuAction.play:
        _onVideoTap(shortDrama);
        break;
      default:
        break;
    }
  }





  @override
  Widget build(BuildContext context) {
    return StyledRefreshIndicator(
      onRefresh: _refreshShortDramasData,
      refreshText: '刷新短剧数据...',
      primaryColor: const Color(0xFF27AE60),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterSection(),
            const SizedBox(height: 16),
            ShortDramaGrid(
              shortDramas: _shortDramas,
              isLoading: _isLoading && _shortDramas.isEmpty,
              errorMessage: _errorMessage,
              onVideoTap: _onVideoTap,
              onGlobalMenuAction: _handleMenuAction,
            ),
            // 底部指示器 - 加载更多或到底提示
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: PulsingDotsIndicator(),
              )
            else if (!_hasMore && _shortDramas.isNotEmpty && !_isLoading)
              _buildEndOfListIndicator()
            else
              const SizedBox(height: 50), // 占位符保持间距
          ],
        ),
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
          const SizedBox(height: 4),
          SizedBox(
            height: 20, // 固定高度确保一致性
            child: Text(
              '精彩短剧，一刷到底',
              style: FontUtils.poppins(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildFilterRow(
        '分类',
        _shortDramaPrimaryOptions,
        _selectedCategoryValue,
        (newValue) {
          setState(() {
            _selectedCategoryValue = newValue;
          });
          _fetchShortDramas(isRefresh: true);
        },
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
