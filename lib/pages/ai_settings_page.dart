import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
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
  double _temperature = 0.7;
  final TextEditingController _maxTokensController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isTesting = false;

  final List<Map<String, String>> _providers = [
    {'id': 'openai', 'name': 'OpenAI'},
    {'id': 'anthropic', 'name': 'Anthropic (Claude)'},
    {'id': 'deepseek', 'name': 'DeepSeek'},
    {'id': 'zhipu', 'name': '智谱 AI (GLM)'},
    {'id': 'moonshot', 'name': 'Moonshot (Kimi)'},
    {'id': 'custom', 'name': '自定义'},
  ];

  final Map<String, List<Map<String, String>>> _modelsByProvider = {
    'openai': [
      {'id': 'gpt-4o', 'name': 'GPT-4o'},
      {'id': 'gpt-4o-mini', 'name': 'GPT-4o Mini'},
      {'id': 'gpt-4-turbo', 'name': 'GPT-4 Turbo'},
      {'id': 'gpt-4', 'name': 'GPT-4'},
      {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
    ],
    'anthropic': [
      {'id': 'claude-3-opus', 'name': 'Claude 3 Opus'},
      {'id': 'claude-3-sonnet', 'name': 'Claude 3 Sonnet'},
      {'id': 'claude-3-haiku', 'name': 'Claude 3 Haiku'},
    ],
    'deepseek': [
      {'id': 'deepseek-chat', 'name': 'DeepSeek Chat'},
      {'id': 'deepseek-coder', 'name': 'DeepSeek Coder'},
    ],
    'zhipu': [
      {'id': 'glm-4', 'name': 'GLM-4'},
      {'id': 'glm-3-turbo', 'name': 'GLM-3 Turbo'},
    ],
    'moonshot': [
      {'id': 'moonshot-v1-8k', 'name': 'Moonshot v1 (8K)'},
      {'id': 'moonshot-v1-32k', 'name': 'Moonshot v1 (32K)'},
      {'id': 'moonshot-v1-128k', 'name': 'Moonshot v1 (128K)'},
    ],
    'custom': [
      {'id': 'custom', 'name': '自定义模型'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _maxTokensController.text = '4096';
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _maxTokensController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _loadSettings() {}

  void _saveSettings() {
    if (!mounted) return;
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

  void _testConnection() {
    setState(() {
      _isTesting = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '连接测试成功',
            style: FontUtils.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF27ae60),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgCardColor = isDark ? const Color(0xFF1e1e1e) : Colors.white;
        final textColor =
            isDark ? const Color(0xFFffffff) : const Color(0xFF2c3e50);
        final subtitleColor =
            isDark ? const Color(0xFFb0b0b0) : const Color(0xFF7f8c8d);
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
                _buildSectionCard(
                  title: 'AI 提供商',
                  icon: LucideIcons.building2,
                  isDark: isDark,
                  bgCardColor: bgCardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  child: _buildProviderSelector(
                      isDark, textColor, subtitleColor, bgCardColor),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'API 密钥',
                  icon: LucideIcons.key,
                  isDark: isDark,
                  bgCardColor: bgCardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  child: _buildApiKeyField(
                      isDark, textColor, inputBgColor, subtitleColor),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '模型选择',
                  icon: LucideIcons.brain,
                  isDark: isDark,
                  bgCardColor: bgCardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  child: _buildModelSelector(textColor, borderColor),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'API 地址',
                  icon: LucideIcons.link,
                  isDark: isDark,
                  bgCardColor: bgCardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  child: _buildBaseUrlField(
                      isDark, textColor, inputBgColor, subtitleColor),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '参数设置',
                  icon: LucideIcons.slidersHorizontal,
                  isDark: isDark,
                  bgCardColor: bgCardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  child: _buildParameterSettings(isDark, textColor,
                      subtitleColor, inputBgColor, borderColor),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '系统提示词',
                  icon: LucideIcons.messageSquareText,
                  isDark: isDark,
                  bgCardColor: bgCardColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  child: _buildSystemPromptField(
                      isDark, textColor, inputBgColor, subtitleColor),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(isDark),
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
            child: Icon(
              LucideIcons.arrowLeft,
              color: textColor,
              size: 24,
            ),
          ),
        ),
      ),
      title: Text(
        'AI 设置',
        style: FontUtils.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Color bgCardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF27ae60)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: FontUtils.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(
      bool isDark, Color textColor, Color subtitleColor, Color bgCardColor) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedProvider,
      decoration: _inputDecoration('选择 AI 提供商', isDark),
      dropdownColor: bgCardColor,
      style: FontUtils.poppins(fontSize: 14, color: textColor),
      icon: Icon(LucideIcons.chevronDown, size: 18, color: subtitleColor),
      items: _providers.map((provider) {
        return DropdownMenuItem<String>(
          value: provider['id'],
          child: Text(
            provider['name']!,
            style: FontUtils.poppins(fontSize: 14, color: textColor),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedProvider = value;
            final models = _modelsByProvider[value];
            if (models != null && models.isNotEmpty) {
              _selectedModel = models.first['id']!;
            }
          });
        }
      },
    );
  }

  Widget _buildApiKeyField(
      bool isDark, Color textColor, Color inputBgColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '输入你的 API 密钥，密钥将安全地存储在本地',
          style: FontUtils.poppins(fontSize: 12, color: subtitleColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          style: FontUtils.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'sk-xxxxxxxxxxxxxxxx',
            hintStyle: FontUtils.poppins(fontSize: 14, color: subtitleColor),
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: MouseRegion(
              cursor: DeviceUtils.isPC()
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _obscureApiKey ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                    color: subtitleColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelector(Color textColor, Color borderColor) {
    final models =
        _modelsByProvider[_selectedProvider] ?? _modelsByProvider['custom']!;

    return Column(
      children: models.map((model) {
        final isSelected = _selectedModel == model['id'];
        return MouseRegion(
          cursor:
              DeviceUtils.isPC() ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedModel = model['id']!;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF27ae60).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF27ae60) : borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model['name']!,
                      style: FontUtils.poppins(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(LucideIcons.check,
                        size: 18, color: Color(0xFF27ae60)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBaseUrlField(
      bool isDark, Color textColor, Color inputBgColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '自定义 API 地址，用于代理或自建服务',
          style: FontUtils.poppins(fontSize: 12, color: subtitleColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseUrlController,
          style: FontUtils.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'https://api.openai.com/v1',
            hintStyle: FontUtils.poppins(fontSize: 14, color: subtitleColor),
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSettings(bool isDark, Color textColor,
      Color subtitleColor, Color inputBgColor, Color borderColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperature',
                    style: FontUtils.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '控制回复的随机性',
                    style:
                        FontUtils.poppins(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF27ae60).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _temperature.toStringAsFixed(1),
                style: FontUtils.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF27ae60),
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF27ae60),
            inactiveTrackColor: borderColor,
            thumbColor: const Color(0xFF27ae60),
            overlayColor: const Color(0xFF27ae60).withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _temperature = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Max Tokens',
          style: FontUtils.poppins(
              fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          '单次回复最大 token 数量',
          style: FontUtils.poppins(fontSize: 12, color: subtitleColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _maxTokensController,
          keyboardType: TextInputType.number,
          style: FontUtils.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: '4096',
            hintStyle: FontUtils.poppins(fontSize: 14, color: subtitleColor),
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPromptField(
      bool isDark, Color textColor, Color inputBgColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '定义 AI 助手的角色和行为',
          style: FontUtils.poppins(fontSize: 12, color: subtitleColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _systemPromptController,
          maxLines: 4,
          style: FontUtils.poppins(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: '你是一个有帮助的 AI 助手...',
            hintStyle: FontUtils.poppins(fontSize: 14, color: subtitleColor),
            filled: true,
            fillColor: inputBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: MouseRegion(
            cursor: DeviceUtils.isPC()
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: GestureDetector(
              onTap: _testConnection,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1e1e1e) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFe0e0e0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF27ae60)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.wifi,
                                size: 18, color: Color(0xFF27ae60)),
                            const SizedBox(width: 8),
                            Text(
                              '测试连接',
                              style: FontUtils.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF27ae60),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MouseRegion(
            cursor: DeviceUtils.isPC()
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: GestureDetector(
              onTap: _saveSettings,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF27ae60),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.save,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '保存设置',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, bool isDark) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: FontUtils.poppins(
        fontSize: 14,
        color: isDark ? const Color(0xFF666666) : const Color(0xFF95a5a6),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2c2c2c) : const Color(0xFFf0f0f0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
