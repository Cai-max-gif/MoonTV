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
  String _selectedProvider = 'openai';
  final TextEditingController _apiKeyController = TextEditingController();
  String _selectedModel = 'gpt-4o';
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
      id: 'openai',
      name: 'OpenAI',
      models: [
        _ModelInfo('gpt-5.5-pro', 'GPT-5.5 Pro'),
        _ModelInfo('gpt-5.5', 'GPT-5.5'),
        _ModelInfo('gpt-5.4', 'GPT-5.4'),
        _ModelInfo('gpt-5.3-codex', 'GPT-5.3 Codex'),
      ],
    ),
    _ProviderInfo(
      id: 'deepseek',
      name: 'DeepSeek',
      models: [
        _ModelInfo('deepseek-v4-pro', 'DeepSeek-V4-Pro'),
        _ModelInfo('deepseek-v4-flash', 'DeepSeek-V4-Flash'),
      ],
    ),
    _ProviderInfo(
      id: 'zhipu',
      name: '智谱 AI (GLM)',
      models: [
        _ModelInfo('glm-5.2', 'GLM-5.2'),
        _ModelInfo('glm-5.1', 'GLM-5.1'),
        _ModelInfo('glm-4.7', 'GLM-4.7'),
        _ModelInfo('glm-4.5', 'GLM-4.5'),
      ],
    ),
    _ProviderInfo(
      id: 'moonshot',
      name: 'Moonshot (Kimi)',
      models: [
        _ModelInfo('kimi-k2.7-code', 'Kimi K2.7 Code'),
        _ModelInfo('kimi-k2.6', 'Kimi K2.6'),
        _ModelInfo('kimi-k2.5', 'Kimi K2.5'),
      ],
    ),
    _ProviderInfo(
      id: 'mimo',
      name: 'MiMo',
      models: [
        _ModelInfo('mimo-v2.5-pro', 'MiMo V2.5 Pro'),
        _ModelInfo('mimo-v2.5', 'MiMo V2.5'),
      ],
    ),
    _ProviderInfo(
      id: 'custom',
      name: '自定义',
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
      if (settings.provider == 'custom') {
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

  bool get _supportsBalance => _selectedProvider == 'deepseek' || _selectedProvider == 'moonshot';

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

  bool get _isCustomProvider => _selectedProvider == 'custom';

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
            '清空聊天记录',
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeXl,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.primary,
            ),
          ),
          content: Text(
            '确定要清空所有聊天记录吗？此操作不可恢复。',
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
        _showSnack('聊天记录已清空', true);
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
          '设置已保存',
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
            isDark ? AppColors.darkDivider : AppColors.grayBorder;

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
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
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
        border: Border.all(color: borderColor, width: 1),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
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
                      if (_selectedProvider == 'custom')
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 8, 12, 16),
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
                  : [const SizedBox(height: 0)],
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
            if (info.id == 'custom') {
              _baseUrlController.clear();
              _customModelController.clear();
            } else if (info.models.isNotEmpty) {
              _selectedModel = info.models.first.id;
            }
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.transparent,
              width: isSelected ? 1.5 : 0,
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
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(LucideIcons.check,
                      size: 14, color: AppColors.white),
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
        selectedModelName = '自定义模型';
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
        border: Border.all(color: borderColor, width: 1),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
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
                          padding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: _buildTextField(
                            controller: _customModelController,
                            hintText: '输入模型名称',
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
                  : [const SizedBox(height: 0)],
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
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.transparent,
              width: isSelected ? 1.5 : 0,
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
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(LucideIcons.check,
                      size: 14, color: AppColors.white),
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
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '密钥将安全地加密存储在本机',
              style: FontUtils.poppins(fontSize: AppDimens.fontSizeXs, color: subtitleColor),
            ),
          ),
          Gap.h10,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _apiKeyController,
                        hintText: 'sk-xxxxxxxxxxxxxxxx',
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
                    padding: const EdgeInsets.only(top: 16),
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
      padding: const EdgeInsets.all(14),
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
                '账户余额',
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                Gap.w8,
                Text(
                  '查询中...',
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
          else if (_balanceInfo!['balance_infos'] != null)
            ...(_balanceInfo!['balance_infos'] as List).map((info) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${info['currency'] ?? ''}: ${formatBalance(info['total_balance'])}',
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              );
            })
          else if (_balanceInfo!['is_available'] != null)
            Text(
              '可用余额: ${formatBalance(_balanceInfo!['available_balance'])}',
              style: FontUtils.poppins(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            )
          else
            Text(
              '余额信息: ${_balanceInfo.toString()}',
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.trash2, size: AppDimens.iconMd, color: AppColors.redAccent),
              Gap.w8,
              Text(
                '删除对话',
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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.accent
                : (isDark ? AppColors.cardDark : AppColors.white),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: isPrimary
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.darkDivider
                      : AppColors.grayBorder),
              width: 1,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
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
