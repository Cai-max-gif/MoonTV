# Flutter 网盘功能实现文档

## 概述

本文档详细说明如何在 Flutter 项目中实现与 MoonTV 一致的网盘资源搜索功能。该功能基于 MoonTV 后端 API，通过代理转发请求到 PanSou 网盘搜索引擎，获取并展示各网盘平台的资源链接和提取码。

### 功能特性

- 支持 12 种网盘类型的资源搜索与展示（百度/阿里/夸克/天翼/UC/移动/115/PikPak/迅雷/123/磁力/电驴）
- 按网盘类型分组展示搜索结果
- 密码显示/隐藏切换
- 一键复制链接和提取码
- 外部浏览器打开网盘链接
- 筛选模式：全部显示/仅显示选中
- 长标题展开/收起
- 30 分钟后端缓存，减少重复请求

---

## 整体架构

```
Flutter App                      MoonTV 后端 API                   PanSou 引擎
┌──────────────────┐  HTTP GET   ┌──────────────────────┐  POST   ┌──────────────┐
│ NetdiskService   │────────────→│ /api/netdisk/search   │────────→│ PanSou API   │
│ 网盘搜索服务      │  Cookie认证  │ q=搜索关键词           │         │ 网盘搜索引擎   │
│                  │←────────────│                       │←───────│              │
│ NetdiskPage      │    JSON     │ merged_by_type 分组    │         └──────────────┘
│ 搜索结果页面      │             └──────────────────────┘
└──────────────────┘
```

---

## API 规范

### 网盘搜索 API

| 项目 | 说明 |
|------|------|
| 端点 | `GET /api/netdisk/search` |
| 认证 | 需要 Cookie 认证（`user_auth`） |
| 超时 | 默认 30 秒 |

#### 请求参数

| 参数名 | 类型 | 必填 | 描述 |
|-------|------|------|------|
| q | string | 是 | 搜索关键词 |

#### 请求示例

```javascript
GET /api/netdisk/search?q=流浪地球
Cookie: user_auth=xxx
```

#### 响应格式（成功）

```json
{
  "success": true,
  "data": {
    "total": 42,
    "merged_by_type": {
      "baidu": [
        {
          "url": "https://pan.baidu.com/s/xxxx",
          "password": "abcd",
          "note": "流浪地球.2160p.mkv",
          "datetime": "2024-01-01T00:00:00Z",
          "source": "pansou",
          "images": []
        }
      ],
      "quark": [
        {
          "url": "https://pan.quark.cn/s/xxxx",
          "password": "1234",
          "note": "流浪地球 4K高码",
          "datetime": "2024-01-02T00:00:00Z",
          "source": "pansou",
          "images": []
        }
      ],
      "aliyun": []
    },
    "source": "pansou",
    "query": "流浪地球",
    "timestamp": "2024-01-01T00:00:00.000Z"
  }
}
```

#### 响应格式（失败）

```json
{
  "success": false,
  "error": "网盘搜索功能未启用"
}
```

---

## Flutter 实现步骤

### 一、添加依赖

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  http: ^1.2.0           # HTTP 请求
  url_launcher: ^6.2.0   # 打开外部链接
  flutter: 
    sdk: flutter
```

### 二、项目文件结构

```
lib/
├── models/
│   ├── netdisk_item.dart       # 数据模型
│   └── cloud_type.dart         # 网盘类型配置
├── services/
│   └── netdisk_service.dart    # API 服务
└── pages/
    └── netdisk_search_page.dart # 搜索结果页面
```

---

### 三、数据模型定义

#### 1. 网盘链接模型 (`lib/models/netdisk_item.dart`)

```dart
/// 单个网盘资源链接
class NetDiskLink {
  final String url;       // 网盘链接地址
  final String password;  // 提取码
  final String note;      // 文件名/备注
  final String datetime;  // 收录时间
  final String source;    // 来源
  final List<String> images; // 预览图

  NetDiskLink({
    required this.url,
    required this.password,
    required this.note,
    required this.datetime,
    required this.source,
    this.images = const [],
  });

  /// 从 JSON 构造
  factory NetDiskLink.fromJson(Map<String, dynamic> json) {
    return NetDiskLink(
      url: json['url'] as String? ?? '',
      password: json['password'] as String? ?? '',
      note: json['note'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
      source: json['source'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// 显示的标题（优先使用 note，为空时显示占位）
  String get displayTitle => note.isNotEmpty ? note : '未命名资源';

  /// 是否有提取码
  bool get hasPassword => password.isNotEmpty;
}

/// 网盘搜索结果
class NetDiskSearchResult {
  final bool success;       // 是否成功
  final String? error;      // 错误信息
  final int total;          // 总资源数
  final Map<String, List<NetDiskLink>> mergedByType; // 按类型分组的链接
  final String source;      // 数据来源
  final String query;       // 搜索关键词
  final String? timestamp;  // 时间戳

  NetDiskSearchResult({
    required this.success,
    this.error,
    this.total = 0,
    this.mergedByType = const {},
    this.source = '',
    this.query = '',
    this.timestamp,
  });

  /// 从 JSON 构造
  factory NetDiskSearchResult.fromJson(Map<String, dynamic> json) {
    // 失败响应
    if (json['success'] != true) {
      return NetDiskSearchResult(
        success: false,
        error: json['error'] as String? ?? '未知错误',
      );
    }

    // 成功响应
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawMerged = data['merged_by_type'] as Map<String, dynamic>? ?? {};

    final mergedByType = <String, List<NetDiskLink>>{};
    rawMerged.forEach((key, value) {
      if (value is List) {
        mergedByType[key] = value
            .map((e) => NetDiskLink.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });

    return NetDiskSearchResult(
      success: true,
      total: data['total'] as int? ?? 0,
      mergedByType: mergedByType,
      source: data['source'] as String? ?? '',
      query: data['query'] as String? ?? '',
      timestamp: data['timestamp'] as String?,
    );
  }
}
```

#### 2. 网盘类型配置 (`lib/models/cloud_type.dart`)

```dart
import 'package:flutter/material.dart';

/// 网盘平台类型配置
class CloudType {
  final String key;        // 类型标识
  final String name;       // 中文名称
  final Color color;       // 主题颜色（用于头部背景）
  final Color lightColor;  // 浅色（用于标签未选中状态）
  final String icon;       // 图标（使用 Emoji）
  final String domain;     // 网盘域名

  const CloudType({
    required this.key,
    required this.name,
    required this.color,
    required this.lightColor,
    required this.icon,
    required this.domain,
  });

  /// 所有支持的网盘类型
  static const Map<String, CloudType> types = {
    'baidu': CloudType(
      key: 'baidu', name: '百度网盘',
      color: Color(0xFF3B82F6), lightColor: Color(0x1A3B82F6),
      icon: '📁', domain: 'pan.baidu.com',
    ),
    'aliyun': CloudType(
      key: 'aliyun', name: '阿里云盘',
      color: Color(0xFFF97316), lightColor: Color(0x1AF97316),
      icon: '☁️', domain: 'alipan.com',
    ),
    'quark': CloudType(
      key: 'quark', name: '夸克网盘',
      color: Color(0xFFA855F7), lightColor: Color(0x1AA855F7),
      icon: '⚡', domain: 'pan.quark.cn',
    ),
    'tianyi': CloudType(
      key: 'tianyi', name: '天翼云盘',
      color: Color(0xFFEF4444), lightColor: Color(0x1AEF4444),
      icon: '📱', domain: 'cloud.189.cn',
    ),
    'uc': CloudType(
      key: 'uc', name: 'UC网盘',
      color: Color(0xFF22C55E), lightColor: Color(0x1A22C55E),
      icon: '🌐', domain: 'drive.uc.cn',
    ),
    'mobile': CloudType(
      key: 'mobile', name: '移动云盘',
      color: Color(0xFF06B6D4), lightColor: Color(0x1A06B6D4),
      icon: '📲', domain: 'caiyun.139.com',
    ),
    '115': CloudType(
      key: '115', name: '115网盘',
      color: Color(0xFF6B7280), lightColor: Color(0x1A6B7280),
      icon: '💾', domain: '115.com',
    ),
    'pikpak': CloudType(
      key: 'pikpak', name: 'PikPak',
      color: Color(0xFFEC4899), lightColor: Color(0x1AEC4899),
      icon: '📦', domain: 'mypikpak.com',
    ),
    'xunlei': CloudType(
      key: 'xunlei', name: '迅雷网盘',
      color: Color(0xFFEAB308), lightColor: Color(0x1AEAB308),
      icon: '⚡', domain: 'pan.xunlei.com',
    ),
    '123': CloudType(
      key: '123', name: '123网盘',
      color: Color(0xFF6366F1), lightColor: Color(0x1A6366F1),
      icon: '🔢', domain: '123pan.com',
    ),
    'magnet': CloudType(
      key: 'magnet', name: '磁力链接',
      color: Color(0xFF1F2937), lightColor: Color(0x1A1F2937),
      icon: '🧲', domain: 'magnet:',
    ),
    'ed2k': CloudType(
      key: 'ed2k', name: '电驴链接',
      color: Color(0xFF14B8A6), lightColor: Color(0x1A14B8A6),
      icon: '🐴', domain: 'ed2k://',
    ),
  };

  /// 根据 key 获取类型配置，未知类型返回默认值
  static CloudType get(String key) {
    return types[key] ?? const CloudType(
      key: 'others', name: '其他',
      color: Color(0xFF9CA3AF), lightColor: Color(0x1A9CA3AF),
      icon: '📄', domain: '',
    );
  }
}
```

---

### 四、API 服务 (`lib/services/netdisk_service.dart`)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/netdisk_item.dart';

/// 网盘搜索服务
///
/// 使用示例：
/// ```dart
/// final service = NetdiskService(
///   baseUrl: 'https://你的MoonTV后端地址',
///   cookie: '你的user_auth值',
/// );
/// final result = await service.search('流浪地球');
/// ```
class NetdiskService {
  final String baseUrl;
  final String cookie;
  final Duration timeout;

  NetdiskService({
    required this.baseUrl,
    required this.cookie,
    this.timeout = const Duration(seconds: 30),
  });

  /// 搜索网盘资源
  ///
  /// [query] 搜索关键词
  ///
  /// 返回 [NetDiskSearchResult]，通过 `success` 判断是否成功
  Future<NetDiskSearchResult> search(String query) async {
    final uri = Uri.parse('$baseUrl/api/netdisk/search').replace(
      queryParameters: {'q': query},
    );

    final response = await http.get(
      uri,
      headers: {
        'Cookie': 'user_auth=$cookie',
        'User-Agent': 'MoonTV-Flutter/1.0',
      },
    ).timeout(timeout);

    // 认证失败
    if (response.statusCode == 401) {
      return NetDiskSearchResult(
        success: false,
        error: '未登录或认证已过期，请重新登录',
      );
    }

    // 响应格式异常
    if (!response.body.trim().startsWith('{')) {
      return NetDiskSearchResult(
        success: false,
        error: '服务器返回格式异常：${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return NetDiskSearchResult.fromJson(json);
  }
}
```

---

### 五、搜索结果页面 (`lib/pages/netdisk_search_page.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/netdisk_item.dart';
import '../models/cloud_type.dart';
import '../services/netdisk_service.dart';

/// 网盘搜索页面
///
/// 使用示例：
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => NetdiskSearchPage(
///       service: netdiskService,
///       initialQuery: '视频标题',
///     ),
///   ),
/// );
/// ```
class NetdiskSearchPage extends StatefulWidget {
  final NetdiskService service;
  final String initialQuery;

  const NetdiskSearchPage({
    super.key,
    required this.service,
    this.initialQuery = '',
  });

  @override
  State<NetdiskSearchPage> createState() => _NetdiskSearchPageState();
}

class _NetdiskSearchPageState extends State<NetdiskSearchPage> {
  final _searchController = TextEditingController();
  NetDiskSearchResult? _result;
  bool _loading = false;
  String? _error;

  // 密码可见状态映射: "${typeKey}-${index}" -> 是否可见
  final _visiblePasswords = <String, bool>{};
  // 标题展开状态映射
  final _expandedTitles = <String, bool>{};

  // 筛选模式: false=全部显示, true=仅显示选中
  bool _filterMode = false;
  final _selectedTypes = <String>[];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      // 可选：进入页面自动搜索
      // _doSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== 数据逻辑 ====================

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _visiblePasswords.clear();
      _expandedTitles.clear();
    });

    try {
      final result = await widget.service.search(query.trim());
      setState(() {
        _result = result;
        _loading = false;
        if (!result.success) {
          _error = result.error;
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '搜索失败: $e';
      });
    }
  }

  /// 根据筛选状态返回当前要显示的结果
  Map<String, List<NetDiskLink>> get _filteredResults {
    if (_result == null) return {};
    if (!_filterMode || _selectedTypes.isEmpty) {
      return _result!.mergedByType;
    }
    return Map.fromEntries(
      _result!.mergedByType.entries
          .where((e) => _selectedTypes.contains(e.key)),
    );
  }

  /// 按链接数量降序排列的类型列表
  List<MapEntry<String, List<NetDiskLink>>> get _sortedTypes {
    return _filteredResults.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
  }

  // ==================== URL 启动 ====================

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开链接')),
      );
    }
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网盘资源搜索'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入关键词搜索网盘资源',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _result = null;
                            _error = null;
                          });
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onSubmitted: _doSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 加载状态
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在搜索网盘资源...'),
          ],
        ),
      );
    }

    // 错误状态
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error!.contains('未启用') ? Icons.info_outline : Icons.error_outline,
                size: 48,
                color: _error!.contains('未启用') ? Colors.blue : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error!.contains('未启用') ? Colors.blue : Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 初始状态
    if (_result == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('输入关键词开始搜索', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 无结果
    if (_result!.mergedByType.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('未找到相关资源'),
            SizedBox(height: 8),
            Text('尝试使用其他关键词搜索', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 搜索结果列表
    return Column(
      children: [
        _buildFilterBar(),
        _buildStatsBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: _sortedTypes.length,
            itemBuilder: (context, index) {
              final entry = _sortedTypes[index];
              return _buildCloudTypeSection(entry.key, entry.value);
            },
          ),
        ),
      ],
    );
  }

  // ==================== 筛选栏 ====================

  Widget _buildFilterBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _filterMode ? '仅显示选中' : '快速筛选',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              ChoiceChip(
                label: Text(_filterMode ? '仅显示选中' : '显示全部'),
                selected: _filterMode,
                onSelected: (v) {
                  setState(() {
                    _filterMode = v;
                    if (!v) _selectedTypes.clear();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _result!.mergedByType.entries.map((entry) {
              final type = CloudType.get(entry.key);
              final selected = _selectedTypes.contains(entry.key);

              return ActionChip(
                avatar: Text(type.icon, style: const TextStyle(fontSize: 14)),
                label: Text(
                  '${type.name} ${entry.value.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: (_filterMode && selected) ? Colors.white : null,
                  ),
                ),
                backgroundColor: (_filterMode && selected)
                    ? type.color
                    : type.lightColor,
                side: BorderSide(
                  color: (_filterMode && selected)
                      ? type.color
                      : Colors.grey.shade300,
                ),
                onPressed: () {
                  if (_filterMode) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.remove(entry.key);
                      } else {
                        _selectedTypes.add(entry.key);
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 结果统计栏 ====================

  Widget _buildStatsBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: '共找到 '),
            TextSpan(
              text: '${_result!.total}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' 个网盘资源，覆盖 '),
            TextSpan(
              text: '${_result!.mergedByType.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' 种网盘类型'),
          ],
        ),
        style: const TextStyle(color: Colors.blue),
      ),
    );
  }

  // ==================== 网盘类型分区 ====================

  Widget _buildCloudTypeSection(String typeKey, List<NetDiskLink> links) {
    final type = CloudType.get(typeKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型头部（带颜色背景）
          Container(
            width: double.infinity,
            color: type.color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  type.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${links.length} 个链接',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // 链接列表
          ...links.asMap().entries.map((entry) {
            return _buildLinkItem(typeKey, entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  // ==================== 单个链接项 ====================

  Widget _buildLinkItem(String typeKey, int index, NetDiskLink link) {
    final linkKey = '$typeKey-$index';
    final isPasswordVisible = _visiblePasswords[linkKey] ?? false;
    final isTitleExpanded = _expandedTitles[linkKey] ?? false;
    final title = link.displayTitle;
    final titleTooLong = title.length > 40;

    return InkWell(
      onTap: () => _launchUrl(link.url),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: isTitleExpanded ? null : 2,
                    overflow: isTitleExpanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            // 标题过长时显示展开/收起按钮
            if (titleTooLong)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedTitles[linkKey] = !isTitleExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isTitleExpanded ? '收起' : '展开',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 链接行
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                _buildCopyButton(link.url, '复制链接'),
              ],
            ),

            // 密码行（仅当有密码时显示）
            if (link.hasPassword) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.lock, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isPasswordVisible ? link.password : '****',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  _buildVisibilityButton(linkKey, isPasswordVisible),
                  _buildCopyButton(link.password, '复制密码'),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // 元信息行
            Row(
              children: [
                Expanded(
                  child: Text(
                    '来源: ${link.source}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('访问链接', style: TextStyle(fontSize: 12)),
                  onPressed: () => _launchUrl(link.url),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),

            // 分隔线（非最后一项）
            if (index < links.length - 1)
              const Divider(height: 16),
          ],
        ),
      ),
    );
  }

  // ==================== 工具按钮 ====================

  Widget _buildCopyButton(String text, String tooltip) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 18),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$tooltip成功'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildVisibilityButton(String linkKey, bool isVisible) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_off : Icons.visibility,
        size: 18,
      ),
      onPressed: () {
        setState(() {
          _visiblePasswords[linkKey] = !isVisible;
        });
      },
      tooltip: isVisible ? '隐藏密码' : '显示密码',
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}
```

---

### 六、集成到视频播放页面

在视频播放页面中添加入口按钮，点击后携带视频标题跳转到网盘搜索页面：

```dart
import 'package:flutter/material.dart';
import '../services/netdisk_service.dart';
import '../pages/netdisk_search_page.dart';

class VideoPlayerPage extends StatefulWidget {
  // ... 其他属性
  const VideoPlayerPage({super.key});
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final NetdiskService _netdiskService;

  // 当前视频信息
  String _videoTitle = '流浪地球'; // 实际应从视频信息中获取

  @override
  void initState() {
    super.initState();

    // 初始化网盘搜索服务
    _netdiskService = NetdiskService(
      baseUrl: 'https://你的MoonTV后端地址',
      cookie: '你的user_auth值', // 登录后从持久化存储中获取
    );
  }

  /// 打开网盘搜索页面
  void _openNetdiskSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NetdiskSearchPage(
          service: _netdiskService,
          initialQuery: _videoTitle, // 自动填入当前视频标题
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 视频播放器
          // ...

          // 控制栏（含网盘搜索按钮）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.cloud_search, color: Colors.white),
              tooltip: '搜索网盘资源',
              onPressed: _openNetdiskSearch,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 七、Cookie 认证管理

网盘搜索 API 需要 Cookie 认证，以下是 Cookie 管理的推荐实现：

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// 认证信息管理
class AuthManager {
  static const _keyUserAuth = 'user_auth_cookie';

  /// 保存认证 Cookie
  static Future<void> saveCookie(String cookieValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAuth, cookieValue);
  }

  /// 读取认证 Cookie
  static Future<String?> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserAuth);
  }

  /// 清除认证 Cookie（退出登录）
  static Future<void> clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserAuth);
  }

  /// 检查是否已登录
  static Future<bool> isLoggedIn() async {
    final cookie = await getCookie();
    return cookie != null && cookie.isNotEmpty;
  }
}
```

初始化网盘服务时读取 Cookie：

```dart
// App 启动时初始化
Future<void> initServices() async {
  final cookie = await AuthManager.getCookie();
  if (cookie == null) {
    // 未登录，跳转到登录页面
    return;
  }

  final netdiskService = NetdiskService(
    baseUrl: 'https://你的MoonTV后端地址',
    cookie: cookie,
  );
  // 传递给应用
}
```

---

### 八、Android / iOS 配置

#### Android 配置 (`android/app/src/main/AndroidManifest.xml`)

在 `<queries>` 标签中声明需要查询的 intent（用于 `url_launcher`）：

```xml
<queries>
  <!-- 允许打开浏览器 -->
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="http" />
  </intent>
  <!-- 磁力链接 -->
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="magnet" />
  </intent>
  <!-- 电驴链接 -->
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="ed2k" />
  </intent>
</queries>
```

#### iOS 配置 (`ios/Runner/Info.plist`)

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
  <string>magnet</string>
</array>
```

---

### 九、数据流总结

```
1. 用户打开视频播放页 → 点击网盘搜索按钮
2. NetdiskSearchPage 初始化，自动填入视频标题作为初始搜索词
3. 用户可以修改关键词后点击搜索
4. NetdiskService.search() → HTTP GET /api/netdisk/search?q=xxx
5. 请求头携带 Cookie: user_auth=xxx 进行认证
6. MoonTV 后端代理转发请求到 PanSou 网盘搜索引擎
7. PanSou 返回各网盘平台的资源链接和提取码
8. 后端按网盘类型合并分组，返回 merged_by_type
9. Flutter 解析 JSON 为 NetDiskSearchResult 模型
10. UI 按网盘类型分组渲染：颜色头部 + 链接列表
11. 用户可以：复制链接/密码、显示/隐藏密码、展开/收起标题、点击跳转到网盘
12. 后端 Redis 缓存 30 分钟内重复搜索的结果
```

---

### 十、与原项目功能对照

| 功能 | MoonTV 原项目 | Flutter 实现 | 状态 |
|------|-------------|-------------|------|
| 搜索关键词输入 | 搜索栏 | TextField + onSubmitted | ✅ |
| Cookie 认证 | 浏览器自动携带 | 手动设置 Cookie 头 | ✅ |
| 按网盘类型分组 | 分组 Card + 颜色头部 | 分组 Card + 颜色头部 | ✅ |
| 12 种网盘类型 | 百度/阿里/夸克/天翼/UC/移动/115/PikPak/迅雷/123/磁力/电驴 | 同左，CloudType 配置 | ✅ |
| 密码显示/隐藏 | EyeIcon 切换 | visibility/visibility_off 图标切换 | ✅ |
| 链接复制 | Clipboard API | Clipboard.setData | ✅ |
| 密码复制 | Clipboard API | Clipboard.setData | ✅ |
| 打开链接 | <a> 标签 target="_blank" | url_launcher.launchUrl | ✅ |
| 筛选模式切换 | "显示全部" / "仅显示选中" | ChoiceChip 切换 | ✅ |
| 标签点击筛选/跳转 | 模式区分 | ActionChip + 模式区分 | ✅ |
| 标题展开/收起 | 移动 30 字符/桌面 80 字符截断 | 40 字符截断，点击展开 | ✅ |
| 加载动画 | 旋转圈 + 文字 | CircularProgressIndicator + 文字 | ✅ |
| 结果统计 | 蓝色信息栏 | 蓝色信息栏 | ✅ |
| 自动填入视频标题 | 从 props 传入 | 通过 initialQuery 传入 | ✅ |
| 后端缓存 | 30 分钟 Redis 缓存 | 后端处理，前端无需操作 | ✅ |
| 错误处理 | 功能未启用/网络错误分类提示 | 同左 | ✅ |
| 动漫磁力 ACG 搜索 | AcgSearch 组件 | 未实现（可后续扩展） | ⚠️ |

---

### 十一、依赖说明

| 依赖 | 版本 | 用途 |
|------|------|------|
| `http` | ^1.2.0 | HTTP 网络请求 |
| `url_launcher` | ^6.2.0 | 在外部浏览器打开网盘链接 |
| `shared_preferences` | ^2.2.0 | Cookie 持久化存储 |
| `flutter` | SDK | Flutter 框架基础 |

---

### 十二、注意事项

1. **认证必须**：网盘搜索 API 需要 `user_auth` Cookie。Flutter App 必须先实现登录功能获取该 Cookie 值
2. **Cookie 过期处理**：当 API 返回 401 时，应引导用户重新登录
3. **PanSou 服务依赖**：网盘搜索依赖后端配置的 PanSou 服务地址（默认 `https://so.252035.xyz`），若后端未配置或 PanSou 不可用则搜索失败
4. **HTTPS 强制**：生产环境中 MoonTV 后端应使用 HTTPS，否则 iOS 可能阻止 HTTP 请求
5. **url_launcher 配置**：Android 需在 `AndroidManifest.xml` 添加 `<queries>` 标签，iOS 需在 `Info.plist` 添加 `LSApplicationQueriesSchemes`
6. **网络权限**：Android 需在 `AndroidManifest.xml` 中声明 `<uses-permission android:name="android.permission.INTERNET" />`
