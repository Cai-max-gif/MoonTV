import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/danmu_item.dart';
import '../constants/app_colors.dart';

class _RunningDanmu {
  final DanmuItem item;
  double x;
  double y;
  double displayDuration;
  final String text;
  final double textWidth;
  final Color color;
  final int trackIndex;
  final TextPainter? cachedTextPainter;
  final TextPainter? cachedShadowPainter;

  _RunningDanmu({
    required this.item,
    required this.x,
    required this.y,
    required this.displayDuration,
    required this.text,
    required this.textWidth,
    required this.color,
    required this.trackIndex,
    this.cachedTextPainter,
    this.cachedShadowPainter,
  });
}

class _DanmuTrack {
  double occupiedUntilX = -1;
}

class DanmuLayer extends StatefulWidget {
  final List<DanmuItem> danmuList;
  final ValueNotifier<double> currentTime;
  final double fontSize;
  final int speedLevel;
  final int opacity;
  final double displayArea;
  final bool antiOverlap;
  final bool visible;
  final bool syncVideoSpeed;
  final double videoPlaybackSpeed;

  const DanmuLayer({
    super.key,
    required this.danmuList,
    required this.currentTime,
    this.fontSize = 1.0,
    this.speedLevel = 2,
    this.opacity = 100,
    this.displayArea = 1.0,
    this.antiOverlap = true,
    this.visible = true,
    this.syncVideoSpeed = true,
    this.videoPlaybackSpeed = 1.0,
  });

  @override
  State<DanmuLayer> createState() => _DanmuLayerState();
}

class _DanmuLayerState extends State<DanmuLayer> with TickerProviderStateMixin {
  final List<_RunningDanmu> _runningDanmu = [];
  final List<_DanmuTrack> _tracks = [];
  late final Ticker _ticker;
  Duration _lastTickTime = Duration.zero;
  Size _screenSize = Size.zero;
  final double _baseFontSize = 24.0;
  int _currentTrackCount = 0;
  int _emittedCount = 0;

  static const int _maxRunningDanmu = 50;
  static const double _trackSpacing = 2.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.visible) {
      _ticker.start();
    }
    _resetDanmuState();
  }

  @override
  void didUpdateWidget(DanmuLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
    if (widget.danmuList != oldWidget.danmuList) {
      _resetDanmuState();
    }
    if (widget.currentTime != oldWidget.currentTime &&
        widget.currentTime.value < oldWidget.currentTime.value - 1.0) {
      _resetDanmuState();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (final danmu in _runningDanmu) {
      danmu.cachedTextPainter?.dispose();
      danmu.cachedShadowPainter?.dispose();
    }
    super.dispose();
  }

  void _resetDanmuState() {
    for (final danmu in _runningDanmu) {
      danmu.cachedTextPainter?.dispose();
      danmu.cachedShadowPainter?.dispose();
    }
    _runningDanmu.clear();
    _emittedCount = 0;
  }

  void _initTracks(double availableHeight, double lineHeight) {
    final trackCount = (availableHeight / lineHeight).floor().clamp(1, 30);
    if (trackCount == _currentTrackCount) return;
    _currentTrackCount = trackCount;
    _tracks.clear();
    for (int i = 0; i < trackCount; i++) {
      _tracks.add(_DanmuTrack());
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !widget.visible) return;

    final deltaSeconds = (_lastTickTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = elapsed;

    if (_screenSize.width <= 0 || _screenSize.height <= 0) return;

    final currentPlayTime = widget.currentTime.value;

    _initTracksIfNeeded();
    _emitNewDanmu(currentPlayTime);
    _updateRunningDanmu(deltaSeconds);
    _removeExpiredDanmu();

    setState(() {});
  }

  void _initTracksIfNeeded() {
    final availableHeight = _screenSize.height * widget.displayArea;
    final lineHeight = _baseFontSize * widget.fontSize * _trackSpacing;
    _initTracks(availableHeight, lineHeight);
  }

  int? _findBestTrack(double textWidth) {
    if (!widget.antiOverlap || _tracks.isEmpty) return null;

    int bestTrack = 0;
    double bestOccupied = double.infinity;

    for (int i = 0; i < _tracks.length; i++) {
      final track = _tracks[i];
      if (track.occupiedUntilX < bestOccupied) {
        bestOccupied = track.occupiedUntilX;
        bestTrack = i;
      }
    }

    return bestTrack;
  }

  void _emitNewDanmu(double currentPlayTime) {
    const tolerance = 0.1;
    const maxToEmit = 5;
    int emitted = 0;

    while (_emittedCount < widget.danmuList.length && emitted < maxToEmit) {
      final item = widget.danmuList[_emittedCount];

      if (item.time > currentPlayTime + tolerance) {
        break;
      }

      if (item.time < currentPlayTime - 5.0) {
        _emittedCount++;
        continue;
      }

      if (_runningDanmu.length >= _maxRunningDanmu) {
        _emittedCount++;
        break;
      }

      final fontSize = _baseFontSize * widget.fontSize;
      final color = item.color ?? AppColors.white;

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
          ),
        ),
      );
      textPainter.layout(maxWidth: _screenSize.width);
      final textWidth = textPainter.width;

      final shadowPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.overlayMedium,
          ),
        ),
      );
      shadowPainter.layout(maxWidth: _screenSize.width);

      if (item.mode == DanmuMode.scroll) {
        _emitScrollDanmu(item, textWidth, textPainter, shadowPainter);
      } else if (item.mode == DanmuMode.top) {
        _emitFixedDanmu(item, textWidth, textPainter, shadowPainter,
            isTop: true);
      } else if (item.mode == DanmuMode.bottom) {
        _emitFixedDanmu(item, textWidth, textPainter, shadowPainter,
            isTop: false);
      }

      _emittedCount++;
      emitted++;
    }
  }

  void _emitScrollDanmu(DanmuItem item, double textWidth,
      TextPainter textPainter, TextPainter shadowPainter) {
    final screenWidth = _screenSize.width;
    final lineHeight = _baseFontSize * widget.fontSize * _trackSpacing;
    final trackCount = _tracks.length;

    int? chosenTrack = _findBestTrack(textWidth);
    chosenTrack ??= Random().nextInt(trackCount.clamp(1, 30));

    final y = chosenTrack * lineHeight + lineHeight * 0.8;
    final x = screenWidth;

    final track = _tracks[chosenTrack];
    track.occupiedUntilX = x + textWidth;

    _runningDanmu.add(_RunningDanmu(
      item: item,
      x: x,
      y: y,
      displayDuration: 0,
      text: item.text,
      textWidth: textWidth,
      color: item.color ?? AppColors.white,
      trackIndex: chosenTrack,
      cachedTextPainter: textPainter,
      cachedShadowPainter: shadowPainter,
    ));
  }

  void _emitFixedDanmu(DanmuItem item, double textWidth,
      TextPainter textPainter, TextPainter shadowPainter,
      {required bool isTop}) {
    final screenWidth = _screenSize.width;
    final lineHeight = _baseFontSize * widget.fontSize * _trackSpacing;
    final trackCount = _tracks.length;

    int chosenTrack;
    double y;

    if (isTop) {
      chosenTrack = Random().nextInt(trackCount > 5 ? 5 : trackCount);
      y = chosenTrack * lineHeight + lineHeight * 0.8;
    } else {
      chosenTrack =
          trackCount - 1 - Random().nextInt(trackCount > 5 ? 5 : trackCount);
      y = chosenTrack * lineHeight + lineHeight * 0.8;
    }

    final x = (screenWidth - textWidth) / 2;

    _runningDanmu.add(_RunningDanmu(
      item: item,
      x: x,
      y: y,
      displayDuration: 3.0,
      text: item.text,
      textWidth: textWidth,
      color: item.color ?? AppColors.white,
      trackIndex: chosenTrack,
      cachedTextPainter: textPainter,
      cachedShadowPainter: shadowPainter,
    ));
  }

  void _updateRunningDanmu(double deltaSeconds) {
    final speedFactors = [0.5, 0.75, 1.0, 1.5, 2.0];
    final speed = speedFactors[widget.speedLevel.clamp(0, 4)];
    final videoSpeedMultiplier =
        widget.syncVideoSpeed ? widget.videoPlaybackSpeed : 1.0;
    final scrollSpeed =
        (120 + speed * 60) * deltaSeconds * videoSpeedMultiplier;

    for (final danmu in _runningDanmu) {
      if (danmu.item.mode == DanmuMode.scroll) {
        danmu.x -= scrollSpeed;
        if (widget.antiOverlap && danmu.trackIndex < _tracks.length) {
          _tracks[danmu.trackIndex].occupiedUntilX = danmu.x + danmu.textWidth;
        }
      } else {
        danmu.displayDuration -= deltaSeconds;
      }
    }
  }

  void _removeExpiredDanmu() {
    _runningDanmu.removeWhere((danmu) {
      bool expired = false;
      if (danmu.item.mode == DanmuMode.scroll) {
        expired = danmu.x + danmu.textWidth < 0;
      } else {
        expired = danmu.displayDuration <= 0;
      }

      if (expired) {
        if (danmu.trackIndex < _tracks.length) {
          final track = _tracks[danmu.trackIndex];
          if (track.occupiedUntilX >= danmu.x) {
            track.occupiedUntilX = -1;
          }
        }
        danmu.cachedTextPainter?.dispose();
        danmu.cachedShadowPainter?.dispose();
      }
      return expired;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.danmuList.isEmpty || widget.opacity == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        return ClipRect(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DanmuPainter(
                runningDanmu: _runningDanmu,
                opacity: widget.opacity / 100.0,
                fontSize: _baseFontSize * widget.fontSize,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
        );
      },
    );
  }
}

class _DanmuPainter extends CustomPainter {
  final List<_RunningDanmu> runningDanmu;
  final double opacity;
  final double fontSize;

  _DanmuPainter({
    required this.runningDanmu,
    required this.opacity,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final danmu in runningDanmu) {
      final alpha = danmu.item.mode == DanmuMode.scroll
          ? opacity
          : min(opacity, danmu.displayDuration / 3.0).clamp(0.0, opacity);

      if (danmu.cachedShadowPainter != null) {
        final shadowPainter = danmu.cachedShadowPainter!;
        final shadowColor = AppColors.black.withValues(alpha: alpha * 0.5);
        shadowPainter.text = TextSpan(
          text: danmu.text,
          style: (shadowPainter.text as TextSpan?)
                  ?.style
                  ?.copyWith(color: shadowColor) ??
              TextStyle(
                fontSize: fontSize,
                color: shadowColor,
              ),
        );
        shadowPainter.layout();
        shadowPainter.paint(canvas, Offset(danmu.x + 1, danmu.y + 1));
        shadowPainter.paint(canvas, Offset(danmu.x - 1, danmu.y - 1));
        shadowPainter.paint(canvas, Offset(danmu.x, danmu.y - 1));
      }

      if (danmu.cachedTextPainter != null) {
        final textPainter = danmu.cachedTextPainter!;
        final textColor = danmu.color.withValues(alpha: alpha);
        textPainter.text = TextSpan(
          text: danmu.text,
          style: (textPainter.text as TextSpan?)
                  ?.style
                  ?.copyWith(color: textColor) ??
              TextStyle(
                fontSize: fontSize,
                color: textColor,
              ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(danmu.x, danmu.y));
      }
    }
  }

  @override
  bool shouldRepaint(_DanmuPainter oldDelegate) {
    return true;
  }
}
