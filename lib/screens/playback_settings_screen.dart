import 'dart:io';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/user_data_service.dart';
import '../utils/font_utils.dart';
import '../widgets/hollow_slider_thumb.dart';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  bool _autoPlayNext = false;
  bool _autoEnterPictureInPicture = false;
  bool _autoSkipOpeningEnding = false;
  bool _familyMode = true;
  double _defaultPlaybackSpeed = 1.0;
  int _skipOpeningDuration = 0;
  int _skipEndingDuration = 0;
  late TextEditingController _skipOpeningDurationController;
  late TextEditingController _skipEndingDurationController;

  // 倍速列表
  final List<double> _playbackSpeeds = AppConfig.playbackSpeedValues;
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
    _loadFamilyMode();
  }

  Future<void> _loadAutoPlayNext() async {
    final enabled = await UserDataService.getAutoPlayNext();
    if (!mounted) return;
    setState(() {
      _autoPlayNext = enabled;
    });
  }

  Future<void> _loadDefaultPlaybackSpeed() async {
    final speed = await UserDataService.getDefaultPlaybackSpeed();
    if (!mounted) return;
    setState(() {
      _defaultPlaybackSpeed = speed;
      _selectedSpeedIndex = _playbackSpeeds.indexOf(speed);
    });
  }

  Future<void> _loadAutoEnterPictureInPicture() async {
    final enabled = await UserDataService.getAutoEnterPictureInPicture();
    if (!mounted) return;
    setState(() {
      _autoEnterPictureInPicture = enabled;
    });
  }

  Future<void> _loadAutoSkipOpeningEnding() async {
    final enabled = await UserDataService.getAutoSkipOpeningEnding();
    if (!mounted) return;
    setState(() {
      _autoSkipOpeningEnding = enabled;
    });
  }

  Future<void> _loadSkipOpeningDuration() async {
    final duration = await UserDataService.getSkipOpeningDuration();
    if (!mounted) return;
    setState(() {
      _skipOpeningDuration = duration;
      _skipOpeningDurationController.text = duration.toString();
    });
  }

  Future<void> _loadSkipEndingDuration() async {
    final duration = await UserDataService.getSkipEndingDuration();
    if (!mounted) return;
    setState(() {
      _skipEndingDuration = duration;
      _skipEndingDurationController.text = duration.toString();
    });
  }

  Future<void> _loadFamilyMode() async {
    final enabled = await UserDataService.getFamilyMode();
    if (!mounted) return;
    setState(() {
      _familyMode = enabled;
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
          isDarkMode ? AppColors.black : AppColors.grayBg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.cardDark : AppColors.white,
        elevation: AppDimens.elevationNone,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.playbackSettingsTitle,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.white : AppColors.textDarkGray,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        children: [
          // 家庭模式设置
          Container(
            padding: AppDimens.listTilePadding,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black10,
                  blurRadius: AppDimens.shadowBlurSm,
                  offset: AppDimens.offset02,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.house,
                      size: AppDimens.iconLg,
                      color: AppColors.accent,
                    ),
                    Gap.w12,
                    Text(
                      AppStrings.playbackFamilyMode,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXl,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? AppColors.white : AppColors.textDarkGray,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _familyMode,
                  onChanged: (value) {
                    setState(() {
                      _familyMode = value;
                    });
                    UserDataService.saveFamilyMode(value);
                  },
                  activeThumbColor: AppColors.accent,
                  inactiveTrackColor: isDarkMode
                      ? AppColors.gray700
                      : AppColors.gray200,
                ),
              ],
            ),
          ),

          Gap.h12,

          // 自动连播设置
          Container(
            padding: AppDimens.listTilePadding,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black10,
                  blurRadius: AppDimens.shadowBlurSm,
                  offset: AppDimens.offset02,
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
                      size: AppDimens.iconLg,
                      color: AppColors.violet,
                    ),
                    Gap.w12,
                    Text(
                      AppStrings.playbackAutoPlay,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXl,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? AppColors.white : AppColors.textDarkGray,
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
                  activeThumbColor: AppColors.violet,
                  inactiveTrackColor: isDarkMode
                      ? AppColors.gray700
                      : AppColors.gray200,
                ),
              ],
            ),
          ),

          Gap.h12,

          // 自动进入画中画设置（仅移动端）
          if (Platform.isAndroid || Platform.isIOS)
            Container(
              padding: AppDimens.listTilePadding,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black10,
                    blurRadius: AppDimens.shadowBlurSm,
                    offset: AppDimens.offset02,
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
                        size: AppDimens.iconLg,
                        color: AppColors.blue,
                      ),
                      Gap.w12,
                      Text(
                        AppStrings.playbackAutoPIP,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.white
                              : AppColors.textDarkGray,
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
                    activeThumbColor: AppColors.blue,
                    inactiveTrackColor: isDarkMode
                        ? AppColors.gray700
                        : AppColors.gray200,
                  ),
                ],
              ),
            ),

          if (Platform.isAndroid || Platform.isIOS) Gap.h12,

          // 默认倍速设置
          Container(
            padding: AppDimens.listTilePadding,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black10,
                  blurRadius: AppDimens.shadowBlurSm,
                  offset: AppDimens.offset02,
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
                      size: AppDimens.iconLg,
                      color: AppColors.amber,
                    ),
                    Gap.w12,
                    Text(
                      AppStrings.playbackDefaultSpeed,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXl,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? AppColors.white : AppColors.textDarkGray,
                      ),
                    ),
                  ],
                ),
                Gap.h12,
                Row(
                  children: [
                    Text(
                      AppStrings.playbackSpeedLabelSlowest,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeMd,
                        color: isDarkMode
                            ? AppColors.gray400
                            : AppColors.gray500,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 20.0,
                          thumbShape: const HollowRoundSliderThumbShape(
                              thumbRadius: 10),
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbColor: AppColors.amber,
                          activeTrackColor: AppColors.amber,
                          inactiveTrackColor: isDarkMode
                              ? AppColors.gray700
                              : AppColors.gray200,
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
                      AppStrings.playbackSpeedLabelFastest,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeMd,
                        color: isDarkMode
                            ? AppColors.gray400
                            : AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Gap.h12,

          // 自动跳过片头片尾设置
          Container(
            padding: AppDimens.listTilePadding,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black10,
                  blurRadius: AppDimens.shadowBlurSm,
                  offset: AppDimens.offset02,
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
                      size: AppDimens.iconLg,
                      color: AppColors.blue,
                    ),
                    Gap.w12,
                    Text(
                      AppStrings.playbackSkipOpeningEnding,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeXl,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode ? AppColors.white : AppColors.textDarkGray,
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
                  activeThumbColor: AppColors.blue,
                  inactiveTrackColor: isDarkMode
                      ? AppColors.gray700
                      : AppColors.gray200,
                ),
              ],
            ),
          ),

          if (_autoSkipOpeningEnding) ...[
            Gap.h12,

            // 片头跳过时长设置
            Container(
              padding: AppDimens.listTilePadding,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black10,
                    blurRadius: AppDimens.shadowBlurSm,
                    offset: AppDimens.offset02,
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
                        size: AppDimens.iconLg,
                        color: AppColors.emerald,
                      ),
                      Gap.w12,
                      Text(
                        AppStrings.playbackSkipOpeningDuration,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.white
                              : AppColors.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: AppDimens.iconSize80,
                        child: TextField(
                          controller: _skipOpeningDurationController,
                          onChanged: (value) {
                            setState(() {
                              // 检查输入长度，超过三位自动改为180
                              if (value.length > 3) {
                                _skipOpeningDuration = AppConfig.defaultSkipOpeningDuration;
                                _skipOpeningDurationController.text = '${AppConfig.defaultSkipOpeningDuration}';
                                UserDataService.saveSkipOpeningDuration(AppConfig.defaultSkipOpeningDuration);
                                return;
                              }

                              int? parsedValue = int.tryParse(value);
                              if (parsedValue != null) {
                                if (parsedValue < 0) {
                                  _skipOpeningDuration = 0;
                                  _skipOpeningDurationController.text = '0';
                                  UserDataService.saveSkipOpeningDuration(0);
                                } else if (parsedValue > AppConfig.defaultSkipOpeningDuration) {
                                  _skipOpeningDuration = AppConfig.defaultSkipOpeningDuration;
                                  _skipOpeningDurationController.text = '${AppConfig.defaultSkipOpeningDuration}';
                                  UserDataService.saveSkipOpeningDuration(AppConfig.defaultSkipOpeningDuration);
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
                            fontSize: AppDimens.fontSizeXl,
                            color: isDarkMode
                                ? AppColors.white
                                : AppColors.textDarkGray,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? AppColors.gray700
                                    : AppColors.gray200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              borderSide: const BorderSide(
                                color: AppColors.emerald,
                              ),
                            ),
                            contentPadding: AppDimens.paddingHorizontal8Vertical8,
                          ),
                        ),
                      ),
                      Gap.w8,
                      Text(
                        AppStrings.playbackSeconds,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          color: isDarkMode
                              ? AppColors.white
                              : AppColors.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Gap.h12,

            // 片尾跳过时长设置
            Container(
              padding: AppDimens.listTilePadding,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black10,
                    blurRadius: AppDimens.shadowBlurSm,
                    offset: AppDimens.offset02,
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
                        size: AppDimens.iconLg,
                        color: AppColors.blue,
                      ),
                      Gap.w12,
                      Text(
                        AppStrings.playbackSkipEndingDuration,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.white
                              : AppColors.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: AppDimens.iconSize80,
                        child: TextField(
                          controller: _skipEndingDurationController,
                          onChanged: (value) {
                            setState(() {
                              // 检查输入长度，超过三位自动改为180
                              if (value.length > 3) {
                                _skipEndingDuration = AppConfig.defaultSkipEndingDuration;
                                _skipEndingDurationController.text = '${AppConfig.defaultSkipEndingDuration}';
                                UserDataService.saveSkipEndingDuration(AppConfig.defaultSkipEndingDuration);
                                return;
                              }

                              int? parsedValue = int.tryParse(value);
                              if (parsedValue != null) {
                                if (parsedValue < 0) {
                                  _skipEndingDuration = 0;
                                  _skipEndingDurationController.text = '0';
                                  UserDataService.saveSkipEndingDuration(0);
                                } else if (parsedValue > AppConfig.defaultSkipEndingDuration) {
                                  _skipEndingDuration = AppConfig.defaultSkipEndingDuration;
                                  _skipEndingDurationController.text = '${AppConfig.defaultSkipEndingDuration}';
                                  UserDataService.saveSkipEndingDuration(AppConfig.defaultSkipEndingDuration);
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
                            fontSize: AppDimens.fontSizeXl,
                            color: isDarkMode
                                ? AppColors.white
                                : AppColors.textDarkGray,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? AppColors.gray700
                                    : AppColors.gray200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              borderSide: const BorderSide(
                                color: AppColors.blue,
                              ),
                            ),
                            contentPadding: AppDimens.paddingHorizontal8Vertical8,
                          ),
                        ),
                      ),
                      Gap.w8,
                      Text(
                        AppStrings.playbackSeconds,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          color: isDarkMode
                              ? AppColors.white
                              : AppColors.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          Gap.h16,

          // 说明文字
          Container(
            padding: AppDimens.listTilePadding,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.098),
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.298),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: AppDimens.iconSize20,
                  color: AppColors.amber,
                ),
                Gap.w12,
                Expanded(
                  child: Text(
                    AppStrings.playbackSettingsTip,
                    style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeMd,
                      color: isDarkMode
                          ? AppColors.amber
                          : AppColors.amber800,
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
