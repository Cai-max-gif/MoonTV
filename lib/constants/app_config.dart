/// 应用统一配置常量
class AppConfig {
  AppConfig._();

  /// 应用名称
  static const String appName = 'MoonTV';

  /// GitHub 仓库地址
  static const String githubRepoUrl = 'https://github.com/Cai-max-gif/MoonTV';

  /// GitHub API 发布页
  static const String githubApiReleases = 'https://api.github.com/repos/Cai-max-gif/MoonTV/releases/latest';

  /// GitHub 下载基础 URL
  static const String githubDownloadBase = 'https://github.com/Cai-max-gif/MoonTV/releases/download';

  /// 默认版本号（package_info 获取失败时的回退）
  static const String defaultVersion = '1.5.1';

  ///服务器
  static const String serverBaseUrl = 'https://moontv.cc.cd';

  //API 端点
  static const String apiPrefix = '/api';
  static const String searchEndpoint = '/api/search';
  static const String searchResourcesEndpoint = '/api/search/resources';
  static const String searchSuggestionsEndpoint = '/api/search/suggestions';
  static const String detailEndpoint = '/api/detail';
  static const String favoritesEndpoint = '/api/favorites';
  static const String playRecordsEndpoint = '/api/playrecords';
  static const String searchHistoryEndpoint = '/api/searchhistory';
  static const String liveSourcesEndpoint = '/api/live/sources';
  static const String liveChannelsEndpoint = '/api/live/channels';
  static const String epgEndpoint = '/api/live/epg';
  static const String shortDramaCategoriesEndpoint = '/api/shortdrama/categories';
  static const String shortDramaListEndpoint = '/api/shortdrama/list';
  static const String shortDramaDetailEndpoint = '/api/shortdrama/detail';
  static const String shortDramaParseEndpoint = '/api/shortdrama/parse';
  static const String shortDramaSearchEndpoint = '/api/shortdrama/search';
  static const String shortDramaRecommendEndpoint = '/api/shortdrama/recommend';
  static const String shortDramaEpisodeCountEndpoint = '/api/shortdrama/episode-count';
  static const String danmuExternalEndpoint = '/api/danmu-external';
  static const String danmuExternalSearchEndpoint = '/api/danmu-external/search';
  static const String netdiskSearchEndpoint = '/api/netdisk/search';
  static const String healthEndpoint = '/api/health';
  static const String userStatusEndpoint = '/api/user/status';
  static const String csrfTokenEndpoint = '/api/csrf-token';
  static const String announcementEndpoint = '/api/announcement';

  // 更多 API 端点
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String sendVerificationCodeEndpoint = '/api/send-verification-code';
  static const String resetPasswordEndpoint = '/api/reset-password';
  static const String releaseCalendarEndpoint = '/api/release-calendar';
  static const String searchWsEndpoint = '/api/search/ws';

  /// 外部服务 URL
  static const String bgmApiBase = 'https://api.bgm.tv';
  static const String bgmSubjectUrl = 'https://bgm.tv/subject';
  static const String doubanSubjectUrl = 'https://movie.douban.com/subject';
  static const String doubanApiBase = 'https://m.douban.com/rexxar/api/v2';
    static const String doubanReferer = 'https://movie.douban.com/';

  /// 默认 AI 提供商
  static const String aiDefaultProvider = 'openai';
  static const String aiDefaultModel = 'gpt-4o';

  /// AI 服务商基础 URL
  static const String aiOpenaiBaseUrl = 'https://api.openai.com/v1';
  static const String aiDeepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String aiZhipuBaseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  static const String aiMoonshotBaseUrl = 'https://api.moonshot.cn/v1';
  static const String aiMimoBaseUrl = 'https://api.xiaomimimo.com/v1';

  /// 默认 User-Agent
  static const String defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';
  static const String doubanUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';
  static const String liveDefaultUserAgent = 'AptvPlayer/1.4.10';
  static const String bangumiUserAgent = 'senshinya/selene/1.0.0 (Android) (http://github.com/senshinya/selene)';

  /// 通知渠道
  static const String downloadChannelId = 'download_channel';
  static const String updateChannelId = 'update_channel';
  static const String notificationIcon = '@mipmap/launcher_icon';

  /// 下载配置
  static const int maxDownloadRetries = 5;

  /// 登录安全
  static const int maxLoginAttempts = 5;
  static const Duration loginLockDuration = Duration(minutes: 15);

  // ── HTTP 请求头值 ──
  static const String headerXmlHttpRequest = 'XMLHttpRequest';
  static const String headerAcceptLanguage = 'zh-CN,zh;q=0.9,en;q=0.8';

  // ── 弹幕默认参数 ──
  static const int danmakuDefaultSpeed = 2;
  static const int danmakuDefaultOpacity = 100;
  static const double danmakuDefaultFontSize = 1.0;
  static const double danmakuDefaultDisplayArea = 1.0;
  static const int danmakuSpeedMin = 0;
  static const int danmakuSpeedMax = 4;
  static const int danmakuOpacityMin = 0;
  static const int danmakuOpacityMax = 100;
  static const double danmakuFontSizeMin = 0.5;
  static const double danmakuFontSizeMax = 2.0;
  static const double danmakuAreaMin = 0.25;
  static const double danmakuAreaMax = 1.0;

  /// API 重试次数
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  /// 缓存时长
  static const Duration doubanDetailCache = Duration(days: 1);
  static const Duration doubanListCache = Duration(hours: 6);
  static const Duration doubanRecommendCache = Duration(hours: 6);
  static const Duration releaseCalendarCache = Duration(days: 1);
  static const Duration shortDramaCategoryCache = Duration(hours: 24);
  static const Duration shortDramaListCache = Duration(hours: 6);
  static const Duration shortDramaRecommendCache = Duration(hours: 3);
  static const Duration bangumiCalendarCache = Duration(days: 1);
  static const Duration bangumiDetailCache = Duration(days: 3);
  static const Duration danmuCacheDuration = Duration(minutes: 30);
  static const Duration announcementCacheDuration = Duration(minutes: 1);
  static const Duration liveCacheDuration = Duration(hours: 2);

  // ── 默认分页 ──
  static const int defaultPageLimit = 25;
  static const int defaultRecommendSize = 10;

  // ── 下载配置 ──
  static const int downloadMinConcurrent = 1;
  static const int downloadMaxConcurrent = 3;
  static const int downloadMinThreads = 1;
  static const int downloadMaxThreads = 16;
  static const int downloadProgressMinDelta = 1;

  // ── 搜索配置 ──
  static const int maxSearchPages = 5;
  static const int maxConcurrentSearchRequests = 2;

  // ── 本地搜索缓存 ──
  static const int localSearchCacheTtlMs = 10 * 60 * 1000;
  static const int localSearchCleanupIntervalMs = 5 * 60 * 1000;
  static const int localSearchMaxEntries = 1000;

  /// 网络超时
  static const Duration downloadConnectTimeout = Duration(seconds: 15);
  static const Duration downloadReceiveTimeout = Duration(seconds: 60);
  static const Duration liveRequestTimeout = Duration(seconds: 15);
  static const Duration aiRequestTimeout = Duration(seconds: 60);
  static const Duration authRequestTimeout = Duration(seconds: 15);
  static const Duration telegramPollTimeout = Duration(minutes: 5);

  /// 分页
  static const int shortDramaPageLimit = 20;

  /// 平板列数配置
  static const int tabletColumnsSmall = 6;
  static const int tabletColumnsMedium = 7;
  static const int tabletColumnsLarge = 8;
  static const int mobileColumns = 3;

  /// Asset 路径
  static const String logoImageAsset = 'assets/images/logo/logo.png';

  // ── 网盘域名 ──
  static const String cloudDomainBaidu = 'pan.baidu.com';
  static const String cloudDomainAliyun = 'alipan.com';
  static const String cloudDomainQuark = 'pan.quark.cn';
  static const String cloudDomainTianyi = 'cloud.189.cn';
  static const String cloudDomainUc = 'drive.uc.cn';
  static const String cloudDomainMobile = 'caiyun.139.com';
  static const String cloudDomain115 = '115.com';
  static const String cloudDomainPikpak = 'mypikpak.com';
  static const String cloudDomainXunlei = 'pan.xunlei.com';
  static const String cloudDomain123 = '123pan.com';
  static const String cloudSchemeMagnet = 'magnet:';
  static const String cloudSchemeEd2k = 'ed2k://';

  // ── M3U8 配置 ──
  static const int m3u8SpeedTestSamples = 3;
  static const int m3u8MaxRecursiveDepth = 5;
  static const double m3u8DefaultMaxSpeed = 1024.0;
  static const int m3u8DefaultMinPing = 50;
  static const int m3u8DefaultMaxPing = 1000;
  static const int m3u8MinFileSize = 100;

  // ── 分辨率阈值 ──
  static const int resolution4k = 3840;
  static const int resolution2k = 2560;
  static const int resolution1080p = 1920;
  static const int resolution720p = 1280;
  static const int resolution480p = 854;
  static const int resolution360p = 640;

  // ── 版本号 ──
  static const int versionSegmentCount = 3;

  // ── 输入验证 ──
  static const int maxUsernameLength = 32;
  static const int maxPasswordLength = 32;
  static const int verificationCodeLength = 6;
  static const int minPasswordLength = 6;
  static const int minRegisterUsernameLength = 3;

  // ── 下载目录 ──
  static const String downloadDirectoryName = 'Download';

  // ── 字体 ──
  static const String fontFamilyWindows = 'Microsoft YaHei';

  // ── 图片源 ──
  static const String manmankanDomain = 'manmankan.com';
  static const String manmankanReferer = 'https://www.manmankan.com/';
  static const String doubanDomainPattern = r'douban(io|)\.com';
  static const String manmankanUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  static const String doubanMobileUserAgent = 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  static const String imageAcceptHeader = 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8';

  // ── 设备布局 ──
  static const double tabletPortraitAspectRatio = 1.2;
  static const int liveMobileColumns = 2;
  static const int liveTabletColumnsSmall = 3;
  static const int liveTabletColumnsMedium = 4;
  static const int liveTabletColumnsLarge = 5;

  // ── 搜索键分隔符 ──
  static const String searchKeySeparator = '+';

  // ── 时间转换 ──
  static const int secondsPerHour = 3600;
  static const int secondsPerMinute = 60;

  // ── 通知配置 ──
  static const int notificationIdBase = 1000;
  static const int notificationIdMax = 2000;

  // ── 源标识 ──
  static const String sourceIdDouban = 'douban';
  static const String sourceIdBangumi = 'bangumi';
  static const String sourceIdManmankan = 'manmankan';

  // ── 账户状态 ──
  static const String accountStatusActive = 'active';

  // ── 缓存键 ──
  static const String cacheKeyShortDramaCategories = 'shortdrama-categories';

  // ── 内容类型标识 ──
  static const String stypeMovie = 'movie';
  static const String stypeTv = 'tv';
  static const String stypeShortDrama = 'shortdrama';

  // ── 环境变量名 ──
  static const String envUserProfile = 'USERPROFILE';
  static const String envHome = 'HOME';

  // ── 设备布局 ──
  static const double tabletHorizontalVisibleCardsSmall = 5.75;
  static const double tabletHorizontalVisibleCardsMedium = 6.75;
  static const double tabletHorizontalVisibleCardsLarge = 7.75;
}
