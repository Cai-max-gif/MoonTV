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
  final VoidCallback? onBack;

  const DanmakuSettingsScreen({super.key, this.onBack});

  @override
  State<DanmakuSettingsScreen> createState() => _DanmakuSettingsScreenState();
}

class _DanmakuSettingsScreenState extends State<DanmakuSettingsScreen> {
  double _danmakuSpeed = 1.0;
  double _danmakuOpacity = 100;
  double _danmakuFontSize = 1.0;
  double _danmakuDisplayArea = 0.25;

  bool get _danmakuEnabled => UserDataService.danmakuEnabledNotifier.value;

  @override
  void initState() {
    super.initState();
    UserDataService.danmakuEnabledNotifier.addListener(_onDanmakuChanged);
    _loadSettings();
  }

  void _onDanmakuChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    UserDataService.danmakuEnabledNotifier.removeListener(_onDanmakuChanged);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    UserDataService.initDanmakuEnabled();
    UserDataService.initDanmakuSettings();
    final speedIndex = await UserDataService.getDanmakuSpeed();
    final opacity = await UserDataService.getDanmakuOpacity();
    final fontSize = await UserDataService.getDanmakuFontSize();
    final displayArea = await UserDataService.getDanmakuDisplayArea();

    final speedValues = [0.5, 0.75, 1.0, 1.5, 2.0];

    if (mounted) {
      setState(() {
        _danmakuSpeed = speedValues[speedIndex.clamp(0, 4)];
        _danmakuOpacity = opacity.clamp(0, 100).toDouble();
        _danmakuFontSize = fontSize.clamp(0.5, 2.0);
        _danmakuDisplayArea = displayArea.clamp(0.25, 1.0);
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
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!.call();
            } else {
              Navigator.pop(context);
            }
          },
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
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5 * 2 - 1, // 5个设置卡片 + 4个间隔
        itemBuilder: (context, index) {
          if (index.isOdd) return const SizedBox(height: 12);
          final itemIndex = index ~/ 2;
          switch (itemIndex) {
            case 0: return _buildDanmakuEnabledCard(isDarkMode);
            case 1: return _buildDanmakuSpeedCard(isDarkMode);
            case 2: return _buildDanmakuOpacityCard(isDarkMode);
            case 3: return _buildDanmakuFontSizeCard(isDarkMode);
            case 4: return _buildDanmakuDisplayAreaCard(isDarkMode);
            default: return const SizedBox.shrink();
          }
        },
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
            color: Colors.black.withValues(alpha: 0.098),
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
    const speedValues = [0.5, 0.75, 1.0, 1.5, 2.0];
    final speedLabels = ['极慢', '较慢', '适中', '较快', '极快'];
    final currentIndex =
        speedValues.indexWhere((v) => (v - _danmakuSpeed).abs() < 0.01);
    final currentLabel = currentIndex >= 0 ? speedLabels[currentIndex] : '适中';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
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
                  LucideIcons.forward,
                  size: 24,
                  color: Color(0xFF3B82F6),
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
                  '$currentLabel (${_danmakuSpeed.toStringAsFixed(1)}x)',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
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
                      thumbColor: const Color(0xFF3B82F6),
                      activeTrackColor: const Color(0xFF3B82F6),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 3,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuSpeed = value;
                              });
                              final index = speedValues
                                  .indexWhere((v) => (v - value).abs() < 0.01);
                              if (index >= 0) {
                                UserDataService.saveDanmakuSpeed(index);
                              }
                            }
                          : null,
                      label: '${_danmakuSpeed.toStringAsFixed(1)}x',
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
            color: Colors.black.withValues(alpha: 0.098),
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
                  color: Color(0xFF8B5CF6),
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
                  '${_danmakuOpacity.round()}%',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '0%',
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
                      thumbColor: const Color(0xFF8B5CF6),
                      activeTrackColor: const Color(0xFF8B5CF6),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuOpacity,
                      min: 0,
                      max: 100,
                      divisions: 4,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuOpacity = value;
                              });
                              UserDataService.saveDanmakuOpacity(value.round());
                            }
                          : null,
                      label: '${_danmakuOpacity.round()}%',
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
            color: Colors.black.withValues(alpha: 0.098),
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
                  color: Color(0xFFF59E0B),
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
                  '${_danmakuFontSize.toStringAsFixed(1)}x (${(_danmakuFontSize * 24).round()}px)',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
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
                      thumbColor: const Color(0xFFF59E0B),
                      activeTrackColor: const Color(0xFFF59E0B),
                      inactiveTrackColor: isDarkMode
                          ? const Color(0xFF374151)
                          : const Color(0xFFe5e7eb),
                    ),
                    child: Slider(
                      value: _danmakuFontSize,
                      min: 0.5,
                      max: 2.0,
                      divisions: 3,
                      onChanged: _danmakuEnabled
                          ? (value) {
                              setState(() {
                                _danmakuFontSize = value;
                              });
                              UserDataService.saveDanmakuFontSize(value);
                            }
                          : null,
                      label: '${_danmakuFontSize.toStringAsFixed(1)}x',
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
    const areaLabels = ['1/4', '半屏', '3/4', '满屏'];
    const areaValues = [0.25, 0.5, 0.75, 1.0];
    final currentIndex =
        areaValues.indexWhere((v) => (v - _danmakuDisplayArea).abs() < 0.01);
    final currentLabel = currentIndex >= 0 ? areaLabels[currentIndex] : '满屏';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
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
                  LucideIcons.maximize,
                  size: 24,
                  color: Color(0xFFEF4444),
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
                  currentLabel,
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '1/4',
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
                      thumbColor: const Color(0xFFEF4444),
                      activeTrackColor: const Color(0xFFEF4444),
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
                              UserDataService.saveDanmakuDisplayArea(value);
                            }
                          : null,
                      label: currentLabel,
                    ),
                  ),
                ),
                Text(
                  '满屏',
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

}
