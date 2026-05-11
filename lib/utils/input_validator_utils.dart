class InputValidatorUtils {
  static const int maxLength = 32;

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
    'yeah.net'
  ];

  static bool isEmail(String input) {
    if (!input.contains('@')) {
      return false;
    }
    final domain = input.split('@').last.toLowerCase();
    return allowedEmailDomains.contains(domain);
  }

  static String filterLoginUsername(String input) {
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    if (isEmail(input)) {
      return input.replaceAll(RegExp(r'[^a-zA-Z0-9.@]'), '');
    }
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_.@\u4e00-\u9fa5]'), '');
  }

  static String filterRegisterUsername(String input) {
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9\u4e00-\u9fa5]'), '');
  }

  static String filterEmail(String input) {
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9.@]'), '');
  }

  static String filterPassword(String input) {
    input = input.replaceAll(
        RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]'), '');
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    return input;
  }

  static String filterVerificationCode(String input) {
    String filtered = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (filtered.length > 6) {
      filtered = filtered.substring(0, 6);
    }
    return filtered;
  }

  static bool containsInvalidLoginUsernameChars(String input) {
    return RegExp(r'[^a-zA-Z0-9_.@\u4e00-\u9fa5]').hasMatch(input);
  }

  static bool containsInvalidRegisterUsernameChars(String input) {
    return RegExp(r'[^a-zA-Z0-9\u4e00-\u9fa5]').hasMatch(input);
  }

  static bool containsInvalidEmailChars(String input) {
    return RegExp(r'[^a-zA-Z0-9.@]').hasMatch(input);
  }

  static bool isVerificationCodeValid(String input) {
    return RegExp(r'^\d{6}$').hasMatch(input);
  }

  static bool isEmailValid(String input) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input);
  }

  static bool isPasswordValid(String input) {
    return input.length >= 6 && input.length <= maxLength;
  }

  static bool isLoginUsernameValid(String input) {
    return input.isNotEmpty &&
        input.length <= maxLength &&
        !containsInvalidLoginUsernameChars(input);
  }

  static bool isRegisterUsernameValid(String input) {
    return input.length >= 3 &&
        input.length <= maxLength &&
        !containsInvalidRegisterUsernameChars(input);
  }
}
