import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../services/theme_service.dart';
import '../services/ai_service.dart';
import '../utils/font_utils.dart';
import '../utils/device_utils.dart';
import 'ai_settings_page.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  AISettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadAISettings();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAISettings() async {
    final settings = await AIService.loadSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final history = await AIService.loadChatHistory();
    if (mounted && history.isNotEmpty) {
      setState(() {
        _messages.clear();
        _messages.addAll(history);
      });
    }
  }

  Future<void> _saveChatHistory() async {
    await AIService.saveChatHistory(_messages);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_settings == null || !_settings!.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '请先在设置中配置AI API密钥',
              style: FontUtils.poppins(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _saveChatHistory();

    final settings = _settings!;
    final history = _buildConversationHistory();

    try {
      final reply = await AIService.sendMessage(
        settings: settings,
        userMessage: message,
        conversationHistory: history,
      );

      if (mounted) {
        setState(() {
          _messages.add({
            'text': reply,
            'isUser': false,
          });
          _isLoading = false;
        });
        _saveChatHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': '错误：${e.toString()}',
            'isUser': false,
            'isError': true,
          });
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, String>> _buildConversationHistory() {
    final history = <Map<String, String>>[];
    final startIndex = (_messages.length > 20) ? _messages.length - 10 : 0;
    for (int i = startIndex; i < _messages.length; i++) {
      final msg = _messages[i];
      history.add({
        'role': msg['isUser'] ? 'user' : 'assistant',
        'content': msg['text'].toString(),
      });
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.isDarkMode
              ? const Color(0xFF000000)
              : const Color(0xFFf5f5f5),
          appBar: AppBar(
            backgroundColor: themeService.isDarkMode
                ? const Color(0xFF1e1e1e)
                : Colors.white,
            elevation: 0,
            leading: MouseRegion(
              cursor: DeviceUtils.isPC()
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: themeService.isDarkMode
                        ? const Color(0xFFffffff)
                        : const Color(0xFF2c3e50),
                    size: 24,
                  ),
                ),
              ),
            ),
            title: Text(
              'AI 助手',
              style: FontUtils.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.isDarkMode
                    ? const Color(0xFFffffff)
                    : const Color(0xFF2c3e50),
              ),
            ),
            centerTitle: true,
            actions: [
              MouseRegion(
                cursor: DeviceUtils.isPC()
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AISettingsPage()),
                    );
                    _loadAISettings();
                    _loadChatHistory();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      LucideIcons.settings,
                      color: themeService.isDarkMode
                          ? const Color(0xFFffffff)
                          : const Color(0xFF2c3e50),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // 对话区域
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == 0) {
                      return _buildLoadingIndicator(themeService);
                    }
                    final messageIndex = _isLoading ? index - 1 : index;
                    if (messageIndex >= 0 && messageIndex < _messages.length) {
                      final message = _messages[_messages.length - 1 - messageIndex];
                      return _buildMessageBubble(message, themeService);
                    }
                    return null;
                  },
                ),
              ),
              // 输入区域
              _buildInputArea(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, ThemeService themeService) {
    final isUser = message['isUser'] as bool;
    final isError = message['isError'] as bool? ?? false;
    final bgColor = isUser
        ? const Color(0xFF27ae60)
        : isError
            ? Colors.redAccent.withValues(alpha: 0.15)
            : themeService.isDarkMode
                ? const Color(0xFF1e1e1e)
                : const Color(0xFFe0e0e0);
    final textColor = isUser
        ? Colors.white
        : isError
            ? Colors.redAccent
            : themeService.isDarkMode
                ? const Color(0xFFffffff)
                : const Color(0xFF2c3e50);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: isUser || isError
            ? Text(
                message['text'].toString(),
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: textColor,
                ),
              )
            : GptMarkdown(
                message['text'].toString(),
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeService themeService) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeService.isDarkMode
              ? const Color(0xFF1e1e1e)
              : const Color(0xFFe0e0e0),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27ae60)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI 正在思考...',
              style: FontUtils.poppins(
                fontSize: 14,
                color: themeService.isDarkMode
                    ? const Color(0xFFffffff)
                    : const Color(0xFF2c3e50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeService.isDarkMode ? const Color(0xFF1e1e1e) : Colors.white,
        border: Border(
          top: BorderSide(
            color: themeService.isDarkMode
                ? const Color(0xFF333333)
                : const Color(0xFFe0e0e0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: themeService.isDarkMode
                    ? const Color(0xFF2c2c2c)
                    : const Color(0xFFf0f0f0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintStyle: FontUtils.poppins(
                    color: themeService.isDarkMode
                        ? const Color(0xFF666666)
                        : const Color(0xFF95a5a6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: themeService.isDarkMode
                      ? const Color(0xFFffffff)
                      : const Color(0xFF2c3e50),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: DeviceUtils.isPC()
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: GestureDetector(
              onTap: _sendMessage,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF27ae60),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
