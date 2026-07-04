import 'dart:async';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/netdisk_item.dart';
import '../models/cloud_type.dart';
import '../services/api_service.dart';

/// 网盘搜索页面
class NetdiskSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const NetdiskSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<NetdiskSearchScreen> createState() => _NetdiskSearchScreenState();
}

class _NetdiskSearchScreenState extends State<NetdiskSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  NetDiskSearchResult? _result;
  bool _loading = false;
  String? _error;
  bool _showStats = false;
  Timer? _statsTimer;
  String? _selectedType;

  // 密码可见状态映射: "${typeKey}-${index}" -> 是否可见
  final Map<String, bool> _visiblePasswords = {};
  // 标题展开状态映射
  final Map<String, bool> _expandedTitles = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchFocusNode.requestFocus();
      // 自动搜索
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _doSearch(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _showStats = false;
      _selectedType = null;
      _visiblePasswords.clear();
      _expandedTitles.clear();
    });

    try {
      final response = await ApiService.searchNetdisk(
        query.trim(),
        context: context,
      );

      if (mounted) {
        setState(() {
          _loading = false;
          if (response.success && response.data != null) {
            _result = response.data;
            _showStats = _result!.total > 0;
            if (!_result!.success) {
              _error = _result!.error;
            }
          } else {
            _error = response.message ?? AppStrings.netdiskSearchFailed;
          }
        });

        if (_showStats) {
          _statsTimer?.cancel();
          _statsTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showStats = false;
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '${AppStrings.netdiskSearchError}${e.toString()}';
        });
      }
    }
  }

  /// 按链接数量降序排列的类型列表
  List<MapEntry<String, List<NetDiskLink>>> get _sortedTypes {
    if (_result == null) return [];
    var entries = _result!.mergedByType.entries.toList();
    if (_selectedType != null) {
      entries = entries.where((e) => e.key == _selectedType).toList();
    }
    return entries..sort((a, b) => b.value.length.compareTo(a.value.length));
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.liveCannotOpenLink)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.netdiskOpenUrlFailed}${e.toString()}')),
        );
      }
    }
  }

  void _togglePasswordVisibility(String key) {
    setState(() {
      _visiblePasswords[key] = !(_visiblePasswords[key] ?? false);
    });
  }

  void _toggleTitleExpansion(String key) {
    setState(() {
      _expandedTitles[key] = !(_expandedTitles[key] ?? false);
    });
  }

  Future<void> _copyToClipboard(String text, String description) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.netdiskCopied}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.netdiskCopyFailed}${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.netdiskSearchTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: AppDimens.horizontalSmVerticalMdPadding,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: AppStrings.netdiskSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _result = null;
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
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
            Gap.h16,
            Text(AppStrings.netdiskSearching),
          ],
        ),
      );
    }

    // 错误状态
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacingXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error!.contains('未启用')
                    ? Icons.info_outline
                    : Icons.error_outline,
                size: 48,
                color: _error!.contains('未启用') ? Colors.blue : Colors.red,
              ),
              Gap.h16,
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error!.contains('未启用') ? AppColors.blue : AppColors.red,
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
            Icon(Icons.cloud, size: 64, color: Colors.grey),
            Gap.h16,
            Text(AppStrings.netdiskSearchStartHint, style: TextStyle(color: AppColors.gray400)),
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
            Gap.h16,
            Text(AppStrings.netdiskNoResults),
            Gap.h8,
            Text(AppStrings.netdiskTryOtherKeywords, style: TextStyle(color: AppColors.gray400)),
          ],
        ),
      );
    }

    // 搜索结果列表
    return Column(
      children: [
        if (_result!.mergedByType.isNotEmpty) _buildFilterBar(),
        if (_showStats) _buildStatsBar(),
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

  Widget _buildFilterBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _result!.mergedByType.entries.map((entry) {
          final type = CloudType.get(entry.key);
          final isSelected = _selectedType == entry.key;

          return ActionChip(
            avatar: Text(type.icon, style: const TextStyle(fontSize: AppDimens.fontSizeMd)),
            label: Text(
              '${type.name} ${entry.value.length}',
              style: const TextStyle(
                fontSize: AppDimens.fontSizeXs,
              ),
            ),
            backgroundColor: isSelected ? type.color : type.lightColor,
            side: BorderSide(
              color: isSelected ? type.color : AppColors.gray300,
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.white : null,
            ),
            onPressed: () {
              setState(() {
                _selectedType = isSelected ? null : entry.key;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimens.spacingMd),
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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
                Text(type.icon, style: const TextStyle(fontSize: AppDimens.fontSizeXxl)),
                Gap.w8,
                Text(
                  type.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap.w8,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Text(
                    '${links.length} 个链接',
                    style: const TextStyle(color: AppColors.white, fontSize: AppDimens.fontSize3xs),
                  ),
                ),
              ],
            ),
          ),

          // 链接列表
          ...links.asMap().entries.expand((entry) {
            final index = entry.key;
            final link = entry.value;
            final items = [_buildLinkItem(typeKey, index, link)];
            if (index < links.length - 1) {
              items.add(const Divider(height: 16));
            }
            return items;
          }),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String typeKey, int index, NetDiskLink link) {
    final linkKey = '$typeKey-$index';
    final isPasswordVisible = _visiblePasswords[linkKey] ?? false;
    final isTitleExpanded = _expandedTitles[linkKey] ?? false;
    final title = link.displayTitle;
    final titleTooLong = title.length > 40;

    return InkWell(
      onTap: () => _launchUrl(link.url),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacingMd),
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
                      fontSize: AppDimens.fontSizeMd,
                    ),
                  ),
                ),
              ],
            ),

            // 标题过长时显示展开/收起按钮
            if (titleTooLong)
              GestureDetector(
                onTap: () => _toggleTitleExpansion(linkKey),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isTitleExpanded ? AppStrings.netdiskCollapse : AppStrings.netdiskExpand,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: AppDimens.fontSizeXs,
                    ),
                  ),
                ),
              ),

            Gap.h8,

            // 链接行
            Row(
              children: [
                const Icon(Icons.link, size: AppDimens.iconSm, color: Colors.grey),
                Gap.w4,
                Expanded(
                  child: Text(
                    link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXs,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: AppDimens.iconMd),
                  onPressed: () => _copyToClipboard(link.url, '链接'),
                  tooltip: AppStrings.netdiskCopyLink,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            // 密码行（仅当有密码时显示）
            if (link.hasPassword) ...[
              Gap.h6,
              Row(
                children: [
                  const Icon(Icons.lock, size: AppDimens.iconSm, color: Colors.grey),
                  Gap.w4,
                  Expanded(
                    child: Text(
                      isPasswordVisible ? link.password : '****',
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeXs,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: AppDimens.iconMd,
                    ),
                    onPressed: () => _togglePasswordVisibility(linkKey),
                    tooltip: isPasswordVisible ? AppStrings.netdiskHidePassword : AppStrings.netdiskShowPassword,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: AppDimens.iconMd),
                    onPressed: () => _copyToClipboard(link.password, '密码'),
                    tooltip: AppStrings.netdiskCopyPassword,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],

            Gap.h8,

            // 元信息行
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppStrings.netdiskSource}${link.source}',
                    style: TextStyle(fontSize: AppDimens.fontSize3xs, color: Colors.grey.shade500),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(AppStrings.netdiskAccessLink, style: const TextStyle(fontSize: AppDimens.fontSizeXs)),
                  onPressed: () => _launchUrl(link.url),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
