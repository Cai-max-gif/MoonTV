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

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  bool _autoPlayNext = false;
  bool _autoEnterPictureInPicture = false;
  bool _autoSkipOpeningEnding = false;
  double _defaultPlaybackSpeed = 1.0;
  int _skipOpeningDuration = 0;
  int _skipEndingDuration = 0;
  late TextEditingController _skipOpeningDurationController;
  late TextEditingController _skipEndingDurationController;

  // 倍速列表
  final List<double> _playbackSpeeds = [0.5, 0.75, 1.0, 1.5, 2.0];
  // 当前选中的倍速索引
  late int _selectedSpeedIndex;

  @override
  void initState() {
    super.initState();
    _skipOpeningDurationController =
        TextEditingController(text: _skipOpeningDuration.toString());
    _skipEndingDurationController =
        TextEditingController(text: _skipEndingDuration.toString());
    _selectedSpeedIndex = _playbackSpeeds.indexOf(_defaultPlaybackSpeed);
    _loadDefaultPlaybackSpeed();
    _loadAutoEnterPictureInPicture();
    _loadAutoSkipOpeningEnding();
    _loadSkipOpeningDuration();
    _loadSkipEndingDuration();
    _loadAutoPlayNext();
  }

  Future<void> _loadAutoPlayNext() async {
    final enabled = await UserDataService.getAutoPlayNext();
    setState(() {
      _autoPlayNext = enabled;
    });
  }

  Future<void> _loadDefaultPlaybackSpeed() async {
    final speed = await UserDataService.getDefaultPlaybackSpeed();
    setState(() {
      _defaultPlaybackSpeed = speed;
      _selectedSpeedIndex = _playbackSpeeds.indexOf(speed);
    });
  }

  Future<void> _loadAutoEnterPictureInPicture() async {
    final enabled = await UserDataService.getAutoEnterPictureInPicture();
    setState(() {
      _autoEnterPictureInPicture = enabled;
    });
  }

  Future<void> _loadAutoSkipOpeningEnding() async {
    final enabled = await UserDataService.getAutoSkipOpeningEnding();
    setState(() {
      _autoSkipOpeningEnding = enabled;
    });
  }

  Future<void> _loadSkipOpeningDuration() async {
    final duration = await UserDataService.getSkipOpeningDuration();
    setState(() {
      _skipOpeningDuration = duration;
      _skipOpeningDurationController.text = duration.toString();
    });
  }

  Future<void> _loadSkipEndingDuration() async {
    final duration = await UserDataService.getSkipEndingDuration();
    setState(() {
      _skipEndingDuration = duration;
      _skipEndingDurationController.text = duration.toString();
    });
  }

  @override
  void dispose() {
    _skipOpeningDurationController.dispose();
    _skipEndingDurationController.dispose();
    super.dispose();
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
          '播放设置',
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
          // 自动连播设置
          Container(
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
                      LucideIcons.repeat,
                      size: 24,
                      color: Color(0xFF8b5cf6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '自动连播',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _autoPlayNext,
                  onChanged: (value) {
                    setState(() {
                      _autoPlayNext = value;
                    });
                    UserDataService.saveAutoPlayNext(value);
                  },
                  activeThumbColor: const Color(0xFF8b5cf6),
                  inactiveTrackColor: isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFe5e7eb),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 自动进入画中画设置
          Container(
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
                      LucideIcons.pictureInPicture,
                      size: 24,
                      color: Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '自动进入画中画',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _autoEnterPictureInPicture,
                  onChanged: (value) {
                    setState(() {
                      _autoEnterPictureInPicture = value;
                    });
                    UserDataService.saveAutoEnterPictureInPicture(value);
                  },
                  activeThumbColor: const Color(0xFF3b82f6),
                  inactiveTrackColor: isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFe5e7eb),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 默认倍速设置
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.zap,
                      size: 24,
                      color: Color(0xFFf59e0b),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '默认倍速',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1f2937),
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
                          thumbShape: const HollowRoundSliderThumbShape(
                              thumbRadius: 10),
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbColor: const Color(0xFFf59e0b),
                          activeTrackColor: const Color(0xFFf59e0b),
                          inactiveTrackColor: isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFe5e7eb),
                        ),
                        child: Slider(
                          value: _selectedSpeedIndex.toDouble(),
                          min: 0,
                          max: _playbackSpeeds.length - 1,
                          divisions: _playbackSpeeds.length - 1,
                          onChanged: (value) {
                            int index = value.round();
                            setState(() {
                              _selectedSpeedIndex = index;
                              _defaultPlaybackSpeed = _playbackSpeeds[index];
                            });
                          },
                          onChangeEnd: (value) {
                            UserDataService.saveDefaultPlaybackSpeed(
                                _defaultPlaybackSpeed);
                          },
                          label:
                              '${_defaultPlaybackSpeed.toStringAsFixed(_defaultPlaybackSpeed == 1.0 ? 0 : 2)}x',
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

          const SizedBox(height: 12),

          // 自动跳过片头片尾设置
          Container(
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
                      LucideIcons.skipBack,
                      size: 24,
                      color: Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '自动跳过片头片尾',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _autoSkipOpeningEnding,
                  onChanged: (value) {
                    setState(() {
                      _autoSkipOpeningEnding = value;
                    });
                    UserDataService.saveAutoSkipOpeningEnding(value);
                  },
                  activeThumbColor: const Color(0xFF3b82f6),
                  inactiveTrackColor: isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFe5e7eb),
                ),
              ],
            ),
          ),

          if (_autoSkipOpeningEnding) ...[
            const SizedBox(height: 12),

            // 片头跳过时长设置
            Container(
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
                        LucideIcons.clock,
                        size: 24,
                        color: Color(0xFF10b981),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '片头跳过时长',
                        style: FontUtils.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _skipOpeningDurationController,
                          onChanged: (value) {
                            setState(() {
                              // 检查输入长度，超过三位自动改为180
                              if (value.length > 3) {
                                _skipOpeningDuration = 180;
                                _skipOpeningDurationController.text = '180';
                                UserDataService.saveSkipOpeningDuration(180);
                                return;
                              }

                              int? parsedValue = int.tryParse(value);
                              if (parsedValue != null) {
                                if (parsedValue < 0) {
                                  _skipOpeningDuration = 0;
                                  _skipOpeningDurationController.text = '0';
                                  UserDataService.saveSkipOpeningDuration(0);
                                } else if (parsedValue > 180) {
                                  _skipOpeningDuration = 180;
                                  _skipOpeningDurationController.text = '180';
                                  UserDataService.saveSkipOpeningDuration(180);
                                } else {
                                  _skipOpeningDuration = parsedValue;
                                  UserDataService.saveSkipOpeningDuration(
                                      parsedValue);
                                }
                              } else {
                                _skipOpeningDuration = 0;
                                _skipOpeningDurationController.text = '0';
                                UserDataService.saveSkipOpeningDuration(0);
                              }
                            });
                          },
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: FontUtils.poppins(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1f2937),
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFe5e7eb),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF10b981),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '秒',
                        style: FontUtils.poppins(
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 片尾跳过时长设置
            Container(
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
                        LucideIcons.clock,
                        size: 24,
                        color: Color(0xFF3b82f6),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '片尾跳过时长',
                        style: FontUtils.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _skipEndingDurationController,
                          onChanged: (value) {
                            setState(() {
                              // 检查输入长度，超过三位自动改为180
                              if (value.length > 3) {
                                _skipEndingDuration = 180;
                                _skipEndingDurationController.text = '180';
                                UserDataService.saveSkipEndingDuration(180);
                                return;
                              }

                              int? parsedValue = int.tryParse(value);
                              if (parsedValue != null) {
                                if (parsedValue < 0) {
                                  _skipEndingDuration = 0;
                                  _skipEndingDurationController.text = '0';
                                  UserDataService.saveSkipEndingDuration(0);
                                } else if (parsedValue > 180) {
                                  _skipEndingDuration = 180;
                                  _skipEndingDurationController.text = '180';
                                  UserDataService.saveSkipEndingDuration(180);
                                } else {
                                  _skipEndingDuration = parsedValue;
                                  UserDataService.saveSkipEndingDuration(
                                      parsedValue);
                                }
                              } else {
                                _skipEndingDuration = 0;
                                _skipEndingDurationController.text = '0';
                                UserDataService.saveSkipEndingDuration(0);
                              }
                            });
                          },
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: FontUtils.poppins(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1f2937),
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFe5e7eb),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF3b82f6),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '秒',
                        style: FontUtils.poppins(
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 说明文字
          Container(
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
                    '提示：开启这些设置可以提升您的观看体验，但可能会消耗更多电量和网络流量。',
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
          ),
        ],
      ),
    );
  }
}
