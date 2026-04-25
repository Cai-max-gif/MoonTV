import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/user_data_service.dart';
import '../utils/font_utils.dart';

class DanmakuSettingsScreen extends StatefulWidget {
  const DanmakuSettingsScreen({super.key});

  @override
  State<DanmakuSettingsScreen> createState() => _DanmakuSettingsScreenState();
}

class _DanmakuSettingsScreenState extends State<DanmakuSettingsScreen> {
  // 外观设置
  bool _danmakuEnabled = true;
  double _danmakuOpacity = 0.8;
  double _danmakuFontSize = 24;
  int _danmakuDisplayArea = 50; // 百分比
  String _danmakuColor = 'white';

  // 同步设置
  bool _danmakuSyncEnabled = true;
  bool _autoLoadDanmaku = true;
  bool _showDanmakuTimestamp = true;

  @override
  void initState() {
    super.initState();
    _loadDanmakuSettings();
  }

  Future<void> _loadDanmakuSettings() async {
    // 这里可以从 UserDataService 加载设置，暂时使用默认值
    setState(() {
      _danmakuEnabled = true;
      _danmakuOpacity = 0.8;
      _danmakuFontSize = 24;
      _danmakuDisplayArea = 50;
      _danmakuColor = 'white';
      _danmakuSyncEnabled = true;
      _autoLoadDanmaku = true;
      _showDanmakuTimestamp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFf5f5f5),
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
          '弹幕设置',
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
          // 外观设置
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
                      LucideIcons.palette,
                      size: 24,
                      color: Color(0xFFec4899),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '外观设置',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 弹幕开关
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '启用弹幕',
                        style: FontUtils.poppins(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                        ),
                      ),
                      Switch(
                        value: _danmakuEnabled,
                        onChanged: (value) {
                          setState(() {
                            _danmakuEnabled = value;
                          });
                        },
                        activeThumbColor: const Color(0xFFec4899),
                        inactiveTrackColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),

                // 弹幕透明度
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '弹幕透明度',
                            style: FontUtils.poppins(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                            ),
                          ),
                          Text(
                            '${(_danmakuOpacity * 100).round()}%',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _danmakuOpacity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            _danmakuOpacity = value;
                          });
                        },
                        activeColor: const Color(0xFFec4899),
                        inactiveColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),

                // 弹幕字体大小
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '弹幕字体大小',
                            style: FontUtils.poppins(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                            ),
                          ),
                          Text(
                            '${_danmakuFontSize.round()}px',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _danmakuFontSize,
                        min: 12,
                        max: 36,
                        onChanged: (value) {
                          setState(() {
                            _danmakuFontSize = value;
                          });
                        },
                        activeColor: const Color(0xFFec4899),
                        inactiveColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),

                // 弹幕显示区域
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '弹幕显示区域',
                            style: FontUtils.poppins(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                            ),
                          ),
                          Text(
                            '$_danmakuDisplayArea%',
                            style: FontUtils.poppins(
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _danmakuDisplayArea.toDouble(),
                        min: 25,
                        max: 100,
                        onChanged: (value) {
                          setState(() {
                            _danmakuDisplayArea = value.round();
                          });
                        },
                        activeColor: const Color(0xFFec4899),
                        inactiveColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),

                // 弹幕颜色
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '弹幕颜色',
                        style: FontUtils.poppins(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _danmakuColor,
                        onChanged: (value) {
                          setState(() {
                            _danmakuColor = value!;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'white',
                            child: Text('白色'),
                          ),
                          DropdownMenuItem(
                            value: 'yellow',
                            child: Text('黄色'),
                          ),
                          DropdownMenuItem(
                            value: 'red',
                            child: Text('红色'),
                          ),
                          DropdownMenuItem(
                            value: 'blue',
                            child: Text('蓝色'),
                          ),
                        ],
                        dropdownColor: isDarkMode ? const Color(0xFF374151) : Colors.white,
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 同步设置
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
                      LucideIcons.sync,
                      size: 24,
                      color: Color(0xFF3b82f6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '同步设置',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 弹幕同步开关
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '启用弹幕同步',
                        style: FontUtils.poppins(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                        ),
                      ),
                      Switch(
                        value: _danmakuSyncEnabled,
                        onChanged: (value) {
                          setState(() {
                            _danmakuSyncEnabled = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF3b82f6),
                        inactiveTrackColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),

                // 自动加载弹幕
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '自动加载弹幕',
                        style: FontUtils.poppins(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                        ),
                      ),
                      Switch(
                        value: _autoLoadDanmaku,
                        onChanged: (value) {
                          setState(() {
                            _autoLoadDanmaku = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF3b82f6),
                        inactiveTrackColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),

                // 显示弹幕时间戳
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '显示弹幕时间戳',
                        style: FontUtils.poppins(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white : const Color(0xFF1f2937),
                        ),
                      ),
                      Switch(
                        value: _showDanmakuTimestamp,
                        onChanged: (value) {
                          setState(() {
                            _showDanmakuTimestamp = value;
                          });
                        },
                        activeThumbColor: const Color(0xFF3b82f6),
                        inactiveTrackColor: isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFe5e7eb),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 说明文字
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFec4899).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFec4899).withAlpha(76),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 20,
                  color: Color(0xFFec4899),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '提示：调整弹幕设置可以获得更好的观看体验，根据网络状况和设备性能选择合适的设置。',
                    style: FontUtils.poppins(
                      fontSize: 14,
                      color: isDarkMode
                          ? const Color(0xFFec4899)
                          : const Color(0xFFbe185d),
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
