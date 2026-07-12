/// 应用统一字符串常量
///
/// 集中管理所有 UI 文本，按功能区域分组。
/// 未来可对接 Flutter l10n 实现国际化。
class AppStrings {
  AppStrings._();

  // ── 通用 ──
  static const String all = '全部';
  static const String cancel = '取消';
  static const String confirm = '确定';
  static const String clear = '清空';
  static const String retry = '重试';
  static const String loading = '加载中...';
  static const String serverError = '服务器错误';
  static const String networkError = '网络异常';
  static const String networkRetryLater = '网络异常，请稍后重试';
  static const String loadFailed = '加载失败';
  static const String noMoreData = '已经到底啦~';
  static const String refreshDot = '刷新中...';
  static const String unknown = '未知';
  static const String done = '完成';
  static const String save = '保存';
  static const String delete = '删除';
  static const String edit = '编辑';
  static const String share = '分享';
  static const String favorite = '收藏';
  static const String unfavorite = '取消收藏';

  // ── 导航标签 ──
  static const String navHome = '首页';
  static const String navMovie = '电影';
  static const String navTv = '电视剧';
  static const String navAnime = '动漫';
  static const String navShow = '综艺';
  static const String navShortDrama = '短剧';
  static const String navLive = '直播';
  static const String navHistory = '播放历史';
  static const String navFavorites = '收藏夹';
  static const String navProfile = '我的';

  // ── Auth：登录 ──
  static const String authLogin = '登录';
  static const String authLoginLoading = '登录中...';
  static const String authLogout = '登出';
  static const String authRegister = '注册';
  static const String authForgotPassword = '忘记密码';
  static const String authUsernameOrEmail = '用户名或邮箱';
  static const String authPassword = '密码';
  static const String authHintUsernameOrEmail = '请输入用户名或邮箱';
  static const String authHintPassword = '请输入密码';
  static const String authValidUsernameOrEmail = '请输入用户名或邮箱';
  static const String authValidEmail = '请输入有效的邮箱地址';
  static const String authValidPassword = '请输入密码';
  static const String authValidPasswordLength = '密码长度不能超过32个字符';
  static const String authValidUsernameLength = '用户名长度不能超过32个字符';
  static const String authLoginSuccess = '登录成功';
  static const String authLoginFailed = '用户名或密码错误';
  static const String authLoginEmpty = '请填写完整的登录信息';
  static const String authAccountLocked = '账户已被锁定';
  static const String authAccountLockedLater = '账户已被锁定，请稍后再试';
  static const String authBannedAccount = '账号已被封禁';
  static const String authTelegramConnecting = '正在连接 Telegram...';
  static const String authTelegramRegisterSuccess = '注册成功，请查看 Telegram 机器人发送的账号密码';
  static const String authTelegramLoginFailed = 'Telegram 登录失败';
  static const String authNewUserSuccess = '注册成功！';
  static const String authRegisterFailed = '注册失败';
  static const String authRegisterDisabled = '注册功能已关闭';
  static const String authTooFrequent = '操作过于频繁';

  // ── Auth：注册 ──
  static const String regTitle = '创建您的新账户';
  static const String regUsername = '用户名';
  static const String regEmail = '邮箱';
  static const String regConfirmPassword = '确认密码';
  static const String regVerificationCode = '验证码';
  static const String regHintUsername = '请输入用户名';
  static const String regHintEmail = '请输入邮箱地址';
  static const String regHintPassword = '请输入密码';
  static const String regHintConfirmPassword = '再次输入密码';
  static const String regHintCode = '请输入6位数字验证码';
  static const String regBtnRegister = '注册';
  static const String regBtnRegistering = '注册中...';
  static const String regGetCode = '获取验证码';
  static const String regSendingCode = '发送验证码';
  static const String regSendCodeSuccess = '验证码已发送到您的邮箱';
  static const String regSendCodeFailed = '发送验证码失败';
  static const String regAlreadyHaveAccount = '已有账户？';
  static const String regLoginNow = '立即登录';
  static const String regValidUsername = '请输入用户名';
  static const String regValidUsernameChars = '用户名只能包含字母、数字和汉字';
  static const String regValidEmail = '请输入邮箱地址';
  static const String regValidEmailFormat = '请输入有效的邮箱地址';
  static const String regValidEmailDomain = '不支持此邮箱';
  static const String regValidPassword = '请输入密码';
  static const String regValidPasswordMin = '密码长度至少6位';
  static const String regValidConfirmPassword = '请再次输入密码';
  static const String regValidPasswordMismatch = '两次输入的密码不一致';
  static const String regValidCode = '请输入验证码';
  static const String regValidCodeFormat = '验证码必须为6位数字';
  static const String regValidCodeFormatHint = '验证码格式错误，应为6位数字';
  static const String regFillAll = '请填写完整的注册信息';

  // ── Auth：忘记密码 ──
  static const String forgotTitle = '重置您的密码';
  static const String forgotNewPassword = '新密码';
  static const String forgotBtnReset = '重置密码';
  static const String forgotBtnResetting = '重置中...';
  static const String forgotHintNewPassword = '请输入新密码';
  static const String forgotFillAll = '请填写完整的信息';
  static const String forgotResetSuccess = '密码重置成功！';
  static const String forgotResetFailed = '重置失败';
  static const String forgotEmailNotRegistered = '邮箱未注册';
  static const String forgotServerResponseError = '服务器响应格式异常';

  // ── 筛选器 ──
  static const String filterCategory = '分类';
  static const String filterType = '类型';
  static const String filterRegion = '地区';
  static const String filterYear = '年代';
  static const String filterPlatform = '平台';
  static const String filterSort = '排序';
  static const String filterMore = '更多筛选';
  static const String filterClear = '重置';

  // 排序选项
  static const String sortComprehensive = '综合排序';
  static const String sortRecent = '近期热度';
  static const String sortAiringTime = '首播时间';
  static const String sortRating = '高分优先';
  static const String sortYearAsc = '年份从旧到新';
  static const String sortYearDesc = '年份从新到旧';

  // ── 筛选年份 ──
  static const String filterAllYears = '全部年份';
  static const String filterAllTitles = '全部标题';

  // 一级分类
  static const String catLatestMovie = '最新电影';

  // 地区
  static const String regionDomestic = '国产';
  static const String regionForeign = '国外';
  static const String regionMainlandChina = '中国大陆';
  static const String regionHongKong = '中国香港';
  static const String regionTaiwan = '中国台湾';
  static const String regionUSA = '美国';
  static const String regionUK = '英国';
  static const String regionFrance = '法国';
  static const String regionGermany = '德国';
  static const String regionItaly = '意大利';
  static const String regionSpain = '西班牙';
  static const String regionRussia = '俄罗斯';
  static const String regionSweden = '瑞典';
  static const String regionBrazil = '巴西';
  static const String regionDenmark = '丹麦';
  static const String regionIndia = '印度';
  static const String regionCanada = '加拿大';
  static const String regionIreland = '爱尔兰';
  static const String regionAustralia = '澳大利亚';
  static const String regionThailand = '泰国';

  // 影片类型
  static const String typeComedy = '喜剧';
  static const String typeRomance = '爱情';
  static const String typeSuspense = '悬疑';
  static const String typeAction = '动作';
  static const String typeDrama = '剧情';
  static const String typeSciFi = '科幻';
  static const String typeHorror = '恐怖';
  static const String typeFantasy = '奇幻';
  static const String typeThriller = '惊悚';
  static const String typeAdventure = '冒险';
  static const String typeDocumentary = '纪录片';
  static const String typeBiography = '传记';
  static const String typeHistory = '历史';
  static const String typeWar = '战争';
  static const String typeCrime = '犯罪';
  static const String typeMusical = '歌舞';
  static const String typeMusic = '音乐';
  static const String typeCostume = '古装';
  static const String typeWuxia = '武侠';
  static const String typeFamily = '家庭';
  static const String typeDisaster = '灾难';
  static const String typeReality = '真人秀';
  static const String typeTalkShow = '脱口秀';

  // 平台
  static const String platformTencent = '腾讯视频';
  static const String platformIqiyi = '爱奇艺';
  static const String platformYouku = '优酷';
  static const String platformHunanTv = '湖南卫视';

  // ── SSE 搜索 ──
  static const String sseNoAvailableResources = '没有可用的搜索资源';
  static const String sseLocalSearchError = '本地搜索异常: ';
  static const String sseSearchTimeout20 = '搜索超时（20秒）';
  static const String sseSearchTimeout15 = '搜索超时（15秒）';
  static const String sseEmptyQuery = '搜索查询不能为空';
  static const String sseUserNotLoggedIn = '用户未登录';
  static const String sseConnectionFailed = '连接失败: ';
  static const String sseParseFailed = '消息解析失败: ';
  static const String sseSearchComplete = '搜索完成';
  static const String sseSearching = '正在搜索: ';
  static const String ssePreparing = '准备搜索...';
  static const String sseError = 'SSE 错误: ';
  static const String sseConnectionFailedStatus = 'SSE 连接失败: ';

  // ── 搜索 ──
  static const String searchHint = '搜索电影、剧集、动漫...';
  static const String searchHistory = '搜索历史';
  static const String searchNoHistory = '暂无搜索历史';
  static const String searchStartHint = '开始搜索你喜欢的内容吧';
  static const String searchResults = '搜索结果';
  static const String searchAggregate = '聚合';
  static const String searchAllSources = '全部来源';
  static const String searchNoResults = '未找到结果';
  static const String searchTryOther = '请尝试更换关键词';
  static const String searchSearching = '搜索中...';
  static const String searchAggregateWait = '聚合搜索中，请稍候';
  static const String searchClearConfirmTitle = '清空搜索历史';
  static const String searchClearConfirmDesc = '确定要清空所有搜索历史吗？此操作无法撤销。';

  // ── 首页 ──
  static const String homeContinueWatching = '继续观看';
  static const String homeUpcoming = '即将上映';
  static const String homeViewMore = '查看更多 >';
  static const String homeHotMovie = '热门电影';
  static const String homeHotTv = '热门剧集';
  static const String homeHotShow = '热门综艺';
  static const String homeHotShortDrama = '热门短剧';
  static const String homeBangumiSchedule = '新番放送';

  // ── 播放器 ──
  static const String playerSearchingSource = '正在搜索播放源...';
  static const String playerFetchingDetail = '正在获取播放源详情...';
  static const String playerReadyPlay = '准备就绪，即将开始播放...';
  static const String playerVideoLoading = '视频加载中...';
  static const String playerSwitchSource = '切换播放源...';
  static const String playerSwitchEpisode = '切换选集...';
  static const String playerAutoNext = '自动播放下一集...';
  static const String playerLastEpisode = '已经是最后一集了';
  static const String playerPlayCompleted = '播放完成';
  static const String playerMissingParam = '缺少必要参数';
  static const String playerNoMatch = '未找到匹配结果';

  // DLNA 投屏
  static const String dlnaStopCasting = '停止投屏';
  static const String dlnaKeepPlaying = 'DLNA 设备可继续保持播放，是否需要停止？\n\n（保持播放时无法同步进度和播放记录）';
  static const String dlnaKeep = '保持';
  static const String dlnaStop = '停止';

  // ── 播放器面板 ──
  static const String panelEpisodes = '选集';
  static const String panelSwitchSource = '换源';
  static const String panelDownload = '下载';
  static const String panelSelectAll = '全选';
  static const String panelAvailableSources = '可用播放源';

  // ── 播放器详情 ──
  static const String detailInfo = '详情';
  static const String detailStyle = '风格';
  static const String detailProduction = '制作信息';
  static const String detailSummary = '简介';
  static const String detailNoSummary = '暂无简介';
  static const String detailNoTitle = '暂无标题';

  // ── 豆瓣 ──
  static const String doubanDetail = '豆瓣详情';
  static const String doubanFromDouban = '来自豆瓣';
  static const String doubanFromBangumi = '来自 Bangumi';
  static const String doubanIntro = '豆瓣简介';
  static const String doubanDirector = '导演';
  static const String doubanActor = '主演';
  static const String doubanOriginal = '原作';
  static const String doubanScript = '脚本';
  static const String doubanStoryboard = '分镜';
  static const String doubanPerform = '演出';
  static const String doubanScreenwriter = '编剧';
  static const String doubanDirectorColon = '导演: ';
  static const String doubanScreenwriterColon = '编剧: ';
  static const String doubanActorColon = '主演: ';

  // ── 视频菜单 ──
  static const String menuPlay = '播放';
  static const String menuDeleteRecord = '删除记录';
  static const String menuComingSoon = '敬请期待';

  // ── 收藏 ──
  static const String favFailed = '收藏失败';
  static const String favUnfavoriteFailed = '取消收藏失败';

  // ── 个人中心 ──
  static const String profileCurrentUser = '当前用户';
  static const String profileUnknownUser = '未知用户';
  static const String profileRoleAdmin = '管理员';
  static const String profileRoleOwner = '站长';
  static const String profileRoleUser = '用户';
  static const String profileDownloadManage = '下载管理';
  static const String profileDownloadSettings = '下载设置';
  static const String profilePlaybackSettings = '播放设置';
  static const String profileDanmakuSettings = '弹幕设置';
  static const String profileThemeSettings = '主题设置';
  static const String profileAnnouncement = '公告';
  static const String profileCheckUpdate = '检查更新';
  static const String profileThemeLight = '浅色';
  static const String profileThemeDark = '深色';
  static const String profileCheckingUpdate = '正在检查更新...';
  static const String profileAlreadyLatest = '当前已是最新版本';
  static const String profileCheckUpdateFailed = '检查更新失败: ';
  static const String profileFetchingAnnouncement = '正在获取公告...';
  static const String profileNoAnnouncement = '暂无公告';
  static const String profileFetchAnnouncementFailed = '获取公告失败: ';
  static const String profileClearDoubanCache = '清除豆瓣缓存';
  static const String profileClearDone = '已清除豆瓣缓存';
  static const String profileClearFailed = '清除豆瓣缓存失败';
  static const String profileLocalSearch = '本地搜索';

  // ── 更新对话框 ──
  static const String updateImportant = '重要更新';
  static const String updateNewVersion = '发现新版本';
  static const String updateForceMsg = '此更新为强制更新，请立即更新以继续使用';
  static const String updateCurrentVersion = '当前版本';
  static const String updateLatestVersion = '最新版本';
  static const String updateContent = '更新内容';
  static const String updateInstallNow = '立即安装';
  static const String updateNow = '立即更新';
  static const String updateIgnore = '忽略';
  static const String updateLater = '稍后';
  static const String updatePleaseWait = '请稍候';
  static const String updateNeedPermission = '需要安装权限才能安装应用';
  static const String updateInstallFailed = '安装失败';
  static const String updateOpenFailed = '打开安装文件失败';
  static const String updateError = '发生错误';
  static const String updateCancelled = '下载已取消';

  // ── 直播 ──
  static const String liveChannelLoading = '正在加载频道列表...';
  static const String livePlayError = '播放出错';
  static const String liveSearch = '搜索直播源';
  static const String liveNoSource = '暂无直播源';
  static const String liveNoChannel = '该直播源暂无频道';
  static const String liveLoadFailed = '加载失败: ';
  static const String liveSourceSwitched = '当前源已不存在，已切换到 ';
  static const String liveRefreshFailed = '刷新失败: ';
  static const String liveChannelList = '频道列表';
  static const String liveSource = '直播源';
  static const String liveGroup = '分组';
  static const String liveNowPlaying = '正在播放: ';
  static const String liveNoProgramInfo = '暂无节目信息';
  static const String liveViewSchedule = '查看节目单';
  static const String liveSchedule = '节目单';
  static const String liveLoadingSchedule = '加载节目单中...';
  static const String liveNoScheduleInfo = '暂无节目单信息';
  static const String liveSwitchChannel = '切换频道...';
  static const String liveSwitchSource = '切换直播源...';
  static const String livePlayerLoadFailed = '播放器加载失败: ';
  static const String liveLoadChannelsFailed = '加载频道列表失败';
  static const String liveLoadSourcesFailed = '加载直播源失败';
  static const String liveLoadScheduleFailed = '加载节目单失败';
  static const String liveCopySuccess = '已复制';
  static const String liveCannotOpenLink = '无法打开链接';

  // ── 下载管理 ──
  static const String downloadDownloading = '下载中';
  static const String downloadCompleted = '已完成';
  static const String downloadDeleteMode = '删除模式';
  static const String downloadQueued = '等待中';
  static const String downloadPaused = '已暂停';
  static const String downloadFailed = '下载失败';
  static const String downloadCannotChangePath = '有正在下载的任务，无法修改保存路径';
  static const String downloadPathUpdated = '保存路径已更新';
  static const String downloadSelectPathFailed = '选择路径失败: ';
  static const String downloadSettings = '下载设置';
  static const String downloadConcurrentTasks = '同时下载任务数';
  static const String downloadConcurrentThreads = '并发线程数';
  static const String downloadSavePath = '保存路径';
  static const String downloadSelectPath = '选择路径';
  static const String downloadNoPath = '未设置保存路径';
  static const String downloadSettingsTip = '提示：增加同时下载任务数和并发线程数可以加快下载速度，但也会消耗更多系统资源。请根据您的设备性能进行调整。';
  static const String downloadManagement = '下载管理';
  static const String downloadTabDownloading = '下载中';
  static const String downloadTabCompleted = '已完成';
  static const String downloadResumeAll = '全部继续';
  static const String downloadPauseAll = '全部暂停';
  static const String downloadDeleteAll = '删除全部';
  static const String downloadBatchDelete = '批量删除';
  static const String downloadDeleteAllConfirm = '确定要删除所有已完成的下载任务吗？';
  static const String downloadDeleteGroup = '删除分组';
  static const String downloadDeleteGroupConfirm = '确定要删除该分组的任务吗？';
  static const String downloadNoContent = '暂无下载内容';
  static const String downloadFileNotFound = '文件不存在: ';
  static const String downloadFailedRetry = '下载失败，点击重试';
  static const String downloadRetrying = '重试中';
  static const String downloadContinue = '继续';
  static const String downloadQueueLabel = '队列';

  // ── 网盘搜索 ──
  static const String netdiskSearchTitle = '网盘资源搜索';
  static const String netdiskSearchHint = '输入关键词搜索网盘资源';
  static const String netdiskSearchStartHint = '输入关键词开始搜索';
  static const String netdiskNoResults = '未找到相关资源';
  static const String netdiskTryOtherKeywords = '尝试使用其他关键词搜索';
  static const String netdiskSearching = '正在搜索网盘资源...';
  static const String netdiskSearchFailed = '搜索失败';
  static const String netdiskSearchError = '搜索失败: ';
  static const String netdiskCannotOpenUrl = '无法打开链接';
  static const String netdiskOpenUrlFailed = '打开链接失败: ';
  static const String netdiskCopied = '已复制';
  static const String netdiskCopyFailed = '复制失败: ';
  static const String netdiskCollapse = '收起';
  static const String netdiskExpand = '展开';
  static const String netdiskAccessLink = '访问链接';
  static const String netdiskCopyLink = '复制链接';
  static const String netdiskCopyPassword = '复制密码';
  static const String netdiskShowPassword = '显示密码';
  static const String netdiskHidePassword = '隐藏密码';
  static const String netdiskLinksCount = '个链接';
  static const String netdiskSource = '来源: ';
  static const String netdiskUnnamedResource = '未命名资源';
  static const String netdiskStatsTotal = '共找到 ';

  // ── 播放源 ──
  static const String playerSourcesCountFormat = '共 %d 个播放源';

  // ── 播放设置 ──
  static const String playbackAutoPlay = '自动连播';
  static const String playbackFamilyMode = '家庭模式';
  static const String playbackDefaultSpeed = '默认播放倍速';
  static const String playbackSkipOpening = '跳过片头';
  static const String playbackSkipEnding = '跳过片尾';
  static const String playbackSeconds = '秒';
  static const String playbackOn = '开启';
  static const String playbackOff = '关闭';
  static const String playbackAutoPIP = '自动开启画中画';
  static const String playbackSettingsTitle = '播放设置';
  static const String playbackSettingsTip = '提示：开启这些设置可以提升您的观看体验，但可能会消耗更多电量和网络流量。';
  static const String playbackSkipOpeningEnding = '自动跳过片头片尾';
  static const String playbackSkipOpeningDuration = '片头跳过时长';
  static const String playbackSkipEndingDuration = '片尾跳过时长';

  // ── 弹幕设置 ──
  static const String danmakuEnable = '弹幕开关';
  static const String danmakuSpeed = '弹幕速度';
  static const String danmakuOpacity = '弹幕透明度';
  static const String danmakuFontSize = '弹幕字号';
  static const String danmakuDisplayArea = '弹幕显示区域';
  static const String danmakuSettings = '弹幕设置';

  // ── 弹幕设置标签 ──
  static const List<String> danmakuSpeedLabels = ['极慢', '较慢', '适中', '较快', '极快'];
  static const List<String> danmakuAreaLabels = ['1/4', '半屏', '3/4', '满屏'];

  // ── AI 页面 ──
  static const String aiSettings = 'AI 设置';
  static const String aiApiKey = 'API Key';
  static const String aiModel = '模型';
  static const String aiSystemPrompt = '系统提示词';

  // ── 上映状态 ──
  static const String releaseToday = '今日上映';
  static const String releaseAlready = '已上映';
  static const String releaseDaysLater = '天后上映';

  // ── 源名称 ──
  static const String doubanSourceName = '豆瓣';
  static const String bangumiSourceName = 'Bangumi';
  static const String shortDramaName = '短剧';

  // ── 网盘名称 ──
  static const String cloudBaidu = '百度网盘';
  static const String cloudAliyun = '阿里云盘';
  static const String cloudQuark = '夸克网盘';
  static const String cloudTianyi = '天翼云盘';
  static const String cloudUc = 'UC网盘';
  static const String cloudMobile = '移动云盘';
  static const String cloud115 = '115网盘';
  static const String cloudPikpak = 'PikPak';
  static const String cloudXunlei = '迅雷网盘';
  static const String cloud123 = '123网盘';
  static const String cloudMagnet = '磁力链接';
  static const String cloudEd2k = '电驴链接';
  static const String cloudOther = '其他';
  // 网盘 emoji
  static const String cloudIconBaidu = '📁';
  static const String cloudIconAliyun = '☁️';
  static const String cloudIconQuark = '⚡';
  static const String cloudIconTianyi = '📱';
  static const String cloudIconUc = '🌐';
  static const String cloudIconMobile = '📲';
  static const String cloudIcon115 = '💾';
  static const String cloudIconPikpak = '📦';
  static const String cloudIconXunlei = '⚡';
  static const String cloudIcon123 = '🔢';
  static const String cloudIconMagnet = '🧲';
  static const String cloudIconEd2k = '🐴';
  static const String cloudIconOther = '📄';

  // ── Telegram 认证 ──
  static const String telegramRequesting = '正在请求 Telegram 认证...';
  static const String telegramOpening = '正在打开 Telegram...';
  static const String telegramNotInstalled = '无法打开 Telegram，请确保已安装 Telegram 客户端';
  static const String telegramWaiting = '等待 Telegram 验证...';
  static const String telegramTimeout = 'Telegram 认证超时';
  static const String telegramError = '认证过程出错';
  static const String telegramRequestFailed = '请求 Telegram 认证失败';
  static const String telegramComponentDestroyed = '组件已销毁';

  // ── AI 服务 ──
  static const String aiTitle = 'AI 助手';
  static const String aiThinking = 'AI 正在思考...';
  static const String aiConfigApiKeyFirst = '请先在设置中配置AI API密钥';
  static const String aiNoValidReply = 'AI没有返回有效回复';
  static const String aiParseFailed = '解析响应失败';
  static const String aiRequestFailed = '请求失败';
  static const String aiInvalidApiKey = 'API密钥无效，请检查设置';
  static const String aiRateLimited = '请求过于频繁，请稍后再试';
  static const String aiServerError = '服务器内部错误';
  static const String aiConnectionSuccess = '连接成功';
  static const String aiConnectionFailed = '连接失败，请检查密钥和网络';
  static const String aiSettingsSaved = '设置已保存';
  static const String aiSelectProvider = '选择提供商';
  static const String aiSelectModel = '选择模型';
  static const String aiEnterModelName = '请输入模型名称';
  static const String aiEnterApiKeyFirst = '请先输入API密钥';
  static const String aiSelectModelHint = '请选择模型';
  static const String aiApiKeySecureStorage = '密钥将安全地加密存储在本机';
  static const String aiApiKeyHint = 'sk-xxxxxxxxxxxxxxxx';
  static const String aiTestConnection = '测试';
  static const String aiBalance = '账户余额';
  static const String aiBalanceChecking = '查询中...';
  static const String aiBalanceQueryFailed = '连接失败请检查密钥';
  static const String aiBalanceHint = '请输入API密钥查询余额';
  static const String aiDeleteConversation = '删除对话';

  // ── 通用错误 ──
  static const String errorConfigApiKey = '请先在设置中配置API密钥';

  // ── 搜索服务 ──
  static const String searchSourceNotFound = '未找到对应的源: ';
  static const String searchDetailInvalid = '获取到的详情内容无效';
  static const String detailRequestFailed = '详情请求失败: ';
  static const String detailPageRequestFailed = '详情页请求失败: ';

  // ── 直播服务 ──
  static const String liveSourceNotFound = '未找到直播源: ';
  static const String liveChannelNotFound = '未找到频道列表: ';

  // ── M3U8 服务 ──
  static const String m3u8NoVideoSegment = '未找到视频片段';
  static const String m3u8NoAvailableSource = '没有可用的源';
  static const String m3u8ParseFailed = '未解析到任何视频片段，可能不是有效的 M3U8 地址';
  static const String m3u8DownloadKeyFailed = '下载解密密钥失败';
  static const String m3u8ParseDepthTooDeep = 'M3U8 解析层级过深，可能存在循环引用';
  static const String m3u8InvalidUrl = '无效的 M3U8 链接';
  static const String m3u8CannotExtractSubPlaylist = '无法从主播放列表提取子播放列表';
  static const String m3u8NoSegmentsToMerge = '没有可合并的视频片段';
  static const String m3u8NoValidSegments = '没有有效的视频片段可合并';
  static const String m3u8MergeSizeAbnormal = '合并后的文件大小异常，可能下载失败';

  // ── Bangumi 服务 ──
  static const String bangumiCalendarFetchFailed = '获取 Bangumi 日历失败';
  static const String bangumiRequestException = 'Bangumi 数据请求异常';
  static const String bangumiCacheFormatError = 'Bangumi 缓存数据格式错误';
  static const String bangumiDetailParseFailed = 'Bangumi 详情数据解析失败';
  static const String bangumiDetailFetchFailed = '获取 Bangumi 详情数据失败';

  // ── 业务提示 ──
  static const String msgSaveSuccess = '保存成功';
  static const String msgOperationSuccess = '操作成功';
  static const String msgOperationFailed = '操作失败';

  // ── 格式化模板 ──
  static const String formatRemainingAttempts = '还有%d次尝试机会';
  static const String formatLockedMinutes = '账户已被锁定，请%d分钟后再试';
  static const String formatLockedLater = '账户已被锁定，请稍后再试';

  static String formatEpisodeTitle(int index) => '第$index集';
  static String formatLockedMinutesTitle(int minutes) => '账户已被锁定，请$minutes分钟后再试';
  static String formatRemainingAttemptsTitle(int attempts) => '还有$attempts次尝试机会';

  // ── 错误消息 ──
  static const String errorGetFailed = '获取失败';
  static const String errorDeleteFailed = '删除失败';
  static const String errorAddFailed = '添加失败';
  static const String errorRequestFailed = '请求失败，请稍后重试';
  static const String errorNetworkRequest = '网络请求异常，请稍后重试';
  static const String errorException = '异常: ';
  static const String msgUnknownError = '未知错误';
  static const String msgNoData = '暂无数据';

  // ── 预定义类型标签 ──
  static const String movie = '电影';
  static const String tvShow = '剧集';
  static const String categoryAnimation = '动画';

  // ── 封禁关键词 ──
  static const String bannedKeyword = '封禁';

  // ── 动漫相关 ──
  static const String animeDailyBroadcast = '每日放送';
  static const String animeSeries = '番剧';
  static const String animeMovie = '剧场版';

  // ── 星期 ──
  static const String weekMonday = '周一';
  static const String weekTuesday = '周二';
  static const String weekWednesday = '周三';
  static const String weekThursday = '周四';
  static const String weekFriday = '周五';
  static const String weekSaturday = '周六';
  static const String weekSunday = '周日';
  static const String weekTitle = '星期';

  // ── 更多影片类型 ──
  static const String typeDarkHumor = '黑色幽默';
  static const String typeInspirational = '励志';
  static const String typeParody = '恶搞';
  static const String typeHealing = '治愈';
  static const String typeSports = '运动';
  static const String typeHarem = '后宫';
  static const String typeErotic = '情色';
  static const String typeChineseAnime = '国漫';
  static const String typeHumanNature = '人性';
  static const String typeLove = '恋爱';
  static const String typeStopMotion = '定格动画';
  static const String typeUsAnimation = '美国动画';
  static const String typeChildren = '儿童';
  static const String typeAnime = '二次元';
  static const String typeAnimal = '动物';
  static const String typeYouth = '青春';
  static const String typeWestern = '西部';
  static const String typeShort = '短片';

  // ── 更多平台 ──
  static const String platformHBO = 'HBO';
  static const String platformBBC = 'BBC';
  static const String platformNHK = 'NHK';
  static const String platformCBS = 'CBS';
  static const String platformNBC = 'NBC';
  static const String platformTvN = 'tvN';
  static const String platformNetflix = 'Netflix';

  // ── 年代 ──
  static const String year2020s = '2020年代';
  static const String year2025 = '2025';
  static const String year2024 = '2024';
  static const String year2023 = '2023';
  static const String year2022 = '2022';
  static const String year2021 = '2021';
  static const String year2020 = '2020';
  static const String year2019 = '2019';
  static const String year2010s = '2010年代';
  static const String year2000s = '2000年代';
  static const String year1990s = '90年代';
  static const String year1980s = '80年代';
  static const String year1970s = '70年代';
  static const String year1960s = '60年代';
  static const String yearEarlier = '更早';

  // ── 时间格式化 ──
  static const String timeJustNow = '刚刚';
  static const String timeMinutesAgo = '分钟前';
  static const String timeHoursAgo = '小时前';
  static const String timeDaysAgo = '天前';

  // ── 通用提示 ──
  static const String noContent = '暂无内容';
  static const String noContentTip = '去看看其他内容吧';
  static const String unknownError = '未知错误';
  static const String content = '内容';

  // ── 格式化方法 ──
  static String noContentWithName(String name) => '暂无$name';
  static String noContentTipWithName(String name) => '去看看其他$name吧';
  static String totalCountWithName(int count, String name) => '共 $count $name';

  // ── HTTP headers ──
  static const String contentTypeJsonUtf8 = 'application/json; charset=utf-8';

  // ── 截图相关（PC 和移动端共用） ──
  static const String screenshotFailed = '截图失败';
  static const String screenshotSaved = '截图已保存';
  static const String screenshotSaveFailed = '保存截图失败：文件未创建';
  static const String saveFailed = '保存失败';
  static const String imageSaveSuccess = '图片已保存';
  static const String imageLoadFailed = '图片加载失败';
  static const String imageDataError = '无法获取图片数据';
  static const String saveToGallery = '保存到相册';
  static const String saveToGalleryFailed = '保存到相册失败';
  static const String saveToFolderFailed = '保存到文件夹失败';
  static const String galleryPermissionRequired = '需要相册权限才能保存截图';
  static const String storagePermissionRequired = '需要存储权限';
  static const String announcementDefaultTitle = '系统公告';

  // ── 播放器补充 ──
  static const String playerGetDetailFailed = '获取短剧详情失败';
  static const String playerRelatedRecommend = '相关推荐';
  static const String playerHint = '提示';
  static const String playerCloseDlnaFirst = '请先关闭投屏后再切换视频';
  static const String playerReverseOrder = '倒序';
  static const String playerForwardOrder = '正序';
  static const String playerExpand = '展开';
  static const String playerErrorTitle = '哎呀, 出现了一些问题';
  static const String playerErrorMsg = '请检查网络连接或尝试刷新页面';
  static const String playerBack = '返回上页';
  static const String playerRetry = '重新尝试';
  static const String playerAddedToQueue = '已添加到下载队列';

  // ── DLNA 补充 ──
  static const String dlnaTitle = '投屏';
  static const String dlnaScanning = '正在投屏到';
  static const String dlnaRescan = '重新扫描';
  static const String dlnaFailed = '投屏失败';
  static const String dlnaChangeDevice = '换设备';
  static const String dlnaPause = '暂停';
  static const String dlnaPlay = '播放';
  static const String dlnaPreparingScan = '准备扫描设备...';
  static const String dlnaScanningDevices = '正在扫描DLNA设备...';
  static const String dlnaSearchingDevices = '正在搜索设备...';
  static const String dlnaNoDeviceFound = '未发现DLNA设备';
  static const String dlnaCurrentDevice = '当前设备';
  static const String dlnaEnsureSameNetwork = '请确保设备与手机在同一网络下';
  static const String dlnaDeviceCountTemplate = '发现 %d 个设备';
  static const String dlnaSelectDevice = '选择投屏设备';
  static const String dlnaScanFailed = '扫描失败';
  static const String dlnaActiveTime = '活跃时间';
  static const String dlnaVideo = '视频';
  static const String dlnaEpisodeSeparator = ' - ';

  // ── 通用错误提示 ──
  static const String clearFailed = '清空失败';
  static const String couldNotLaunch = '无法打开';
  static String couldNotLaunchUrl(String url) => '无法打开 $url';

  // ── 加载状态 ──
  static const String loadingEmojiSearch = '🔍';
  static const String loadingEmojiMagic = '✨';
  static const String loadingEmojiError = '😵';

  // ── 播放器 ──
  static const String playerDetail = '详情';
  static const String playerUnknown = 'unknown';

  // ── 保存场景 ──
  static const String sceneBackButton = '返回按钮';
  static const String sceneTimedSave = '定时保存';
  static const String sceneAppBackground = '应用进入后台';
  static const String scenePause = '暂停';
  static const String sceneDlnaPause = 'DLNA暂停';
  static const String sceneNextEpisodeButton = '下一集按钮';
  static const String sceneAutoNextEpisode = '自动播放下一集';
  static const String sceneEpisodeListClick = '选集列表点击';
  static const String sceneEpisodePanelClick = '选集面板点击';

  // ── 通知相关 ──
  static const String notifUpdateFileNotExist = '更新文件不存在，请重新下载';
  static const String notifWaitDownload = '等待下载完成后安装';
  static const String notifVersionUnavailable = '版本信息不可用，请稍后重试';
  static const String notifUpdateError = '处理更新时发生错误';
  static const String notifDownloadComplete = '下载完成';
  static const String notifUpdating = '正在更新到';
  static const String notifClickToInstall = '点击安装更新';
  static const String notifDownloadFailed = '下载失败';
  static const String notifDownloadChannel = '下载通知';
  static const String notifDownloadChannelDesc = '视频下载进度通知';
  static const String notifUpdateChannel = '更新通知';
  static const String notifUpdateChannelDesc = '应用更新下载进度通知';

  // ── 搜索补充 ──
  static const String searchSource = '来源';
  static const String searchTitle = '标题';
  static const String searchYear = '年份';

  // ── 收藏/播放记录 ──
  static const String clearPlayRecords = '清空播放记录';
  static const String clearPlayRecordsConfirm = '确定要清空所有播放记录吗？此操作无法撤销。';
  static const String loadPlayRecordsFailed = '加载播放记录失败';

  // ── 视频信息 ──
  static const String episodesCount = '%d集';

  // ── 邮箱域名允许列表 ──
  static const List<String> allowedEmailDomains = [
    'gmail.com',
    'qq.com',
    '163.com',
    '126.com',
    'outlook.com',
    'hotmail.com',
    'foxmail.com',
    'sina.com',
    'sohu.com',
    'yahoo.com',
    'aliyun.com',
    'icloud.com',
    'live.com',
    'msn.com',
    '139.com',
    'yeah.net',
  ];

  // ── 刷新文本 ──
  static const String refreshMovie = '刷新电影数据...';
  static const String refreshTv = '刷新电视剧数据...';
  static const String refreshAnime = '刷新动漫数据...';
  static const String refreshShow = '刷新综艺数据...';
  static const String refreshShortDrama = '刷新短剧数据...';

  // ── 计数格式 ──
  static const String countMovie = '共 %d 部电影';
  static const String countTv = '共 %d 部电视剧';
  static const String countAnime = '共 %d 部%s';
  static const String countShow = '共 %d 个综艺';
  static const String countShortDrama = '共 %d 部短剧';

  // ── 播放器面板补充 ──
  static const String downloadCount = '下载 (%d)';
  static const String episodeCount = '选集 (%d)';

  // ── 下载补充 ──
  static const String downloadAddedToQueue = '已添加 %d 个任务到下载队列';
  static const String downloadSegmentFailed = '下载失败：部分片段下载出错';

  // ── 打开详情 ──
  static const String openingDoubanDetail = '正在打开豆瓣详情: ';
  static const String openingBangumiDetail = '正在打开 Bangumi 详情: ';

  // ── 收藏/记录 ──
  static const String getFavoritesFailed = '获取收藏夹失败';
  static const String getPlayRecordsFailed = '获取播放记录失败';
  static const String clearPlayRecordsDone = '播放记录已清空';

  // ── HTTP Header 值 ──
  static const String authorizationBearer = 'Bearer ';

  // ── 分类计数格式 ──
  static const String countAnimeSeries = '个番剧';
  static const String countAnimeMovie = '部动画电影';
  static const String countAllAnime = '部番剧';

  // ── 搜索/筛选 ──
  static const String sortDefault = 'T';
  static const String sortAll = 'all';
  static const String categoryHot = '热门';
  static const String categoryLatest = '最新';
  static const String filterFormat = '形式';

  // ── 短剧类型 ──
  static const String shortDramaFemaleLove = '女频恋爱';
  static const String shortDramaReverseCool = '反转爽剧';
  static const String shortDramaCostumeXianxia = '古装仙侠';
  static const String shortDramaEraTravel = '年代穿越';
  static const String shortDramaBrainSuspense = '脑洞悬疑';
  static const String shortDramaModernCity = '现代都市';
  static const String shortDramaEdge = '擦边短剧';

  // ── AI 设置 ──
  static const String aiCustom = '自定义';
  static const String aiCustomModel = '自定义模型';

  // ── 通用提示 ──
  static const String pullToRefresh = '下拉刷新';
  static const String noFavoritesContent = '您收藏的视频将显示在这里';
  static const String noHistoryContent = '您观看过的视频将显示在这里';
  static const String comingSoonMore = '敬请期待更多精彩内容';
  static const String unknownYear = '未知年份';

  // ── 网盘搜索 ──
  static const String netdiskUnavailable = '未启用';
  static const String netdiskCopyLinkLabel = '链接';
  static const String netdiskCopyPasswordLabel = '密码';

  // ── DLNA 设备类型关键词 ──
  static const String dlnaDeviceTv = 'tv';
  static const String dlnaDeviceTelevision = '电视';
  static const String dlnaDeviceBox = 'box';
  static const String dlnaDevicePlayer = '播放器';

  // ── 服务错误 ──
  static const String doubanDetailParseEmpty = '豆瓣详情数据解析为空';
  static const String releaseCalendarFetchFailed = '获取即将上映数据失败';
  static const String releaseCalendarException = '获取即将上映数据异常: ';
  static const String cacheItemMissingFields = '缓存项缺少必需字段: ';
  static const String cacheTimestampTypeError = 'timestamp 字段类型错误: ';
  static const String cacheExpirationTypeError = 'expiration 字段类型错误: ';
  static const String m3u8Timeout = '超时';
  static const String m3u8FetchStreamTimeout = '获取流信息超时';

  // ── 确认对话框 ──
  static const String confirmClearChatHistory = '确定要清空所有聊天记录吗？此操作不可恢复。';
  static const String chatHistoryCleared = '聊天记录已清空';

  // ── 下载设置 ──
  static const String downloadHasActiveTasks = '有正在下载的任务，无法修改保存路径';

  // ── 下载管理 ──
  static const String downloadConfirmDeleteAll = '确定要删除所有已完成的下载任务吗？';
  static const String downloadConfirmDeleteGroup = '确定要删除"%s"的%d个任务吗？';

  // ── DLNA ──
  static const String dlnaVideoLoading = '视频加载中...';

  // ── 图片查看器 ──
  static const String imageSaving = '正在保存图片...';

  // ── AI 设置 ──
  static const String aiAvailableBalance = '可用余额: %s';
  static const String aiBalanceInfo = '余额信息: %s';

  // ── 登录提示 ──
  static const String authAccountLockedMinutes = '账户已被锁定，请%d分钟后再试';
  static const String authRemainingAttempts = '还有%d次尝试机会';

  // ── 电影角色/职位名称 ──
  static const String roleDirector = '导演';
  static const String roleSupervisor = '监督';
  static const String roleOriginal = '原作';
  static const String roleScript = '脚本';
  static const String roleStoryboard = '分镜';
  static const String rolePerformance = '演出';
  static const String roleSeriesComposition = '系列构成';
  static const String roleScreenplay = '剧本';
  static const String roleStoryboardComposition = '分镜构图';
  static const String roleStoryboardPerformance = '分镜・演出';

  // ── 文件路径 ──
  static const String directoryPictures = 'Pictures';
  static const String directoryScreenshots = 'Screenshots';

  // ── 截图相关 ──
  static const String screenshotFormatPng = 'image/png';
  static const String screenshotFileNameTemplate = 'screenshot_';

  // ── 播放速度 ──
  static const String playbackSpeed2x = '2x';

  // ── 筛选器值 ──
  static const String filterValueHot = '热门';
  static const String filterValueLatest = '最新';
  static const String filterValueDoubanHighRating = '豆瓣高分';
  static const String filterValueUnpopularGood = '冷门佳片';
  static const String filterValueRecentHot = '最近热门';
  static const String filterValueChinese = '华语';
  static const String filterValueWestern = '欧美';
  static const String filterValueKorean = '韩国';
  static const String filterValueJapanese = '日本';

  // ── 网盘搜索统计 ──
  static const String netdiskStatsResources = ' 个网盘资源，覆盖 ';
  static const String netdiskStatsTypes = ' 种网盘类型';

  // ── 集数格式 ──
  static const String episodeSuffix = '集';
  static const String daysSuffix = '天';
  static const String unknownSearchEventType = '的搜索事件类型';

  // ── 链接数量 ──
  static const String linkCountSuffix = '个链接';

  // ── Bangumi 详情 ──
  static const String bangumiDetail = 'Bangumi 详情';

  // ── 源数量 ──
  static const String sourceCountSeparator = '等';
  static const String sourceCountSuffix = '源';

  // ── 豆瓣服务错误消息 ──
  static const String doubanParseFailed = '豆瓣数据解析失败';
  static const String doubanFetchFailed = '获取豆瓣数据失败';
  static const String doubanRequestException = '豆瓣数据请求异常';
  static const String doubanRecommendParseFailed = '豆瓣推荐数据解析失败';
  static const String doubanRecommendFetchFailed = '获取豆瓣推荐数据失败';
  static const String doubanRecommendRequestException = '豆瓣推荐数据请求异常';
  static const String doubanDetailParseFailed = '豆瓣详情数据解析失败';
  static const String doubanDetailFetchFailed = '获取豆瓣详情数据失败';
  static const String doubanDetailRequestException = '豆瓣详情数据请求异常';

  // ── 通用字符串 ──
  static const String aiLabel = 'AI';
  static const String icon = 'icon';
  static const String label = 'label';

  // ── 错误消息 ──
  static const String errorContextNotMounted = 'Context not mounted';

  // ── 分隔符 ──
  static const String separatorPipe = ' | ';
  static const String separatorSlash = ' / ';

  // ── 播放速度标签 ──
  static const String playbackSpeedLabelSlowest = '0.5x';
  static const String playbackSpeedLabelFastest = '2.0x';

  // ── 资源路径 ──
  static const String assetDanmuIcon = 'assets/images/danmu.svg';

}
