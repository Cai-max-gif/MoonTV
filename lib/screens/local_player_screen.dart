import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_player_surface.dart';
import '../utils/device_utils.dart';
import '../constants/app_colors.dart';

class LocalPlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const LocalPlayerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: VideoPlayerWidget(
        surface: DeviceUtils.isPC()
            ? VideoPlayerSurface.desktop
            : VideoPlayerSurface.mobile,
        url: File(widget.filePath).uri.toString(),
        onBackPressed: _onBackPressed,
        videoTitle: widget.title,
        live: false,
        isLocalFile: true,
      ),
    );
  }
}
