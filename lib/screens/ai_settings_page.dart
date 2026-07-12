import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../constants/app_config.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/ai_service.dart';
import '../constants/app_strings.dart';
import '../utils/font_utils.dart';
import '../utils/device_utils.dart';

class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  String _selectedProvider = AppConfig.aiProviderOpenai;
  final TextEditingController _apiKeyController = TextEditingController();
  String _selectedModel = AppConfig.aiDefaultModel;
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isCheckingBalance = false;
  bool _isProviderExpanded = false;
  bool _isModelExpanded = false;
  Map<String, dynamic>? _balanceInfo;
  bool _balanceQueryFailed = false;

  static const List<_ProviderInfo> _providers = [
    _ProviderInfo(
      id: AppConfig.aiProviderOpenai,
      name: AppConfig.aiProviderNameOpenai,
      models: [
        _ModelInfo(AppConfig.aiModelGpt55Pro, AppConfig.aiModelNameGpt55Pro),
        _ModelInfo(AppConfig.aiModelGpt55, AppConfig.aiModelNameGpt55),
        _ModelInfo(AppConfig.aiModelGpt54, AppConfig.aiModelNameGpt54),
        _ModelInfo(AppConfig.aiModelGpt53Codex, AppConfig.aiModelNameGpt53Codex),
      ],
    ),
    _ProviderInfo(
      id: AppConfig.aiProviderDeepseek,
      name: AppConfig.aiProviderNameDeepseek,
      models: [
        _ModelInfo(AppConfig.aiModelDeepseekV4Pro, AppConfig.aiModelNameDeepseekV4Pro),
        _ModelInfo(AppConfig.aiModelDeepseekV4Flash, AppConfig.aiModelNameDeepseekV4Flash),
      ],
    ),
    _ProviderInfo(
      id: AppConfig.aiProviderZhipu,
      name: AppConfig.aiProviderNameZhipu,
      models: [
        _ModelInfo(AppConfig.aiModelGlm52, AppConfig.aiModelNameGlm52),
        _ModelInfo(AppConfig.aiModelGlm51, AppConfig.aiModelNameGlm51),
        _ModelInfo(AppConfig.aiModelGlm47, AppConfig.aiModelNameGlm47),
        _ModelInfo(AppConfig.aiModelGlm45, AppConfig.aiModelNameGlm45),
      ],
    ),
    _ProviderInfo(
      id: AppConfig.aiProviderMoonshot,
      name: AppConfig.aiProviderNameMoonshot,
      models: [
        _ModelInfo(AppConfig.aiModelKimiK27Code, AppConfig.aiModelNameKimiK27Code),
        _ModelInfo(AppConfig.aiModelKimiK26, AppConfig.aiModelNameKimiK26),
        _ModelInfo(AppConfig.aiModelKimiK25, AppConfig.aiModelNameKimiK25),
      ],
    ),
    _ProviderInfo(
      id: AppConfig.aiProviderMimo,
      name: AppConfig.aiProviderNameMimo,
      models: [
        _ModelInfo(AppConfig.aiModelMimoV25Pro, AppConfig.aiModelNameMimoV25Pro),
        _ModelInfo(AppConfig.aiModelMimoV25, AppConfig.aiModelNameMimoV25),
      ],
    ),
    _ProviderInfo(
      id: AppConfig.aiProviderCustom,
      name: AppStrings.aiCustom,
      models: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _apiKeyController.addListener(() {
      _autoCheckBalance();
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await AIService.loadSettings();
    if (!mounted) return;
    setState(() {
      _selectedProvider = settings.provider;
      _apiKeyController.text = settings.apiKey;
      _baseUrlController.text = settings.baseUrl;
      if (settings.provider == AppConfig.aiProviderCustom) {
        _customModelController.text = settings.model;
      } else {
        _selectedModel = settings.model;
      }
    });
  }

  List<_ModelInfo> get _currentModels {
    for (final p in _providers) {
      if (p.id == _selectedProvider) return p.models;
    }
    return _providers.last.models;
  }

  bool get _supportsBalance => _selectedProvider == AppConfig.aiProviderDeepseek || _selectedProvider == AppConfig.aiProviderMoonshot;

  Future<void> _autoCheckBalance() async {
    if (!_supportsBalance) {
      setState(() {
        _balanceInfo = null;
        _balanceQueryFailed = false;
      });
      return;
    }

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _balanceInfo = null;
        _balanceQueryFailed = false;
      });
      return;
    }

    setState(() {
      _isCheckingBalance = true;
      _balanceQueryFailed = false;
    });

    final settings = AISettings(
      provider: _selectedProvider,
      apiKey: apiKey,
      model: _effectiveModel,
      baseUrl: _baseUrlController.text.trim(),
    );

    final balance = await AIService.getBalance(settings);

    if (!mounted) return;

    setState(() {
      _isCheckingBalance = false;
      _balanceInfo = balance;
      _balanceQueryFailed = balance == null;
    });
  }

  bool get _isCustomProvider => _selectedProvider == AppConfig.aiProviderCustom;

  String get _effectiveModel {
    if (_isCustomProvider) {
      return _customModelController.text.trim();
    }
    return _selectedModel;
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
          title: Text(
            AppStrings.aiDeleteConversation,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXl,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.primary,
            ),
          ),
          content: Text(
            AppStrings.confirmClearChatHistory,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                AppStrings.cancel,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                AppStrings.confirm,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await AIService.clearChatHistory();
      if (mounted) {
        _showSnack(AppStrings.chatHistoryCleared, true);
      }
    }
  }

  Future<void> _saveSettings() async {
    final model = _effectiveModel;
    if (model.isEmpty) {
      _showSnack(AppStrings.aiEnterModelName, false);
      return;
    }

    setState(() => _isSaving = true);

    final settings = AISettings(
      provider: _selectedProvider,
      apiKey: _apiKeyController.text.trim(),
      model: model,
      baseUrl: _baseUrlController.text.trim(),
    );

    await AIService.saveSettings(settings);

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.aiSettingsSaved,
          style: FontUtils.poppins(fontSize: AppDimens.fontSizeMd, color: AppColors.white),
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
        duration: AppDurations.twoSeconds,
      ),
    );
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showSnack(AppStrings.aiEnterApiKeyFirst, false);
      return;
    }

    setState(() => _isTesting = true);

    final settings = AISettings(
      provider: _selectedProvider,
      apiKey: apiKey,
      model: _effectiveModel,
      baseUrl: _baseUrlController.text.trim(),
    );

    final success = await AIService.testConnection(settings);

    if (!mounted) return;

    setState(() => _isTesting = false);

    _showSnack(
      success ? AppStrings.aiConnectionSuccess : AppStrings.aiConnectionFailed,
      success,
    );
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FontUtils.poppins(fontSize: AppDimens.fontSizeMd, color: AppColors.white),
        ),
        backgroundColor: success ? AppColors.accent : AppColors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
        duration: AppDurations.twoSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final textColor =
            isDark ? AppColors.white : AppColors.primary;
        final subtitleColor =
            isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
        final cardColor = isDark ? AppColors.cardDark : AppColors.white;
        final inputBgColor =
            isDark ? AppColors.inputBgDark : AppColors.inputBgLight;
        final borderColor =
            isDark ? AppColors.borderDark : AppColors.gray200;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.black : AppColors.grayBg,
          appBar: _buildAppBar(isDark, textColor),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProviderSection(isDark, cardColor, textColor,
                    subtitleColor, inputBgColor, borderColor),
                Gap.h16,
                _buildModelSection(isDark, cardColor, textColor, subtitleColor,
                    inputBgColor, borderColor),
                Gap.h16,
                _buildApiKeySection(isDark, cardColor, textColor, subtitleColor,
                    inputBgColor, borderColor),
                Gap.h16,
                _buildDeleteButton(isDark, cardColor, textColor, subtitleColor, borderColor),
                Gap.h16,
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      elevation: AppDimens.elevationNone,
      leading: MouseRegion(
        cursor:
            DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Icon(LucideIcons.arrowLeft, color: textColor, size: AppDimens.iconLg),
          ),
        ),
      ),
      title: Text(
        AppStrings.aiSettings,
        style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeXxl, fontWeight: FontWeight.w600, color: textColor),
      ),
      centerTitle: true,
      actions: [
        MouseRegion(
          cursor: DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            onTap: _isSaving ? null : _saveSettings,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: AppDimens.paddingFromLTRB08168,
              child: _isSaving
                  ? const SizedBox(
                      width: AppDimens.iconSize20,
                      height: AppDimens.iconSize20,
                      child: CircularProgressIndicator(
                        strokeWidth: AppDimens.borderWidthMd,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.save, size: AppDimens.iconSm, color: textColor),
                        Gap.w4,
                        Text(
                          AppStrings.save,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeMd,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSection(bool isDark, Color cardColor, Color textColor,
      Color subtitleColor, Color inputBgColor, Color borderColor) {
    final selectedProviderName = _providers
        .firstWhere((p) => p.id == _selectedProvider, orElse: () => _providers[0])
        .name;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        border: Border.all(color: borderColor, width: AppDimens.borderWidthSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: DeviceUtils.isPC()
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _isProviderExpanded = !_isProviderExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: AppDimens.paddingLeft16Right12Top16Bottom12,
                child: Row(
                  children: [
                    const Icon(LucideIcons.building2,
                        size: AppDimens.iconMd, color: AppColors.accent),
                    Gap.w8,
                    Text(
                      AppStrings.aiSelectProvider,
                      style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeLg,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const Spacer(),
                    Text(
                      selectedProviderName,
                      style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor),
                    ),
                    Gap.w8,
                    AnimatedRotation(
                      turns: _isProviderExpanded ? 0.5 : 0,
                      duration: AppDurations.normal,
                      child: Icon(LucideIcons.chevronDown,
                          size: AppDimens.iconMd, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.normal,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _isProviderExpanded
                  ? [
                      ..._providers.map((p) => _buildProviderTile(
                          p, isDark, textColor, subtitleColor, borderColor)),
                      if (_selectedProvider == AppConfig.aiProviderCustom)
                        Padding(
                          padding: AppDimens.paddingLeft12Right12Top8Bottom16,
                          child: _buildTextField(
                            controller: _baseUrlController,
                            hintText: AppConfig.aiOpenaiBaseUrl,
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            inputBgColor: inputBgColor,
                          ),
                        )
                      else
                        Gap.h12,
                    ]
                  : [Gap.h0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderTile(_ProviderInfo info, bool isDark, Color textColor,
      Color subtitleColor, Color borderColor) {
    final isSelected = _selectedProvider == info.id;
    return MouseRegion(
      cursor: DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () {
          if (_selectedProvider == info.id) return;
          setState(() {
            _selectedProvider = info.id;
            if (info.id == AppConfig.aiProviderCustom) {
              _baseUrlController.clear();
              _customModelController.clear();
            } else if (info.models.isNotEmpty) {
              _selectedModel = info.models.first.id;
            }
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: AppDimens.marginHorizontal12Vertical4,
          padding: AppDimens.paddingHorizontal14Vertical12,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.transparent,
              width: isSelected ? AppDimens.borderWidth15 : 0,
            ),
          ),
          child: Row(
            children: [
              Text(
                info.name,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: AppDimens.iconSize22,
                  height: AppDimens.iconSize22,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppDimens.radiusCircle11,
                  ),
                  child: const Icon(LucideIcons.check,
                      size: AppDimens.iconSize14, color: AppColors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelSection(bool isDark, Color cardColor, Color textColor,
      Color subtitleColor, Color inputBgColor, Color borderColor) {
    final models = _currentModels;
    String selectedModelName = '';
    if (_isCustomProvider) {
      selectedModelName = _customModelController.text.trim();
      if (selectedModelName.isEmpty) {
        selectedModelName = AppStrings.aiCustomModel;
      }
    } else {
      final selectedModel = models.firstWhere(
          (m) => m.id == _selectedModel,
          orElse: () => models.isNotEmpty ? models[0] : const _ModelInfo('', ''));
      selectedModelName = selectedModel.name.isNotEmpty ? selectedModel.name : AppStrings.aiSelectModelHint;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        border: Border.all(color: borderColor, width: AppDimens.borderWidthSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: DeviceUtils.isPC()
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _isModelExpanded = !_isModelExpanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: AppDimens.paddingLeft16Right12Top16Bottom12,
                child: Row(
                  children: [
                    const Icon(LucideIcons.brain,
                        size: AppDimens.iconMd, color: AppColors.accent),
                    Gap.w8,
                    Text(
                      AppStrings.aiSelectModel,
                      style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeLg,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const Spacer(),
                    Text(
                      selectedModelName,
                      style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor),
                    ),
                    Gap.w8,
                    AnimatedRotation(
                      turns: _isModelExpanded ? 0.5 : 0,
                      duration: AppDurations.normal,
                      child: Icon(LucideIcons.chevronDown,
                          size: AppDimens.iconMd, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.normal,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _isModelExpanded
                  ? [
                      if (_isCustomProvider)
                        Padding(
                          padding: AppDimens.paddingLeft12Right12Top0Bottom16,
                          child: _buildTextField(
                            controller: _customModelController,
                            hintText: AppStrings.aiEnterModelName,
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            inputBgColor: inputBgColor,
                          ),
                        )
                      else ...[
                          ...models.map((m) => _buildModelTile(
                              m, isDark, textColor, subtitleColor, borderColor)),
                          Gap.h12,
                        ],
                    ]
                  : [Gap.h0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTile(_ModelInfo info, bool isDark, Color textColor,
      Color subtitleColor, Color borderColor) {
    final isSelected = _selectedModel == info.id;
    return MouseRegion(
      cursor: DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () {
          if (_selectedModel == info.id) return;
          setState(() => _selectedModel = info.id);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: AppDimens.marginHorizontal12Vertical4,
          padding: AppDimens.paddingHorizontal14Vertical12,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.transparent,
              width: isSelected ? AppDimens.borderWidth15 : 0,
            ),
          ),
          child: Row(
            children: [
              Text(
                info.name,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: AppDimens.iconSize22,
                  height: AppDimens.iconSize22,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppDimens.radiusCircle11,
                  ),
                  child: const Icon(LucideIcons.check,
                      size: AppDimens.iconSize14, color: AppColors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeySection(bool isDark, Color cardColor, Color textColor,
      Color subtitleColor, Color inputBgColor, Color borderColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        border: Border.all(color: borderColor, width: AppDimens.borderWidthSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppDimens.paddingLeft16Right12Top16Bottom12,
            child: Row(
              children: [
                const Icon(LucideIcons.key, size: AppDimens.iconMd, color: AppColors.accent),
                Gap.w8,
                Text(
                  AppStrings.aiApiKey,
                  style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeLg,
                      fontWeight: FontWeight.w600,
                      color: textColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppDimens.paddingHorizontal12,
            child: Text(
              AppStrings.aiApiKeySecureStorage,
              style: FontUtils.poppins(fontSize: AppDimens.fontSizeXs, color: subtitleColor),
            ),
          ),
          Gap.h10,
          Padding(
            padding: AppDimens.paddingLeft12Right12Top0Bottom16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _apiKeyController,
                        hintText: AppStrings.aiApiKeyHint,
                        obscureText: _obscureApiKey,
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        inputBgColor: inputBgColor,
                        suffixIcon: MouseRegion(
                          cursor: DeviceUtils.isPC()
                              ? SystemMouseCursors.click
                              : MouseCursor.defer,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _obscureApiKey = !_obscureApiKey),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(AppDimens.spacingMd),
                              child: Icon(
                                _obscureApiKey
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: AppDimens.iconMd,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Gap.w10,
                    _buildMiniButton(
                      onTap: _isTesting ? null : _testConnection,
                      icon: LucideIcons.wifi,
                      label: AppStrings.aiTestConnection,
                      isLoading: _isTesting,
                      isDark: isDark,
                      isPrimary: false,
                    ),
                  ],
                ),
                if (_supportsBalance)
                  Padding(
                    padding: AppDimens.paddingTop16,
                    child: _buildBalanceInfo(isDark, textColor, subtitleColor),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(bool isDark, Color textColor, Color subtitleColor) {
    String formatBalance(dynamic value) {
      if (value == null) return '-';
      return value.toString();
    }

    return Container(
      width: double.infinity,
      padding: AppDimens.paddingAll14,
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wallet, size: AppDimens.iconSm, color: AppColors.accent),
              Gap.w6,
              Text(
                AppStrings.aiBalance,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          Gap.h8,
          if (_isCheckingBalance)
            Row(
              children: [
                const SizedBox(
                  width: AppDimens.iconSm,
                  height: AppDimens.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: AppDimens.borderWidthMd,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                Gap.w8,
                Text(
                  AppStrings.aiBalanceChecking,
                  style: FontUtils.poppins(fontSize: AppDimens.fontSizeSm, color: subtitleColor),
                ),
              ],
            )
          else if (_balanceQueryFailed)
            Text(
              AppStrings.aiBalanceQueryFailed,
              style: FontUtils.poppins(fontSize: AppDimens.fontSizeSm, color: AppColors.redAccent),
            )
          else if (_balanceInfo == null)
            Text(
              AppStrings.aiBalanceHint,
              style: FontUtils.poppins(fontSize: AppDimens.fontSizeSm, color: subtitleColor),
            )
          else if (_balanceInfo![AppConfig.jsonBalanceInfos] != null)
            ...(_balanceInfo![AppConfig.jsonBalanceInfos] as List).map((info) {
              return Padding(
                padding: AppDimens.paddingBottom4,
                child: Text(
                  '${info[AppConfig.jsonCurrency] ?? ''}: ${formatBalance(info[AppConfig.jsonTotalBalance])}',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              );
            })
          else if (_balanceInfo![AppConfig.jsonIsAvailable] != null)
            Text(
              AppStrings.aiAvailableBalance.replaceAll('%s', formatBalance(_balanceInfo![AppConfig.jsonAvailableBalance])),
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            )
          else
            Text(
              AppStrings.aiBalanceInfo.replaceAll('%s', _balanceInfo.toString()),
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeSm,
                color: subtitleColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(bool isDark, Color cardColor, Color textColor,
      Color subtitleColor, Color borderColor) {
    return MouseRegion(
      cursor: DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: _clearChatHistory,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: AppDimens.paddingVertical14,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
            border: Border.all(color: borderColor, width: AppDimens.borderWidthSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.trash2, size: AppDimens.iconMd, color: AppColors.redAccent),
              Gap.w8,
              Text(
                AppStrings.aiDeleteConversation,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required Color inputBgColor,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: FontUtils.poppins(fontSize: AppDimens.fontSizeMd, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: FontUtils.poppins(fontSize: AppDimens.fontSizeMd, color: subtitleColor),
        filled: true,
        fillColor: inputBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            AppDimens.paddingHorizontal14Vertical14,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildMiniButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
    required bool isLoading,
    required bool isDark,
    required bool isPrimary,
  }) {
    return MouseRegion(
      cursor: DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          padding: AppDimens.paddingHorizontal14Vertical14,
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.accent
                : (isDark ? AppColors.cardDark : AppColors.white),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: isPrimary
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.borderDark
                      : AppColors.gray200),
              width: AppDimens.borderWidthSm,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: AppDimens.iconMd,
                    height: AppDimens.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimens.borderWidthMd,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimary ? AppColors.white : AppColors.accent,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: AppDimens.iconSm,
                          color: isPrimary
                              ? AppColors.white
                              : AppColors.accent),
                      Gap.w4,
                      Text(
                        label,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeSm,
                          fontWeight: FontWeight.w600,
                          color: isPrimary
                              ? AppColors.white
                              : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget buildFeatureRow(String title, String desc, Color subtitleColor) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: AppDimens.iconSm, color: AppColors.accent),
        Gap.w8,
        Text(
          '$title - $desc',
          style: FontUtils.poppins(fontSize: AppDimens.fontSizeSm, color: subtitleColor),
        ),
      ],
    );
  }

}

class _ProviderInfo {
  final String id;
  final String name;
  final List<_ModelInfo> models;

  const _ProviderInfo({
    required this.id,
    required this.name,
    required this.models,
  });
}

class _ModelInfo {
  final String id;
  final String name;

  const _ModelInfo(this.id, this.name);
}
