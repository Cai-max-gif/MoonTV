import 'package:flutter/material.dart';
import '../utils/font_utils.dart';

class SyncSettingsScreen extends StatelessWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '同步设置',
          style: FontUtils.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          '同步设置页面',
          style: FontUtils.poppins(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFffffff)
                : const Color(0xFF1f2937),
          ),
        ),
      ),
    );
  }
}
