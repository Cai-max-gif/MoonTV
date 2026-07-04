import '../constants/app_regex.dart';
import '../constants/app_strings.dart';
import '../constants/app_config.dart';

class InputValidatorUtils {
  static const int maxLength = AppConfig.maxUsernameLength;

  static bool isEmail(String input) {
    if (!input.contains('@')) {
      return false;
    }
    final domain = input.split('@').last.toLowerCase();
    return AppStrings.allowedEmailDomains.contains(domain);
  }

  static String filterLoginUsername(String input) {
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    if (isEmail(input)) {
      return input.replaceAll(RegExp(AppRegex.emailInputChars), '');
    }
    return input.replaceAll(RegExp(AppRegex.loginUsernameFilterChars), '');
  }

  static String filterRegisterUsername(String input) {
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    return input.replaceAll(RegExp(AppRegex.registerUsernameFilterChars), '');
  }

  static String filterEmail(String input) {
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    return input.replaceAll(RegExp(AppRegex.emailInputChars), '');
  }

  static String filterPassword(String input) {
    input = input.replaceAll(RegExp(AppRegex.chineseChars), '');
    if (input.length > maxLength) {
      input = input.substring(0, maxLength);
    }
    return input;
  }

  static String filterVerificationCode(String input) {
    String filtered = input.replaceAll(RegExp(AppRegex.nonDigits), '');
    if (filtered.length > AppConfig.verificationCodeLength) {
      filtered = filtered.substring(0, AppConfig.verificationCodeLength);
    }
    return filtered;
  }

  static bool containsInvalidLoginUsernameChars(String input) {
    return !RegExp(AppRegex.usernameLogin).hasMatch(input);
  }

  static bool containsInvalidRegisterUsernameChars(String input) {
    return !RegExp(AppRegex.usernameRegister).hasMatch(input);
  }

  static bool containsInvalidEmailChars(String input) {
    return !RegExp(AppRegex.emailInput).hasMatch(input);
  }

  static bool isVerificationCodeValid(String input) {
    return RegExp(AppRegex.verificationCode).hasMatch(input);
  }

  static bool isEmailValid(String input) {
    return RegExp(AppRegex.email).hasMatch(input);
  }

  static bool isPasswordValid(String input) {
    return input.length >= AppConfig.minPasswordLength && input.length <= maxLength;
  }

  static bool isLoginUsernameValid(String input) {
    return input.isNotEmpty &&
        input.length <= maxLength &&
        !containsInvalidLoginUsernameChars(input);
  }

  static bool isRegisterUsernameValid(String input) {
    return input.length >= AppConfig.minRegisterUsernameLength &&
        input.length <= maxLength &&
        !containsInvalidRegisterUsernameChars(input);
  }
}
