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

  /// 协议前缀
  static const String httpsProtocol = 'https://';

  /// 默认 AI 提供商
  static const String aiDefaultProvider = 'openai';
  static const String aiDefaultModel = 'gpt-4o';

  // ── AI 提供商标识 ──
  static const String aiProviderOpenai = 'openai';
  static const String aiProviderDeepseek = 'deepseek';
  static const String aiProviderZhipu = 'zhipu';
  static const String aiProviderMoonshot = 'moonshot';
  static const String aiProviderMimo = 'mimo';
  static const String aiProviderCustom = 'custom';

  // ── AI 提供商显示名称 ──
  static const String aiProviderNameOpenai = 'OpenAI';
  static const String aiProviderNameDeepseek = 'DeepSeek';
  static const String aiProviderNameZhipu = '智谱 AI (GLM)';
  static const String aiProviderNameMoonshot = 'Moonshot (Kimi)';
  static const String aiProviderNameMimo = 'MiMo';

  // ── AI API 端点 ──
  static const String aiChatCompletionsEndpoint = '/chat/completions';
  static const String aiDeepseekBalanceEndpoint = '/user/balance';
  static const String aiMoonshotBalanceEndpoint = '/users/me/balance';

  // ── AI 模型标识 ──
  static const String aiModelGpt55Pro = 'gpt-5.5-pro';
  static const String aiModelGpt55 = 'gpt-5.5';
  static const String aiModelGpt54 = 'gpt-5.4';
  static const String aiModelGpt53Codex = 'gpt-5.3-codex';
  static const String aiModelDeepseekV4Pro = 'deepseek-v4-pro';
  static const String aiModelDeepseekV4Flash = 'deepseek-v4-flash';
  static const String aiModelGlm52 = 'glm-5.2';
  static const String aiModelGlm51 = 'glm-5.1';
  static const String aiModelGlm47 = 'glm-4.7';
  static const String aiModelGlm45 = 'glm-4.5';
  static const String aiModelKimiK27Code = 'kimi-k2.7-code';
  static const String aiModelKimiK26 = 'kimi-k2.6';
  static const String aiModelKimiK25 = 'kimi-k2.5';
  static const String aiModelMimoV25Pro = 'mimo-v2.5-pro';
  static const String aiModelMimoV25 = 'mimo-v2.5';

  // ── AI 模型显示名称 ──
  static const String aiModelNameGpt55Pro = 'GPT-5.5 Pro';
  static const String aiModelNameGpt55 = 'GPT-5.5';
  static const String aiModelNameGpt54 = 'GPT-5.4';
  static const String aiModelNameGpt53Codex = 'GPT-5.3 Codex';
  static const String aiModelNameDeepseekV4Pro = 'DeepSeek-V4-Pro';
  static const String aiModelNameDeepseekV4Flash = 'DeepSeek-V4-Flash';
  static const String aiModelNameGlm52 = 'GLM-5.2';
  static const String aiModelNameGlm51 = 'GLM-5.1';
  static const String aiModelNameGlm47 = 'GLM-4.7';
  static const String aiModelNameGlm45 = 'GLM-4.5';
  static const String aiModelNameKimiK27Code = 'Kimi K2.7 Code';
  static const String aiModelNameKimiK26 = 'Kimi K2.6';
  static const String aiModelNameKimiK25 = 'Kimi K2.5';
  static const String aiModelNameMimoV25Pro = 'MiMo V2.5 Pro';
  static const String aiModelNameMimoV25 = 'MiMo V2.5';

  // ── AI 存储键 ──
  static const String aiApiKeyPrefix = 'ai_api_key_';
  static const String aiSettingsKey = 'ai_settings';
  static const String aiChatHistoryKey = 'ai_chat_history';

  /// AI 服务商基础 URL
  static const String aiOpenaiBaseUrl = 'https://api.openai.com/v1';
  static const String aiDeepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String aiZhipuBaseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  static const String aiMoonshotBaseUrl = 'https://api.moonshot.cn/v1';
  static const String aiMimoBaseUrl = 'https://api.xiaomimimo.com/v1';

  /// 默认 User-Agent
  static const String defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';
  static const String liveDefaultUserAgent = 'AptvPlayer/1.4.10';
  static const String bangumiUserAgent = 'senshinya/selene/1.0.0 (Android) (http://github.com/senshinya/selene)';

  /// 通知渠道
  static const String downloadChannelId = 'download_channel';
  static const String updateChannelId = 'update_channel';
  static const String notificationIcon = '@mipmap/launcher_icon';

  /// 下载配置
  static const int downloadMaxRetryCount = 5;

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
  static const int downloadDefaultThreads = 4;
  static const int downloadProgressMinDelta = 1;

  // ── 播放设置配置 ──
  static const int defaultSkipOpeningDuration = 180;
  static const int defaultSkipEndingDuration = 180;

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

  // ── 网盘类型键 ──
  static const String cloudKeyBaidu = 'baidu';
  static const String cloudKeyAliyun = 'aliyun';
  static const String cloudKeyQuark = 'quark';
  static const String cloudKeyTianyi = 'tianyi';
  static const String cloudKeyUc = 'uc';
  static const String cloudKeyMobile = 'mobile';
  static const String cloudKey115 = '115';
  static const String cloudKeyPikpak = 'pikpak';
  static const String cloudKeyXunlei = 'xunlei';
  static const String cloudKey123 = '123';
  static const String cloudKeyMagnet = 'magnet';
  static const String cloudKeyEd2k = 'ed2k';
  static const String cloudKeyOthers = 'others';

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

  // ── Android 架构类型 ──
  static const String androidArchV7 = 'v7';
  static const String androidArchV8 = 'v8';
  static const String androidArchX86_64 = 'x86_64';
  static const String androidArchUniversal = 'universal';

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

  // ── 搜索服务常量 ──
  static const String apiSiteKeyFfzy = 'ffzy';

  // ── 缓存键补充 ──
  static const String cacheKeyShortDramaList = 'shortdrama-list';
  static const String cacheKeyShortDramaRecommends = 'shortdrama-recommends';

  // ── M3U8 相关常量 ──
  static const String m3u8TagExtM3u = '#EXTM3U';
  static const String m3u8TagExtXStreamInf = '#EXT-X-STREAM-INF';
  static const String m3u8TagExtXKey = '#EXT-X-KEY:';
  static const String m3u8TagExtInf = '#EXTINF:';
  static const String m3u8AttrBandwidth = 'BANDWIDTH';
  static const String m3u8AttrResolution = 'RESOLUTION';

  // ── 弹幕速度/字号标签 ──
  static const String danmakuSpeedLabelSlowest = '0.5x';
  static const String danmakuSpeedLabelFastest = '2.0x';
  static const String danmakuOpacityLabelMax = '100%';
  static const String danmakuFontSizeLabelSmallest = '0.5x';
  static const String danmakuFontSizeLabelLargest = '2.0x';

  // ── 时间格式常量 ──
  static const String timeFormatMs = 'ms';
  static const String timeFormatZero = '0';

  // ── 字符集常量 ──
  static const String charsetGbk = 'gbk';
  static const String charsetGb2312 = 'gb2312';

  // ── 直播相关常量 ──
  static const String liveUngroupedDefault = '无分组';
  static const String liveUngrouped = '未分组';

  // ── Telegram 相关常量 ──
  static const String telegramScheme = 'tg://';

  // ── 文件名清理正则 ──
  static const String filenameInvalidCharsPattern = r'[^\w\s-]';

  // ── EPG XML 标签 ──
  static const String epgTagProgramme = 'programme';
  static const String epgTagTitle = 'title';
  static const String epgAttrChannel = 'channel';
  static const String epgAttrStart = 'start';
  static const String epgAttrStop = 'stop';

  // ── 通知配置 ──
  static const int notificationIdBase = 1000;
  static const int notificationIdMax = 2000;
  static const int notificationIdModulo = 1000;

  // ── 源标识 ──

  // ── 账户状态 ──
  static const String accountStatusActive = 'active';

  // ── 用户角色 ──
  static const String userRoleUser = 'user';
  static const String userRoleAdmin = 'admin';
  static const String userRoleOwner = 'owner';

  // ── 缓存键 ──
  static const String cacheKeyShortDramaCategories = 'shortdrama-categories';

  // ── 内容类型标识 ──
  static const String stypeMovie = 'movie';
  static const String stypeTv = 'tv';
  static const String stypeShortDrama = 'shortdrama';
  static const String stypeShow = 'show';
  static const String stypeAnime = 'anime';

  // ── 豆瓣 category 参数 ──
  static const String categoryShow = 'show';

  // ── 来源/场景标识符 ──
  static const String sourceFavorite = 'favorite';
  static const String sourcePlayrecord = 'playrecord';
  static const String sourceSearch = 'search';
  static const String sourceAgg = 'agg';
  static const String sourceShortDrama = 'shortdrama';
  static const String sourceUpcoming = 'upcoming';
  static const String sourceIdManmankan = 'manmankan';
  static const String sourceDanmu = 'danmu';
  static const String sourceLive = 'live';
  static const String sourceRecommends = 'recommends';
  static const String sourceList = 'list';
  static const String sourceBangumi = 'bangumi';
  static const String sourceDouban = 'douban';

  // ── 环境变量名 ──
  static const String envUserProfile = 'USERPROFILE';
  static const String envHome = 'HOME';

  // ── 设备布局 ──
  static const double tabletHorizontalVisibleCardsSmall = 5.75;
  static const double tabletHorizontalVisibleCardsMedium = 6.75;
  static const double tabletHorizontalVisibleCardsLarge = 7.75;

  // ── 聚合搜索 ──
  static const String aggregatedSource = 'aggregated';

  // ── 视频排序字段 ──
  static const String sortByHot = 'hot';
  static const String sortByNew = 'new';
  static const String sortByScore = 'score';
  static const String sortByTime = 'time';

  // ── 下载重试延迟系数 ──
  static const int downloadRetryDelayMultiplier = 1;

  // ── Telegram API 端点 ──
  static const String telegramMobileAuthRequestEndpoint = '/api/telegram/mobile-auth/request';
  static const String telegramMobileAuthPollEndpoint = '/api/telegram/mobile-auth/poll';

  // ── 缓存键 ──
  static const String cacheKeyBangumiCalendarRaw = 'bangumi_calendar_raw_v1';
  static const String cacheKeyAnnouncement = 'announcement_cache';
  static const String cacheKeyAnnouncementTime = 'announcement_cache_time';
  static const String cacheKeyDanmu = 'danmu_cache_';
  static const String cacheKeyDoubanCategory = 'douban_category';
  static const String cacheKeyDoubanRecommends = 'douban_recommends';
  static const String cacheKeyDoubanDetails = 'douban_details';
  static const String cacheKeyBangumiDetails = 'bangumi_details';
  static const String cacheKeyPlayRecords = 'play_records';
  static const String cacheKeySearchHistory = 'search_history';
  static const String cacheKeyHotMovies = 'hot_movies';
  static const String cacheKeyHotTvShows = 'hot_tv_shows';
  static const String cacheKeyHotShows = 'hot_shows';
  static const String cacheKeyBangumiCalendar = 'bangumi_calendar';
  static const String cacheKeyFavorites = 'favorites';

  // ── 缓存目录 ──
  static const String cacheDirectoryDouban = 'douban_cache';

  // ── 请求头常量 ──
  static const String headerAcceptJson = 'application/json';
  static const String headerAcceptEventStream = 'text/event-stream';
  static const String headerCacheControlNoCache = 'no-cache';

  // ── 通知 Payload 常量 ──
  static const String notificationPayloadUpdate = 'update';
  static const String notificationPayloadDownloadPrefix = 'download_';

  // ── M3U8 属性常量 ──
  static const String m3u8AttrMethod = 'METHOD';
  static const String m3u8AttrUri = 'URI';
  static const String m3u8AttrIv = 'IV';
  static const String m3u8KeyAes128 = 'AES-128';

  // ── 搜索错误常量 ──
  static const String searchErrorConnectionClosed = 'connection closed';
  static const String searchErrorClientException = 'clientexception';
  static const String searchErrorConnectionTerminated = 'connection terminated';

  // ── 错误关键词 ──
  static const String errorKeywordBanned = 'banned';
  static const String errorKeywordBan = 'ban';

  // ── 查询参数常量 ──
  static const String queryRefresh = 'refresh';
  static const String queryStart = 'start';
  static const String queryCount = 'count';
  static const String querySelectedCategories = 'selected_categories';
  static const String queryUncollect = 'uncollect';
  static const String queryScoreRange = 'score_range';
  static const String queryTags = 'tags';
  static const String querySort = 'sort';
  static const String queryKind = 'kind';
  static const String queryCategory = 'category';
  static const String queryType = 'type';
  static const String queryPage = 'page';
  static const String queryPageLimit = 'pageLimit';
  static const String queryFormat = 'format';
  static const String queryRegion = 'region';
  static const String queryYear = 'year';
  static const String queryPlatform = 'platform';
  static const String queryLabel = 'label';
  static const String queryDoubanId = 'doubanId';
  static const String queryBangumiId = 'bangumiId';
  static const String queryAc = 'ac';
  static const String queryIds = 'ids';

  // ── JSON 字段名 ──
  static const String jsonAnnouncement = 'announcement';
  static const String jsonTitle = 'title';
  static const String jsonContent = 'content';
  static const String jsonError = 'error';
  static const String jsonToken = 'token';
  static const String jsonDeepLink = 'deepLink';
  static const String jsonBotUsername = 'botUsername';
  static const String jsonUsername = 'username';
  static const String jsonIsNewUser = 'isNewUser';
  static const String jsonTimestamp = 'timestamp';
  static const String jsonExpiration = 'expiration';
  static const String jsonData = 'data';
  static const String jsonItems = 'items';
  static const String jsonMessage = 'message';
  static const String jsonCount = 'count';
  static const String jsonTotal = 'total';
  static const String jsonScore = 'score';
  static const String jsonLarge = 'large';
  static const String jsonCommon = 'common';
  static const String jsonMedium = 'medium';
  static const String jsonSmall = 'small';
  static const String jsonGrid = 'grid';
  static const String jsonDoing = 'doing';
  static const String jsonOnHold = 'on_hold';
  static const String jsonDropped = 'dropped';
  static const String jsonWish = 'wish';
  static const String jsonCollect = 'collect';
  static const String jsonEn = 'en';
  static const String jsonCn = 'cn';
  static const String jsonJa = 'ja';
  static const String jsonNsfw = 'nsfw';
  static const String jsonLocked = 'locked';
  static const String jsonDate = 'date';
  static const String jsonPlatform = 'platform';
  static const String jsonInfobox = 'infobox';
  static const String jsonKey = 'key';
  static const String jsonValue = 'value';
  static const String jsonVolumes = 'volumes';
  static const String jsonEps = 'eps';
  static const String jsonTotalEpisodes = 'total_episodes';
  static const String jsonTags = 'tags';
  static const String jsonMetaTags = 'meta_tags';
  static const String jsonSeries = 'series';
  static const String jsonUrl = 'url';
  static const String jsonName = 'name';
  static const String jsonNameCn = 'name_cn';
  static const String jsonSummary = 'summary';
  static const String jsonAirDate = 'air_date';
  static const String jsonAirWeekday = 'air_weekday';
  static const String jsonRating = 'rating';
  static const String jsonRank = 'rank';
  static const String jsonImages = 'images';
  static const String jsonCollection = 'collection';
  static const String jsonRole = 'role';
  static const String jsonProvider = 'provider';
  static const String jsonModel = 'model';
  static const String jsonBaseUrl = 'baseUrl';
  static const String jsonCreatedAt = 'created_at';
  static const String jsonIsActive = 'is_active';
  static const String jsonCategory = 'category';
  static const String jsonCategoryId = 'categoryId';
  static const String jsonChoices = 'choices';
  static const String jsonMessages = 'messages';
  static const String jsonId = 'id';
  static const String jsonVerificationCode = 'verificationCode';
  static const String jsonNewPassword = 'newPassword';
  static const String jsonConfirmPassword = 'confirmPassword';
  static const String jsonKeyword = 'keyword';
  static const String jsonRecord = 'record';
  static const String jsonFavorite = 'favorite';
  static const String jsonFile = 'file';
  static const String jsonSuggestions = 'suggestions';
  static const String jsonCurrency = 'currency';
  static const String jsonTotalBalance = 'total_balance';
  static const String jsonIsAvailable = 'is_available';
  static const String jsonAvailableBalance = 'available_balance';
  static const String jsonSuccess = 'success';
  static const String jsonWidth = 'width';
  static const String jsonHeight = 'height';
  static const String jsonDownloadSpeed = 'downloadSpeed';
  static const String jsonLatency = 'latency';
  static const String jsonBestSource = 'bestSource';
  static const String jsonAllSourcesSpeed = 'allSourcesSpeed';
  static const String jsonVoteAverage = 'vote_average';
  static const String jsonBody = 'body';
  static const String jsonTagName = 'tag_name';

  // ── M3U8 JSON 字段 ──
  static const String jsonResolution = 'resolution';
  static const String jsonQuality = 'quality';
  static const String jsonLoadSpeed = 'loadSpeed';
  static const String jsonPingTime = 'pingTime';

  // ── VideoInfo JSON 字段 ──
  static const String jsonSourceName = 'source_name';
  static const String jsonYear = 'year';
  static const String jsonCover = 'cover';
  static const String jsonBackdrop = 'backdrop';
  static const String jsonUpdateTime = 'update_time';
  static const String jsonIndex = 'index';
  static const String jsonPlayTime = 'play_time';
  static const String jsonTotalTime = 'total_time';
  static const String jsonSaveTime = 'save_time';
  static const String jsonSearchTitle = 'search_title';
  static const String jsonDoubanId = 'douban_id';
  static const String jsonBangumiId = 'bangumi_id';
  static const String jsonRate = 'rate';
  static const String jsonReleaseDate = 'release_date';
  static const String jsonReleaseStatus = 'release_status';

  // ── 其他 JSON 字段 ──
  static const String jsonText = 'text';
  static const String jsonTime = 'time';
  static const String jsonColor = 'color';
  static const String jsonMode = 'mode';
  static const String jsonType = 'type';
  static const String jsonLimit = 'limit';
  static const String jsonIsUser = 'isUser';
  static const String jsonIsError = 'isError';
  static const String jsonVodPlayUrl = 'vod_play_url';
  static const String jsonVodYear = 'vod_year';
  static const String jsonVodId = 'vod_id';
  static const String jsonVodName = 'vod_name';
  static const String jsonVodPic = 'vod_pic';
  static const String jsonVodClass = 'vod_class';
  static const String jsonVodContent = 'vod_content';
  static const String jsonVodDoubanId = 'vod_douban_id';
  static const String jsonCacheTime = '_cacheTime';
  static const String jsonSourceNames = 'sourceNames';

  // ── AI 角色 ──
  static const String aiRoleSystem = 'system';
  static const String aiRoleUser = 'user';
  static const String aiRoleAssistant = 'assistant';
  static const String jsonDirector = 'director';
  static const String jsonActors = 'actors';
  static const String jsonRegion = 'region';
  static const String jsonGenre = 'genre';
  static const String jsonDescription = 'description';
  static const String jsonEpisodes = 'episodes';
  static const String jsonSource = 'source';
  static const String jsonUpdatedAt = 'updatedAt';
  static const String jsonOrigin = 'origin';
  static const String jsonPic = 'pic';
  static const String jsonNormal = 'normal';

  // ── EPG JSON 字段 ──
  static const String jsonChannel = 'channel';
  static const String jsonStart = 'start';
  static const String jsonStop = 'stop';
  static const String jsonEnd = 'end';
  static const String jsonTvgId = 'tvgId';
  static const String jsonEpgUrl = 'epgUrl';
  static const String jsonPrograms = 'programs';
  static const String jsonPoster = 'poster';
  static const String jsonLogo = 'logo';
  static const String jsonGroup = 'group';
  static const String jsonIsFavorite = 'isFavorite';
  static const String jsonUa = 'ua';
  static const String jsonEpg = 'epg';
  static const String jsonFrom = 'from';
  static const String jsonDisabled = 'disabled';
  static const String jsonDetail = 'detail';
  static const String jsonApi = 'api';
  static const String jsonEpisodesTitles = 'episodes_titles';
  static const String jsonClass = 'class';
  static const String jsonDesc = 'desc';
  static const String jsonTypeName = 'type_name';
  static const String jsonQuery = 'query';
  static const String jsonTotalSources = 'totalSources';
  static const String jsonTotalResults = 'totalResults';
  static const String jsonCompletedSources = 'completedSources';
  static const String jsonMergedByType = 'merged_by_type';
  static const String jsonPassword = 'password';
  static const String jsonNote = 'note';
  static const String jsonDatetime = 'datetime';
  static const String jsonCoverUrl = 'cover_url';
  static const String jsonAverage = 'average';
  static const String jsonPubdate = 'pubdate';
  static const String jsonCardSubtitle = 'card_subtitle';
  static const String jsonDurations = 'durations';
  static const String jsonOriginalTitle = 'original_title';
  static const String jsonImdb = 'imdb';
  static const String jsonIntro = 'intro';
  static const String jsonCasts = 'casts';
  static const String jsonScreenwriters = 'screenwriters';
  static const String jsonCountries = 'countries';
  static const String jsonLanguages = 'languages';
  static const String jsonRecommends = 'recommends';
  static const String jsonDirectors = 'directors';
  static const String jsonGenres = 'genres';
  static const String jsonDuration = 'duration';
  static const String jsonTotalEpisodesCamel = 'totalEpisodes';
  static const String jsonImdbId = 'imdbId';
  static const String jsonWeekday = 'weekday';
  static const String jsonReleaseDateCamel = 'releaseDate';
  static const String jsonOriginalTitleCamel = 'originalTitle';

  // ── 通用 JSON 字段 ──
  static const String jsonEmail = 'email';
  static const String jsonOk = 'ok';
  static const String jsonList = 'list';
  static const String jsonTypeId = 'type_id';
  static const String jsonUserAuth = 'user_auth';
  static const String jsonAuth = 'auth';
  static const String jsonBalanceInfos = 'balance_infos';

  // ── 下载任务 JSON 字段 ──
  static const String jsonEpisode = 'episode';
  static const String jsonEpisodeId = 'episode_id';
  static const String jsonEpisodeTitle = 'episode_title';
  static const String jsonEpisodeIndex = 'episode_index';
  static const String jsonProxy = 'proxy';
  static const String jsonResults = 'results';
  static const String jsonEpisodeCount = 'episode_count';
  static const String jsonVideoUrl = 'video_url';
  static const String jsonSavePath = 'save_path';
  static const String jsonProgress = 'progress';

  // ── 下游搜索 API 参数 ──
  static const String apiParamAc = 'ac';
  static const String apiParamWd = 'wd';
  static const String apiParamPg = 'pg';
  static const String apiValueVideolist = 'videolist';

  // ── infobox 值字段 ──
  static const String jsonV = 'v';

  // ── 文件名相关 ──
  static const String fileExtensionTs = '.ts';
  static const String invalidFilenameChars = r'[\\/:*?"<>|]';

  // ── URL 分隔符 ──
  static const String urlSeparatorDollar = r'\$';
  static const String urlSeparatorHash = '#';
  static const String urlSeparatorTripleDollar = '\$\$\$';
  static const String urlSeparatorAmpersand = '&';

  // ── 弹幕缓存键前缀 ──
  static const String danmuCacheKeyTitle = 't';
  static const String danmuCacheKeyDoubanId = 'd';
  static const String danmuCacheKeyEpisode = 'e';
  static const String danmuCacheKeyEpisodeId = 'ei';

  // ── 缓存键前缀 ──
  static const String cacheKeyPrefixShortDrama = 'shortdrama';
  static const String cacheKeyPrefixList = 'list';
  static const String cacheKeyPrefixRecommends = 'recommends';

  // ── 查询参数常量 ──
  static const String queryCategoryId = 'categoryId';
  static const String queryKeyword = 'keyword';
  static const String queryQ = 'q';
  static const String queryQuery = 'query';
  static const String jsonStatus = 'status';
  static const String jsonTotalBytes = 'total_bytes';
  static const String jsonDownloadedBytes = 'downloaded_bytes';
  static const String jsonCompletedAt = 'completed_at';
  static const String jsonLocalFileName = 'local_file_name';
  static const String jsonRetryCount = 'retry_count';
  static const String jsonPageCount = 'pagecount';
  static const String jsonDanmu = 'danmu';
  static const String jsonExpired = 'expired';
  static const String jsonNullValue = 'null';
  static const String jsonSize = 'size';
  static const String jsonSizeLimited = 'sizeLimited';

  // ── 内容类型标识 ──
  static const String contentTypeAll = 'all';
  static const String contentTypeHistory = 'history';
  static const String contentTypeMusical = 'musical';
  static const String contentTypeDarkHumor = 'dark_humor';
  static const String contentTypeInspirational = 'inspirational';
  static const String contentTypeParody = 'parody';
  static const String contentTypeHealing = 'healing';
  static const String contentTypeSports = 'sports';
  static const String contentTypeHarem = 'harem';
  static const String contentTypeErotic = 'erotic';
  static const String contentTypeChineseAnime = 'chinese_anime';
  static const String contentTypeHumanNature = 'human_nature';
  static const String contentTypeSuspense = 'suspense';
  static const String contentTypeLove = 'love';
  static const String contentTypeFantasy = 'fantasy';
  static const String contentTypeSciFi = 'sci_fi';
  static const String contentTypeStopMotion = 'stop_motion';
  static const String contentTypeBiography = 'biography';
  static const String contentTypeUsAnimation = 'us_animation';
  static const String contentTypeRomance = 'romance';
  static const String contentTypeChildren = 'children';
  static const String contentTypeAnime = 'anime';
  static const String contentTypeAnimal = 'animal';
  static const String contentTypeYouth = 'youth';

  // ── 搜索事件类型 ──
  static const String searchEventStart = 'start';
  static const String searchEventSourceResult = 'source_result';
  static const String searchEventSourceError = 'source_error';
  static const String searchEventComplete = 'complete';

  // ── HTTP 请求头补充 ──
  static const String headerAcceptAll = '*/*';
  static const String headerAcceptTextHtml = 'text/html';
  static const String headerReferer = 'Referer';
  static const String headerOrigin = 'Origin';
  static const String headerContentType = 'Content-Type';
  static const String headerUserAgent = 'User-Agent';
  static const String headerAuthorization = 'Authorization';
  static const String headerAccept = 'Accept';
  static const String headerSetCookie = 'set-cookie';
  static const String headerAcceptJsonTextPlain = 'application/json, text/plain, */*';
  static const String headerGithubApi = 'application/vnd.github.v3+json';

  // ── 存储键 ──
  static const String storageKeyUsername = 'username';
  static const String storageKeyPassword = 'password';
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyCookies = 'cookies';
  static const String storageKeyLocalSearch = 'local_search';
  static const String storageKeyDefaultPlaybackSpeed = 'default_playback_speed';
  static const String storageKeyAutoEnterPictureInPicture = 'auto_enter_picture_in_picture';
  static const String storageKeyAutoSkipOpeningEnding = 'auto_skip_opening_ending';
  static const String storageKeySkipOpeningDuration = 'skip_opening_duration';
  static const String storageKeySkipEndingDuration = 'skip_ending_duration';
  static const String storageKeyAutoPlayNext = 'auto_play_next';
  static const String storageKeyFamilyMode = 'family_mode';
  static const String storageKeyDanmakuEnabled = 'danmaku_enabled';
  static const String storageKeyDanmakuSpeed = 'danmaku_speed';
  static const String storageKeyDanmakuOpacity = 'danmaku_opacity';
  static const String storageKeyDanmakuFontSize = 'danmaku_font_size';
  static const String storageKeyDanmakuDisplayArea = 'danmaku_display_area';
  static const String storageKeyDanmakuAntiBlock = 'danmaku_anti_block';
  static const String storageKeyDanmakuSyncSpeed = 'danmaku_sync_speed';
  static const String storageKeyLoginAttempts = 'login_attempts';
  static const String storageKeyLastLoginAttempt = 'last_login_attempt';
  static const String storageKeyAccountLockedUntil = 'account_locked_until';
  static const String storageKeyDownloadTasks = 'download_tasks';
  static const String storageKeyMaxConcurrentDownloads = 'max_concurrent_downloads';
  static const String storageKeyConcurrentThreads = 'concurrent_threads';
  static const String storageKeyDownloadSavePath = 'download_save_path';
  static const String storageKeyServerUrl = 'serverUrl';
  static const String storageKeyAuthToken = 'token';

  // ── 下载相关 ──
  static const String downloadTempDirSuffix = '_temp';
  static const String downloadSegmentPrefix = 'seg_';
  static const String downloadEncryptedExtension = '._enc';

  // ── 文件名后缀 ──
  static const String fileExtensionJson = '.json';
  static const String fileExtensionApk = '.apk';
  static const String fileExtensionDmg = '.dmg';
  static const String fileExtensionIpa = '.ipa';
  static const String fileExtensionExe = '.exe';

  // ── DLNA 传输状态 ──
  static const String dlnaStatePlaying = 'PLAYING';
  static const String dlnaStatePaused = 'PAUSED_PLAYBACK';
  static const String dlnaStateStopped = 'STOPPED';

  // ── API 注入过滤字符 ──
  static const List<String> injectionFilterChars = [
    "'", '"', ';', '--', '/*', '*/', '<', '>'
  ];

  // ── 占位符常量 ──
  static const String emptyId = '0';

  // ── 播放速度值 ──
  static const List<double> playbackSpeedValues = [0.5, 0.75, 1.0, 1.5, 2.0];

  // ── 弹幕速度值 ──
  static const List<double> danmakuSpeedValues = [0.5, 0.75, 1.0, 1.5, 2.0];

  // ── 弹幕显示区域值 ──
  static const List<double> danmakuAreaValues = [0.25, 0.5, 0.75, 1.0];

  // ── 存储键 ──
  static const String storageKeyLastVersionCheck = 'last_version_check';
  static const String storageKeyDismissedVersion = 'dismissed_version';

  // ── 筛选器值常量（地区） ──
  static const String filterRegionChinese = 'chinese';
  static const String filterRegionWestern = 'western';
  static const String filterRegionForeign = 'foreign';
  static const String filterRegionKorean = 'korean';
  static const String filterRegionJapanese = 'japanese';
  static const String filterRegionMainlandChina = 'mainland_china';
  static const String filterRegionHongKong = 'hong_kong';
  static const String filterRegionTaiwan = 'taiwan';
  static const String filterRegionThailand = 'thailand';
  static const String filterRegionItaly = 'italy';
  static const String filterRegionFrance = 'france';
  static const String filterRegionGermany = 'germany';
  static const String filterRegionSpain = 'spain';
  static const String filterRegionRussia = 'russia';
  static const String filterRegionSweden = 'sweden';
  static const String filterRegionBrazil = 'brazil';
  static const String filterRegionDenmark = 'denmark';
  static const String filterRegionIndia = 'india';
  static const String filterRegionCanada = 'canada';
  static const String filterRegionIreland = 'ireland';
  static const String filterRegionAustralia = 'australia';
  static const String filterRegionUSA = 'usa';
  static const String filterRegionUK = 'uk';

  // ── 筛选器值常量（年代） ──
  static const String filterYear2020s = '2020s';
  static const String filterYear2025 = '2025';
  static const String filterYear2024 = '2024';
  static const String filterYear2023 = '2023';
  static const String filterYear2022 = '2022';
  static const String filterYear2021 = '2021';
  static const String filterYear2020 = '2020';
  static const String filterYear2019 = '2019';
  static const String filterYear2010s = '2010s';
  static const String filterYear2000s = '2000s';
  static const String filterYear1990s = '1990s';
  static const String filterYear1980s = '1980s';
  static const String filterYear1970s = '1970s';
  static const String filterYear1960s = '1960s';
  static const String filterYearEarlier = 'earlier';

  // ── 筛选器值常量（平台） ──
  static const String filterPlatformTencent = 'tencent';
  static const String filterPlatformIqiyi = 'iqiyi';
  static const String filterPlatformYouku = 'youku';
  static const String filterPlatformHunanTv = 'hunan_tv';
  static const String filterPlatformNetflix = 'netflix';
  static const String filterPlatformHBO = 'hbo';
  static const String filterPlatformBBC = 'bbc';
  static const String filterPlatformNHK = 'nhk';
  static const String filterPlatformCBS = 'cbs';
  static const String filterPlatformNBC = 'nbc';
  static const String filterPlatformTvN = 'tvn';

  // ── 通用常量 ──
  static const String fontFamilyMonospace = 'monospace';
  static const String resetType = 'reset';

  // ── HTTP 头补充 ──
  static const String headerXRequestedWith = 'X-Requested-With';
  static const String headerXUserAuth = 'X-User-Auth';
  static const String headerCacheControl = 'Cache-Control';
  static const String headerCookie = 'Cookie';
}
