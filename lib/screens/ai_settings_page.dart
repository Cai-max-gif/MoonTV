import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/ai_service.dart';
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
        _ModelInfo('gpt-5.5', 'GPT-5.5'),
        _ModelInfo('gpt-5.4', 'GPT-5.4'),
        _ModelInfo('gpt-5.4-mini', 'GPT-5.4 Mini'),
      ],
    ),
    _ProviderInfo(
      id: 'deepseek',
      name: 'DeepSeek',
      models: [
        _ModelInfo('deepseek-v4-pro', 'V4-Pro'),
        _ModelInfo('deepseek-v4-flash', 'V4-Flash'),
        _ModelInfo('deepseek-chat', 'DeepSeek Chat'),
        _ModelInfo('deepseek-reasoner', 'DeepSeek Reasoner'),
      ],
    ),
    _ProviderInfo(
      id: 'zhipu',
      name: '智谱 AI (GLM)',
      models: [
        _ModelInfo('glm-5.1', 'GLM-5.1'),
        _ModelInfo('glm-5', 'GLM-5'),
        _ModelInfo('glm-5-turbo', 'GLM-5 Turbo'),
        _ModelInfo('glm-4.7', 'GLM-4.7'),
        _ModelInfo('glm-4.6', 'GLM-4.6'),
        _ModelInfo('glm-4.5', 'GLM-4.5'),
      ],
    ),
    _ProviderInfo(
      id: 'moonshot',
      name: 'Moonshot (Kimi)',
      models: [
        _ModelInfo('kimi-k2.6', 'Kimi K2.6'),
        _ModelInfo('kimi-k2.5', 'Kimi K2.5'),
        _ModelInfo('moonshot-v1-8k', 'Moonshot v1 (8K)'),
        _ModelInfo('moonshot-v1-32k', 'Moonshot v1 (32K)'),
        _ModelInfo('moonshot-v1-128k', 'Moonshot v1 (128K)'),
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

  Future<void> _loadSettings() async {
    final settings = await AIService.loadSettings();
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

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
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
          backgroundColor: isDark ? const Color(0xFF1e1e1e) : Colors.white,
          title: Text(
            '清空聊天记录',
            style: FontUtils.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2c3e50),
            ),
          ),
          content: Text(
            '确定要清空所有聊天记录吗？此操作不可恢复。',
            style: FontUtils.poppins(
              fontSize: 14,
              color: isDark ? const Color(0xFFb0b0b0) : const Color(0xFF7f8c8d),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                '取消',
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFb0b0b0)
                      : const Color(0xFF7f8c8d),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                '确定',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF27ae60),
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
      _showSnack('请输入模型名称', false);
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
          style: FontUtils.poppins(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF27ae60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showSnack('请先输入API密钥', false);
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
      success ? '连接成功' : '连接失败，请检查密钥和网络',
      success,
    );
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FontUtils.poppins(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF27ae60) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final textColor =
            isDark ? const Color(0xFFffffff) : const Color(0xFF2c3e50);
        final subtitleColor =
            isDark ? const Color(0xFFb0b0b0) : const Color(0xFF7f8c8d);
        final cardColor = isDark ? const Color(0xFF1e1e1e) : Colors.white;
        final inputBgColor =
            isDark ? const Color(0xFF2c2c2c) : const Color(0xFFf0f0f0);
        final borderColor =
            isDark ? const Color(0xFF333333) : const Color(0xFFe0e0e0);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
          appBar: _buildAppBar(isDark, textColor),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProviderSection(isDark, cardColor, textColor,
                    subtitleColor, inputBgColor, borderColor),
                const SizedBox(height: 16),
                _buildModelSection(isDark, cardColor, textColor, subtitleColor,
                    inputBgColor, borderColor),
                const SizedBox(height: 16),
                _buildApiKeySection(isDark, cardColor, textColor, subtitleColor,
                    inputBgColor, borderColor),
                const SizedBox(height: 16),
                _buildDeleteButton(isDark, cardColor, textColor, subtitleColor, borderColor),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1e1e1e) : Colors.white,
      elevation: 0,
      leading: MouseRegion(
        cursor:
            DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(LucideIcons.arrowLeft, color: textColor, size: 24),
          ),
        ),
      ),
      title: Text(
        'AI 设置',
        style: FontUtils.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.save, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          '保存',
                          style: FontUtils.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
        borderRadius: BorderRadius.circular(14),
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
                        size: 18, color: Color(0xFF27ae60)),
                    const SizedBox(width: 8),
                    Text(
                      '选择提供商',
                      style: FontUtils.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const Spacer(),
                    Text(
                      selectedProviderName,
                      style: FontUtils.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isProviderExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(LucideIcons.chevronDown,
                          size: 18, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
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
                            hintText: 'https://api.openai.com',
                            isDark: isDark,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            inputBgColor: inputBgColor,
                          ),
                        )
                      else
                        const SizedBox(height: 12),
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
                ? const Color(0xFF27ae60)
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF27ae60) : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Row(
            children: [
              Text(
                info.name,
                style: FontUtils.poppins(
                  fontSize: 14,
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
                    color: const Color(0xFF27ae60),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(LucideIcons.check,
                      size: 14, color: Colors.white),
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
      selectedModelName = selectedModel.name.isNotEmpty ? selectedModel.name : '请选择模型';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
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
                        size: 18, color: Color(0xFF27ae60)),
                    const SizedBox(width: 8),
                    Text(
                      '选择模型',
                      style: FontUtils.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const Spacer(),
                    Text(
                      selectedModelName,
                      style: FontUtils.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isModelExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(LucideIcons.chevronDown,
                          size: 18, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
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
                        const SizedBox(height: 12),
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
                ? const Color(0xFF27ae60)
                    .withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF27ae60) : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          ),
          child: Row(
            children: [
              Text(
                info.name,
                style: FontUtils.poppins(
                  fontSize: 14,
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
                    color: const Color(0xFF27ae60),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(LucideIcons.check,
                      size: 14, color: Colors.white),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(LucideIcons.key, size: 18, color: Color(0xFF27ae60)),
                const SizedBox(width: 8),
                Text(
                  'API 密钥',
                  style: FontUtils.poppins(
                      fontSize: 15,
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
              style: FontUtils.poppins(fontSize: 12, color: subtitleColor),
            ),
          ),
          const SizedBox(height: 10),
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
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _obscureApiKey
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                size: 18,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildMiniButton(
                      onTap: _isTesting ? null : _testConnection,
                      icon: LucideIcons.wifi,
                      label: '测试',
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
        color: isDark ? const Color(0xFF2c2c2c) : const Color(0xFFf0f0f0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wallet, size: 16, color: Color(0xFF27ae60)),
              const SizedBox(width: 6),
              Text(
                '账户余额',
                style: FontUtils.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isCheckingBalance)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '查询中...',
                  style: FontUtils.poppins(fontSize: 13, color: subtitleColor),
                ),
              ],
            )
          else if (_balanceQueryFailed)
            Text(
              '连接失败请检查密钥',
              style: FontUtils.poppins(fontSize: 13, color: Colors.redAccent),
            )
          else if (_balanceInfo == null)
            Text(
              '请输入API密钥查询余额',
              style: FontUtils.poppins(fontSize: 13, color: subtitleColor),
            )
          else if (_balanceInfo!['balance_infos'] != null)
            ...(_balanceInfo!['balance_infos'] as List).map((info) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${info['currency'] ?? ''}: ${formatBalance(info['total_balance'])}',
                  style: FontUtils.poppins(
                    fontSize: 14,
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            )
          else
            Text(
              '余额信息: ${_balanceInfo.toString()}',
              style: FontUtils.poppins(
                fontSize: 13,
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                '删除对话',
                style: FontUtils.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
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
      style: FontUtils.poppins(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: FontUtils.poppins(fontSize: 14, color: subtitleColor),
        filled: true,
        fillColor: inputBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF27ae60)
                : (isDark ? const Color(0xFF1e1e1e) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF27ae60)
                  : (isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFe0e0e0)),
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
                        isPrimary ? Colors.white : const Color(0xFF27ae60),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 16,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF27ae60)),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: FontUtils.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF27ae60),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
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
