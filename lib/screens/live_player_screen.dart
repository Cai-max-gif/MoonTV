import 'dart:io' show Platform;
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/video_player_surface.dart';
import '../widgets/video_player_widget.dart';
import '../models/live_channel.dart';
import '../models/live_source.dart';
import '../models/epg_program.dart';
import '../services/live_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import '../widgets/windows_title_bar.dart';
import '../widgets/switch_loading_overlay.dart';
import '../widgets/filter_pill_hover.dart';
import '../widgets/filter_options_selector.dart';

class LivePlayerScreen extends StatefulWidget {
  final LiveChannel channel;
  final LiveSource source;

  const LivePlayerScreen({
    super.key,
    required this.channel,
    required this.source,
  });

  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen>
    with TickerProviderStateMixin {
  late SystemUiOverlayStyle _originalStyle;
  bool _isInitialized = false;
  late LiveChannel _currentChannel;
  late LiveSource _currentSource;
  List<EpgProgram>? _programs;
  bool _isLoadingEpg = false;
  List<LiveChannel> _allChannels = [];
  List<LiveSource> _allSources = [];
  String _selectedGroup = AppStrings.all;

  // 缓存设备类型
  late bool _isTablet;
  late bool _isPortraitTablet;

  // 播放器控制器
  VideoPlayerWidgetController? _videoPlayerController;

  // 播放器的 GlobalKey
  final GlobalKey _playerKey = GlobalKey();

  // 当前节目的 GlobalKey，用于滚动定位
  final GlobalKey _currentProgramKey = GlobalKey();

  // 当前频道的 GlobalKey，用于滚动定位
  final GlobalKey _currentChannelKey = GlobalKey();

  // 节目单滚动控制器（横向）
  final ScrollController _programScrollController = ScrollController();

  // 节目单滚动控制器（纵向，用于弹窗）
  final ScrollController _verticalProgramScrollController = ScrollController();

  // 频道列表滚动控制器
  final ScrollController _channelScrollController = ScrollController();

  // 网页全屏状态
  bool _isWebFullscreen = false;

  // 加载状态
  bool _isLoading = true;
  String _loadingMessage = AppStrings.liveChannelLoading;
  late AnimationController _loadingAnimationController;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _currentSource = widget.source;

    // 初始化动画控制器
    _loadingAnimationController = AnimationController(
      duration: AppDurations.oneSecond,
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // 缓存设备类型 - 在这里调用是安全的，因为 MediaQuery 已经可用
      _isTablet = DeviceUtils.isTablet(context);
      _isPortraitTablet = DeviceUtils.isPortraitTablet(context);

      // 保存当前的系统UI样式
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;
      _originalStyle = SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      );
      _isInitialized = true;

      // 加载数据
      _loadAllSources();
      _loadAllChannels();
      _loadEpgData();
    }
  }

  Future<void> _loadAllSources() async {
    try {
      final sources = await LiveService.getLiveSources();
      if (mounted) {
        setState(() {
          _allSources = sources;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allSources = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.liveLoadSourcesFailed)),
        );
      }
    }
  }

  Future<void> _loadAllChannels() async {
    try {
      final channels = await LiveService.getLiveChannels(_currentSource.key);
      if (mounted) {
        setState(() {
          _allChannels = channels;
        });

        // 滚动到当前频道
        _scrollToCurrentChannel();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allChannels = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.liveLoadChannelsFailed)),
        );
      }
    }
  }

  void _switchChannel(LiveChannel channel) {
    setState(() {
      _currentChannel = channel;
      _isLoading = true;
      _loadingMessage = AppStrings.liveSwitchChannel;
    });

    // 重新加载 EPG
    _loadEpgData();

    // 滚动到当前频道
    _scrollToCurrentChannel();
  }

  @override
  void dispose() {
    final controller = _videoPlayerController;
    _videoPlayerController = null;

    if (controller != null) {
      controller.pause();
      Future.microtask(() async {
        await controller.dispose();
      });
    }

    SystemChrome.setSystemUIOverlayStyle(_originalStyle);
    _programScrollController.dispose();
    _verticalProgramScrollController.dispose();
    _channelScrollController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadEpgData() async {
    setState(() {
      _isLoadingEpg = true;
    });

    try {
      // 如果 tvgId 为空，则不加载 EPG
      if (_currentChannel.tvgId.isEmpty) {
        if (mounted) {
          setState(() {
            _programs = null;
            _isLoadingEpg = false;
          });
        }
        return;
      }

      // 调用 LiveService 获取 EPG 数据
      final epgData = await LiveService.getLiveEpg(
        _currentChannel.tvgId,
        _currentSource.key,
      );

      if (mounted) {
        setState(() {
          _programs = epgData?.programs;
          _isLoadingEpg = false;
        });

        // 滚动到当前节目
        _scrollToCurrentProgram();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _programs = null;
          _isLoadingEpg = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.liveLoadScheduleFailed)),
        );
      }
    }
  }

  // 退出网页全屏
  void _exitWebFullscreen() {
    if (!DeviceUtils.isPC()) {
      return;
    }
    // 通知播放器控件退出网页全屏
    // 播放器控件会通过 onWebFullscreenChanged 回调来更新 _isWebFullscreen 状态
    if (_videoPlayerController != null) {
      _videoPlayerController!.exitWebFullscreen();
    }
  }

  /// 处理视频播放器 ready 事件
  void _onVideoPlayerReady() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 滚动到当前正在播放的节目（横向列表）
  void _scrollToCurrentProgram() {
    if (_programs == null || _programs!.isEmpty) {
      return;
    }

    // 找到当前正在播放的节目索引
    final currentIndex = _programs!.indexWhere((p) => p.isLive);
    if (currentIndex == -1) {
      return;
    }

    // 延迟执行，确保列表已经渲染
    Future.delayed(AppDurations.slow, () {
      if (!_programScrollController.hasClients) {
        return;
      }

      // 根据最大滚动范围反推实际的卡片宽度
      // maxScrollExtent = 总宽度 - 可视区域宽度
      final viewportWidth = _programScrollController.position.viewportDimension;
      final totalContentWidth =
          _programScrollController.position.maxScrollExtent + viewportWidth;
      final actualItemWidth = totalContentWidth / _programs!.length;

      // 计算卡片左边缘的位置
      final itemLeftPosition = currentIndex * actualItemWidth;

      // 将卡片居中：卡片左边缘位置 - (可视区域宽度 / 2) + (卡片宽度 / 2)
      final centerOffset =
          itemLeftPosition - (viewportWidth / 2) + (actualItemWidth / 2);

      // 确保不会滚动到负值或超出最大滚动范围
      final maxScrollExtent = _programScrollController.position.maxScrollExtent;
      final clampedOffset = centerOffset.clamp(0.0, maxScrollExtent);

      // 滚动到目标位置
      _programScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// 滚动到当前正在播放的节目（纵向列表）
  void _scrollToCurrentProgramInVerticalList() {
    if (_programs == null || _programs!.isEmpty) {
      return;
    }

    // 找到当前正在播放的节目
    final currentIndex = _programs!.indexWhere((p) => p.isLive);
    if (currentIndex == -1) {
      return;
    }

    // 使用 postFrameCallback 确保在渲染完成后立即执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verticalProgramScrollController.hasClients) {
        return;
      }

      // 估算每个项目的高度（包括 margin）
      // padding: 12, margin: 4*2 = 8, 总高度约 80
      const estimatedItemHeight = 80.0;
      final targetOffset = currentIndex * estimatedItemHeight;

      // 获取可视区域高度
      final viewportHeight =
          _verticalProgramScrollController.position.viewportDimension;

      // 计算滚动位置，使目标项显示在屏幕上方 25% 的位置
      final scrollOffset = targetOffset - (viewportHeight * 0.25);

      // 确保不会滚动到负值或超出最大滚动范围
      final maxScrollExtent =
          _verticalProgramScrollController.position.maxScrollExtent;
      final clampedOffset = scrollOffset.clamp(0.0, maxScrollExtent);

      _verticalProgramScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// 滚动到当前频道
  void _scrollToCurrentChannel() {
    if (_allChannels.isEmpty) return;

    // 获取筛选后的频道列表
    final filteredChannels = _getFilteredChannels();
    if (filteredChannels.isEmpty) return;

    // 找到当前频道的索引
    final currentIndex =
        filteredChannels.indexWhere((c) => c.id == _currentChannel.id);
    if (currentIndex == -1) return;

    // 定义滚动执行函数
    void performScroll() {
      if (!mounted || !_channelScrollController.hasClients) return;

      // ListTile 的固定高度（通过 SizedBox 设置）
      const itemHeight = 68.0;

      // ListView 的 padding: EdgeInsets.symmetric(vertical: 4)
      const listPadding = 4.0;

      // 计算目标位置：列表顶部 padding + 前面所有 item 的高度
      final targetPosition = listPadding + (currentIndex * itemHeight);

      // 获取可视区域高度
      final viewportHeight =
          _channelScrollController.position.viewportDimension;

      // 让目标 item 显示在可视区域顶部向下 20% 的位置
      final scrollOffset = targetPosition - (viewportHeight * 0.2);

      // 限制在有效范围内
      final maxScrollExtent = _channelScrollController.position.maxScrollExtent;
      final clampedOffset = scrollOffset.clamp(0.0, maxScrollExtent);

      _channelScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // 等待 ScrollController 准备好
    if (_channelScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => performScroll());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_channelScrollController.hasClients) {
          performScroll();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) => performScroll());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeService = context.watch<ThemeService>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor:
            isDarkMode ? AppColors.black : theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.lightBlueBg,
                      AppColors.lightBlueBg,
                      AppColors.gradMid2,
                      AppColors.gradMid3,
                      AppColors.gradMid4,
                      AppColors.gradEnd,
                    ],
                    stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
                  ),
            color: isDarkMode ? theme.scaffoldBackgroundColor : null,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Windows 自定义标题栏
                  if (Platform.isWindows)
                    const WindowsTitleBar(
                      customBackgroundColor: AppColors.black,
                    ),
                  // 主要内容
                  Expanded(
                    child: Stack(
                      children: [
                        // 主要内容（不包含播放器）
                        if (!_isWebFullscreen)
                          if (_isTablet && !_isPortraitTablet)
                            _buildTabletLandscapeLayout(theme, themeService)
                          else if (_isPortraitTablet)
                            _buildPortraitTabletLayout(theme, themeService)
                          else
                            _buildPhoneLayout(theme, themeService),
                        // 播放器层
                        _buildPlayerLayer(theme),
                      ],
                    ),
                  ),
                ],
              ),
              // 状态栏黑色背景（覆盖在最上层）
              if (!Platform.isWindows)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).padding.top,
                  child: Container(
                    color: AppColors.black,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建播放器层
  Widget _buildPlayerLayer(ThemeData theme) {
    final statusBarHeight = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final macOSPadding = DeviceUtils.isMacOS() ? 32.0 : 0.0;
    final topOffset = statusBarHeight + macOSPadding;

    if (_isWebFullscreen) {
      // 网页全屏模式：播放器占据整个屏幕（保留顶部安全区域）
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Column(
          children: [
            // 顶部安全区域
            Container(
              height: topOffset,
              color: AppColors.black,
            ),
            // 播放器
            Expanded(
              child: Stack(
                children: [
                  Container(
                    key: _playerKey,
                    color: AppColors.black,
                    child: _buildPlayerWidget(),
                  ),
                  // 加载蒙版
                  _buildSwitchLoadingOverlay(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 非网页全屏模式：根据不同布局计算播放器位置
      if (_isTablet && !_isPortraitTablet) {
        // 平板横屏模式：播放器在左侧65%区域
        final screenWidth = MediaQuery.of(context).size.width;
        final leftWidth = screenWidth * 0.65;
        final playerHeight = leftWidth / (16 / 9);

        return Positioned(
          top: topOffset,
          left: 0,
          width: leftWidth,
          height: playerHeight,
          child: Stack(
            children: [
              Container(
                key: _playerKey,
                color: AppColors.black,
                child: _buildPlayerWidget(),
              ),
              // 加载蒙版
              _buildSwitchLoadingOverlay(),
            ],
          ),
        );
      } else if (_isPortraitTablet) {
        // 平板竖屏模式：播放器占50%高度
        final screenHeight = MediaQuery.of(context).size.height;
        final playerHeight = (screenHeight - topOffset) * 0.5;

        return Positioned(
          top: topOffset,
          left: 0,
          right: 0,
          height: playerHeight,
          child: Stack(
            children: [
              Container(
                key: _playerKey,
                color: AppColors.black,
                child: _buildPlayerWidget(),
              ),
              // 加载蒙版
              _buildSwitchLoadingOverlay(),
            ],
          ),
        );
      } else {
        // 手机模式：16:9 比例
        final screenWidth = MediaQuery.of(context).size.width;
        final playerHeight = screenWidth / (16 / 9);

        return Positioned(
          top: topOffset,
          left: 0,
          right: 0,
          height: playerHeight,
          child: Stack(
            children: [
              Container(
                key: _playerKey,
                color: AppColors.black,
                child: _buildPlayerWidget(),
              ),
              // 加载蒙版
              _buildSwitchLoadingOverlay(),
            ],
          ),
        );
      }
    }
  }

  /// 构建播放器组件
  Widget _buildPlayerWidget() {
    final videoUrl = _currentChannel.url;
    return VideoPlayerWidget(
      surface: DeviceUtils.isPC()
          ? VideoPlayerSurface.desktop
          : VideoPlayerSurface.mobile,
      key: ValueKey(_currentChannel.id),
      url: videoUrl,
      headers: <String, String>{
        'User-Agent': _currentSource.ua.isNotEmpty
            ? _currentSource.ua
            : 'AptvPlayer/1.4.10',
      },
      videoTitle: _currentChannel.name,
      onBackPressed:
          _isWebFullscreen ? _exitWebFullscreen : () => Navigator.pop(context),
      onControllerCreated: (controller) {
        _videoPlayerController = controller;
      },
      onWebFullscreenChanged: (isWebFullscreen) {
        setState(() {
          _isWebFullscreen = isWebFullscreen;
        });
      },
      onExitFullScreen: () {
        // 退出全屏后，重新滚动到当前节目
        _scrollToCurrentProgram();
      },
      onReady: _onVideoPlayerReady,
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.livePlayerLoadFailed}$error')),
          );
        }
      },
      live: true,
    );
  }

  /// 构建手机模式布局
  Widget _buildPhoneLayout(ThemeData theme, ThemeService themeService) {
    final statusBarHeight = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final macOSPadding = DeviceUtils.isMacOS() ? 32.0 : 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth / (16 / 9);

    return Column(
      children: [
        // macOS/状态栏黑色背景
        Container(
          height: statusBarHeight + macOSPadding,
          color: AppColors.black,
        ),
        // 播放器占位
        SizedBox(height: playerHeight),
        // 频道信息
        _buildChannelInfo(theme, themeService),
        // 正在播放和查看节目单按钮
        _buildCurrentProgramWithDropdown(theme, themeService),
        // 播放源和分组筛选
        _buildSourceSelector(theme, themeService),
        // 频道列表（占据剩余空间）
        Expanded(
          child: _buildChannelList(theme, themeService),
        ),
      ],
    );
  }

  /// 构建平板横屏布局
  Widget _buildTabletLandscapeLayout(
      ThemeData theme, ThemeService themeService) {
    final statusBarHeight = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final macOSPadding = DeviceUtils.isMacOS() ? 32.0 : 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final leftWidth = screenWidth * 0.65;
    final playerHeight = leftWidth / (16 / 9);

    return Column(
      children: [
        // macOS/状态栏黑色背景
        Container(
          height: statusBarHeight + macOSPadding,
          color: AppColors.black,
        ),
        Expanded(
          child: Row(
            children: [
              // 左侧：播放器、台标台名和节目单
              SizedBox(
                width: leftWidth,
                child: Column(
                  children: [
                    // 播放器占位
                    SizedBox(height: playerHeight),
                    // 可滚动内容区域
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildChannelInfo(theme, themeService),
                            _buildProgramGuideScrollable(theme, themeService),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧：播放源和频道列表
              Expanded(
                child: Container(
                  color: AppColors.transparent,
                  child: Column(
                    children: [
                      // 顶部栏
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          AppStrings.liveChannelList,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXxl,
                            fontWeight: FontWeight.w600,
                            color: themeService.isDarkMode
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      // 内容区域
                      Expanded(
                        child: Column(
                          children: [
                            // 播放源选择器
                            _buildSourceSelector(theme, themeService),
                            // 频道列表
                            Expanded(
                              child: _buildChannelList(theme, themeService),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建平板竖屏布局
  Widget _buildPortraitTabletLayout(
      ThemeData theme, ThemeService themeService) {
    final statusBarHeight = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final macOSPadding = DeviceUtils.isMacOS() ? 32.0 : 0.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final playerHeight = (screenHeight - statusBarHeight - macOSPadding) * 0.5;

    return Column(
      children: [
        // macOS/状态栏黑色背景
        Container(
          height: statusBarHeight + macOSPadding,
          color: AppColors.black,
        ),
        // 播放器占位
        SizedBox(height: playerHeight),
        // 频道信息
        _buildChannelInfo(theme, themeService),
        // 正在播放和查看节目单按钮
        _buildCurrentProgramWithDropdown(theme, themeService),
        // 播放源和分组筛选
        _buildSourceSelector(theme, themeService),
        // 频道列表（占据剩余空间）
        Expanded(
          child: _buildChannelList(theme, themeService),
        ),
      ],
    );
  }

  /// 构建频道信息
  Widget _buildChannelInfo(ThemeData theme, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.transparent,
      ),
      child: Row(
        children: [
          // 台标 - 2:1 长方形，高度充满容器
          if (_currentChannel.logo.isNotEmpty)
            SizedBox(
              height: 56,
              child: AspectRatio(
                aspectRatio: 2.0,
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.spacingXs),
                  decoration: BoxDecoration(
                    color: themeService.isDarkMode
                        ? AppColors.darkBg2
                        : AppColors.gray350,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: Image.network(
                      _currentChannel.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultLogoIcon();
                      },
                    ),
                  ),
                ),
              ),
            )
          else
            _buildDefaultLogo(themeService),
          Gap.w16,
          // 频道信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentChannel.name,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXxl,
                          fontWeight: FontWeight.w600,
                          color: themeService.isDarkMode
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Gap.h4,
                Text(
                  '${_currentSource.name} > ${_currentChannel.group}',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    color: themeService.isDarkMode
                        ? AppColors.textHint
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo(ThemeService themeService) {
    return SizedBox(
      height: 56,
      child: AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          decoration: BoxDecoration(
            color: themeService.isDarkMode
                ? AppColors.darkBg2
                : AppColors.gray350,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: const Icon(
            Icons.tv,
            size: AppDimens.iconLg,
            color: AppColors.gray475,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogoIcon() {
    return const Icon(
      Icons.tv,
      size: AppDimens.iconLg,
      color: AppColors.gray475,
    );
  }

  /// 构建频道列表
  Widget _buildChannelList(ThemeData theme, ThemeService themeService) {
    final filteredChannels = _getFilteredChannels();

    if (filteredChannels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingXl),
          child: Text(
            AppStrings.liveNoChannel,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: themeService.isDarkMode
                  ? AppColors.textHint
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _channelScrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filteredChannels.length,
      itemBuilder: (context, index) {
        final channel = filteredChannels[index];
        final isSelected = channel.id == _currentChannel.id;

        // 只给当前频道添加 key，用于滚动定位
        final itemKey =
            isSelected ? _currentChannelKey : ValueKey('channel_${channel.id}');

        return SizedBox(
          height: 68.0, // 固定高度，从 72 减小到 68
          child: ListTile(
            key: itemKey,
            selected: isSelected,
            selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
            visualDensity: const VisualDensity(vertical: -1),
            leading: channel.logo.isNotEmpty
                ? AspectRatio(
                    aspectRatio: 2.0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: themeService.isDarkMode
                            ? AppColors.darkBg2
                            : AppColors.gray350,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        child: Image.network(
                          channel.logo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.tv,
                              size: AppDimens.iconSm,
                              color: AppColors.gray475,
                            );
                          },
                        ),
                      ),
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 2.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeService.isDarkMode
                            ? AppColors.darkBg2
                            : AppColors.gray350,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.tv,
                        size: AppDimens.iconSm,
                        color: AppColors.gray475,
                      ),
                    ),
                  ),
            title: Text(
              channel.name,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.accent
                    : themeService.isDarkMode
                        ? Colors.white
                        : AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              channel.group,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeXs,
                color: themeService.isDarkMode
                    ? AppColors.textHint
                    : AppColors.textSecondary,
              ),
            ),
            onTap: () => _switchChannel(channel),
          ),
        );
      },
    );
  }

  /// 构建播放源和分组选择器
  Widget _buildSourceSelector(ThemeData theme, ThemeService themeService) {
    // 获取所有分组，保持原始顺序
    final allGroups = [AppStrings.all];
    final seenGroups = <String>{};
    for (var channel in _allChannels) {
      if (channel.group.isNotEmpty && !seenGroups.contains(channel.group)) {
        seenGroups.add(channel.group);
        allGroups.add(channel.group);
      }
    }

    // 构建分组选项
    final groupOptions =
        allGroups.map((g) => SelectorOption(label: g, value: g)).toList();

    // 构建直播源选项
    final sourceOptions = _allSources
        .map((s) => SelectorOption(label: s.name, value: s.key))
        .toList();

    // 判断是否只有一个直播源
    final showSourceFilter = _allSources.length > 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeService.isDarkMode
                ? AppColors.darkDivider
                : AppColors.grayBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // 直播源筛选（只有多个源时显示）
          if (showSourceFilter) ...[
            _buildFilterPill(
              AppStrings.liveSource,
              sourceOptions,
              _currentSource.key,
              (value) async {
                final source = _allSources.firstWhere((s) => s.key == value);
                setState(() {
                  _currentSource = source;
                  _selectedGroup = AppStrings.all;
                  _isLoading = true;
                  _loadingMessage = AppStrings.liveSwitchSource;
                });
                await _loadAllChannels();
                if (mounted && _allChannels.isNotEmpty) {
                  _switchChannel(_allChannels.first);
                }
              },
              themeService,
            ),
            Gap.w8,
          ],
          // 分组筛选
          _buildFilterPill(
            AppStrings.liveGroup,
            groupOptions,
            _selectedGroup,
            (value) {
              setState(() {
                _selectedGroup = value;
              });
            },
            themeService,
          ),
          const Spacer(),
          // 滚动到当前频道按钮
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildScrollToCurrentChannelButton(themeService),
          ),
        ],
      ),
    );
  }

  /// 构建滚动到当前频道按钮
  Widget _buildScrollToCurrentChannelButton(ThemeService themeService) {
    return _HoverButton(
      onTap: _scrollToCurrentChannel,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                themeService.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    String title,
    List<SelectorOption> options,
    String selectedValue,
    ValueChanged<String> onSelected,
    ThemeService themeService,
  ) {
    final selectedOption = options.firstWhere(
      (e) => e.value == selectedValue,
      orElse: () => options.first,
    );
    final isDefault = selectedValue == AppStrings.all || selectedValue.isEmpty;

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
    if (DeviceUtils.isPC()) {
      // PC端使用 filter_options_selector.dart 中的 PC 组件
      showFilterOptionsSelector(
        context: context,
        title: title,
        options: options,
        selectedValue: selectedValue,
        onSelected: onSelected,
        useCompactLayout: title == AppStrings.liveGroup, // 只有标题筛选使用紧凑布局
      );
    } else {
      // 移动端显示底部弹出
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        isScrollControlled: true,
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final modalWidth =
              DeviceUtils.isTablet(context) ? screenWidth * 0.5 : screenWidth;
          const horizontalPadding = 16.0;
          const spacing = 10.0;
          final itemWidth =
              (modalWidth - horizontalPadding * 2 - spacing * 2) / 3;

          return Container(
            width: DeviceUtils.isTablet(context)
                ? modalWidth
                : double.infinity, // 设置宽度为100%
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimens.spacingLg),
                  child: Center(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                    minHeight: 200.0,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: horizontalPadding, vertical: 8),
                      child: Wrap(
                        alignment: WrapAlignment.start, // 左对齐
                        spacing: spacing,
                        runSpacing: spacing,
                        children: options.map((option) {
                          final isSelected = option.value == selectedValue;
                          return SizedBox(
                            width: itemWidth,
                            child: InkWell(
                              onTap: () {
                                onSelected(option.value);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                alignment: Alignment.centerLeft, // 内容左对齐
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent
                                      : Theme.of(context)
                                          .chipTheme
                                          .backgroundColor,
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                ),
                                child: Text(
                                  option.label,
                                  textAlign: TextAlign.left, // 文字左对齐
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Gap.h16,
              ],
            ),
          );
        },
      );
    }
  }

  /// 获取筛选后的频道列表
  List<LiveChannel> _getFilteredChannels() {
    if (_selectedGroup == AppStrings.all) {
      return _allChannels;
    } else {
      return _allChannels.where((c) => c.group == _selectedGroup).toList();
    }
  }

  /// 构建当前节目信息和查看节目单按钮（用于平板竖屏和手机）
  Widget _buildCurrentProgramWithDropdown(
      ThemeData theme, ThemeService themeService) {
    // 获取当前正在播放的节目
    EpgProgram? currentProgram;
    if (_programs != null && _programs!.isNotEmpty) {
      try {
        currentProgram = _programs!.firstWhere((p) => p.isLive);
      } catch (e) {
        // 如果没有找到正在播放的节目，使用第一个
        currentProgram = null;
      }
    }

    return Container(
      padding: AppDimens.listTilePadding,
      child: Row(
        children: [
          // 正在播放标签和节目名称
          Expanded(
            child: Row(
              children: [
                Text(
                  '${AppStrings.liveNowPlaying}',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    color: themeService.isDarkMode
                        ? AppColors.textHint
                        : AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _isLoadingEpg
                      ? Text(
                          AppStrings.loading,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeMd,
                            fontWeight: FontWeight.w500,
                            color: themeService.isDarkMode
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : currentProgram != null
                          ? Text(
                              currentProgram.title,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeMd,
                                fontWeight: FontWeight.w500,
                                color: themeService.isDarkMode
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              AppStrings.liveNoProgramInfo,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeMd,
                                fontWeight: FontWeight.w500,
                                color: themeService.isDarkMode
                                    ? AppColors.textDarkHint
                                    : AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                ),
              ],
            ),
          ),
          Gap.w20,
          // 查看节目单按钮
          _HoverButton(
            onTap: () => _showProgramListDropdown(theme, themeService),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -1.2),
                  child: Text(
                    AppStrings.liveViewSchedule,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: themeService.isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                Gap.w4,
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: themeService.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示节目单下拉列表
  void _showProgramListDropdown(ThemeData theme, ThemeService themeService) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final playerHeight = screenWidth / (16 / 9);
    final panelHeight = screenHeight - statusBarHeight - playerHeight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.black30,
      builder: (context) {
        return Container(
          height: panelHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(AppDimens.spacingLg),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: themeService.isDarkMode
                          ? AppColors.darkDivider
                          : AppColors.grayBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      AppStrings.liveSchedule,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXxl,
                        fontWeight: FontWeight.w600,
                        color: themeService.isDarkMode
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: themeService.isDarkMode
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // 节目列表
              Expanded(
                child: _buildVerticalProgramList(themeService),
              ),
            ],
          ),
        );
      },
    );

    // 显示弹窗后立即触发滚动
    _scrollToCurrentProgramInVerticalList();
  }

  /// 构建垂直节目列表
  Widget _buildVerticalProgramList(ThemeService themeService) {
    if (_isLoadingEpg) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              Gap.h16,
              Text(
                AppStrings.liveLoadingSchedule,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  color: themeService.isDarkMode
                      ? AppColors.textHint
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_programs == null || _programs!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: themeService.isDarkMode
                    ? AppColors.textDarkHint
                    : AppColors.textHint,
              ),
              Gap.h16,
              Text(
                AppStrings.liveNoScheduleInfo,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  color: themeService.isDarkMode
                      ? AppColors.textHint
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _verticalProgramScrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _programs!.length,
      itemBuilder: (context, index) {
        final program = _programs![index];
        // 给当前正在播放的节目添加 key，用于滚动定位
        final itemKey = program.isLive ? _currentProgramKey : null;
        return _buildVerticalProgramItem(program, themeService, key: itemKey);
      },
    );
  }

  /// 构建垂直节目列表项
  Widget _buildVerticalProgramItem(
    EpgProgram program,
    ThemeService themeService, {
    Key? key,
  }) {
    final now = DateTime.now();
    final isLive = program.isLive;
    final isPast = now.isAfter(program.endTime);

    // 根据节目状态选择颜色
    Color textColor;
    Color timeColor;

    if (isLive) {
      // 正在播放 - 绿色
      textColor = themeService.isDarkMode
          ? AppColors.green400
          : AppColors.green700;
      timeColor = themeService.isDarkMode
          ? AppColors.green400
          : AppColors.green700;
    } else if (isPast) {
      // 过去的节目 - 灰色
      textColor = themeService.isDarkMode
          ? AppColors.gray400
          : AppColors.gray500;
      timeColor = themeService.isDarkMode
          ? AppColors.gray400
          : AppColors.gray500;
    } else {
      // 未开始的节目 - 蓝色
      textColor = themeService.isDarkMode
          ? AppColors.blue400
          : AppColors.blue600;
      timeColor = themeService.isDarkMode
          ? AppColors.blue400
          : AppColors.blue600;
    }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Row(
        children: [
          // 时间
          Text(
            program.timeRange,
            style: FontUtils.sourceCodePro(
              fontSize: AppDimens.fontSizeSm,
              color: timeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap.w16,
          // 节目标题
          Expanded(
            child: Text(
              program.title,
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: isLive ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可滚动的节目单（用于平板横屏）
  Widget _buildProgramGuideScrollable(
      ThemeData theme, ThemeService themeService) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 节目单标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  AppStrings.liveSchedule,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    fontWeight: FontWeight.w600,
                    color: themeService.isDarkMode
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
                const Spacer(),
                // 滚动到当前节目按钮
                _buildScrollToCurrentButton(themeService),
              ],
            ),
          ),
          // 节目列表
          _buildProgramList(themeService),
        ],
      ),
    );
  }

  /// 构建滚动到当前节目按钮
  Widget _buildScrollToCurrentButton(ThemeService themeService) {
    return _HoverButton(
      onTap: _scrollToCurrentProgram,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                themeService.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建节目列表
  Widget _buildProgramList(ThemeService themeService) {
    if (_isLoadingEpg) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            AppStrings.liveLoadingSchedule,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: themeService.isDarkMode
                  ? AppColors.textHint
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_programs == null || _programs!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: themeService.isDarkMode
                    ? AppColors.textDarkHint
                    : AppColors.textHint,
              ),
              Gap.h12,
              Text(
                AppStrings.liveNoScheduleInfo,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  color: themeService.isDarkMode
                      ? AppColors.textHint
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.builder(
        controller: _programScrollController,
        scrollDirection: Axis.horizontal,
        padding: AppDimens.horizontalSmVerticalMdPadding,
        itemCount: _programs!.length,
        itemBuilder: (context, index) {
          final program = _programs![index];
          return _buildProgramItem(
            program,
            themeService,
            key: program.isLive ? _currentProgramKey : null,
          );
        },
      ),
    );
  }

  Widget _buildProgramItem(
    EpgProgram program,
    ThemeService themeService, {
    Key? key,
  }) {
    final now = DateTime.now();
    final isLive = program.isLive;
    final isPast = now.isAfter(program.endTime);

    // 根据节目状态选择颜色和边框
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Color timeColor;

    if (isLive) {
      // 正在播放 - 绿色背景 + 绿色边框
      backgroundColor = themeService.isDarkMode
          ? AppColors.accent.withValues(alpha: 0.2)
          : AppColors.accent.withValues(alpha: 0.1);
      borderColor = AppColors.accent.withValues(alpha: 0.3);
      textColor = themeService.isDarkMode
          ? AppColors.green400
          : AppColors.green700;
      timeColor = themeService.isDarkMode
          ? AppColors.green400
          : AppColors.green700;
    } else if (isPast) {
      // 过去的节目 - 灰色背景 + 灰色边框
      backgroundColor = themeService.isDarkMode
          ? AppColors.borderDarkGray.withValues(alpha: 0.5)
          : AppColors.gray300.withValues(alpha: 0.5);
      borderColor = themeService.isDarkMode
          ? AppColors.gray600
          : AppColors.gray300;
      textColor = themeService.isDarkMode
          ? AppColors.gray400
          : AppColors.gray500;
      timeColor = themeService.isDarkMode
          ? AppColors.gray400
          : AppColors.gray500;
    } else {
      // 未开始的节目 - 蓝色背景 + 蓝色边框
      backgroundColor = themeService.isDarkMode
          ? AppColors.info.withValues(alpha: 0.2)
          : AppColors.info.withValues(alpha: 0.1);
      borderColor = AppColors.info.withValues(alpha: 0.3);
      textColor = themeService.isDarkMode
          ? AppColors.blue400
          : AppColors.blue600;
      timeColor = themeService.isDarkMode
          ? AppColors.blue400
          : AppColors.blue600;
    }

    return Container(
      key: key,
      width: 120,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(AppDimens.spacingSm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                program.timeRange,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMinSm,
                  color: timeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isLive)
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      AppStrings.navLive,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeMin,
                        color: timeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Text(
            program.title,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSize3xs,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建切换加载蒙版（只覆盖播放器）
  Widget _buildSwitchLoadingOverlay() {
    return SwitchLoadingOverlay(
      isVisible: _isLoading,
      message: _loadingMessage,
      animationController: _loadingAnimationController,
      onBackPressed:
          _isWebFullscreen ? _exitWebFullscreen : () => Navigator.pop(context),
    );
  }
}

/// 带 hover 效果的按钮组件（PC 端专用）
class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPC = DeviceUtils.isPC();

    return MouseRegion(
      cursor: (isPC && widget.onTap != null)
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: isPC ? (_) => setState(() => _isHovered = true) : null,
      onExit: isPC ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          child: ColorFiltered(
            colorFilter: (isPC && _isHovered)
                ? const ColorFilter.mode(
                    Colors.green,
                    BlendMode.modulate,
                  )
                : const ColorFilter.mode(
                    Colors.white,
                    BlendMode.modulate,
                  ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
