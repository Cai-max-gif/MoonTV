import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // 模拟 AI 回复
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': '这是一个 AI 回复示例。你可以根据需要实现真正的 AI 功能。',
            'isUser': false,
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AISettingsPage()),
                    );
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _messages.length) {
                      final message = _messages[index];
                      return _buildMessageBubble(message, themeService);
                    } else {
                      return _buildLoadingIndicator(themeService);
                    }
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
    final isUser = message['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF27ae60)
              : themeService.isDarkMode
                  ? const Color(0xFF1e1e1e)
                  : const Color(0xFFe0e0e0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Text(
          message['text'],
          style: FontUtils.poppins(
            fontSize: 14,
            color: isUser
                ? Colors.white
                : themeService.isDarkMode
                    ? const Color(0xFFffffff)
                    : const Color(0xFF2c3e50),
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
                  hintText: '输入你的问题...',
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
