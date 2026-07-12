import 'dart:async';
import '../constants/app_dimensions.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import '../utils/image_url.dart';
import '../utils/font_utils.dart';
import '../services/theme_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_durations.dart';
import '../constants/app_config.dart';

/// 全屏图片查看器
class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String source;
  final String title;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.source,
    required this.title,
  });

  /// 显示全屏图片查看器
  static void show(
    BuildContext context, {
    required String imageUrl,
    required String source,
    required String title,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullscreenImageViewer(
          imageUrl: imageUrl,
          source: source,
          title: title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: AppDurations.slow,
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  bool _isSaving = false;

  /// 显示保存图片选择菜单
  void _showSaveImageMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          final isDark = themeService.isDarkMode;
          final backgroundColor = isDark
              ? AppColors.cardDark.withValues(alpha: 0.95)
              : AppColors.white.withValues(alpha: 0.95);
          final textColor = isDark ? AppColors.white : AppColors.primary;
          final secondaryTextColor = isDark
              ? AppColors.white.withValues(alpha: 0.7)
              : AppColors.primary.withValues(alpha: 0.7);
          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: AppDimens.radius16,
                topRight: AppDimens.radius16,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Padding(
                    padding: AppDimens.paddingFromLTRB2020208,
                    child: Text(
                      AppStrings.screenshotSaved,
                      style: FontUtils.poppins(
                        color: textColor,
                        fontSize: AppDimens.fontSizeXxl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 选项列表
                  ListTile(
                    leading: Icon(
                      Icons.download,
                      color: textColor,
                    ),
                    title: Text(
                      AppStrings.saveToGallery,
                      style: FontUtils.poppins(
                        color: textColor,
                        fontSize: AppDimens.fontSizeXl,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _saveImageToGallery();
                    },
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.close,
                      color: secondaryTextColor,
                    ),
                    title: Text(
                      AppStrings.cancel,
                      style: FontUtils.poppins(
                        color: secondaryTextColor,
                        fontSize: AppDimens.fontSizeXl,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _checkStoragePermission() async {
    return true;
  }

  /// 保存图片到相册
  Future<void> _saveImageToGallery() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 检查权限
      final hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // 显示保存提示
      if (mounted) {
        final themeService = Provider.of<ThemeService>(context, listen: false);
        final isDark = themeService.isDarkMode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.imageSaving,
              style: FontUtils.poppins(
                color: isDark ? AppColors.white : AppColors.white,
              ),
            ),
            backgroundColor: isDark
                ? AppColors.cardDark.withValues(alpha: 0.9)
                : AppColors.primary.withValues(alpha: 0.9),
            duration: AppDurations.twoSeconds,
          ),
        );
      }

      // 获取缓存的图片数据
      final imageBytes = await _getCachedImageBytes();

      if (imageBytes == null) {
        throw Exception(AppStrings.imageDataError);
      }

      // 保存到相册
      await Gal.putImageBytes(
        imageBytes,
        name: widget.title.replaceAll(RegExp(AppConfig.filenameInvalidCharsPattern), ''),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.imageSaveSuccess,
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.green.withValues(alpha: 0.8),
            duration: AppDurations.twoSeconds,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.saveFailed}: ${e.toString()}',
              style: FontUtils.poppins(color: AppColors.white),
            ),
            backgroundColor: AppColors.red.withValues(alpha: 0.8),
            duration: AppDurations.toastDuration,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 获取缓存的图片数据
  Future<Uint8List?> _getCachedImageBytes() async {
    try {
      // 使用 CachedNetworkImage 的缓存机制获取图片数据
      final imageProvider = CachedNetworkImageProvider(
        widget.imageUrl,
        headers: getImageRequestHeaders(widget.imageUrl, widget.source),
      );

      // 获取图片数据
      final imageStream = imageProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<Uint8List>();

      late ImageStreamListener listener;
      listener =
          ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
        final image = imageInfo.image;
        image.toByteData(format: ui.ImageByteFormat.png).then((byteData) {
          if (byteData != null) {
            completer.complete(byteData.buffer.asUint8List());
          } else {
            completer.completeError(AppStrings.imageDataError);
          }
        }).catchError((error) {
          completer.completeError(error);
        });
        imageStream.removeListener(listener);
      }, onError: (exception, stackTrace) {
        completer.completeError(exception);
        imageStream.removeListener(listener);
      });

      imageStream.addListener(listener);
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final backgroundColor = isDark ? AppColors.black : AppColors.white;
        final textColor = isDark ? AppColors.white : AppColors.primary;
        final progressIndicatorColor =
            isDark ? AppColors.white : AppColors.primary;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // 背景点击区域
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // 点击背景区域关闭
                  child: Container(color: AppColors.transparent),
                ),
              ),

              // 图片区域
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(), // 点击图片也关闭
                  onLongPress: _showSaveImageMenu, // 长按显示保存菜单
                  child: FutureBuilder<String>(
                    future: getImageUrl(widget.imageUrl, widget.source),
                    builder: (context, snapshot) {
                      final String imageUrl = snapshot.data ?? widget.imageUrl;
                      final headers =
                          getImageRequestHeaders(imageUrl, widget.source);

                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        httpHeaders: headers,
                        fit: BoxFit.fitWidth,
                        width: MediaQuery.of(context).size.width,
                        placeholder: (context, url) => Container(
                          color: backgroundColor,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: progressIndicatorColor,
                                ),
                                Gap.h16,
                                Text(
                                  AppStrings.loading,
                                  style: FontUtils.poppins(
                                    color: textColor,
                                    fontSize: AppDimens.fontSizeXl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: backgroundColor,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: textColor,
                                  size: AppDimens.iconButtonSize,
                                ),
                                Gap.h16,
                                Text(
                                  AppStrings.imageLoadFailed,
                                  style: FontUtils.poppins(
                                    color: textColor,
                                    fontSize: AppDimens.fontSizeXl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
