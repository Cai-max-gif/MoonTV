# MoonTV

## 项目概述

MoonTV是一款基于Flutter开发的跨平台视频播放应用，支持Android、iOS、Windows和macOS平台。该应用提供了丰富的视频内容浏览、搜索和播放功能，为用户提供流畅的观影体验。

## 技术栈

### 框架与语言
- **Flutter**: 3.4.3+
- **Dart**: 3.0+

### 主要依赖库

| 库名称 | 版本 | 用途 |
| :--- | :--- | :--- |
| `cupertino_icons` | ^1.0.6 | iOS风格图标 |
| `google_fonts` | ^8.0.2 | Google字体集成 |
| `flutter_svg` | ^2.0.10+1 | SVG图片渲染 |
| `http` | ^1.2.1 | HTTP请求 |
| `dio` | ^5.4.0 | 高性能HTTP客户端 |
| `shared_preferences` | ^2.2.3 | 本地数据存储 |
| `flutter_secure_storage` | ^9.0.0 | 安全数据存储 |
| `provider` | ^6.1.2 | 状态管理 |
| `web_socket_channel` | ^3.0.3 | WebSocket通信 |
| `cached_network_image` | ^3.3.1 | 网络图片缓存 |
| `media_kit` | ^1.2.6 | 跨平台媒体播放 |
| `flutter_local_notifications` | ^18.0.1 | 本地通知 |
| `permission_handler` | ^11.3.1 | 权限管理 |
| `dlna_dart` | ^0.1.0 | DLNA投屏支持 |
| `bitsdojo_window` | ^0.1.6 | Windows窗口控制 |
| `macos_window_utils` | ^1.5.1 | macOS窗口工具 |

## 项目结构

```
MoonTV/
├── android/              # Android平台配置
│   ├── app/              # Android应用代码
│   └── gradle/           # Gradle构建配置
├── ios/                  # iOS平台配置
│   └── Runner/           # iOS应用代码
├── macos/                # macOS平台配置
│   └── Runner/           # macOS应用代码
├── windows/              # Windows平台配置
│   └── runner/           # Windows应用代码
├── lib/                  # Flutter核心代码
│   ├── models/           # 数据模型
│   ├── screens/          # 页面组件
│   ├── services/         # 服务层
│   ├── utils/            # 工具类
│   ├── widgets/          # 自定义组件
│   └── main.dart         # 应用入口
├── assets/               # 静态资源
│   └── images/           # 图片资源
└── pubspec.yaml          # 依赖配置
```

### 目录说明

| 目录 | 说明 |
| :--- | :--- |
| `lib/models/` | 数据模型定义，包含视频、收藏、下载任务等 |
| `lib/screens/` | 页面组件，如首页、搜索页、播放页等 |
| `lib/services/` | 服务层，处理API请求、数据缓存、通知等 |
| `lib/utils/` | 工具类，提供通用工具函数 |
| `lib/widgets/` | 可复用的自定义组件 |
| `assets/images/` | 应用图标和图片资源 |

## 功能特性

### 已完成功能

- **多平台支持**：支持Android、iOS、Windows、macOS平台
- **视频内容浏览**：分类浏览电影、电视剧、动漫等多种视频内容
- **搜索功能**：支持关键词搜索和智能推荐
- **视频播放**：支持多种视频格式和播放源
- **收藏管理**：支持收藏喜欢的视频内容
- **历史记录**：自动记录观看历史
- **多语言支持**：支持中文界面
- **响应式设计**：适配不同屏幕尺寸
- **自动跳过片头片尾**：支持自动跳过视频片头和片尾，提升观影体验
- **自动播放下一集**：视频播放完成后自动播放下一集，无需手动操作
- **下载功能**：支持视频内容下载到本地
- **下载本地通知**：支持 Android、iOS、macOS 平台的下载进度、完成和失败通知
- **弹幕功能**：支持视频播放时显示弹幕
- **家庭模式**：支持过滤成人内容，提供更适合全家观看的内容环境
- **AI功能**：支持联网搜索影视并进行智能推荐，帮助用户发现更多优质内容
- **同步功能**：支持多设备数据同步，包括收藏、观看历史等
- **网盘集成**：支持从网盘获取视频
- **Telegram集成**：支持通过Telegram认证和接收通知

## 安装指南

### Android平台

1. **直接安装APK**：
   - 从[发布页面](https://github.com/Cai-max-gif/MoonTV/releases)下载对应架构的APK文件
   - 允许安装来自未知来源的应用
   - 点击APK文件进行安装
2. **架构选择**：
   - `MoonTV-universal.apk`：通用版本，支持所有架构
   - `MoonTV-v7.apk`：适用于32位ARM设备
   - `MoonTV-v8.apk`：适用于64位ARM设备
   - `MoonTV-x86_64.apk`：适用于x86_64架构设备

### Windows平台

1. **使用安装程序**：
   - 从[发布页面](https://github.com/Cai-max-gif/MoonTV/releases)下载`MoonTV-Setup.exe`
   - 双击运行安装程序
   - 按照安装向导完成安装
2. **使用便携版本**：
   - 从[发布页面](https://github.com/Cai-max-gif/MoonTV/releases)下载便携版压缩包
   - 解压到任意目录
   - 运行`MoonTV.exe`启动应用

### macOS平台

1. 从[发布页面](https://github.com/Cai-max-gif/MoonTV/releases)下载`.dmg`文件
2. 双击打开磁盘映像
3. 将MoonTV拖到Applications文件夹

### iOS平台

1. 使用Xcode打开`ios/Runner.xcworkspace`
2. 配置开发者账号
3. 连接设备或选择模拟器
4. 点击Run按钮安装

## 开发环境搭建

### 前置要求

- **Flutter SDK**：3.4.3或更高版本
- **Dart SDK**：3.0.0或更高版本
- **Android Studio**：用于Android开发
- **Visual Studio**：用于Windows开发（需要安装C++开发工具）
- **Xcode**：用于iOS和macOS开发（仅Mac）
- **Git**：版本控制

### 安装步骤

1. **克隆项目**：
   ```bash
   git clone https://github.com/Cai-max-gif/MoonTV.git
   cd MoonTV
   ```
2. **安装依赖**：
   ```bash
   flutter pub get
   ```
3. **构建项目**：
   - Android：
     ```bash
     flutter build apk --split-per-abi
     ```
   - Windows：
     ```bash
     flutter build windows
     ```
   - macOS：
     ```bash
     flutter build macos
     ```
   - iOS：
     ```bash
     flutter build ios
     ```

## 配置方法

### 网络配置

- 应用默认使用内置的API服务
- 如需自定义API地址，可在设置页面进行配置

### 缓存设置

- 默认缓存大小为1GB
- 可在设置页面调整缓存大小或清除缓存

### 播放器设置

- 可在设置页面调整播放器默认清晰度
- 支持硬件加速和字幕设置

## 使用说明

### 首次启动

1. 打开应用后，系统会自动加载首页内容
2. 您可以通过底部导航栏切换不同的内容分类
3. 点击视频卡片进入详情页
4. 在详情页选择播放源开始观看

### 搜索功能

1. 点击顶部搜索图标
2. 输入关键词进行搜索
3. 从搜索结果中选择感兴趣的内容

### 收藏管理

1. 在视频详情页点击收藏按钮
2. 在个人中心查看已收藏的内容

### 播放控制

- **播放/暂停**：点击视频区域
- **音量调节**：使用音量键或屏幕右侧上下滑动
- **进度调节**：点击进度条或屏幕左侧上下滑动
- **全屏切换**：点击全屏按钮或双击视频区域


## 常见问题（FAQ）

### Q1: 应用无法启动怎么办？

**A**：请检查以下几点：
- 确保设备满足最低系统版本要求
- 尝试清除应用缓存后重新启动
- 确保应用已获得必要的权限（存储、网络等）

### Q2: 视频无法播放怎么办？

**A**：可能的原因和解决方案：
- **网络问题**：检查网络连接，尝试切换网络
- **播放源问题**：尝试切换其他播放源
- **格式不支持**：某些格式可能需要特定的解码器支持

### Q3: 如何解决下载失败的问题？

**A**：请检查：
- 网络连接是否稳定
- 存储空间是否充足
- 是否获得了存储权限

### Q4: 弹幕功能不显示怎么办？

**A**：请检查：
- 是否在播放设置中开启了弹幕功能
- 当前视频是否支持弹幕
- 网络连接是否正常

### Q5: 如何同步数据到其他设备？

**A**：
1. 在设置页面登录您的账号
2. 在其他设备上使用相同账号登录
3. 数据会自动同步

### Q6: 家庭模式如何启用？

**A**：
1. 进入设置页面
2. 找到"家庭模式"选项
3. 开启家庭模式开关
4. 应用将自动过滤成人内容

## 贡献指南

我们欢迎社区贡献！如果您想为MoonTV做出贡献，请按照以下步骤：

### 贡献流程

1. **Fork项目**：在GitHub上fork本项目
2. **创建分支**：创建一个新的分支用于您的功能或修复
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **提交更改**：提交您的代码更改
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```
4. **推送分支**：将分支推送到您的fork
   ```bash
   git push origin feature/your-feature-name
   ```
5. **创建PR**：向主分支创建Pull Request
6. **代码审查**：等待维护者的代码审查

### 代码规范

- 遵循Flutter官方代码风格
- 保持代码简洁明了
- 添加适当的注释
- 使用`dartfmt`格式化代码

### 提交规范

请使用以下提交类型前缀：

| 前缀 | 说明 |
| :--- | :--- |
| `feat` | 新增功能 |
| `fix` | 修复bug |
| `docs` | 文档更新 |
| `style` | 代码格式调整 |
| `refactor` | 代码重构 |
| `test` | 测试相关 |
| `chore` | 构建/工具更新 |

### PR模板

提交PR时请包含以下信息：

1. **描述**：简要说明您的更改
2. **动机**：为什么需要这个更改
3. **测试**：如何验证您的更改
4. **截图**：如果涉及UI更改，请提供截图

## 许可证

本项目采用MIT许可证。详情请参阅[LICENSE](LICENSE)文件。

## 联系方式

- **项目地址**：<https://github.com/Cai-max-gif/MoonTV>
- **问题反馈**：[GitHub Issues](https://github.com/Cai-max-gif/MoonTV/issues)
- **邮箱**：<moontv.cc.cd@foxmail.com>

***

**感谢使用MoonTV！** 我们将持续改进和更新，为您提供更好的观影体验。