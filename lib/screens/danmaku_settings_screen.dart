import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/user_data_service.dart';
import '../utils/font_utils.dart';

class HollowRoundSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const HollowRoundSliderThumbShape({this.thumbRadius = 10});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, thumbRadius, paint);
  }
}

class DanmakuSettingsScreen extends StatefulWidget {
  const DanmakuSettingsScreen({super.key});

  @override
  State<DanmakuSettingsScreen> createState() => _DanmakuSettingsScreenState();
}

class _DanmakuSettingsScreenState extends State<DanmakuSettingsScreen> {
  bool _danmakuEnabled = true;
  double _danmakuSpeed = 1.0;
  double _danmakuOpacity = 1.0;
  double _danmakuFontSize = 1.0;
  double _danmakuDisplayArea = 1.0;
  int _danmakuMaxCount = 100;
  bool _danmakuAntiBlock = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await UserDataService.getDanmakuEnabled();
    final speed = await UserDataService.getDanmakuSpeed();
    final opacity = await UserDataService.getDanmakuOpacity();
    final fontSize = await UserDataService.getDanmakuFontSize();
    final displayArea = await UserDataService.getDanmakuDisplayArea();
    final maxCount = await UserDataService.getDanmakuMaxCount();
    final antiBlock = await UserDataService.getDanmakuAntiBlock();

    if (mounted) {
      setState(() {
        _danmakuEnabled = enabled;
        _danmakuSpeed = speed.clamp(0.5, 2.0);
        _danmakuOpacity = opacity.clamp(0.1, 1.0);
        _danmakuFontSize = fontSize.clamp(0.5, 2.0);
        _danmakuDisplayArea = displayArea.clamp(0.25, 1.0);
        _danmakuMaxCount = maxCount.clamp(10, 500);
        _danmakuAntiBlock = antiBlock;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '弹幕设置',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildDanmakuEnabledCard(isDarkMode),
          const SizedBox(height: 12),
          _buildDanmakuSpeedCard(isDarkMode),
          const SizedBox(height: 12),
          _buildDanmakuOpacityCard(isDarkMode),
          const SizedBox(height: 12),
          _buildDanmakuFontSizeCard(isDarkMode),
          const SizedBox(height: 12),
          _buildDanmakuDisplayAreaCard(isDarkMode),
          const SizedBox(height: 12),
          _buildDanmakuMaxCountCard(isDarkMode),
          const SizedBox(height: 12),
          _buildDanmakuAntiBlockCard(isDarkMode),
          const SizedBox(height: 16),
          _buildHintCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDanmakuEnabledCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.messageSquare,
                size: 24,
                color: Color(0xFFec4899),
              ),
              const SizedBox(width: 12),
              Text(
                '弹幕开关',
                style: FontUtils.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                ),
              ),
            ],
          ),
          Switch(
            value: _danmakuEnabled,
            onChanged: (value) {
              setState(() {
                _danmakuEnabled = value;
              });
              UserDataService.saveDanmakuEnabled(value);
            },
            activeThumbColor: const Color(0xFFec4899),
            inactiveTrackColor:
                isDarkMode ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
          ),
        ],
      ),
    );
  }

  Widget _buildDanmakuSpeedCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _danmakuEnabled ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.gauge,
                  size: 24,
                  color: Color(0xFFf59e0b),
                ),
                const SizedBox(width: 12),
                Text(
                  '弹幕速度',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_danmakuSpeed.toStringAsFixed(1)}x',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFf59e0b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '0.5x',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 20.0,
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: const Color(0xFFf59e0b),
                      activeTrackColor: const Color(0xFFf59e0b),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuSpeed =
                                    (value * 10).roundToDouble() / 10;
                              });
                            }
                          : null,
                      onChangeEnd: _danmakuEnabled
                          ? (value) {
                              UserDataService.saveDanmakuSpeed(_danmakuSpeed);
                            }
                          : null,
                    ),
                  ),
                ),
                Text(
                  '2.0x',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanmakuOpacityCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _danmakuEnabled ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.eye,
                  size: 24,
                  color: Color(0xFF3b82f6),
                ),
                const SizedBox(width: 12),
                Text(
                  '弹幕透明度',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_danmakuOpacity * 100).round()}%',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3b82f6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '10%',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 20.0,
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: const Color(0xFF3b82f6),
                      activeTrackColor: const Color(0xFF3b82f6),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuOpacity =
                                    (value * 10).roundToDouble() / 10;
                              });
                            }
                          : null,
                      onChangeEnd: _danmakuEnabled
                          ? (value) {
                              UserDataService.saveDanmakuOpacity(
                                  _danmakuOpacity);
                            }
                          : null,
                    ),
                  ),
                ),
                Text(
                  '100%',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanmakuFontSizeCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _danmakuEnabled ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.type,
                  size: 24,
                  color: Color(0xFF10b981),
                ),
                const SizedBox(width: 12),
                Text(
                  '弹幕字体大小',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_danmakuFontSize.toStringAsFixed(1)}x',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10b981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '0.5x',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 20.0,
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: const Color(0xFF10b981),
                      activeTrackColor: const Color(0xFF10b981),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuFontSize,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuFontSize =
                                    (value * 10).roundToDouble() / 10;
                              });
                            }
                          : null,
                      onChangeEnd: _danmakuEnabled
                          ? (value) {
                              UserDataService.saveDanmakuFontSize(
                                  _danmakuFontSize);
                            }
                          : null,
                    ),
                  ),
                ),
                Text(
                  '2.0x',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanmakuDisplayAreaCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _danmakuEnabled ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.rows4,
                  size: 24,
                  color: Color(0xFF8b5cf6),
                ),
                const SizedBox(width: 12),
                Text(
                  '弹幕显示区域',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                Text(
                  _danmakuDisplayArea >= 1.0
                      ? '全屏'
                      : _danmakuDisplayArea <= 0.5
                          ? '1/4屏'
                          : _danmakuDisplayArea <= 0.75
                              ? '半屏'
                              : '3/4屏',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8b5cf6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '1/4屏',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 20.0,
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: const Color(0xFF8b5cf6),
                      activeTrackColor: const Color(0xFF8b5cf6),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuDisplayArea,
                      min: 0.25,
                      max: 1.0,
                      divisions: 3,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuDisplayArea = value;
                              });
                            }
                          : null,
                      onChangeEnd: _danmakuEnabled
                          ? (value) {
                              UserDataService.saveDanmakuDisplayArea(
                                  _danmakuDisplayArea);
                            }
                          : null,
                    ),
                  ),
                ),
                Text(
                  '全屏',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanmakuMaxCountCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _danmakuEnabled ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.list,
                  size: 24,
                  color: Color(0xFFef4444),
                ),
                const SizedBox(width: 12),
                Text(
                  '弹幕最大数量',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_danmakuMaxCount',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFef4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '10',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 20.0,
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: const Color(0xFFef4444),
                      activeTrackColor: const Color(0xFFef4444),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuMaxCount.toDouble(),
                      min: 10,
                      max: 500,
                      divisions: 49,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuMaxCount = value.round();
                              });
                            }
                          : null,
                      onChangeEnd: _danmakuEnabled
                          ? (value) {
                              UserDataService.saveDanmakuMaxCount(
                                  _danmakuMaxCount);
                            }
                          : null,
                    ),
                  ),
                ),
                Text(
                  '500',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanmakuAntiBlockCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: _danmakuEnabled ? 1.0 : 0.4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.shield,
                  size: 24,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 12),
                Text(
                  '弹幕防遮挡',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            Switch(
              value: _danmakuAntiBlock,
              onChanged: _danmakuEnabled
                  ? (value) {
                      setState(() {
                        _danmakuAntiBlock = value;
                      });
                      UserDataService.saveDanmakuAntiBlock(value);
                    }
                  : null,
              activeThumbColor: const Color(0xFF27AE60),
              inactiveTrackColor: isDarkMode
                  ? const Color(0xFF374151)
                  : const Color(0xFFe5e7eb),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFf59e0b).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFf59e0b).withAlpha(76),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            size: 20,
            color: Color(0xFFf59e0b),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '提示：弹幕设置仅在视频播放时生效。关闭弹幕开关后，其他弹幕设置将被禁用。弹幕数量过多可能影响播放性能。',
              style: FontUtils.poppins(
                fontSize: 14,
                color: isDarkMode
                    ? const Color(0xFFf59e0b)
                    : const Color(0xFF92400e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
