import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import '../constants/app_strings.dart';
import 'package:pip/pip.dart';
import '../services/user_data_service.dart';
import 'mobile_player_controls.dart';
import 'pc_player_controls.dart';
import 'video_player_surface.dart';

// 只在 PC 平台导入 media_kit 库
import 'package:media_kit/media_kit.dart' if (dart.library.html) 'dart:html';
import 'package:media_kit_video/media_kit_video.dart'
    if (dart.library.html) 'dart:html';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerSurface surface;
  final String? url;
  final Map<String, String>? headers;
  final VoidCallback? onBackPressed;
  final Function(VideoPlayerWidgetController)? onControllerCreated;
  final VoidCallback? onReady;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onVideoCompleted;
  final VoidCallback? onPause;
  final bool isLastEpisode;
  final Function(dynamic)? onCastStarted;
  final String? videoTitle;
  final int? currentEpisodeIndex;
  final int? totalEpisodes;
  final String? sourceName;
  final Function(bool isWebFullscreen)? onWebFullscreenChanged;
  final VoidCallback? onExitFullScreen;
  final bool live;
  final Function(bool isPipMode)? onPipModeChanged;
  final Function(String error)? onError;
  final List<String>? episodes;
  final List<String>? episodesTitles;
  final Function(int episodeIndex)? onSingleEpisodeDownload;
  final Future<void> Function(List<int> episodeIndices)?
      onBatchEpisodesDownload;
  final VoidCallback? onDanmakuSettings;
  final bool isLocalFile;
  final VoidCallback? onNetdiskSearch;
  final Widget Function()? danmuOverlayBuilder;
  final Function(VideoState?)? onVideoStateChanged;

  const VideoPlayerWidget({
    super.key,
    this.surface = VideoPlayerSurface.mobile,
    this.url,
    this.headers,
    this.onBackPressed,
    this.onControllerCreated,
    this.onReady,
    this.onNextEpisode,
    this.onVideoCompleted,
    this.onPause,
    this.isLastEpisode = false,
    this.onCastStarted,
    this.videoTitle,
    this.currentEpisodeIndex,
    this.totalEpisodes,
    this.sourceName,
    this.onWebFullscreenChanged,
    this.onExitFullScreen,
    this.live = false,
    this.onPipModeChanged,
    this.onError,
    this.episodes,
    this.episodesTitles,
    this.onSingleEpisodeDownload,
    this.onBatchEpisodesDownload,
    this.onDanmakuSettings,
    this.isLocalFile = false,
    this.onNetdiskSearch,
    this.danmuOverlayBuilder,
    this.onVideoStateChanged,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class VideoPlayerWidgetController {
  VideoPlayerWidgetController._(this._state);
  final _VideoPlayerWidgetState _state;

  Future<void> updateDataSource(
    String url, {
    Duration? startAt,
    Map<String, String>? headers,
  }) async {
    await _state._updateDataSource(
      url,
      startAt: startAt,
      headers: headers,
    );
  }

  Future<void> seekTo(Duration position) async {
    await _state._player?.seek(position);
  }

  Duration? get currentPosition => _state._player?.state.position;

  Duration? get duration => _state._player?.state.duration;

  bool get isPlaying => _state._player?.state.playing ?? false;

  Future<void> pause() async {
    if (_state._playerDisposed) return;
    await _state._player?.pause();
  }

  Future<void> play() async {
    await _state._player?.play();
  }

  void addProgressListener(VoidCallback listener) {
    _state._addProgressListener(listener);
  }

  void removeProgressListener(VoidCallback listener) {
    _state._removeProgressListener(listener);
  }

  Future<void> setSpeed(double speed) async {
    await _state._setPlaybackSpeed(speed);
  }

  double get playbackSpeed => _state._playbackSpeed.value;

  Future<void> setVolume(double volume) async {
    await _state._player?.setVolume(volume);
  }

  double? get volume => _state._player?.state.volume;

  void exitWebFullscreen() {
    _state._exitWebFullscreen();
  }

  Future<void> dispose() async {
    await _state._externalDispose();
  }

  bool get isPipMode => _state._isPipMode;
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  // 只在 PC 平台使用 media_kit
  dynamic _player;
  dynamic _videoController;
  bool _isInitialized = false;
  bool _hasCompleted = false;
  bool _isLoadingVideo = false;
  String? _currentUrl;
  Map<String, String>? _currentHeaders;
  final List<VoidCallback> _progressListeners = [];
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  final ValueNotifier<double> _playbackSpeed = ValueNotifier<double>(1.0);
  bool _playerDisposed = false;
  VoidCallback? _exitWebFullscreenCallback;
  final Pip _pip = Pip();
  bool _isPipMode = false;
  bool _autoSkipOpeningEnding = false;
  int _skipOpeningDuration = 0;
  int _skipEndingDuration = 0;
  bool _hasSkippedOpening = false;
  bool _hasSkippedEnding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUrl = widget.url;
    _currentHeaders = widget.headers;
    _loadDefaultPlaybackSpeed();
    _loadAutoSkipSettings();
    _initializePlayer();
    unawaited(_setupPip());
    _registerPipObserver();
    widget.onControllerCreated?.call(VideoPlayerWidgetController._(this));
  }

  Future<void> _loadAutoSkipSettings() async {
    _autoSkipOpeningEnding = await UserDataService.getAutoSkipOpeningEnding();
    _skipOpeningDuration = await UserDataService.getSkipOpeningDuration();
    _skipEndingDuration = await UserDataService.getSkipEndingDuration();
  }

  Future<void> _loadDefaultPlaybackSpeed() async {
    final speed = await UserDataService.getDefaultPlaybackSpeed();
    _playbackSpeed.value = speed;
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.headers != oldWidget.headers && widget.headers != null) {
      _currentHeaders = widget.headers;
    }
    if (widget.url != oldWidget.url && widget.url != null) {
      unawaited(_updateDataSource(widget.url!));
    }
  }

  Future<void> _initializePlayer() async {
    if (_playerDisposed) {
      return;
    }
    try {
      _player = Player(
        configuration: PlayerConfiguration(
          title: AppConfig.appName,
        ),
      );
      _videoController = VideoController(_player!);
      _setupPlayerListeners();
      if (_currentUrl != null) {
        await _openCurrentMedia();
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isInitialized = true;
      });
      widget.onError?.call(AppStrings.networkError);
    }
  }

  Future<void> _openCurrentMedia({Duration? startAt}) async {
    if (_playerDisposed || _player == null || _currentUrl == null) {
      return;
    }
    setState(() {
      _isLoadingVideo = true;
    });
    try {
      await _player!.open(
        Media(
          _currentUrl!,
          start: startAt,
          httpHeaders: _currentHeaders ?? const <String, String>{},
        ),
        play: true,
      );
      await _player!.setRate(_playbackSpeed.value);
      setState(() {
        _hasCompleted = false;
        _isLoadingVideo = false;
      });
      widget.onReady?.call();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
        });
        widget.onError?.call(error.toString());
      }
    }
  }

  void _setupPlayerListeners() {
    if (_player == null) {
      return;
    }
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _durationSubscription?.cancel();

    _positionSubscription = _player!.stream.position.listen((position) {
      if (_playerDisposed || _player == null) return;
      for (final listener in List<VoidCallback>.from(_progressListeners)) {
        listener();
      }

      if (_autoSkipOpeningEnding && _player != null && !_playerDisposed) {
        final duration = _player!.state.duration;
        if (duration != Duration.zero) {
          // 跳过片头
          if (!_hasSkippedOpening &&
              _skipOpeningDuration > 0 &&
              position <= AppDurations.oneSecond) {
            _hasSkippedOpening = true;
            _player!.seek(Duration(seconds: _skipOpeningDuration));
          }

          // 跳过片尾
          if (!_hasSkippedEnding && _skipEndingDuration > 0) {
            final endPosition =
                duration - Duration(seconds: _skipEndingDuration);
            if (position >= endPosition) {
              _hasSkippedEnding = true;
              _player!.seek(duration);
            }
          }
        }
      }
    });

    _playingSubscription = _player!.stream.playing.listen((playing) async {
      if (!mounted || _playerDisposed || _player == null) return;
      if (!playing) {
        setState(() {
          _hasCompleted = false;
        });
        if (Platform.isAndroid || Platform.isIOS) {
          final autoEnter =
              await UserDataService.getAutoEnterPictureInPicture();
          _pip.setup(PipOptions(
            autoEnterEnabled: autoEnter,
            aspectRatioX: 16,
            aspectRatioY: 9,
            preferredContentWidth: 480,
            preferredContentHeight: 270,
            controlStyle: 2,
          ));
        }
      } else {
        if (Platform.isAndroid || Platform.isIOS) {
          final autoEnter =
              await UserDataService.getAutoEnterPictureInPicture();
          _pip.setup(PipOptions(
            autoEnterEnabled: autoEnter,
            aspectRatioX: 16,
            aspectRatioY: 9,
            preferredContentWidth: 480,
            preferredContentHeight: 270,
            controlStyle: 2,
          ));
        }
      }
    });

    if (!widget.live) {
      _completedSubscription = _player!.stream.completed.listen((completed) async {
        if (!mounted || _playerDisposed || _player == null) return;
        if (completed && !_hasCompleted) {
          // 验证播放位置是否真的接近视频结尾
          // 防止因网络问题或缓冲问题导致的误触发
          final position = _player!.state.position;
          final duration = _player!.state.duration;

          // 只有当播放位置在视频最后 5 秒内，或者 duration 为 0 时才认为是真正的播放完成
          if (duration == Duration.zero ||
              position >= duration - AppDurations.healthCheckTimeout) {
            _hasCompleted = true;
            widget.onVideoCompleted?.call();
          } else {
          }
        }
      });
    }

    _durationSubscription = _player!.stream.duration.listen((duration) {
      if (!mounted || _playerDisposed || _player == null) return;
      if (duration != Duration.zero) {
        if (_isLoadingVideo) {
          setState(() {
            _isLoadingVideo = false;
          });
        }
        widget.onReady?.call();
      }
    });
  }

  Future<void> _updateDataSource(
    String url, {
    Duration? startAt,
    Map<String, String>? headers,
  }) async {
    if (_playerDisposed) {
      return;
    }
    _currentUrl = url;
    if (headers != null) {
      _currentHeaders = headers;
    }

    // 重置跳过标记
    _hasSkippedOpening = false;
    _hasSkippedEnding = false;

    if (_player == null) {
      await _initializePlayer();
      return;
    }

    setState(() {
      _isLoadingVideo = true;
    });

    try {
      final currentSpeed = _player!.state.rate;
      await _player!.open(
        Media(
          url,
          start: startAt,
          httpHeaders: _currentHeaders ?? const <String, String>{},
        ),
        play: true,
      );
      _playbackSpeed.value = currentSpeed;
      await _player!.setRate(currentSpeed);
      if (mounted) {
        setState(() {
          _hasCompleted = false;
          // _isLoadingVideo = false;
        });
      }
      // widget.onReady?.call();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
        });
      }
    }
  }

  void _addProgressListener(VoidCallback listener) {
    if (!_progressListeners.contains(listener)) {
      _progressListeners.add(listener);
    }
  }

  void _removeProgressListener(VoidCallback listener) {
    _progressListeners.remove(listener);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    _playbackSpeed.value = speed;
    if (_player != null) {
      await _player?.setRate(speed);
    }
    // 保存倍速设置到 UserDataService
    await UserDataService.saveDefaultPlaybackSpeed(speed);
  }

  void _exitWebFullscreen() {
    _exitWebFullscreenCallback?.call();
  }

  Future<void> _setupPip() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    final autoEnter = await UserDataService.getAutoEnterPictureInPicture();
    _pip.setup(PipOptions(
      autoEnterEnabled: autoEnter,
      aspectRatioX: 16,
      aspectRatioY: 9,
      preferredContentWidth: 480,
      preferredContentHeight: 270,
      controlStyle: 2,
    ));
  }

  void _registerPipObserver() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    _pip.registerStateChangedObserver(PipStateChangedObserver(
      onPipStateChanged: (state, error) {
        if (!mounted) return;
        switch (state) {
          case PipState.pipStateStarted:
            if (mounted) {
              setState(() => _isPipMode = true);
              widget.onPipModeChanged?.call(true);
            }
            break;
          case PipState.pipStateStopped:
            if (mounted) {
              setState(() {
                _isPipMode = false;
              });
              widget.onPipModeChanged?.call(false);
            }
            break;
          case PipState.pipStateFailed:
            if (mounted) {
              setState(() => _isPipMode = false);
              widget.onPipModeChanged?.call(false);
            }
            break;
        }
      },
    ));
  }

  Future<void> _enterPipMode() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      var support = await _pip.isSupported();
      if (!support) {
        return;
      }
      if (_player != null) {
        await _player?.play();
      }
      await _pip.start();
    } catch (e) {
      _setupPip();
    }
  }

  Future<void> _externalDispose() async {
    if (!mounted || _playerDisposed) {
      return;
    }
    await _disposePlayer();
  }

  Future<void> _disposePlayer() async {
    if (_playerDisposed) {
      return;
    }
    _playerDisposed = true;

    // 1. 先取消所有订阅
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription = null;
    _playingSubscription = null;
    _completedSubscription = null;
    _durationSubscription = null;
    _progressListeners.clear();

    final player = _player;
    final videoController = _videoController;
    _player = null;
    _videoController = null;

    if (player != null) {
      // 2. 先暂停播放
      await player.pause();

      // 3. 先释放 VideoController
      videoController?.dispose();

      // 4. 最后释放 Player
      await player.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_player == null || _playerDisposed) {
      return;
    }
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 应用进入后台时，检查是否启用了自动进入画中画
        _checkAutoEnterPictureInPicture();
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _checkAutoEnterPictureInPicture() async {
    final autoEnter = await UserDataService.getAutoEnterPictureInPicture();
    if (autoEnter && !_isPipMode) {
      await _enterPipMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid || Platform.isIOS) {
      _pip.unregisterStateChangedObserver();
      _pip.dispose();
    }
    // 释放播放器资源（不等待，避免阻塞 dispose）
    _disposePlayer();
    _playbackSpeed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: _isInitialized
          ? _videoController != null && _player != null
              ? Video(
                  controller: _videoController!,
                  controls: (state) {
                    // 保存 VideoState 引用（只在非全屏路由时保存）
                    if (!state.isFullscreen()) {
                      widget.onVideoStateChanged?.call(state);
                    }
                    final danmuOverlay = widget.danmuOverlayBuilder?.call();
                    final controls =
                        widget.surface == VideoPlayerSurface.desktop
                            ? PCPlayerControls(
                                state: state,
                                player: _player!,
                                onBackPressed: widget.onBackPressed,
                                onNextEpisode: widget.onNextEpisode,
                                onPause: widget.onPause,
                                videoUrl: _currentUrl ?? '',
                                isLastEpisode: widget.isLastEpisode,
                                isLoadingVideo: _isLoadingVideo,
                                onCastStarted: widget.onCastStarted,
                                videoTitle: widget.videoTitle,
                                currentEpisodeIndex: widget.currentEpisodeIndex,
                                totalEpisodes: widget.totalEpisodes,
                                sourceName: widget.sourceName,
                                onWebFullscreenChanged:
                                    widget.onWebFullscreenChanged,
                                onExitWebFullscreenCallbackReady: (callback) {
                                  _exitWebFullscreenCallback = callback;
                                },
                                onExitFullScreen: widget.onExitFullScreen,
                                live: widget.live,
                                playbackSpeedListenable: _playbackSpeed,
                                onSetSpeed: _setPlaybackSpeed,
                                episodes: widget.episodes,
                                episodesTitles: widget.episodesTitles,
                                onSingleEpisodeDownload:
                                    widget.onSingleEpisodeDownload,
                                onBatchEpisodesDownload:
                                    widget.onBatchEpisodesDownload,
                                onDanmakuSettings: widget.onDanmakuSettings,
                                isLocalFile: widget.isLocalFile,
                                onNetdiskSearch: widget.onNetdiskSearch,
                              )
                            : MobilePlayerControls(
                                player: _player!,
                                state: state,
                                onControlsVisibilityChanged: (_) {},
                                onBackPressed: widget.onBackPressed,
                                onFullscreenChange: (_) {},
                                onNextEpisode: widget.onNextEpisode,
                                onPause: widget.onPause,
                                videoUrl: _currentUrl ?? '',
                                isLastEpisode: widget.isLastEpisode,
                                isLoadingVideo: _isLoadingVideo,
                                onCastStarted: widget.onCastStarted,
                                videoTitle: widget.videoTitle,
                                currentEpisodeIndex: widget.currentEpisodeIndex,
                                totalEpisodes: widget.totalEpisodes,
                                sourceName: widget.sourceName,
                                onExitFullScreen: widget.onExitFullScreen,
                                live: widget.live,
                                playbackSpeedListenable: _playbackSpeed,
                                onSetSpeed: _setPlaybackSpeed,
                                onEnterPipMode: _enterPipMode,
                                isPipMode: _isPipMode,
                                episodes: widget.episodes,
                                episodesTitles: widget.episodesTitles,
                                onSingleEpisodeDownload:
                                    widget.onSingleEpisodeDownload,
                                onBatchEpisodesDownload:
                                    widget.onBatchEpisodesDownload,
                                onDanmakuSettings: widget.onDanmakuSettings,
                                isLocalFile: widget.isLocalFile,
                                onNetdiskSearch: widget.onNetdiskSearch,
                              );
                    if (danmuOverlay == null) return controls;
                    return SizedBox.expand(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(child: danmuOverlay),
                          ),
                          Positioned.fill(child: controls),
                        ],
                      ),
                    );
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                  ),
                )
          : const Center(
              child: CircularProgressIndicator(
                color: AppColors.white,
              ),
            ),
    );
  }
}
