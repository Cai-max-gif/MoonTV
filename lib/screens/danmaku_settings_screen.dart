import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/user_data_service.dart';
import '../utils/font_utils.dart';
import '../widgets/hollow_slider_thumb.dart';

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
          isDarkMode ? AppColors.black : AppColors.grayBg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
        elevation: AppDimens.elevationNone,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDarkMode ? Colors.white : AppColors.textDarkGray,
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
          AppStrings.danmakuSettings,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textDarkGray,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
        itemCount: 5 * 2 - 1, // 5个设置卡片 + 4个间隔
        itemBuilder: (context, index) {
          if (index.isOdd) return Gap.h12;
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
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
            blurRadius: AppDimens.shadowBlurSm,
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
                size: AppDimens.iconLg,
                color: AppColors.pinkAccent,
              ),
              Gap.w12,
              Text(
                AppStrings.danmakuEnable,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.textDarkGray,
                ),
              ),
            ],
          ),
          Switch(
            value: _danmakuEnabled,
            onChanged: (value) {
              UserDataService.saveDanmakuEnabled(value);
            },
            activeThumbColor: AppColors.pinkAccent,
            inactiveTrackColor:
                isDarkMode ? AppColors.borderDarkGray : AppColors.borderLightGray,
          ),
        ],
      ),
    );
  }

  Widget _buildDanmakuSpeedCard(bool isDarkMode) {
    const speedValues = [0.5, 0.75, 1.0, 1.5, 2.0];
    final speedLabels = AppStrings.danmakuSpeedLabels;
    final currentIndex =
        speedValues.indexWhere((v) => (v - _danmakuSpeed).abs() < 0.01);
    final currentLabel = currentIndex >= 0 ? speedLabels[currentIndex] : AppStrings.danmakuSpeedLabels[2];

    return Container(
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
            blurRadius: AppDimens.shadowBlurSm,
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
                  size: AppDimens.iconLg,
                  color: AppColors.blue,
                ),
                Gap.w12,
                Text(
                  AppStrings.danmakuSpeed,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textDarkGray,
                  ),
                ),
                const Spacer(),
                Text(
                  '$currentLabel (${_danmakuSpeed.toStringAsFixed(1)}x)',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppColors.gray400
                        : AppColors.gray500,
                  ),
                ),
              ],
            ),
            Gap.h12,
            Row(
              children: [
                Text(
                  '0.5x',
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
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: AppColors.blue,
                      activeTrackColor: AppColors.blue,
                      inactiveTrackColor: isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
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
    );
  }

  Widget _buildDanmakuOpacityCard(bool isDarkMode) {
    return Container(
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
            blurRadius: AppDimens.shadowBlurSm,
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
                  size: AppDimens.iconLg,
                  color: AppColors.violet,
                ),
                Gap.w12,
                Text(
                  AppStrings.danmakuOpacity,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textDarkGray,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_danmakuOpacity.round()}%',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppColors.gray400
                        : AppColors.gray500,
                  ),
                ),
              ],
            ),
            Gap.h12,
            Row(
              children: [
                Text(
                  '0%',
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
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: AppColors.violet,
                      activeTrackColor: AppColors.violet,
                      inactiveTrackColor: isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
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
    );
  }

  Widget _buildDanmakuFontSizeCard(bool isDarkMode) {
    return Container(
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
            blurRadius: AppDimens.shadowBlurSm,
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
                  size: AppDimens.iconLg,
                  color: AppColors.amber,
                ),
                Gap.w12,
                Text(
                  AppStrings.danmakuFontSize,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textDarkGray,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_danmakuFontSize.toStringAsFixed(1)}x (${(_danmakuFontSize * 24).round()}px)',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppColors.gray400
                        : AppColors.gray500,
                  ),
                ),
              ],
            ),
            Gap.h12,
            Row(
              children: [
                Text(
                  '0.5x',
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
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: AppColors.amber,
                      activeTrackColor: AppColors.amber,
                      inactiveTrackColor: isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
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
    );
  }

  Widget _buildDanmakuDisplayAreaCard(bool isDarkMode) {
    const areaLabels = AppStrings.danmakuAreaLabels;
    const areaValues = [0.25, 0.5, 0.75, 1.0];
    final currentIndex =
        areaValues.indexWhere((v) => (v - _danmakuDisplayArea).abs() < 0.01);
    final currentLabel = currentIndex >= 0 ? areaLabels[currentIndex] : AppStrings.danmakuAreaLabels[3];

    return Container(
      padding: AppDimens.listTilePadding,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.098),
            blurRadius: AppDimens.shadowBlurSm,
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
                  size: AppDimens.iconLg,
                  color: AppColors.red,
                ),
                Gap.w12,
                Text(
                  AppStrings.danmakuDisplayArea,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppColors.textDarkGray,
                  ),
                ),
                const Spacer(),
                Text(
                  currentLabel,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? AppColors.gray400
                        : AppColors.gray500,
                  ),
                ),
              ],
            ),
            Gap.h12,
            Row(
              children: [
                Text(
                  AppStrings.danmakuAreaLabels[0],
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
                      thumbShape:
                          const HollowRoundSliderThumbShape(thumbRadius: 10),
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: AppColors.red,
                      activeTrackColor: AppColors.red,
                      inactiveTrackColor: isDarkMode
                          ? AppColors.borderDarkGray
                          : AppColors.borderLightGray,
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
                  AppStrings.danmakuAreaLabels[3],
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
    );
  }

}
