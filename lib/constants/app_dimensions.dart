import 'package:flutter/widgets.dart';

/// 应用统一尺寸常量（间距、圆角、字号等）

class AppDimens {
  AppDimens._();

  // ── 间距 ──
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacingXxxl = 40;

  // ── 圆角 ──
  static const double radiusXxs = 1;
  static const double radiusXs = 2;
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;
  static const double radiusXxl = 14;
  static const double radiusXxxl = 16;
  static const double radiusRound = 20;
  static const double radiusPill = 24;
  static const double radiusCircle = 36;
  static const double radius3 = 3;
  static const double radius6 = 6;
  static const double radius11 = 11;

  // ── 字号 ──
  static const double fontSize2xs = 10;
  static const double fontSize3xs = 11;
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 13;
  static const double fontSizeMd = 14;
  static const double fontSizeLg = 15;
  static const double fontSizeXl = 16;
  static const double fontSizeXxl = 18;
  static const double fontSizeTitle = 20;
  static const double fontSizeHeadline = 28;
  static const double fontSizeHero = 42;
  static const double fontSizeMin = 8;
  static const double fontSizeMinSm = 9;

  // ── 图标尺寸 ──
  static const double iconSm = 16;
  static const double iconMd = 18;
  static const double iconLg = 24;
  static const double iconSize20 = 20;
  static const double iconSize22 = 22;

  // ── 组件尺寸 ──
  static const double buttonHeight = 48;
  static const double miniButtonHeight = 44;
  static const double avatarSm = 32;
  static const double avatarMd = 48;

  // ── 封面尺寸 ──
  static const double cardCoverWidth = 120;
  static const double cardCoverHeight = 170;

  // ── Logo ──
  static const double logoSize = 100;

  // ── 窗口 ──
  static const double windowMinWidth = 1024;
  static const double windowMinHeight = 600;
  static const double windowDefaultWidth = 1024;
  static const double windowDefaultHeight = 600;

  // ── 阴影 ──
  static const double elevationNone = 0;
  static const double elevationSm = 2;
  static const double elevationMd = 8;
  static const double shadowBlurSm = 8;
  static const double shadowBlurMd = 10;
  static const double shadowBlurLg = 20;

  // ── 平板断点 ──
  static const double tabletMinWidth = 600;
  static const double tabletMediumWidth = 1000;
  static const double tabletLargeWidth = 1200;

  // ── 常用 EdgeInsets 组合 ──
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets gridContentPadding = EdgeInsets.fromLTRB(16, 0, 16, 16);
  static const EdgeInsets pageHeaderPadding = EdgeInsets.fromLTRB(20, 20, 16, 8);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 18);

  // ── 边框宽度 ──
  static const double borderWidthSm = 1;
  static const double borderWidthMd = 2;
  static const double borderWidthLg = 3;

  // ── 网格间距 ──
  static const double gridSpacingSm = 8;
  static const double gridSpacingMd = 12;
  static const double gridSpacingLg = 16;
  static const double gridSpacingXl = 24;

  // ── 图标按钮尺寸 ──
  static const double iconButtonSize = 48;

  // ── 头像尺寸 ──
  static const double avatarLg = 64;
  static const double avatarXl = 80;

  // ── 图片预览 ──
  static const double previewImageMaxHeight = 400;

  // ── 滚动阈值 ──
  static const double scrollLoadMoreThreshold = 50;

  // ── 分割线高度 ──
  static const double dividerHeight = 0.5;

  // ── 最小触摸目标 ──
  static const double minTouchTarget = 44;

  // ── 直播频道宽高比 ──
  static const double liveChannelAspectRatio = 1.5;

  // ── 搜索历史高度 ──
  static const double searchHistoryItemHeight = 36;

  // ── 常用 EdgeInsets 组合 ──
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const EdgeInsets contentMargin = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets horizontalLgPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets horizontalXlPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets horizontalSmVerticalMdPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets verticalSmPadding = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets verticalMdPadding = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets buttonContentPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(16, 8, 16, 8);
  static const EdgeInsets buttonMdPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 10);

  // ── 文本缩放 ──
  static const double windowsTextScaleFactor = 1.0;
}

/// 通用 SizedBox 快捷常量
class Gap {
  Gap._();

  static const h2 = SizedBox(height: 2);
  static const h4 = SizedBox(height: 4);
  static const h6 = SizedBox(height: 6);
  static const h8 = SizedBox(height: 8);
  static const h10 = SizedBox(height: 10);
  static const h12 = SizedBox(height: 12);
  static const h16 = SizedBox(height: 16);
  static const h20 = SizedBox(height: 20);
  static const h24 = SizedBox(height: 24);
  static const h32 = SizedBox(height: 32);
  static const h40 = SizedBox(height: 40);

  static const w4 = SizedBox(width: 4);
  static const w6 = SizedBox(width: 6);
  static const w8 = SizedBox(width: 8);
  static const w10 = SizedBox(width: 10);
  static const w12 = SizedBox(width: 12);
  static const w16 = SizedBox(width: 16);
  static const w20 = SizedBox(width: 20);
  static const w24 = SizedBox(width: 24);
  static const w40 = SizedBox(width: 40);
  static const h100 = SizedBox(height: 100);

  static const SizedBox h48 = SizedBox(height: 48);
  static const SizedBox h50 = SizedBox(height: 50);
  static const SizedBox h56 = SizedBox(height: 56);
  static const SizedBox h60 = SizedBox(height: 60);
  static const SizedBox h64 = SizedBox(height: 64);
  static const SizedBox h80 = SizedBox(height: 80);
  static const SizedBox h120 = SizedBox(height: 120);
  static const SizedBox h200 = SizedBox(height: 200);

  static const SizedBox w2 = SizedBox(width: 2);
  static const SizedBox w3 = SizedBox(width: 3);
}
