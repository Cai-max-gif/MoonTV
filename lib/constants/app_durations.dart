/// 应用统一动画时长常量
class AppDurations {
  AppDurations._();

  /// 极速动画（淡出、微交互）
  static const Duration fastest = Duration(milliseconds: 100);

  /// 快速动画（悬停、微交互）
  static const Duration fast = Duration(milliseconds: 150);

  /// 标准动画（展开/折叠、切换）
  static const Duration normal = Duration(milliseconds: 200);

  /// 慢速动画（页面切换、弹窗）
  static const Duration slow = Duration(milliseconds: 300);

  /// 动画循环
  static const Duration oneSecond = Duration(seconds: 1);
  static const Duration twoSeconds = Duration(seconds: 2);
  static const Duration loadingCycle = Duration(milliseconds: 1500);

  // ── 网络请求超时 ──
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration mediumTimeout = Duration(seconds: 15);
  static const Duration sseTimeout = Duration(seconds: 15);
  static const Duration healthCheckTimeout = Duration(seconds: 5);

  // ── 轮询间隔 ──
  static const Duration accountCheckInterval = Duration(seconds: 30);
  static const Duration versionCheckInterval = Duration(hours: 1);
  static const Duration accountStatusCache = Duration(minutes: 1);

  // ── UI 提示时长 ──
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration halfSecond = Duration(milliseconds: 500);

  // ── UI 防抖 ──
  static const Duration debounceInterval = Duration(milliseconds: 50);
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // ── 进度保存 ──
  static const Duration saveProgressInterval = Duration(seconds: 10);

  // ── 页面切换 ──
  static const Duration pageTransition = Duration(milliseconds: 350);

  // ── 加载状态延迟（避免闪烁） ──
  static const Duration loadingMinDuration = Duration(milliseconds: 500);

  // ── 快进/快退步进 ──
  static const Duration seekStep = Duration(seconds: 10);

  // ── 下载进度轮询 ──
  static const Duration downloadProgressPoll = Duration(milliseconds: 500);

  // ── 播放器相关 ──
  static const Duration playerControlHideDelay = Duration(milliseconds: 250);
  static const Duration playerScrollAnimation = Duration(milliseconds: 500);
  static const Duration playerTransition = Duration(milliseconds: 300);
  static const Duration playerSeekTimeout = Duration(seconds: 10);

  // ── 网络请求 ──
  static const Duration statsTimerInterval = Duration(seconds: 3);

  // ── 音量菜单自动隐藏 ──
  static const Duration volumeMenuHideDelay = Duration(seconds: 1);

  // ── 即时过渡 ──
  static const Duration instantTransition = Duration(milliseconds: 0);

  // ── 补充 Duration 常量 ──
  static const Duration floatingAnimation = Duration(milliseconds: 1200);
  static const Duration minimalTransition = Duration(milliseconds: 1);

  // ── 图片缓存动画 ──
  static const Duration imageFadeIn = Duration(milliseconds: 150);
  static const Duration imageFadeOut = Duration(milliseconds: 100);
}
