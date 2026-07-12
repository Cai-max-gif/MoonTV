import 'package:flutter/widgets.dart';

/// 应用统一尺寸常量（间距、圆角、字号等）

class AppDimens {
  AppDimens._();

  // ── 间距 ──
  static const double spacingXs = 4;
  static const double spacing6 = 6;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;
  static const double spacingXxxl = 40;

  // ── 圆角 ──
  static const double radiusXxs = 1;
  static const double radiusSm = 4;
  static const double radiusMdSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;
  static const double radiusXxl = 14;
  static const double radiusXxxl = 16;
  static const double radiusRound = 20;
  static const double radiusPill = 24;
  static const double radiusCircle = 36;

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
  static const double iconSize12 = 12;
  static const double iconSize14 = 14;
  static const double iconSize20 = 20;
  static const double iconSize22 = 22;
  static const double iconSize25 = 25;
  static const double iconSize28 = 28;
  static const double iconSize32 = 32;
  static const double iconSize40 = 40;
  static const double iconSize50 = 50;
  static const double iconSize64 = 64;
  static const double iconSize80 = 80;

  // ── 组件尺寸 ──
  static const double capsuleTabHeight = 32;
  static const double buttonHeight = 48;
  static const double miniButtonHeight = 44;
  static const double avatarSm = 32;
  static const double avatarMd = 48;

  // ── 封面尺寸 ──
  static const double cardCoverWidth = 120;
  static const double cardCoverHeight = 170;

  // ── 组件尺寸补充 ──
  static const double filterSectionHeight = 66;
  static const double loadingAnimationSize = 100;
  static const double loadingAnimationIconSize = 80;
  static const double iconButtonSizeLarge = 64;
  static const double iconButtonSizeMedium = 40;
  static const double progressIndicatorWidth = 36;
  static const double pulsingDotSize = 10;
  static const double switchWidth = 44;
  static const double switchHeight = 24;
  static const double switchThumbSize = 20;
  static const double customSwitchWidth = 50;
  static const double customSwitchHeight = 30;
  static const double userMenuWidth = 280;
  static const double videoCardBorderWidth = 2.5;
  static const double videoCardIconWidth = 30;
  static const double videoCardIconWidthLarge = 32;
  static const double videoMenuIconSize = 50;
  static const double windowsTitleButtonWidth = 46;
  static const double windowsTitleButtonHeight = 40;
  static const double borderWidth2 = 2;

  // ── 行高 ──
  static const double lineHeightTighter = 1.0;
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightLoose = 1.5;
  static const double lineHeightExtraLoose = 1.6;

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
  static const double shadowBlurXs = 2;
  static const double shadowBlur3 = 3;
  static const double shadowBlur4 = 4;
  static const double shadowBlurSm = 8;
  static const double shadowBlurMd = 10;
  static const double shadowBlur12 = 12;
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
  static const double borderWidth08 = 0.8;
  static const double borderWidth15 = 1.5;

  // ── 网格间距 ──
  static const double gridSpacingSm = 8;
  static const double gridSpacingMd = 12;
  static const double gridSpacingLg = 16;
  static const double gridSpacingXl = 24;

  // ── 网格布局常量 ──
  static const double gridPaddingHorizontal = 16;
  static const double gridPaddingHorizontalDouble = 32;
  static const double gridMinItemWidth = 80;
  static const double gridMinCardWidth = 120;

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
  static const double dividerHeightMd = 2;
  static const double dividerHeightSm = 1.0;
  static const double dividerHeightLg = 1.5;

  // ── 语义化尺寸常量 ──
  static const double dividerThicknessThin = 1;
  static const double dividerThicknessMd = 2;
  static const double iconHeightSm = 6;
  static const double spacingMdAlt = 10;
  static const double videoCardBadgeSize = 30;
  static const double videoCardIconSize = 33;
  static const double videoCardPlayButtonSize = 42;
  static const double liveCardHeightSm = 68;
  static const double liveCardHeightMd = 72;
  static const double liveCardHeightLg = 88;
  static const double verticalProgramItemHeight = 80;
  static const double navBarWidthMobile = 240;

  // ── 组件尺寸补充 ──
  static const double buttonHeightLarge = 56;
  static const double loadingBarWidth = 200;

  // ── 最小触摸目标 ──
  static const double minTouchTarget = 44;

  // ── 直播频道宽高比 ──
  static const double liveChannelAspectRatio = 1.5;

  // ── 播放器布局比例 ──
  static const double playerAspectRatio16x9 = 16 / 9;
  static const double tabletLandscapePlayerWidthRatio = 0.65;
  static const double tabletPortraitPlayerHeightRatio = 0.5;

  // ── 搜索历史高度 ──
  static const double searchHistoryItemHeight = 36;

  // ── 常用 EdgeInsets 组合 ──
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const EdgeInsets contentMargin = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets horizontalLgPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets horizontalXlPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets verticalSmPadding = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets verticalMdPadding = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets buttonContentPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(16, 8, 16, 8);
  static const EdgeInsets buttonMdPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 10);

  // ── 文本缩放 ──
  static const double windowsTextScaleFactor = 1.0;

  // ── 更多 EdgeInsets 组合 ──
  static const EdgeInsets horizontalMdVerticalSmPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets horizontalMdVerticalMdPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets horizontalLgVerticalMdPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets horizontalSmVerticalMdPaddingAlt = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets horizontalMdVerticalLgPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsets horizontalMdVerticalSmPaddingAlt = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets horizontalMdVerticalMdPaddingAlt = EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  static const EdgeInsets horizontalSmPadding = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets horizontalLgPaddingAlt = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets topLgPadding = EdgeInsets.only(top: 16);
  static const EdgeInsets bottomSmPadding = EdgeInsets.only(bottom: 4);
  static const EdgeInsets bottomMdPadding = EdgeInsets.only(bottom: 8);
  static const EdgeInsets rightSmPadding = EdgeInsets.only(right: 10);
  static const EdgeInsets allXsPadding = EdgeInsets.all(6);

  // ── 组件尺寸 ──
  static const double playerDetailCoverHeight = 160;
  static const double playerEpisodePanelWidth = 120;
  static const double playerControlsHeight = 44;
  static const double playerSliderHeight = 6;
  static const double playerThumbSize = 16;
  static const double progressIndicatorHeight = 2;
  static const double filterDialogWidth = 480;
  static const double videoCardCoverWidth = 60;
  static const double videoCardCoverHeight = 80;
  static const double avatarSize18 = 18;
  static const double avatarSize20 = 20;
  static const double avatarSize22 = 22;
  static const double scrollbarThumbSize = 6;
  static const double scrollbarThumbWidth = 4;
  static const double textFieldHeight = 50;
  static const double buttonWidth40 = 40;
  static const double buttonWidth80 = 80;
  static const double buttonWidth160 = 160;
  static const double buttonWidth200 = 200;
  static const double buttonWidth100 = 100;

  

  // ── 更多 EdgeInsets 组合 ──
  static const EdgeInsets paddingVertical10 = EdgeInsets.symmetric(vertical: 10);
  static const EdgeInsets paddingVertical14 = EdgeInsets.symmetric(vertical: 14);
  static const EdgeInsets paddingHorizontal12 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets paddingHorizontal6Vertical3 = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
  static const EdgeInsets paddingHorizontal8Vertical2 = EdgeInsets.symmetric(horizontal: 8, vertical: 2);
  static const EdgeInsets paddingHorizontal8Vertical4 = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const EdgeInsets paddingHorizontal8Vertical6 = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  static const EdgeInsets paddingHorizontal12Vertical6 = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets paddingHorizontal12Vertical8 = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets paddingHorizontal14Vertical12 = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets paddingHorizontal14Vertical14 = EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  static const EdgeInsets paddingHorizontal20Vertical8 = EdgeInsets.symmetric(horizontal: 20, vertical: 8);
  static const EdgeInsets paddingHorizontal20Vertical12 = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static const EdgeInsets paddingHorizontal20Vertical16 = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets paddingHorizontal40Vertical16 = EdgeInsets.symmetric(horizontal: 40, vertical: 16);
  static const EdgeInsets paddingAll2 = EdgeInsets.all(2);
  static const EdgeInsets paddingAll6 = EdgeInsets.all(6);
  static const EdgeInsets paddingAll14 = EdgeInsets.all(14);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(24);
  static const EdgeInsets paddingTop4 = EdgeInsets.only(top: 4);
  static const EdgeInsets paddingTop6 = EdgeInsets.only(top: 6);
  static const EdgeInsets paddingTop16 = EdgeInsets.only(top: 16);
  static const EdgeInsets paddingBottom4 = EdgeInsets.only(bottom: 4);
  static const EdgeInsets paddingBottom8 = EdgeInsets.only(bottom: 8);
  static const EdgeInsets paddingBottom16 = EdgeInsets.only(bottom: 16);
  static const EdgeInsets paddingBottom24 = EdgeInsets.only(bottom: 24);
  static const EdgeInsets paddingBottom32 = EdgeInsets.only(bottom: 32);
  static const EdgeInsets paddingRight4 = EdgeInsets.only(right: 4);
  static const EdgeInsets paddingRight6 = EdgeInsets.only(right: 6);
  static const EdgeInsets paddingRight8 = EdgeInsets.only(right: 8);
  static const EdgeInsets paddingRight10 = EdgeInsets.only(right: 10);
  static const EdgeInsets paddingLeft4Right4 = EdgeInsets.only(left: 4, right: 4);
  static const EdgeInsets paddingLeft6Right4 = EdgeInsets.only(left: 6, right: 4);
  static const EdgeInsets paddingLeft16Right16Top12 = EdgeInsets.only(left: 16, right: 16, top: 12);
  static const EdgeInsets paddingLeft16Right16Top12Bottom0 = EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 0);
  static const EdgeInsets paddingLeft16Right16Top12Bottom12 = EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12);
  static const EdgeInsets paddingLeft16Right16Top12Bottom16 = EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16);
  static const EdgeInsets paddingLeft16Right16Bottom16 = EdgeInsets.only(left: 16, right: 16, bottom: 16);
  static const EdgeInsets paddingLeft16Right16Bottom8 = EdgeInsets.fromLTRB(16, 0, 16, 8);
  static const EdgeInsets paddingLeft16Right12Top16Bottom12 = EdgeInsets.fromLTRB(16, 16, 12, 12);
  static const EdgeInsets paddingLeft12Right12Top8Bottom16 = EdgeInsets.fromLTRB(12, 8, 12, 16);
  static const EdgeInsets paddingLeft12Right12Top0Bottom16 = EdgeInsets.fromLTRB(12, 0, 12, 16);
  static const EdgeInsets paddingLeft16Right16Top16Bottom0 = EdgeInsets.fromLTRB(16, 16, 16, 0);
  static const EdgeInsets paddingLeft16Right16Top16Bottom8 = EdgeInsets.fromLTRB(16, 16, 16, 8);
  static const EdgeInsets paddingLeft16Right16Top0Bottom16 = EdgeInsets.fromLTRB(16, 0, 16, 16);
  static const EdgeInsets paddingLeft16Right16Top8Bottom16 = EdgeInsets.fromLTRB(16, 8, 16, 16);

  // ── 更多 Margin 组合 ──
  static const EdgeInsets marginHorizontal12Vertical4 = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
  static const EdgeInsets marginHorizontal12Vertical6 = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const EdgeInsets marginHorizontal16Vertical4 = EdgeInsets.symmetric(horizontal: 16, vertical: 4);
  static const EdgeInsets marginHorizontal16Vertical6 = EdgeInsets.symmetric(horizontal: 16, vertical: 6);
  static const EdgeInsets marginHorizontal20Vertical4 = EdgeInsets.symmetric(horizontal: 20, vertical: 4);
  static const EdgeInsets marginHorizontal40 = EdgeInsets.symmetric(horizontal: 40);
  static const EdgeInsets marginHorizontal20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets marginHorizontal2 = EdgeInsets.symmetric(horizontal: 2);
  static const EdgeInsets marginVertical4 = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets marginVertical8 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets marginBottom8 = EdgeInsets.only(bottom: 8);
  static const EdgeInsets marginBottom12 = EdgeInsets.only(bottom: 12);
  static const EdgeInsets marginBottom16 = EdgeInsets.only(bottom: 16);
  static const EdgeInsets marginBottom24 = EdgeInsets.only(bottom: 24);
  static const EdgeInsets marginRight6 = EdgeInsets.only(right: 6);
  static const EdgeInsets marginRight8 = EdgeInsets.only(right: 8);
  static const EdgeInsets marginLeft16Right16Bottom100 = EdgeInsets.only(left: 16, right: 16, bottom: 100);
  static const EdgeInsets paddingTopBottomLeftRight16 = EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 8);

  // ── 特殊尺寸 ──
  static const double searchBarLeftPadding = 22.0;
  static const double searchBarRightPadding = 16.0;
  static const double searchBarTopPadding = 120.0;

  // ── 缺失的 EdgeInsets 组合 ──
  static const EdgeInsets paddingFromLTRB08168 = EdgeInsets.fromLTRB(0, 8, 16, 8);
  static const EdgeInsets paddingFromLTRB164160 = EdgeInsets.fromLTRB(16, 4, 16, 0);
  static const EdgeInsets paddingFromLTRB1612168 = EdgeInsets.fromLTRB(16, 12, 16, 8);
  static const EdgeInsets paddingFromLTRB160164 = EdgeInsets.fromLTRB(16, 0, 16, 4);
  static const EdgeInsets paddingFromLTRB16141610 = EdgeInsets.fromLTRB(16, 14, 16, 10);
  static const EdgeInsets paddingFromLTRB2002020 = EdgeInsets.fromLTRB(20, 0, 20, 20);
  static const EdgeInsets paddingHorizontal12Vertical4 = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
  static const EdgeInsets paddingVertical18 = EdgeInsets.symmetric(vertical: 18);
  static const EdgeInsets paddingVertical24 = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets paddingHorizontal8Vertical18 = EdgeInsets.symmetric(horizontal: 8, vertical: 18);
  static const EdgeInsets paddingHorizontal16Vertical10 = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  static const EdgeInsets paddingHorizontal8Vertical8 = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  static const EdgeInsets paddingFromLTRB1681616 = EdgeInsets.fromLTRB(16, 8, 16, 16);
  static const EdgeInsets paddingHorizontal32 = EdgeInsets.symmetric(horizontal: 32);
  static const EdgeInsets paddingHorizontal32Vertical24 = EdgeInsets.symmetric(horizontal: 32, vertical: 24);
  static const EdgeInsets paddingHorizontal4 = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets paddingVertical4Horizontal0 = EdgeInsets.symmetric(vertical: 4, horizontal: 0);
  static const EdgeInsets paddingBottom12 = EdgeInsets.only(bottom: 12);
  static const EdgeInsets paddingLeft4Right4Top6 = EdgeInsets.only(left: 4, right: 4, top: 6);
  static const EdgeInsets paddingTop120 = EdgeInsets.only(top: 120);
  static const EdgeInsets paddingLeft22Right16 = EdgeInsets.only(left: 22, right: 16);

  // ── 更多 EdgeInsets 组合 ──
  static const EdgeInsets paddingHorizontal8 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets paddingHorizontal7Vertical4 = EdgeInsets.symmetric(horizontal: 7, vertical: 4);
  static const EdgeInsets paddingVertical12 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets paddingFromLTRB0121212 = EdgeInsets.fromLTRB(0, 12, 12, 12);
  static const EdgeInsets paddingFromLTRB2020208 = EdgeInsets.fromLTRB(20, 20, 20, 8);
  static const EdgeInsets paddingFromLTRB20202016 = EdgeInsets.fromLTRB(20, 20, 20, 16);
  static const EdgeInsets paddingHorizontal24Vertical40 = EdgeInsets.symmetric(horizontal: 24, vertical: 40);
  static const EdgeInsets paddingHorizontal8Vertical12 = EdgeInsets.symmetric(horizontal: 8, vertical: 12);
  static const EdgeInsets filterChipPadding = EdgeInsets.fromLTRB(8, 6, 8, 6);
  static const EdgeInsets filterChipPaddingFirst = EdgeInsets.fromLTRB(0, 6, 8, 6);

  // ── BorderRadius 圆角常量 ──
  static final BorderRadius radiusCircle2 = BorderRadius.circular(2);
  static final BorderRadius radiusCircle3 = BorderRadius.circular(3);
  static final BorderRadius radiusCircle6 = BorderRadius.circular(6);
  static final BorderRadius radiusCircle8 = BorderRadius.circular(8);
  static final BorderRadius radiusCircle11 = BorderRadius.circular(11);
  static final BorderRadius radiusCircle22 = BorderRadius.circular(22);
  static final BorderRadius radiusCircle24 = BorderRadius.circular(24);

  // ── Radius 圆角常量（用于 BorderRadius.only） ──
  static const Radius radius16 = Radius.circular(16);
  static const Radius radius20 = Radius.circular(20);
  static const Radius radius22 = Radius.circular(22);
  static const Radius radius4 = Radius.circular(4);
  static const Radius radius6 = Radius.circular(6);
  static const Radius radius8 = Radius.circular(8);

  // ── Offset 常量 ──
  static const Offset offset02 = Offset(0, 2);
  static const Offset offset04 = Offset(0, 4);
  static const Offset offset08 = Offset(0, 8);
  static const Offset offset010 = Offset(0, 10);
  static const Offset offset01 = Offset(0, 1);
  static const Offset offset10 = Offset(1, 0);
  static const Offset offset03 = Offset(0, 3);
  static const Offset offset035 = Offset(0, 3.5);
  static const Offset offset026 = Offset(0, 2.6);

  // ── 播放器控制按钮 padding ──
  static const EdgeInsets playerControlButtonPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  static const EdgeInsets playerControlButtonPaddingNarrow = EdgeInsets.symmetric(horizontal: 6, vertical: 8);
  static const EdgeInsets playerControlPlayButtonPadding = EdgeInsets.fromLTRB(8, 8, 0, 8);
  static const EdgeInsets playerControlPlayButtonPaddingNarrow = EdgeInsets.fromLTRB(6, 8, 0, 8);
  static const EdgeInsets playerTimePadding = EdgeInsets.only(left: 8, right: 8);

  // ── 搜索按钮 padding ──
  static const EdgeInsets searchButtonPadding = EdgeInsets.all(8);
  static const EdgeInsets searchButtonPaddingTablet = EdgeInsets.all(6);

  // ── 查看更多按钮 padding ──
  static const EdgeInsets viewMoreButtonPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  // ── 搜索结果标签 padding ──
  static const EdgeInsets searchTagPadding = EdgeInsets.fromLTRB(8, 6, 8, 6);
  static const EdgeInsets searchTagPaddingFirst = EdgeInsets.fromLTRB(0, 6, 8, 6);

  // ── 播放器信息行 padding ──
  static const EdgeInsets playerInfoRowPadding = EdgeInsets.only(top: 6, left: 4, right: 4);

  // ── 底部导航栏 ──
  static const double bottomNavBarMarginHorizontal = 20;
  static const double bottomNavBarMarginBottom = 20;
  static const double bottomNavBarWidthReduction = 40;
  static const EdgeInsets bottomNavBarMargin = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets bottomNavBarPadding = EdgeInsets.only(left: 0, right: 0, top: 4);

  // ── 导航项 padding ──
  static const EdgeInsets navItemPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 2);
  static const EdgeInsets navItemPaddingTablet = EdgeInsets.symmetric(horizontal: 16, vertical: 2);
  static const EdgeInsets navItemLabelPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
  static const EdgeInsets navItemLabelPaddingTablet = EdgeInsets.symmetric(horizontal: 16, vertical: 4);

  // ── 搜索框 padding ──
  static const EdgeInsets searchContentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);

  // ── 播放器控制栏 ──
  static const double playerProgressBarHeight = 24;
  static const double bottomControlsFullscreenBottom = 4;
  static const double bottomControlsNonFullscreenBottom = -6;

  // ── 播放器底部控制栏 padding ──
  static const EdgeInsets bottomControlsPaddingFullscreen = EdgeInsets.only(left: 16, right: 16, bottom: 8);
  static const EdgeInsets bottomControlsPaddingNonFullscreen = EdgeInsets.only(left: 8, right: 8, bottom: 8);

  // ── 播放器菜单尺寸 ──
  static const double playerMenuWidthFullscreen = 120;
  static const double playerMenuWidthNonFullscreen = 90;
  static const double playerMenuHeightFullscreen = 48;
  static const double playerMenuHeightNonFullscreen = 36;
  static const double playerMenuSubMenuWidthFullscreen = 42;
  static const double playerMenuSubMenuWidthNonFullscreen = 36;
  static const double playerMenuSubMenuHeightFullscreen = 200;
  static const double playerMenuSubMenuHeightNonFullscreen = 150;
  static const double playerMenuTopOffsetFullscreen = 2;
  static const double playerMenuTopOffsetNonFullscreen = 36;

  // ── 网格行间距 ──
  static const double gridMainAxisSpacingTablet = 0;
  static const double gridMainAxisSpacingMobile = 16;

  // ── macOS 顶部安全区 padding ──
  static const double macOSPadding = 32;

  // ── 动态 padding ──
  static const EdgeInsets paddingHorizontal16Vertical32 = EdgeInsets.symmetric(horizontal: 16, vertical: 32);
  static const EdgeInsets paddingHorizontal16Top16Bottom32 = EdgeInsets.fromLTRB(16, 16, 16, 32);
  static const EdgeInsets paddingHorizontal16TopNegative10Bottom32 = EdgeInsets.fromLTRB(16, -10, 16, 32);
  static const EdgeInsets paddingHorizontal16Vertical8 = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // ── 下载进度按钮尺寸 ──
  static const double downloadButtonSize = 48;
  static const double downloadProgressStrokeWidth = 4;

  // ── Tab 按钮尺寸 ──
  static const double tabHorizontalPadding = 12;

  // ── 过滤选项字体尺寸 ──
  static const double filterOptionCompactFontSize = 12;

  static const double searchBarHeight = 56;
  static const int countdownDefault = 60;
  static const double letterSpacingWide = 1.5;
  static const double letterSpacingNormal = 1.0;
  static const double sliderTrackHeight = 20.0;
  static const double sliderThumbRadius = 10.0;
  static const int titleMaxLength = 40;
}

/// 通用 SizedBox 快捷常量
class Gap {
  Gap._();

  static const h0 = SizedBox(height: 0);
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

  static const w2 = SizedBox(width: 2);
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

  static const SizedBox w3 = SizedBox(width: 3);
  static const SizedBox w18 = SizedBox(width: 18);
  static const SizedBox w36 = SizedBox(width: 36);
}
