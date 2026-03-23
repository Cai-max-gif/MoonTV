# MoonTV

## 项目概述

MoonTV是一款基于Flutter开发的跨平台视频播放应用，支持Android和Windows平台。该应用提供了丰富的视频内容浏览、搜索和播放功能，为用户提供流畅的观影体验。

## 功能特性

- **多平台支持**：支持Android和Windows平台
- **视频内容浏览**：分类浏览电影、电视剧、动漫等多种视频内容
- **搜索功能**：支持关键词搜索和智能推荐
- **视频播放**：支持多种视频格式和播放源
- **收藏管理**：支持收藏喜欢的视频内容
- **历史记录**：自动记录观看历史
- **多语言支持**：支持中文界面
- **响应式设计**：适配不同屏幕尺寸

## 技术栈

- **前端框架**：Flutter 3.x
- **后端服务**：RESTful API
- **状态管理**：Provider/Bloc
- **视频播放**：media_kit
- **存储**：本地存储 + 网络缓存

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

## 开发环境搭建

### 前置要求

- **Flutter SDK**：3.0.0或更高版本
- **Dart SDK**：2.17.0或更高版本
- **Android Studio**：用于Android开发
- **Visual Studio**：用于Windows开发（需要安装C++开发工具）
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

## 配置方法

### 网络配置

- 应用默认使用内置的API服务
- 如需自定义API地址，请在设置页面修改

### 缓存设置

- 默认缓存大小为1GB
- 可在设置页面调整缓存大小或清除缓存

### 播放器设置

- 可在设置页面调整播放器默认清晰度
- 支持硬件加速和字幕设置

## 贡献指南

我们欢迎社区贡献！如果您想为MoonTV做出贡献，请按照以下步骤：

1. **Fork项目**：在GitHub上fork本项目
2. **创建分支**：创建一个新的分支用于您的功能或修复
3. **提交更改**：提交您的代码更改
4. **创建PR**：向主分支创建Pull Request
5. **代码审查**：等待维护者的代码审查

### 代码规范

- 遵循Flutter官方代码风格
- 保持代码简洁明了
- 添加适当的注释
- 编写单元测试

## 许可证

本项目采用MIT许可证。详情请参阅[LICENSE](LICENSE)文件。

## 联系方式

- **项目地址**：[https://github.com/Cai-max-gif/MoonTV](https://github.com/Cai-max-gif/MoonTV)
- **问题反馈**：[GitHub Issues](https://github.com/Cai-max-gif/MoonTV/issues)
- **邮箱**：[moontv.cc.cd@foxmail.com](mailto:moontv.cc.cd@foxmail.com)

## 更新日志

### v1.0.0
- 初始版本
- 支持Android和Windows平台
- 实现基本的视频浏览和播放功能
- 添加搜索和收藏功能

---

**感谢使用MoonTV！** 我们将持续改进和更新，为您提供更好的观影体验。