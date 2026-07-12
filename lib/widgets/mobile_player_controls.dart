import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dlna_device_dialog.dart';
import 'player_download_panel.dart';
import '../utils/device_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/user_data_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';

class MobilePlayerControls extends StatefulWidget {
  final dynamic player;
  final dynamic state;
  final Function(bool) onControlsVisibilityChanged;
  final VoidCallback? onBackPressed;
  final Function(bool) onFullscreenChange;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPause;
  final String videoUrl;
  final bool isLastEpisode;
  final bool isLoadingVideo;
  final Function(dynamic)? onCastStarted;
  final String? videoTitle;
  final int? currentEpisodeIndex;
  final int? totalEpisodes;
  final String? sourceName;
  final VoidCallback? onExitFullScreen;
  final bool live;
  final ValueNotifier<double> playbackSpeedListenable;
  final Future<void> Function(double speed) onSetSpeed;
  final Future<void> Function() onEnterPipMode;
  final bool isPipMode;
  final List<String>? episodes;
  final List<String>? episodesTitles;
  final Function(int episodeIndex)? onSingleEpisodeDownload;
  final Future<void> Function(List<int> episodeIndices)?
      onBatchEpisodesDownload;
  final VoidCallback? onDanmakuSettings;
  final bool isLocalFile;
  final VoidCallback? onNetdiskSearch;

  const MobilePlayerControls({
    super.key,
    this.player,
    this.state,
    required this.onControlsVisibilityChanged,
    this.onBackPressed,
    required this.onFullscreenChange,
    this.onNextEpisode,
    this.onPause,
    required this.videoUrl,
    this.isLastEpisode = false,
    this.isLoadingVideo = false,
    this.onCastStarted,
    this.videoTitle,
    this.currentEpisodeIndex,
    this.totalEpisodes,
    this.sourceName,
    this.onExitFullScreen,
    this.live = false,
    required this.playbackSpeedListenable,
    required this.onSetSpeed,
    required this.onEnterPipMode,
    required this.isPipMode,
    this.episodes,
    this.episodesTitles,
    this.onSingleEpisodeDownload,
    this.onBatchEpisodesDownload,
    this.onDanmakuSettings,
    this.isLocalFile = false,
    this.onNetdiskSearch,
  });

  @override
  State<MobilePlayerControls> createState() => _MobilePlayerControlsState();
}

class _MobilePlayerControlsState extends State<MobilePlayerControls> {
  final List<StreamSubscription> _subscriptions = [];
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _isLongPressing = false;
  double _originalPlaybackSpeed = 1.0;
  Duration? _dragPosition;
  bool _isSeekingViaSwipe = false;
  double _swipeStartX = 0;
  Duration _swipeStartPosition = Duration.zero;
  Size? _screenSize;
  bool _isLocked = false;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  bool _autoEnterPipEnabled = false;
  Timer? _volumeHideTimer;
  Timer? _brightnessHideTimer;
  Timer? _timeUpdateTimer;
  String _currentTime = '';

  // 截图相关
  bool _showScreenshotToast = false;
  String _screenshotToastMessage = '';
  Timer? _screenshotToastTimer;

  @override
  void initState() {
    super.initState();
    _initSystemControls();
    _listenPlayerStreams();
    _updateCurrentTime();
    _startTimeUpdateTimer();
    UserDataService.initDanmakuEnabled();
    _initAutoEnterPip();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _forceStartHideTimer();
      widget.onControlsVisibilityChanged(true);
      // 本地文件播放时，移动端默认进入全屏
      if (widget.isLocalFile && DeviceUtils.isMobile()) {
        _enterFullscreen();
      }
    });
  }

  Future<void> _initAutoEnterPip() async {
    _autoEnterPipEnabled = await UserDataService.getAutoEnterPictureInPicture();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MobilePlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 PIP 模式停止时，显示控制栏
    if (oldWidget.isPipMode && !widget.isPipMode) {
      setState(() => _controlsVisible = true);
      widget.onControlsVisibilityChanged(true);
      _startHideTimer();
    }
  }

  void _initSystemControls() {
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.getVolume().then((value) {
      if (mounted) {
        setState(() => _currentVolume = value);
      }
    }).catchError((_) {});
    ScreenBrightness().application.then((value) {
      if (mounted) {
        setState(() => _currentBrightness = value);
      }
    }).catchError((_) {});
  }

  void _listenPlayerStreams() {
    if (widget.player != null) {
      _subscriptions.add(widget.player.stream.playing.listen((playing) {
        if (!mounted) return;
        if (playing && _controlsVisible) {
          _startHideTimer();
        }
        if (!playing) {
          _hideTimer?.cancel();
          if (!_controlsVisible) {
            setState(() => _controlsVisible = true);
            widget.onControlsVisibilityChanged(true);
          }
        }
      }));

      _subscriptions.add(widget.player.stream.position.listen((_) {
        if (!mounted) return;
        if (_controlsVisible && !_isSeekingViaSwipe) {
          setState(() {});
        }
      }));

      _subscriptions.add(widget.player.stream.completed.listen((_) {
        if (!mounted) return;
        setState(() {});
      }));
    }
  }

  void _openDanmakuSettings() {
    _onUserInteraction();
    widget.onDanmakuSettings?.call();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _hideTimer?.cancel();
    _volumeHideTimer?.cancel();
    _brightnessHideTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _screenshotToastTimer?.cancel();
    VolumeController.instance.showSystemUI = true;
    super.dispose();
  }

  bool get _isFullscreen => widget.state?.isFullscreen() ?? false;
  bool get _isPlaying => widget.player?.state?.playing ?? false;
  Duration get _position => widget.player?.state?.position ?? Duration.zero;
  Duration get _duration => widget.player?.state?.duration ?? Duration.zero;

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(AppDurations.toastDuration, () {
        if (mounted) {
          setState(() => _controlsVisible = false);
          widget.onControlsVisibilityChanged(false);
        }
      });
    }
  }

  void _forceStartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(AppDurations.toastDuration, () {
      if (mounted) {
        setState(() => _controlsVisible = false);
        widget.onControlsVisibilityChanged(false);
      }
    });
  }

  void _onUserInteraction() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
      widget.onControlsVisibilityChanged(true);
    }
    _startHideTimer();
  }

  void _toggleControlsVisibility() {
    if (_isLocked) {
      setState(() => _controlsVisible = !_controlsVisible);
      if (_controlsVisible) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
      }
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    widget.onControlsVisibilityChanged(_controlsVisible);
    if (_controlsVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_isLocked || widget.live || !_isPlaying) return;
    setState(() {
      _isLongPressing = true;
      _originalPlaybackSpeed = widget.playbackSpeedListenable.value;
    });
    widget.onSetSpeed(2.0);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isLocked || !_isLongPressing || widget.live) return;
    widget.onSetSpeed(_originalPlaybackSpeed);
    setState(() => _isLongPressing = false);
  }

  void _onSwipeStart(DragStartDetails details) {
    if (_isLocked || widget.live) return;
    _screenSize ??= MediaQuery.of(context).size;
    setState(() {
      _isSeekingViaSwipe = true;
      _swipeStartX = details.globalPosition.dx;
      _swipeStartPosition = _position;
      _dragPosition = null;
      _controlsVisible = true;
    });
    _hideTimer?.cancel();
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    if (_isLocked ||
        !_isSeekingViaSwipe ||
        widget.live ||
        _screenSize == null) {
      return;
    }
    final screenWidth = _screenSize!.width;
    final swipeDistance = details.globalPosition.dx - _swipeStartX;
    final swipeRatio = swipeDistance / (screenWidth * 0.5);
    final duration = _duration;
    if (duration == Duration.zero) return;
    final targetPosition = _swipeStartPosition +
        Duration(
          milliseconds: (duration.inMilliseconds * swipeRatio * 0.1).round(),
        );
    final clamped = Duration(
      milliseconds:
          targetPosition.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    setState(() => _dragPosition = clamped);
  }

  void _onSwipeEnd(DragEndDetails details) {
    if (_isLocked || !_isSeekingViaSwipe || widget.live) return;
    if (_dragPosition != null && widget.player != null) {
      widget.player.seek(_dragPosition!);
    }
    setState(() {
      _isSeekingViaSwipe = false;
      _dragPosition = null;
    });
    _startHideTimer();
  }

  void _onVolumeSwipeStart(DragStartDetails details) {
    if (!_isFullscreen || _isLocked) return;
    _volumeHideTimer?.cancel();
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
  }

  void _onVolumeSwipeUpdate(DragUpdateDetails details) {
    if (!_isFullscreen || _isLocked) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final volumeChange = -(details.delta.dy / screenHeight) * 2;
    setState(() {
      _currentVolume = (_currentVolume + volumeChange).clamp(0.0, 1.0);
      _showVolumeIndicator = true;
    });
    VolumeController.instance.setVolume(_currentVolume);
    _startVolumeHideTimer();
  }

  void _onVolumeSwipeEnd(DragEndDetails details) {
    if (!_isFullscreen || _isLocked) return;
    _startVolumeHideTimer();
    _startHideTimer();
  }

  void _startVolumeHideTimer() {
    _volumeHideTimer?.cancel();
    _volumeHideTimer = Timer(AppDurations.twoSeconds, () {
      if (mounted) {
        setState(() => _showVolumeIndicator = false);
      }
    });
  }

  void _onBrightnessSwipeStart(DragStartDetails details) {
    if (!_isFullscreen || _isLocked) return;
    _brightnessHideTimer?.cancel();
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
  }

  void _onBrightnessSwipeUpdate(DragUpdateDetails details) {
    if (!_isFullscreen || _isLocked) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final brightnessChange = -(details.delta.dy / screenHeight) * 2;
    setState(() {
      _currentBrightness =
          (_currentBrightness + brightnessChange).clamp(0.0, 1.0);
      _showBrightnessIndicator = true;
    });
    ScreenBrightness().setApplicationScreenBrightness(_currentBrightness);
    _startBrightnessHideTimer();
  }

  void _onBrightnessSwipeEnd(DragEndDetails details) {
    if (!_isFullscreen || _isLocked) return;
    _startBrightnessHideTimer();
    _startHideTimer();
  }

  void _startBrightnessHideTimer() {
    _brightnessHideTimer?.cancel();
    _brightnessHideTimer = Timer(AppDurations.twoSeconds, () {
      if (mounted) {
        setState(() => _showBrightnessIndicator = false);
      }
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
    });
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(AppDurations.oneSecond, (_) {
      if (mounted) {
        _updateCurrentTime();
      }
    });
  }

  Future<void> _togglePlayPause() async {
    _onUserInteraction();
    if (widget.player != null) {
      if (_isPlaying) {
        await widget.player.pause();
        widget.onPause?.call();
      } else {
        await widget.player.play();
      }
    }
  }

  void _enterFullscreen() {
    if (widget.state != null) {
      widget.state.enterFullscreen();
      widget.onFullscreenChange(true);
      _onUserInteraction();
    }
  }

  void _exitFullscreen() {
    if (widget.state != null) {
      widget.state.exitFullscreen();
      widget.onFullscreenChange(false);
      // 触发退出全屏回调
      widget.onExitFullScreen?.call();
      // 确保控制栏可见并重新启动隐藏计时器
      setState(() {
        _controlsVisible = true;
        _isLocked = false;
      });
      widget.onControlsVisibilityChanged(true);
      _startHideTimer();
    }
  }

  Future<void> _showDLNADialog() async {
    if (widget.player != null) {
      if (_isPlaying) {
        await widget.player.pause();
        widget.onPause?.call();
      }
      if (_isFullscreen) {
        _exitFullscreen();
        await Future.delayed(AppDurations.playerControlHideDelay);
      }
      final resumePos = widget.player.state?.position ?? Duration.zero;
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => DLNADeviceDialog(
          currentUrl: widget.videoUrl,
          resumePosition: resumePos,
          videoTitle: widget.videoTitle,
          currentEpisodeIndex: widget.currentEpisodeIndex,
          totalEpisodes: widget.totalEpisodes,
          sourceName: widget.sourceName,
          onCastStarted: widget.onCastStarted,
        ),
      );
    }
  }

  Future<void> _showSpeedDialog() async {
    final speeds = AppConfig.playbackSpeedValues;
    final currentSpeed = widget.playbackSpeedListenable.value;
    final screenHeight = MediaQuery.of(context).size.height;
    final result = await showModalBottomSheet<double>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: speeds.map((speed) {
                  final selected = (speed - currentSpeed).abs() < 0.01;
                  return ListTile(
                    title: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: selected
                            ? AppColors.red
                            : (isDark ? AppColors.white : AppColors.black87),
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(speed),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
    if (result != null) {
      await widget.onSetSpeed(result);
    }
  }

  Future<void> _enterPipMode() async {
    // 隐藏控制栏
    setState(() => _controlsVisible = false);
    widget.onControlsVisibilityChanged(false);
    _hideTimer?.cancel();
    // 调用父层的 PIP 逻辑
    await widget.onEnterPipMode();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _showDownloadPanel() {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final playerHeight = screenWidth / (16 / 9);
    final panelHeight = screenHeight - statusBarHeight - playerHeight;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: AppColors.transparent,
      transitionDuration: AppDurations.instantTransition,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: AppColors.transparent,
            child: SizedBox(
              width: double.infinity,
              height: panelHeight,
              child: PlayerDownloadPanel(
                theme: theme,
                episodes: widget.episodes ?? [],
                episodesTitles: widget.episodesTitles ?? [],
                currentEpisodeIndex: widget.currentEpisodeIndex ?? 0,
                isReversed: false,
                onSingleEpisodeTap: (index) {
                  widget.onSingleEpisodeDownload?.call(index);
                },
                onBatchDownload: (indices) async {
                  await widget.onBatchEpisodesDownload?.call(indices);
                },
                onToggleOrder: () {},
              ),
            ),
          ),
        );
      },
    );
  }

  // 截图功能
  Future<void> _takeScreenshot() async {
    try {
      // 使用media_kit的screenshot方法获取真实的视频帧
      final screenshot = await widget.player.screenshot(format: AppStrings.screenshotFormatPng);

      if (screenshot != null && screenshot.isNotEmpty) {
        await _saveScreenshot(screenshot);
      } else {
        _showScreenshotToastMessage(AppStrings.screenshotFailed);
      }
    } catch (e) {
      _showScreenshotToastMessage('${AppStrings.screenshotFailed}: $e');
    }
  }

  // 保存截图
  Future<void> _saveScreenshot(Uint8List imageData) async {
    try {
      if (DeviceUtils.isMobile()) {
        // 移动端：保存到相册
        await _saveToGallery(imageData);
      } else {
        // PC端：保存到截图文件夹
        await _saveToScreenshotsFolder(imageData);
      }
    } catch (e) {
      _showScreenshotToastMessage('${AppStrings.saveFailed}: $e');
    }
  }

  // 保存到相册
  Future<void> _saveToGallery(Uint8List imageData) async {
    try {
      // 检查权限
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          _showScreenshotToastMessage(AppStrings.galleryPermissionRequired);
          return;
        }
      }

      // 保存到相册
      await Gal.putImageBytes(imageData);
      _showScreenshotToastMessage(AppStrings.screenshotSaved);
    } catch (e) {
      _showScreenshotToastMessage('${AppStrings.saveToGalleryFailed}: $e');
    }
  }

  // 保存到截图文件夹
  Future<void> _saveToScreenshotsFolder(Uint8List imageData) async {
    try {
      // 获取截图文件夹路径
      Directory screenshotsDir;

      if (Platform.isWindows) {
        // Windows平台：C:\Users\用户名\Pictures\Screenshots
        final userProfile = Platform.environment[AppConfig.envUserProfile];
        if (userProfile != null) {
          // 使用path包构建路径，避免反斜杠问题
          final picturesDir = path.join(userProfile, AppStrings.directoryPictures);
          screenshotsDir = Directory(path.join(picturesDir, AppStrings.directoryScreenshots));
        } else {
          //  fallback to documents directory if USERPROFILE is not available
          final documentsDir = await getApplicationDocumentsDirectory();
          screenshotsDir =
              Directory(path.join(documentsDir.path, AppStrings.directoryScreenshots));
        }
      } else if (Platform.isMacOS) {
        // macOS平台：~/Pictures/Screenshots
        final homeDir = Platform.environment[AppConfig.envHome];
        if (homeDir != null) {
          screenshotsDir =
              Directory(path.join(homeDir, AppStrings.directoryPictures, AppStrings.directoryScreenshots));
        } else {
          //  fallback to documents directory if HOME is not available
          final documentsDir = await getApplicationDocumentsDirectory();
          screenshotsDir =
              Directory(path.join(documentsDir.path, AppStrings.directoryScreenshots));
        }
      } else {
        // 其他平台：文档目录下的Screenshots文件夹
        final documentsDir = await getApplicationDocumentsDirectory();
        screenshotsDir = Directory(path.join(documentsDir.path, AppStrings.directoryScreenshots));
      }

      // 创建文件夹
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      // 生成文件名
      final fileName =
          '${AppStrings.screenshotFileNameTemplate}${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path.join(screenshotsDir.path, fileName));

      // 保存文件
      await file.writeAsBytes(imageData);

      // 验证文件是否存在
      if (await file.exists()) {
        _showScreenshotToastMessage(AppStrings.screenshotSaved);
      } else {
        _showScreenshotToastMessage(AppStrings.screenshotSaveFailed);
      }
    } catch (e) {
      // 尝试使用应用支持目录作为fallback
      try {
        final appSupportDir = await getApplicationSupportDirectory();
        final fallbackDir =
            Directory(path.join(appSupportDir.path, AppStrings.directoryScreenshots));
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        final fileName =
            '${AppStrings.screenshotFileNameTemplate}${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path.join(fallbackDir.path, fileName));
        await file.writeAsBytes(imageData);
        if (await file.exists()) {
          _showScreenshotToastMessage(AppStrings.screenshotSaved);
        } else {
          _showScreenshotToastMessage(AppStrings.screenshotSaveFailed);
        }
      } catch (fallbackError) {
        _showScreenshotToastMessage('${AppStrings.saveToFolderFailed}: $e');
      }
    }
  }

  // 显示截图提示
  void _showScreenshotToastMessage(String message) {
    setState(() {
      _screenshotToastMessage = message;
      _showScreenshotToast = true;
    });

    // 取消之前的定时器
    _screenshotToastTimer?.cancel();

    // 3秒后隐藏提示
    _screenshotToastTimer = Timer(AppDurations.toastDuration, () {
      if (mounted) {
        setState(() {
          _showScreenshotToast = false;
        });
      }
    });
  }

  // 构建截图提示组件
  Widget _buildScreenshotToast() {
    if (!_showScreenshotToast) return const SizedBox.shrink();

    return Positioned.fill(
      child: Center(
        child: Container(
          padding: AppDimens.buttonMdPadding,
          decoration: BoxDecoration(
            color: AppColors.overlayHeavy,
            borderRadius: AppDimens.radiusCircle8,
          ),
          child: Text(
            _screenshotToastMessage,
            style: TextStyle(
              color: AppColors.white,
              fontSize: AppDimens.fontSizeXl,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingVideo) {
      return Container(
        color: AppColors.overlayHeavy,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.white, strokeWidth: 3),
              Gap.h16,
              Text(AppStrings.loading,
                  style: TextStyle(color: AppColors.white, fontSize: AppDimens.fontSizeMd)),
            ],
          ),
        ),
      );
    }

    Widget content = Stack(
      children: [
        Positioned.fill(child: _buildGestureLayer()),
        _buildTopGradient(),
        _buildBottomGradient(),
        if (_isFullscreen) _buildCurrentTime(),
        _buildBackButton(),
        _buildNetdiskButton(),
        _buildCastButton(),
        _buildCenterPlayPause(),
        _buildProgressBar(),
        _buildBottomControls(),
        if (_isLongPressing && !_isLocked) _buildLongPressIndicator(),
        if (_isFullscreen && _showBrightnessIndicator && !_isLocked)
          _buildBrightnessIndicator(),
        if (_isFullscreen) _buildRightOverlay(),
        // 截图提示
        _buildScreenshotToast(),
      ],
    );

    if (_isFullscreen) {
      content = PopScope(
        canPop: !_isLocked,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && _isLocked) {
            setState(() {
              _isLocked = false;
              _controlsVisible = true;
            });
            _startHideTimer();
          }
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildGestureLayer() {
    return Positioned.fill(
      child: Row(
        children: [
          if (_isFullscreen)
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _toggleControlsVisibility,
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                onLongPressCancel: () {
                  if (_isLongPressing) {
                    _onLongPressEnd(const LongPressEndDetails());
                  }
                },
                onHorizontalDragStart: _onSwipeStart,
                onHorizontalDragUpdate: _onSwipeUpdate,
                onHorizontalDragEnd: _onSwipeEnd,
                onVerticalDragStart: _onBrightnessSwipeStart,
                onVerticalDragUpdate: _onBrightnessSwipeUpdate,
                onVerticalDragEnd: _onBrightnessSwipeEnd,
                behavior: HitTestBehavior.opaque,
              ),
            ),
          Expanded(
            flex: _isFullscreen ? 2 : 1,
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              onLongPressStart: _onLongPressStart,
              onLongPressEnd: _onLongPressEnd,
              onLongPressCancel: () {
                if (_isLongPressing) {
                  _onLongPressEnd(const LongPressEndDetails());
                }
              },
              onHorizontalDragStart: _onSwipeStart,
              onHorizontalDragUpdate: _onSwipeUpdate,
              onHorizontalDragEnd: _onSwipeEnd,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          if (_isFullscreen)
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _toggleControlsVisibility,
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                onLongPressCancel: () {
                  if (_isLongPressing) {
                    _onLongPressEnd(const LongPressEndDetails());
                  }
                },
                onHorizontalDragStart: _onSwipeStart,
                onHorizontalDragUpdate: _onSwipeUpdate,
                onHorizontalDragEnd: _onSwipeEnd,
                onVerticalDragStart: _onVolumeSwipeStart,
                onVerticalDragUpdate: _onVolumeSwipeUpdate,
                onVerticalDragEnd: _onVolumeSwipeEnd,
                behavior: HitTestBehavior.opaque,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          child: Container(
            height: _isFullscreen ? 120 : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.overlayMedium,
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTime() {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          child: Center(
            child: Text(
              _currentTime,
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppDimens.fontSizeXl,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          child: Container(
            height: _isFullscreen ? 140 : 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.overlayMedium,
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: _isFullscreen ? 8 : 4,
      left: _isFullscreen ? 16.0 : 8.0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          ignoring: !_controlsVisible || _isLocked,
          child: GestureDetector(
            onTap: () {
              _onUserInteraction();
              if (_isFullscreen) {
                _exitFullscreen();
              } else {
                widget.onBackPressed?.call();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: AppDimens.smallPadding,
              child: Icon(
                Icons.arrow_back,
                color: AppColors.white,
                size: _isFullscreen ? 24 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetdiskButton() {
    if (widget.isLocalFile) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: _isFullscreen ? 8 : 4,
      right: widget.isLocalFile
          ? (_isFullscreen ? 16.0 : 8.0)
          : (_isFullscreen ? 60.0 : 52.0),
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          ignoring: !_controlsVisible || _isLocked,
          child: GestureDetector(
            onTap: () {
              _onUserInteraction();
              widget.onNetdiskSearch?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: AppDimens.smallPadding,
              child: Icon(
                Icons.cloud,
                color: AppColors.white,
                size: _isFullscreen ? 24 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCastButton() {
    if (widget.isLocalFile) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: _isFullscreen ? 8 : 4,
      right: _isFullscreen ? 16.0 : 8.0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          ignoring: !_controlsVisible || _isLocked,
          child: GestureDetector(
            onTap: () async {
              _onUserInteraction();
              if (!widget.live && widget.player != null) {
                widget.player.pause();
              }
              await _showDLNADialog();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: AppDimens.smallPadding,
              child: Icon(
                Icons.cast,
                color: AppColors.white,
                size: _isFullscreen ? 24 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPlayPause() {
    return Positioned.fill(
      child: Center(
        child: AnimatedOpacity(
          opacity:
              (!_isLocked && (!_isPlaying || _controlsVisible)) ? 1.0 : 0.0,
          duration: AppDurations.normal,
          child: IgnorePointer(
            ignoring: _isLocked || (_isPlaying && !_controlsVisible),
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.white,
                size: _isFullscreen ? 64 : 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: _isFullscreen ? 58.0 : 42.0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          ignoring: !_controlsVisible || _isLocked,
          child: Container(
            height: AppDimens.playerProgressBarHeight,
            margin: AppDimens.horizontalLgPadding,
            child: _MobileVideoProgressBar(
              player: widget.player,
              live: widget.live,
              onDragStart: () {
                setState(() => _controlsVisible = true);
                _hideTimer?.cancel();
              },
              onDragEnd: () {
                setState(() => _dragPosition = null);
                _startHideTimer();
              },
              onDragUpdate: () {
                if (!_controlsVisible) {
                  setState(() => _controlsVisible = true);
                }
                _hideTimer?.cancel();
              },
              onPositionUpdate: (duration) {
                setState(() => _dragPosition = duration);
              },
              dragPosition: _dragPosition,
              isSeekingViaSwipe: _isSeekingViaSwipe,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final position = _dragPosition ?? _position;
    final duration = _duration;
    return Positioned(
      bottom: _isFullscreen ? AppDimens.bottomControlsFullscreenBottom : AppDimens.bottomControlsNonFullscreenBottom,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: (_controlsVisible && !_isLocked) ? 1.0 : 0.0,
        duration: AppDurations.normal,
        child: IgnorePointer(
          ignoring: !_controlsVisible || _isLocked,
          child: Padding(
            padding: _isFullscreen ? AppDimens.bottomControlsPaddingFullscreen : AppDimens.bottomControlsPaddingNonFullscreen,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayPause,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: _isFullscreen ? AppDimens.playerControlPlayButtonPadding : AppDimens.playerControlPlayButtonPaddingNarrow,
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: AppColors.white,
                      size: _isFullscreen ? AppDimens.iconLg : AppDimens.iconSize22,
                    ),
                  ),
                ),
                if (!widget.isLastEpisode && !widget.live)
                  GestureDetector(
                    onTap: () {
                      _onUserInteraction();
                      widget.onNextEpisode?.call();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                      child: Icon(
                        Icons.skip_next,
                        color: AppColors.white,
                        size: _isFullscreen ? AppDimens.iconLg : AppDimens.iconSize22,
                      ),
                    ),
                  ),
                if (!widget.live)
                  Expanded(
                    child: Padding(
                      padding: AppDimens.playerTimePadding,
                      child: Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style:
                            TextStyle(color: AppColors.white, fontSize: AppDimens.fontSizeXs),
                      ),
                    ),
                  ),
                if (widget.live) const Spacer(),
                if (!widget.live && !widget.isLocalFile)
                  GestureDetector(
                    onTap: () {
                      _onUserInteraction();
                      // 显示下载选集面板
                      _showDownloadPanel();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                      child: Icon(
                        Icons.download,
                        color: AppColors.white,
                        size: _isFullscreen ? AppDimens.iconSize20 : AppDimens.iconMd,
                      ),
                    ),
                  ),
                if (!widget.live && !widget.isLocalFile)
                  ValueListenableBuilder<bool>(
                    valueListenable: UserDataService.danmakuEnabledNotifier,
                    builder: (context, enabled, _) {
                      return GestureDetector(
                        onTap: _openDanmakuSettings,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                          child: Opacity(
                            opacity: enabled ? 1.0 : 0.4,
                            child: SvgPicture.asset(
                              'assets/images/danmu.svg',
                              width: _isFullscreen ? AppDimens.iconSize20 : AppDimens.iconMd,
                              height: _isFullscreen ? AppDimens.iconSize20 : AppDimens.iconMd,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (!widget.live)
                  GestureDetector(
                    onTap: () {
                      _onUserInteraction();
                      // 触发截图功能
                      _takeScreenshot();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                      child: Icon(
                        Icons.camera_alt,
                        color: AppColors.white,
                        size: _isFullscreen ? AppDimens.iconSize20 : AppDimens.iconMd,
                      ),
                    ),
                  ),
                if (!widget.live)
                  GestureDetector(
                    onTap: () async {
                      _onUserInteraction();
                      await _showSpeedDialog();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                      child: Icon(
                        Icons.speed,
                        color: AppColors.white,
                        size: _isFullscreen ? AppDimens.iconSize20 : AppDimens.iconMd,
                      ),
                    ),
                  ),
                if ((Platform.isAndroid || Platform.isIOS) && !_autoEnterPipEnabled)
                  GestureDetector(
                    onTap: () async {
                      _onUserInteraction();
                      await _enterPipMode();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                      child: Icon(
                        Icons.picture_in_picture_alt,
                        color: AppColors.white,
                        size: _isFullscreen ? AppDimens.iconSize20 : AppDimens.iconMd,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    _onUserInteraction();
                    if (_isFullscreen) {
                      _exitFullscreen();
                    } else {
                      _enterFullscreen();
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: _isFullscreen ? AppDimens.playerControlButtonPadding : AppDimens.playerControlButtonPaddingNarrow,
                    child: Icon(
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: AppColors.white,
                      size: _isFullscreen ? AppDimens.iconLg : AppDimens.iconSize22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLongPressIndicator() {
    return const Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppStrings.playbackSpeed2x,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimens.fontSizeXxl,
                  fontWeight: FontWeight.bold)),
          Gap.w6,
          Icon(Icons.fast_forward, color: AppColors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildBrightnessIndicator() {
    return Positioned(
      left: 16.0,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          padding: AppDimens.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.overlayHeavy,
            borderRadius: AppDimens.radiusCircle24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _currentBrightness < 0.5
                    ? Icons.brightness_low
                    : Icons.brightness_high,
                color: AppColors.white,
                size: AppDimens.iconLg,
              ),
              Gap.h8,
              SizedBox(
                height: 100,
                width: AppDimens.spacingXs,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.3),
                        borderRadius: AppDimens.radiusCircle2,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: _currentBrightness,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: AppDimens.radiusCircle2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Gap.h8,
              Text(
                '${(_currentBrightness * 100).round()}',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppDimens.fontSizeXs,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightOverlay() {
    if (_showVolumeIndicator && !_isLocked) {
      return Positioned(
        right: 16.0,
        top: 0,
        bottom: 0,
        child: Center(
          child: Container(
            padding: AppDimens.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.overlayHeavy,
              borderRadius: AppDimens.radiusCircle24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentVolume == 0
                      ? Icons.volume_off
                      : _currentVolume < 0.5
                          ? Icons.volume_down
                          : Icons.volume_up,
                  color: AppColors.white,
                  size: AppDimens.iconLg,
                ),
                Gap.h8,
                SizedBox(
                  height: 100,
                  width: AppDimens.spacingXs,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.3),
                          borderRadius: AppDimens.radiusCircle2,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: _currentVolume,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: AppDimens.radiusCircle2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.h8,
                Text(
                  '${(_currentVolume * 100).round()}',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: AppDimens.fontSizeXs,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      right: 16.0,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: AppDurations.normal,
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLocked = !_isLocked;
                  _controlsVisible = true;
                });
                _startHideTimer();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: AppDimens.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.overlayMedium,
                  borderRadius: AppDimens.radiusCircle24,
                ),
                child: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  color: AppColors.white,
                  size: AppDimens.iconLg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileVideoProgressBar extends StatefulWidget {
  final dynamic player;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragUpdate;
  final Function(Duration)? onPositionUpdate;
  final Duration? dragPosition;
  final bool isSeekingViaSwipe;
  final bool live;

  const _MobileVideoProgressBar({
    this.player,
    this.onDragStart,
    this.onDragEnd,
    this.onDragUpdate,
    this.onPositionUpdate,
    this.dragPosition,
    this.isSeekingViaSwipe = false,
    this.live = false,
  });

  @override
  State<_MobileVideoProgressBar> createState() =>
      _MobileVideoProgressBarState();
}

class _MobileVideoProgressBarState extends State<_MobileVideoProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _isSeeking = false; // 新增：标记是否正在 seek
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.player != null) {
      _positionSubscription = widget.player.stream.position.listen((_) {
          if (mounted && !_isDragging && !_isSeeking) {
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.player?.state?.duration ?? Duration.zero;
    final position = widget.dragPosition ??
        (widget.player?.state?.position ?? Duration.zero);

    double value = 0.0;
    if (duration.inMilliseconds > 0) {
      if (widget.live) {
        value = 1.0;
      } else {
        value = position.inMilliseconds / duration.inMilliseconds;
      }
    }

    if (_isDragging && !widget.live) {
      value = _dragValue;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: widget.live
          ? null
          : (details) {
              _isDragging = true;
              widget.onDragStart?.call();
              _updateDrag(details.localPosition.dx, context);
            },
      onHorizontalDragUpdate: widget.live
          ? null
          : (details) {
              if (_isDragging) {
                widget.onDragUpdate?.call();
                _updateDrag(details.localPosition.dx, context);
              }
            },
      onHorizontalDragEnd: widget.live
          ? null
          : (details) async {
              if (_isDragging && widget.player != null) {
                final seekPosition = Duration(
                  milliseconds: (_dragValue * duration.inMilliseconds).round(),
                );

                setState(() {
                  _isDragging = false;
                  _isSeeking = true; // 标记开始 seek
                });

                await widget.player.seek(seekPosition);

                // seek 完成后，延迟一小段时间再允许位置更新，确保播放器状态已同步
                await Future.delayed(AppDurations.fastest);

                if (mounted) {
                  setState(() {
                    _isSeeking = false; // 标记 seek 完成
                  });
                }

                widget.onDragEnd?.call();
              }
            },
      onTapDown: widget.live
          ? null
          : (details) async {
              if (widget.player != null) {
                widget.onDragStart?.call();
                _updateDrag(details.localPosition.dx, context);
                final seekPosition = Duration(
                  milliseconds: (_dragValue * duration.inMilliseconds).round(),
                );

                setState(() {
                  _isSeeking = true; // 标记开始 seek
                });

                await widget.player.seek(seekPosition);

                // seek 完成后，延迟一小段时间再允许位置更新，确保播放器状态已同步
                await Future.delayed(AppDurations.fastest);

                if (mounted) {
                  setState(() {
                    _isSeeking = false; // 标记 seek 完成
                  });
                }

                widget.onDragEnd?.call();
              }
            },
      child: Container(
        height: AppDimens.playerProgressBarHeight,
        color: AppColors.transparent,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progressWidth = constraints.maxWidth;
              final progressValue = value.clamp(0.0, 1.0);
              final thumbPosition = (progressValue * progressWidth)
                  .clamp(8.0, progressWidth - 8.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 9,
                    child: Container(
                      height: AppDimens.iconHeightSm,
                      decoration: BoxDecoration(
                        borderRadius: AppDimens.radiusCircle3,
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 9,
                    child: Container(
                      width: progressValue * progressWidth,
                      height: AppDimens.iconHeightSm,
                      decoration: BoxDecoration(
                        borderRadius: AppDimens.radiusCircle3,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                  if (!widget.live)
                    Positioned(
                      left: thumbPosition - 8,
                      top: 4,
                      child: AnimatedScale(
                        scale: widget.isSeekingViaSwipe ? 1.25 : 1.0,
                        duration: AppDurations.fast,
                        child: Container(
                          width: AppDimens.spacingLg,
                          height: AppDimens.spacingLg,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black30,
                                blurRadius: AppDimens.shadowBlur4,
                                offset: AppDimens.offset02,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _updateDrag(double dx, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final width = box.size.width;
    final value = (dx / width).clamp(0.0, 1.0);
    setState(() => _dragValue = value);
    if (!widget.live && widget.player != null) {
      final duration = widget.player.state?.duration ?? Duration.zero;
      final position =
          Duration(milliseconds: (value * duration.inMilliseconds).round());
      widget.onPositionUpdate?.call(position);
    }
  }
}
