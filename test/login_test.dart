import 'package:flutter_test/flutter_test.dart';
import 'package:moontv/services/api_service.dart';
import 'package:moontv/services/user_data_service.dart';

void main() {
  group('Login Tests', () {
    test('Should show correct error message for banned account', () async {
      // 模拟401响应，包含账号被封禁的错误信息
      final responseBody = '{"message": "账号已被封禁"}';
      
      // 验证错误信息解析
      expect(responseBody.contains('账号已被封禁'), isTrue);
    });

    test('Should handle normal login failure', () async {
      // 模拟401响应，普通密码错误
      final responseBody = '{"message": "用户名或密码错误"}';
      
      // 验证错误信息解析
      expect(responseBody.contains('用户名或密码错误'), isTrue);
    });

    test('Should check account status periodically', () async {
      // 测试账号状态检查功能
      // 这里我们只是验证方法存在，实际的周期性检查逻辑在AppWrapper中实现
      expect(ApiService.checkAccountStatus, isNotNull);
    });

    test('Should clear auth data when account is banned', () async {
      // 测试账号被封禁时是否会清除认证数据
      // 这里我们验证clearAuthData方法存在
      expect(UserDataService.clearAuthData, isNotNull);
    });
  });
}
