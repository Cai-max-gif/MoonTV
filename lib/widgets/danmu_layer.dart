import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/danmu_item.dart';

class _RunningDanmu {
  final DanmuItem item;
  double x;
  double y;
  double displayDuration;
  final String text;
  final double textWidth;
  final Color color;
  final int trackIndex;

  _RunningDanmu({
    required this.item,
    required this.x,
    required this.y,
    required this.displayDuration,
    required this.text,
    required this.textWidth,
    required this.color,
    required this.trackIndex,
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
    super.dispose();
  }

  void _resetDanmuState() {
    _runningDanmu.clear();
    _emittedCount = 0;
  }

  void _initTracks(double availableHeight, double lineHeight) {
    final trackCount = (availableHeight / lineHeight).floor().clamp(1, 50);
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

    if (_runningDanmu.isNotEmpty || _emittedCount < widget.danmuList.length) {
      setState(() {});
    }
  }

  void _initTracksIfNeeded() {
    final availableHeight = _screenSize.height * widget.displayArea;
    final lineHeight = _baseFontSize * widget.fontSize * 1.8;
    _initTracks(availableHeight, lineHeight);
  }

  void _emitNewDanmu(double currentPlayTime) {
    while (_emittedCount < widget.danmuList.length) {
      final item = widget.danmuList[_emittedCount];

      if (item.time > currentPlayTime) break;

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: _baseFontSize * widget.fontSize,
            color: item.color ?? Colors.white,
          ),
        ),
      );
      textPainter.layout();
      final textWidth = textPainter.width;

      _emittedCount++;

      if (item.mode == DanmuMode.scroll) {
        _emitScrollDanmu(item, textWidth);
      } else if (item.mode == DanmuMode.top) {
        _emitFixedDanmu(item, textWidth, isTop: true);
      } else if (item.mode == DanmuMode.bottom) {
        _emitFixedDanmu(item, textWidth, isTop: false);
      }
    }
  }

  void _emitScrollDanmu(DanmuItem item, double textWidth) {
    final screenWidth = _screenSize.width;
    final lineHeight = _baseFontSize * widget.fontSize * 1.8;
    final trackCount = _tracks.length;

    int? chosenTrack;

    if (widget.antiOverlap && trackCount > 0) {
      for (int attempt = 0; attempt < trackCount; attempt++) {
        final trackIndex = (attempt + item.time.toInt()) % trackCount;
        final track = _tracks[trackIndex];
        if (track.occupiedUntilX < 0) {
          chosenTrack = trackIndex;
          break;
        }
      }
    }

    chosenTrack ??= Random().nextInt(trackCount.clamp(1, 50));

    final y = chosenTrack * lineHeight + lineHeight * 0.8;
    final x = screenWidth;

    final track = _tracks[chosenTrack];
    track.occupiedUntilX = x + textWidth - screenWidth * 0.3;

    _runningDanmu.add(_RunningDanmu(
      item: item,
      x: x,
      y: y,
      displayDuration: 0,
      text: item.text,
      textWidth: textWidth,
      color: item.color ?? Colors.white,
      trackIndex: chosenTrack,
    ));
  }

  void _emitFixedDanmu(DanmuItem item, double textWidth,
      {required bool isTop}) {
    final screenWidth = _screenSize.width;
    final lineHeight = _baseFontSize * widget.fontSize * 1.8;
    final trackCount = _tracks.length;

    int chosenTrack;
    double y;

    if (isTop) {
      chosenTrack = _emittedCount % (trackCount.clamp(1, 10));
      y = chosenTrack * lineHeight + lineHeight * 0.8;
    } else {
      chosenTrack =
          trackCount - 1 - (_emittedCount % (trackCount.clamp(1, 10)));
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
      color: item.color ?? Colors.white,
      trackIndex: chosenTrack,
    ));
  }

  void _updateRunningDanmu(double deltaSeconds) {
    final speedFactors = [0.5, 0.75, 1.0, 1.5, 2.0];
    final speed = speedFactors[widget.speedLevel.clamp(0, 4)];
    final videoSpeedMultiplier =
        widget.syncVideoSpeed ? widget.videoPlaybackSpeed : 1.0;
    final scrollSpeed =
        (100 + speed * 50) * deltaSeconds * videoSpeedMultiplier;

    for (final danmu in _runningDanmu) {
      if (danmu.item.mode == DanmuMode.scroll) {
        danmu.x -= scrollSpeed;
        if (widget.antiOverlap && danmu.trackIndex < _tracks.length) {
          _tracks[danmu.trackIndex].occupiedUntilX =
              danmu.x + danmu.textWidth - _screenSize.width * 0.3;
        }
      } else {
        danmu.displayDuration -= deltaSeconds;
      }
    }
  }

  void _removeExpiredDanmu() {
    _runningDanmu.removeWhere((danmu) {
      if (danmu.item.mode == DanmuMode.scroll) {
        final expired = danmu.x + danmu.textWidth < 0;
        if (expired && danmu.trackIndex < _tracks.length) {
          _tracks[danmu.trackIndex].occupiedUntilX = -1;
        }
        return expired;
      } else {
        final expired = danmu.displayDuration <= 0;
        if (expired && danmu.trackIndex < _tracks.length) {
          _tracks[danmu.trackIndex].occupiedUntilX = -1;
        }
        return expired;
      }
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

      final shadowPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: danmu.text,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.black.withValues(alpha: alpha * 0.5),
          ),
        ),
      );
      shadowPainter.layout(maxWidth: size.width);

      shadowPainter.paint(canvas, Offset(danmu.x + 1, danmu.y + 1));
      shadowPainter.paint(canvas, Offset(danmu.x - 1, danmu.y - 1));
      shadowPainter.paint(canvas, Offset(danmu.x, danmu.y - 1));

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: danmu.text,
          style: TextStyle(
            fontSize: fontSize,
            color: danmu.color.withValues(alpha: alpha),
          ),
        ),
      );
      textPainter.layout(maxWidth: size.width);
      textPainter.paint(canvas, Offset(danmu.x, danmu.y));
    }
  }

  @override
  bool shouldRepaint(_DanmuPainter oldDelegate) {
    return true;
  }
}
