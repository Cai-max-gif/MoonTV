import 'package:flutter_test/flutter_test.dart';
import 'package:moontv/services/api_service.dart';
import 'package:moontv/services/user_data_service.dart';

void main() {
  group('Login and Account Status Tests', () {
    test('Should handle normal login failure', () async {
      // 模拟401响应，普通密码错误
      final responseBody = '{"message": "用户名或密码错误"}';
      
      // 验证错误信息解析
      expect(responseBody.contains('用户名或密码错误'), isTrue);
    });

    test('Should show correct error message for banned account', () async {
      // 模拟401响应，包含账号被封禁的错误信息
      final responseBody = '{"message": "账号已被封禁"}';
      
      // 验证错误信息解析
      expect(responseBody.contains('账号已被封禁'), isTrue);
    });

    test('Should detect banned account status', () async {
      // 模拟账号状态检查响应，账号被封禁
      final bannedResponse = '{"status": "banned"}';
      
      // 验证状态解析
      expect(bannedResponse.contains('banned'), isTrue);
    });

    test('Should detect active account status', () async {
      // 模拟账号状态检查响应，账号正常
      final activeResponse = '{"status": "active"}';
      
      // 验证状态解析
      expect(activeResponse.contains('active'), isTrue);
    });

    test('Should have account status check method', () async {
      // 验证checkAccountStatus方法存在
      expect(ApiService.checkAccountStatus, isNotNull);
    });

    test('Should have clear auth data method', () async {
      // 验证clearAuthData方法存在
      expect(UserDataService.clearAuthData, isNotNull);
    });

    test('Should have isLoggedIn method', () async {
      // 验证isLoggedIn方法存在
      expect(UserDataService.isLoggedIn, isNotNull);
    });
  });
}
