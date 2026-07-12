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
    AppConfig.cloudKeyBaidu: CloudType(
      key: AppConfig.cloudKeyBaidu,
      name: AppStrings.cloudBaidu,
      color: AppColors.blue,
      lightColor: AppColors.cloudBaiduLight,
      icon: AppStrings.cloudIconBaidu,
      domain: AppConfig.cloudDomainBaidu,
    ),
    AppConfig.cloudKeyAliyun: CloudType(
      key: AppConfig.cloudKeyAliyun,
      name: AppStrings.cloudAliyun,
      color: AppColors.orange500,
      lightColor: AppColors.cloudAliyunLight,
      icon: AppStrings.cloudIconAliyun,
      domain: AppConfig.cloudDomainAliyun,
    ),
    AppConfig.cloudKeyQuark: CloudType(
      key: AppConfig.cloudKeyQuark,
      name: AppStrings.cloudQuark,
      color: AppColors.purple500,
      lightColor: AppColors.cloudQuarkLight,
      icon: AppStrings.cloudIconQuark,
      domain: AppConfig.cloudDomainQuark,
    ),
    AppConfig.cloudKeyTianyi: CloudType(
      key: AppConfig.cloudKeyTianyi,
      name: AppStrings.cloudTianyi,
      color: AppColors.red,
      lightColor: AppColors.cloudTianyiLight,
      icon: AppStrings.cloudIconTianyi,
      domain: AppConfig.cloudDomainTianyi,
    ),
    AppConfig.cloudKeyUc: CloudType(
      key: AppConfig.cloudKeyUc,
      name: AppStrings.cloudUc,
      color: AppColors.green500,
      lightColor: AppColors.cloudUcLight,
      icon: AppStrings.cloudIconUc,
      domain: AppConfig.cloudDomainUc,
    ),
    AppConfig.cloudKeyMobile: CloudType(
      key: AppConfig.cloudKeyMobile,
      name: AppStrings.cloudMobile,
      color: AppColors.cyan500,
      lightColor: AppColors.cloudMobileLight,
      icon: AppStrings.cloudIconMobile,
      domain: AppConfig.cloudDomainMobile,
    ),
    AppConfig.cloudKey115: CloudType(
      key: AppConfig.cloudKey115,
      name: AppStrings.cloud115,
      color: AppColors.gray500,
      lightColor: AppColors.cloud115Light,
      icon: AppStrings.cloudIcon115,
      domain: AppConfig.cloudDomain115,
    ),
    AppConfig.cloudKeyPikpak: CloudType(
      key: AppConfig.cloudKeyPikpak,
      name: AppStrings.cloudPikpak,
      color: AppColors.pinkAccent,
      lightColor: AppColors.cloudPikpakLight,
      icon: AppStrings.cloudIconPikpak,
      domain: AppConfig.cloudDomainPikpak,
    ),
    AppConfig.cloudKeyXunlei: CloudType(
      key: AppConfig.cloudKeyXunlei,
      name: AppStrings.cloudXunlei,
      color: AppColors.yellow500,
      lightColor: AppColors.cloudXunleiLight,
      icon: AppStrings.cloudIconXunlei,
      domain: AppConfig.cloudDomainXunlei,
    ),
    AppConfig.cloudKey123: CloudType(
      key: AppConfig.cloudKey123,
      name: AppStrings.cloud123,
      color: AppColors.indigo500,
      lightColor: AppColors.cloud123Light,
      icon: AppStrings.cloudIcon123,
      domain: AppConfig.cloudDomain123,
    ),
    AppConfig.cloudKeyMagnet: CloudType(
      key: AppConfig.cloudKeyMagnet,
      name: AppStrings.cloudMagnet,
      color: AppColors.gray700,
      lightColor: AppColors.cloudMagnetLight,
      icon: AppStrings.cloudIconMagnet,
      domain: AppConfig.cloudSchemeMagnet,
    ),
    AppConfig.cloudKeyEd2k: CloudType(
      key: AppConfig.cloudKeyEd2k,
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
      key: AppConfig.cloudKeyOthers,
      name: AppStrings.cloudOther,
      color: AppColors.gray400,
      lightColor: AppColors.cloudOtherLight,
      icon: AppStrings.cloudIconOther,
      domain: '',
    );
  }
}
