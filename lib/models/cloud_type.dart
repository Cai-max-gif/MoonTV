import 'package:flutter/material.dart';

/// 网盘平台类型配置
class CloudType {
  final String key;
  final String name;
  final Color color;
  final Color lightColor;
  final String icon;
  final String domain;

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
      key: 'baidu',
      name: '百度网盘',
      color: Color(0xFF3B82F6),
      lightColor: Color(0x1A3B82F6),
      icon: '📁',
      domain: 'pan.baidu.com',
    ),
    'aliyun': CloudType(
      key: 'aliyun',
      name: '阿里云盘',
      color: Color(0xFFF97316),
      lightColor: Color(0x1AF97316),
      icon: '☁️',
      domain: 'alipan.com',
    ),
    'quark': CloudType(
      key: 'quark',
      name: '夸克网盘',
      color: Color(0xFFA855F7),
      lightColor: Color(0x1AA855F7),
      icon: '⚡',
      domain: 'pan.quark.cn',
    ),
    'tianyi': CloudType(
      key: 'tianyi',
      name: '天翼云盘',
      color: Color(0xFFEF4444),
      lightColor: Color(0x1AEF4444),
      icon: '📱',
      domain: 'cloud.189.cn',
    ),
    'uc': CloudType(
      key: 'uc',
      name: 'UC网盘',
      color: Color(0xFF22C55E),
      lightColor: Color(0x1A22C55E),
      icon: '🌐',
      domain: 'drive.uc.cn',
    ),
    'mobile': CloudType(
      key: 'mobile',
      name: '移动云盘',
      color: Color(0xFF06B6D4),
      lightColor: Color(0x1A06B6D4),
      icon: '📲',
      domain: 'caiyun.139.com',
    ),
    '115': CloudType(
      key: '115',
      name: '115网盘',
      color: Color(0xFF6B7280),
      lightColor: Color(0x1A6B7280),
      icon: '💾',
      domain: '115.com',
    ),
    'pikpak': CloudType(
      key: 'pikpak',
      name: 'PikPak',
      color: Color(0xFFEC4899),
      lightColor: Color(0x1AEC4899),
      icon: '📦',
      domain: 'mypikpak.com',
    ),
    'xunlei': CloudType(
      key: 'xunlei',
      name: '迅雷网盘',
      color: Color(0xFFEAB308),
      lightColor: Color(0x1AEAB308),
      icon: '⚡',
      domain: 'pan.xunlei.com',
    ),
    '123': CloudType(
      key: '123',
      name: '123网盘',
      color: Color(0xFF6366F1),
      lightColor: Color(0x1A6366F1),
      icon: '🔢',
      domain: '123pan.com',
    ),
    'magnet': CloudType(
      key: 'magnet',
      name: '磁力链接',
      color: Color(0xFF1F2937),
      lightColor: Color(0x1A1F2937),
      icon: '🧲',
      domain: 'magnet:',
    ),
    'ed2k': CloudType(
      key: 'ed2k',
      name: '电驴链接',
      color: Color(0xFF14B8A6),
      lightColor: Color(0x1A14B8A6),
      icon: '🐴',
      domain: 'ed2k://',
    ),
  };

  /// 根据 key 获取类型配置，未知类型返回默认值
  static CloudType get(String key) {
    return types[key] ?? const CloudType(
      key: 'others',
      name: '其他',
      color: Color(0xFF9CA3AF),
      lightColor: Color(0x1A9CA3AF),
      icon: '📄',
      domain: '',
    );
  }
}
