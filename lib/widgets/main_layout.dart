import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/search_service.dart';
import '../services/user_data_service.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../screens/ai_page.dart';
import '../screens/netdisk_search_screen.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'windows_title_bar.dart';

class MainLayout extends StatefulWidget {
  final Widget content;
  final int currentBottomNavIndex;
  final Function(int) onBottomNavChanged;
  final String selectedTopTab;
  final Function(String) onTopTabChanged;
  final bool isSearchMode;
  final VoidCallback? onSearchTap;
  final VoidCallback? onHomeTap;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final String? searchQuery;
  final Function(String)? onSearchQueryChanged;
  final Function(String)? onSearchSubmitted;
  final VoidCallback? onClearSearch;
  final bool showBottomNav;
  final Function(int)? onTopCategoryChanged;
  final int? currentTopNavIndex;
  final bool useNetdiskIcon;

  const MainLayout({
    super.key,
    required this.content,
    required this.currentBottomNavIndex,
    required this.onBottomNavChanged,
    required this.selectedTopTab,
    required this.onTopTabChanged,
    this.onTopCategoryChanged,
    this.currentTopNavIndex,
    this.isSearchMode = false,
    this.onSearchTap,
    this.onHomeTap,
    this.searchController,
    this.searchFocusNode,
    this.searchQuery,
    this.onSearchQueryChanged,
    this.onSearchSubmitted,
    this.onClearSearch,
    this.showBottomNav = true,
    this.useNetdiskIcon = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSearchButtonPressed = false;

  // 用于跟踪底部导航栏按钮的 hover 状态
  int? _hoveredBottomNavIndex;

  // 用于跟踪顶部导航栏按钮的 hover 状态
  int? _hoveredTopNavIndex;

  // 用于跟踪搜索按钮的 hover 状态
  bool _isSearchButtonHovered = false;

  // 用于跟踪主题切换按钮的 hover 状态
  bool _isThemeButtonHovered = false;

  // 用于跟踪返回按钮的 hover 状态
  bool _isBackButtonHovered = false;

  // 用于跟踪搜索框内清除按钮的 hover 状态
  bool _isClearButtonHovered = false;

  // 用于跟踪搜索框内搜索按钮的 hover 状态
  bool _isSearchSubmitButtonHovered = false;

  // 搜索建议相关状态
  List<String> _searchSuggestions = [];
  Timer? _debounceTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _searchSuggestions = [];
            });
            _removeOverlay();
          }
        });
      }
      return;
    }

    final currentQuery = query;
    final isLocalSearch = await UserDataService.getLocalSearch();

    List<String> suggestionResults;
    if (isLocalSearch) {
      suggestionResults = await SearchService.searchRecommand(query.trim());
    } else {
      suggestionResults = await ApiService.getSearchSuggestions(query.trim());
    }

    // 检查搜索框内容是否已变化
    if (!mounted ||
        widget.searchQuery != currentQuery ||
        suggestionResults.isEmpty) {
      return;
    }

    // 使用 post-frame callback 确保在正确的时机更新状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.searchQuery != currentQuery) {
        return;
      }

      if (suggestionResults.isNotEmpty) {
        setState(() {
          _searchSuggestions = suggestionResults.take(8).toList();
        });
        // 再次使用 post-frame callback 显示 overlay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _searchSuggestions.isNotEmpty) {
            _showSuggestionsOverlay();
          }
        });
      } else {
        setState(() {
          _searchSuggestions = [];
        });
        _removeOverlay();
      }
    });
  }

  void _onSearchQueryChanged(String query) {
    // 使用 post-frame callback 来调用父组件回调，避免在 build 期间触发 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSearchQueryChanged?.call(query);
    });

    // 取消之前的防抖计时器
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      // 使用 post-frame callback 来清除建议
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _searchSuggestions = [];
          });
          _removeOverlay();
        }
      });
      return;
    }

    // 设置新的防抖计时器（300ms），提高响应速度
    _debounceTimer = Timer(AppDurations.slow, () {
      if (mounted && query == widget.searchQuery) {
        _fetchSearchSuggestions(query);
      }
    });
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();

    if (_searchSuggestions.isEmpty) {
      return;
    }

    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isTablet = DeviceUtils.isTablet(context);

    // 计算建议框宽度
    // 平板模式：屏幕宽度的 50%
    // 移动端：屏幕宽度 - 左右padding(32) - 右侧按钮宽度(32*2) - 按钮间距(12) - 按钮与搜索框间距(16)
    final screenWidth = MediaQuery.of(context).size.width;
    final suggestionWidth =
        isTablet ? screenWidth * 0.5 : screenWidth - 32 - 16 - 32 - 12 - 32;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: suggestionWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 42), // 紧贴搜索框
          child: Material(
            elevation: AppDimens.elevationMd,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            color: themeService.isDarkMode
                ? AppColors.cardDark
                : AppColors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                padding: AppDimens.marginVertical4,
                shrinkWrap: true,
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  return InkWell(
                    onTap: () {
                      widget.searchController?.text = suggestion;
                      widget.onSearchSubmitted?.call(suggestion);
                      _removeOverlay();
                    },
                    child: Container(
                      padding: AppDimens.horizontalMdVerticalMdPadding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.search,
                            size: AppDimens.iconSm,
                            color: themeService.isDarkMode
                                ? AppColors.textDarkHint
                                : AppColors.textHint,
                          ),
                          Gap.w12,
                          Expanded(
                            child: Text(
                              suggestion,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeMd,
                                color: themeService.isDarkMode
                                    ? AppColors.white
                                    : AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Theme(
          data: themeService.isDarkMode
              ? themeService.darkTheme
              : themeService.lightTheme,
          child: Scaffold(
            resizeToAvoidBottomInset: !widget.isSearchMode,
            body: GestureDetector(
              // 点击空白处关闭搜索建议
              onTap: () {
                _removeOverlay();
              },
              // 滑动时关闭搜索建议
              onVerticalDragStart: (details) {
                _removeOverlay();
              },
              child: Stack(
                children: [
                  // 主要内容区域
                  Column(
                    children: [
                      // 主内容区域（包含header和content）
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeService.isDarkMode
                                ? AppColors.black // 深色模式纯黑色
                                : null,
                            gradient: themeService.isDarkMode
                                ? null
                                : const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.lightBlueBg, // 浅色模式渐变
                                      AppColors.lightBlueBg,
                                      AppColors.gradMid2,
                                      AppColors.gradMid3,
                                      AppColors.gradMid4,
                                      AppColors.gradEnd,
                                    ],
                                    stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
                                  ),
                          ),
                          child: Column(
                            children: [
                              // Windows 自定义标题栏
                              if (Platform.isWindows)
                                WindowsTitleBar(
                                  customBackgroundColor: widget.isSearchMode
                                      ? (themeService.isDarkMode
                                          ? AppColors.scaffoldDark
                                          : AppColors.grayBg)
                                      : null,
                                ),
                              // 固定 Header
                              _buildHeader(context, themeService),
                              // 主要内容区域
                              Expanded(child: widget.content),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 底部导航栏（可选）
                  if (widget.showBottomNav)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomNavBar(themeService),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeService themeService) {
    final isTablet = DeviceUtils.isTablet(context);

    // macOS 下需要额外的顶部 padding 来避免与透明标题栏重叠
    // Windows 下不需要额外 padding，因为自定义标题栏已经占据了空间
    final topPadding = DeviceUtils.isMacOS()
        ? MediaQuery.of(context).padding.top + 32
        : Platform.isWindows
            ? 8.0
            : MediaQuery.of(context).padding.top + 8;

    return Container(
      padding: EdgeInsets.only(top: topPadding, left: AppDimens.spacingLg, right: AppDimens.spacingLg, bottom: AppDimens.spacingSm),
      decoration: BoxDecoration(
        color: widget.isSearchMode
            ? themeService.isDarkMode
                ? AppColors.scaffoldDark
                : AppColors.grayBg
            : themeService.isDarkMode
                ? AppColors.cardDark.withValues(alpha: 0.9)
                : AppColors.white70,
      ),
      child: widget.isSearchMode
          ? _buildSearchHeader(context, themeService, isTablet)
          : _buildNormalHeader(context, themeService),
    );
  }

  Widget _buildNormalHeader(BuildContext context, ThemeService themeService) {
    return SizedBox(
      height: AppDimens.avatarSm, // 缩小导航栏高度
      child: Stack(
        children: [
          // 左侧搜索图标
          Positioned(
            left: 0,
            top: 0, // 调整位置垂直居中
            child: MouseRegion(
              cursor: DeviceUtils.isPC()
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onEnter: DeviceUtils.isPC()
                  ? (_) {
                      setState(() {
                        _isSearchButtonHovered = true;
                      });
                    }
                  : null,
              onExit: DeviceUtils.isPC()
                  ? (_) {
                      setState(() {
                        _isSearchButtonHovered = false;
                      });
                    }
                  : null,
              child: GestureDetector(
                onTap: () {
                  // 防止重复点击
                  if (_isSearchButtonPressed) return;

                  setState(() {
                    _isSearchButtonPressed = true;
                  });

                  widget.onSearchTap?.call();

                  // 延迟重置按钮状态，防止快速重复点击
                  Future.delayed(AppDurations.slow, () {
                    if (mounted) {
                      setState(() {
                        _isSearchButtonPressed = false;
                      });
                    }
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: AppDimens.avatarSm,
                  height: AppDimens.avatarSm,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DeviceUtils.isPC() && _isSearchButtonHovered
                        ? (themeService.isDarkMode
                            ? AppColors.borderDark
                            : AppColors.gray200)
                        : AppColors.transparent,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.search,
                      color: themeService.isDarkMode
                          ? AppColors.white
                          : AppColors.primary,
                      size: AppDimens.iconLg,
                      weight: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 完全居中的导航链接
          Positioned(
            top: 0, // 调整位置垂直居中
            left: 0,
            right: 0,
            child: Center(
              child: _buildTopNavLinks(themeService),
            ),
          ),
          // 右侧按钮组
          Positioned(right: 0, top: 0, child: _buildRightButtons(themeService)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(
    BuildContext context,
    ThemeService themeService,
    bool isTablet,
  ) {
    final searchBoxWidget = CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        // 阻止事件冒泡，确保点击搜索框时不会触发外部的onTap
        onTap: (() {
          // 聚焦时如果有内容，直接显示建议
          if (widget.searchQuery?.trim().isNotEmpty ?? false) {
            _fetchSearchSuggestions(widget.searchQuery!);
          }
        }),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: themeService.isDarkMode
                ? AppColors.cardDark
                : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                // 失焦时关闭建议框
                _removeOverlay();
              }
            },
            child: TextField(
              controller: widget.searchController,
              focusNode: widget.searchFocusNode,
              autofocus: false,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                hintStyle: FontUtils.poppins(
                  color: themeService.isDarkMode
                      ? AppColors.textDarkHint
                      : AppColors.textHint,
                  fontSize: AppDimens.fontSizeMd,
                ),
                suffixIcon: SizedBox(
                  width: isTablet ? 80 : 80, // 固定宽度确保按钮位置一致
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      // 搜索按钮 - 固定在右侧
                      Positioned(
                        right: isTablet ? 8 : 12,
                        child: MouseRegion(
                          cursor: (widget.searchQuery?.trim().isNotEmpty ??
                                      false) &&
                                  DeviceUtils.isPC()
                              ? SystemMouseCursors.click
                              : MouseCursor.defer,
                          onEnter: DeviceUtils.isPC() &&
                                  (widget.searchQuery?.trim().isNotEmpty ??
                                      false)
                              ? (_) {
                                  setState(() {
                                    _isSearchSubmitButtonHovered = true;
                                  });
                                }
                              : null,
                          onExit: DeviceUtils.isPC() &&
                                  (widget.searchQuery?.trim().isNotEmpty ??
                                      false)
                              ? (_) {
                                  setState(() {
                                    _isSearchSubmitButtonHovered = false;
                                  });
                                }
                              : null,
                          child: GestureDetector(
                            onTap:
                                (widget.searchQuery?.trim().isNotEmpty ?? false)
                                    ? () {
                                        _removeOverlay();
                                        widget.onSearchSubmitted?.call(
                                          widget.searchQuery!,
                                        );
                                      }
                                    : null,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: isTablet ? AppDimens.searchButtonPaddingTablet : AppDimens.searchButtonPadding,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DeviceUtils.isPC() &&
                                        _isSearchSubmitButtonHovered &&
                                        (widget.searchQuery
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                    ? (themeService.isDarkMode
                                        ? AppColors.borderDark
                                        : AppColors.gray200)
                                    : AppColors.transparent,
                              ),
                              child: Icon(
                                LucideIcons.search,
                                color: (widget.searchQuery?.trim().isNotEmpty ??
                                        false)
                                    ? AppColors.accent
                                    : themeService.isDarkMode
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textSecondary,
                                size: isTablet ? 18 : 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 清除按钮 - 在搜索按钮左侧（仅在有内容时显示）
                      Positioned(
                        right: isTablet ? 42 : 44,
                        child: Visibility(
                          visible: widget.searchQuery?.isNotEmpty ?? false,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: MouseRegion(
                            cursor: DeviceUtils.isPC()
                                ? SystemMouseCursors.click
                                : MouseCursor.defer,
                            onEnter: DeviceUtils.isPC()
                                ? (_) {
                                    setState(() {
                                      _isClearButtonHovered = true;
                                    });
                                  }
                                : null,
                            onExit: DeviceUtils.isPC()
                                ? (_) {
                                    setState(() {
                                      _isClearButtonHovered = false;
                                    });
                                  }
                                : null,
                            child: GestureDetector(
                              onTap: () {
                                _removeOverlay();
                                widget.onClearSearch?.call();
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: isTablet ? AppDimens.searchButtonPaddingTablet : AppDimens.searchButtonPadding,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DeviceUtils.isPC() &&
                                          _isClearButtonHovered
                                      ? (themeService.isDarkMode
                                          ? AppColors.borderDark
                                          : AppColors.gray200)
                                      : AppColors.transparent,
                                ),
                                child: Icon(
                                  LucideIcons.x,
                                  color: themeService.isDarkMode
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                  size: isTablet ? 18 : 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                border: InputBorder.none,
                contentPadding: AppDimens.searchContentPadding,
                isDense: true,
              ),
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                color: themeService.isDarkMode
                    ? AppColors.white
                    : AppColors.primary,
                height: AppDimens.lineHeightTight,
              ),
              onSubmitted: (value) {
                _removeOverlay();
                widget.onSearchSubmitted?.call(value);
              },
              onChanged: _onSearchQueryChanged,
              // 移除TextField的onTap，使用外部GestureDetector的onTap
            ),
          ),
        ),
      ),
    );

    // 平板模式下居中
    if (isTablet) {
      return SizedBox(
        height: AppDimens.spacingXxxl, // 固定高度
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 左侧返回按钮
            Positioned(
              left: 0,
              child: MouseRegion(
                cursor: DeviceUtils.isPC()
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onEnter: DeviceUtils.isPC()
                    ? (_) {
                        setState(() {
                          _isBackButtonHovered = true;
                        });
                      }
                    : null,
                onExit: DeviceUtils.isPC()
                    ? (_) {
                        setState(() {
                          _isBackButtonHovered = false;
                        });
                      }
                    : null,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: AppDimens.avatarSm,
                    height: AppDimens.avatarSm,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DeviceUtils.isPC() && _isBackButtonHovered
                          ? (themeService.isDarkMode
                              ? AppColors.borderDark
                              : AppColors.gray200)
                          : AppColors.transparent,
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.arrowLeft,
                        color: themeService.isDarkMode
                            ? AppColors.white
                            : AppColors.primary,
                        size: AppDimens.iconLg,
                        weight: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 搜索框在整个屏幕水平居中
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: searchBoxWidget,
              ),
            ),
            // 右侧按钮 - 垂直居中
            Positioned(right: 0, child: _buildRightButtons(themeService)),
          ],
        ),
      );
    }

    // 非平板模式下，搜索框居左，右侧留出按钮空间
    return SizedBox(
      height: AppDimens.spacingXxxl, // 固定高度
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: searchBoxWidget),
          Gap.w16,
          _buildRightButtons(themeService),
        ],
      ),
    );
  }

  Widget _buildRightButtons(ThemeService themeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 深浅模式切换按钮
        MouseRegion(
          cursor:
              DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: DeviceUtils.isPC()
              ? (_) {
                  setState(() {
                    _isThemeButtonHovered = true;
                  });
                }
              : null,
          onExit: DeviceUtils.isPC()
              ? (_) {
                  setState(() {
                    _isThemeButtonHovered = false;
                  });
                }
              : null,
          child: GestureDetector(
            onTap: widget.useNetdiskIcon
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NetdiskSearchScreen(),
                      ),
                    );
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AIPage()),
                    );
                  },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: AppDimens.avatarSm,
              height: AppDimens.avatarSm,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DeviceUtils.isPC() && _isThemeButtonHovered
                    ? (themeService.isDarkMode
                        ? AppColors.borderDark
                        : AppColors.gray200)
                    : AppColors.transparent,
              ),
              child: Center(
                child: widget.useNetdiskIcon
                    ? Icon(
                        Icons.cloud,
                        color: themeService.isDarkMode
                            ? AppColors.white
                            : AppColors.primary,
                        size: AppDimens.iconLg,
                      )
                    : Text(
                        AppStrings.aiLabel,
                        style: TextStyle(
                          color: themeService.isDarkMode
                              ? AppColors.white
                              : AppColors.primary,
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(ThemeService themeService) {
    final List<Map<String, dynamic>> navItems = [
      {AppStrings.icon: LucideIcons.house, AppStrings.label: AppStrings.navHome},
      {AppStrings.icon: LucideIcons.history, AppStrings.label: AppStrings.navHistory},
      {AppStrings.icon: LucideIcons.star, AppStrings.label: AppStrings.navFavorites},
      {AppStrings.icon: LucideIcons.user, AppStrings.label: AppStrings.navProfile},
    ];

    final isTablet = DeviceUtils.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: screenWidth - AppDimens.bottomNavBarWidthReduction,
      margin: EdgeInsets.only(
        left: AppDimens.bottomNavBarMarginHorizontal,
        right: AppDimens.bottomNavBarMarginHorizontal,
        bottom: AppDimens.bottomNavBarMarginBottom + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: themeService.isDarkMode
            ? AppColors.cardDark.withValues(alpha: 0.9)
            : AppColors.white70,
        borderRadius: BorderRadius.circular(AppDimens.radiusCircle), // 改为36圆角
        border: Border(
          top: BorderSide(
            color: themeService.isDarkMode
                ? AppColors.borderDark.withValues(alpha: 0.3)
                : AppColors.white20,
            width: AppDimens.dividerThicknessThin,
          ),
        ),
      ),
      padding: AppDimens.bottomNavBarPadding,
      child: Row(
        mainAxisAlignment:
            isTablet ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
        children: [
          // 平板模式下添加左侧空白
          if (isTablet) const Spacer(flex: 3),

          // 导航按钮
          ...navItems.asMap().entries.expand((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            bool isSelected =
                !widget.isSearchMode && widget.currentBottomNavIndex == index;
            bool isHovered =
                DeviceUtils.isPC() && _hoveredBottomNavIndex == index;

            return [
              MouseRegion(
                cursor: DeviceUtils.isPC()
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onEnter: DeviceUtils.isPC()
                    ? (_) {
                        setState(() {
                          _hoveredBottomNavIndex = index;
                        });
                      }
                    : null,
                onExit: DeviceUtils.isPC()
                    ? (_) {
                        setState(() {
                          _hoveredBottomNavIndex = null;
                        });
                      }
                    : null,
                child: GestureDetector(
                  onTap: () {
                    widget.onBottomNavChanged(index);
                  },
                  behavior: HitTestBehavior.opaque, // 确保整个区域都可以点击
                  child: Container(
                    padding: isTablet ? AppDimens.navItemPaddingTablet : AppDimens.navItemPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item[AppStrings.icon],
                          color: isSelected
                              ? AppColors.accent
                              : isHovered
                                  ? AppColors.greenLight // hover 时的浅绿色
                                  : themeService.isDarkMode
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                          size: AppDimens.iconLg,
                        ),
                        Gap.h2,
                        Text(
                          item[AppStrings.label],
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeMd,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.accent
                                : isHovered
                                    ? AppColors.greenLight // hover 时的浅绿色
                                    : themeService.isDarkMode
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 平板模式下在按钮之间添加间距
              if (isTablet && index < navItems.length - 1)
                Gap.w36,
            ];
          }),

          // 平板模式下添加右侧空白
          if (isTablet) const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildTopNavLinks(ThemeService themeService) {
    final List<Map<String, dynamic>> navItems = [
      {'label': AppStrings.navHome},
      {'label': AppStrings.navMovie},
      {'label': AppStrings.navTv},
      {'label': AppStrings.navAnime},
      {'label': AppStrings.navShow},
      {'label': AppStrings.navShortDrama},
      {'label': AppStrings.navLive},
    ];

    final isMobile = !DeviceUtils.isPC();
    final isTablet = DeviceUtils.isTablet(context);

    if (isMobile && !isTablet) {
      // 移动端：使用可水平滑动的ListView，设置固定宽度
      return SizedBox(
        height: AppDimens.spacingXxl,
        width: AppDimens.navBarWidthMobile,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: navItems.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> item = navItems[index];
            bool isSelected =
                !widget.isSearchMode && widget.currentTopNavIndex == index;
            bool isHovered = DeviceUtils.isPC() && _hoveredTopNavIndex == index;

            return MouseRegion(
              cursor: DeviceUtils.isPC()
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onEnter: DeviceUtils.isPC()
                  ? (_) {
                      setState(() {
                        _hoveredTopNavIndex = index;
                      });
                    }
                  : null,
              onExit: DeviceUtils.isPC()
                  ? (_) {
                      setState(() {
                        _hoveredTopNavIndex = null;
                      });
                    }
                  : null,
              child: GestureDetector(
                onTap: () {
                  widget.onTopCategoryChanged?.call(index);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: AppDimens.navItemLabelPadding,
                  child: Center(
                    child: Text(
                      item['label'],
                      style: FontUtils.poppins(
                        fontSize: isSelected ? 16 : 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.accent
                            : isHovered
                                ? AppColors.greenLight
                                : themeService.isDarkMode
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // 非移动端：保持原来的布局
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...navItems.asMap().entries.expand((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            bool isSelected =
                !widget.isSearchMode && widget.currentTopNavIndex == index;
            bool isHovered = DeviceUtils.isPC() && _hoveredTopNavIndex == index;

            return [
              MouseRegion(
                cursor: DeviceUtils.isPC()
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                onEnter: DeviceUtils.isPC()
                    ? (_) {
                        setState(() {
                          _hoveredTopNavIndex = index;
                        });
                      }
                    : null,
                onExit: DeviceUtils.isPC()
                    ? (_) {
                        setState(() {
                          _hoveredTopNavIndex = null;
                        });
                      }
                    : null,
                child: GestureDetector(
                  onTap: () {
                    widget.onTopCategoryChanged?.call(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: AppDimens.navItemLabelPaddingTablet,
                    child: Text(
                      item['label'],
                      style: FontUtils.poppins(
                        fontSize: isSelected ? 16 : 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.accent
                            : isHovered
                                ? AppColors.greenLight
                                : themeService.isDarkMode
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              if (index < navItems.length - 1) Gap.w24,
            ];
          }),
        ],
      );
    }
  }
}
