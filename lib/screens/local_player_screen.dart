import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/video_player_surface.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
          ),
          onPressed: _onBackPressed,
        ),
        title: Text(
          widget.title,
          style: FontUtils.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: VideoPlayerWidget(
            surface: DeviceUtils.isPC()
                ? VideoPlayerSurface.desktop
                : VideoPlayerSurface.mobile,
            url: File(widget.filePath).uri.toString(),
            onBackPressed: _onBackPressed,
            videoTitle: widget.title,
            live: false,
          ),
        ),
      ),
    );
  }
}
