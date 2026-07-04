import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

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
      name: AppStrings.cloudBaidu,
      color: AppColors.blue,
      lightColor: AppColors.cloudBaiduLight,
      icon: AppStrings.cloudIconBaidu,
      domain: AppConfig.cloudDomainBaidu,
    ),
    'aliyun': CloudType(
      key: 'aliyun',
      name: AppStrings.cloudAliyun,
      color: AppColors.orange500,
      lightColor: AppColors.cloudAliyunLight,
      icon: AppStrings.cloudIconAliyun,
      domain: AppConfig.cloudDomainAliyun,
    ),
    'quark': CloudType(
      key: 'quark',
      name: AppStrings.cloudQuark,
      color: AppColors.purple500,
      lightColor: AppColors.cloudQuarkLight,
      icon: AppStrings.cloudIconQuark,
      domain: AppConfig.cloudDomainQuark,
    ),
    'tianyi': CloudType(
      key: 'tianyi',
      name: AppStrings.cloudTianyi,
      color: AppColors.red,
      lightColor: AppColors.cloudTianyiLight,
      icon: AppStrings.cloudIconTianyi,
      domain: AppConfig.cloudDomainTianyi,
    ),
    'uc': CloudType(
      key: 'uc',
      name: AppStrings.cloudUc,
      color: AppColors.green500,
      lightColor: AppColors.cloudUcLight,
      icon: AppStrings.cloudIconUc,
      domain: AppConfig.cloudDomainUc,
    ),
    'mobile': CloudType(
      key: 'mobile',
      name: AppStrings.cloudMobile,
      color: AppColors.cyan500,
      lightColor: AppColors.cloudMobileLight,
      icon: AppStrings.cloudIconMobile,
      domain: AppConfig.cloudDomainMobile,
    ),
    '115': CloudType(
      key: '115',
      name: AppStrings.cloud115,
      color: AppColors.gray500,
      lightColor: AppColors.cloud115Light,
      icon: AppStrings.cloudIcon115,
      domain: AppConfig.cloudDomain115,
    ),
    'pikpak': CloudType(
      key: 'pikpak',
      name: AppStrings.cloudPikpak,
      color: AppColors.pinkAccent,
      lightColor: AppColors.cloudPikpakLight,
      icon: AppStrings.cloudIconPikpak,
      domain: AppConfig.cloudDomainPikpak,
    ),
    'xunlei': CloudType(
      key: 'xunlei',
      name: AppStrings.cloudXunlei,
      color: AppColors.yellow500,
      lightColor: AppColors.cloudXunleiLight,
      icon: AppStrings.cloudIconXunlei,
      domain: AppConfig.cloudDomainXunlei,
    ),
    '123': CloudType(
      key: '123',
      name: AppStrings.cloud123,
      color: AppColors.indigo500,
      lightColor: AppColors.cloud123Light,
      icon: AppStrings.cloudIcon123,
      domain: AppConfig.cloudDomain123,
    ),
    'magnet': CloudType(
      key: 'magnet',
      name: AppStrings.cloudMagnet,
      color: AppColors.gray700,
      lightColor: AppColors.cloudMagnetLight,
      icon: AppStrings.cloudIconMagnet,
      domain: AppConfig.cloudSchemeMagnet,
    ),
    'ed2k': CloudType(
      key: 'ed2k',
      name: AppStrings.cloudEd2k,
      color: AppColors.teal500,
      lightColor: AppColors.cloudEd2kLight,
      icon: AppStrings.cloudIconEd2k,
      domain: AppConfig.cloudSchemeEd2k,
    ),
  };

  /// 根据 key 获取类型配置，未知类型返回默认值
  static CloudType get(String key) {
    return types[key] ?? const CloudType(
      key: 'others',
      name: AppStrings.cloudOther,
      color: AppColors.gray400,
      lightColor: AppColors.cloudOtherLight,
      icon: AppStrings.cloudIconOther,
      domain: '',
    );
  }
}
