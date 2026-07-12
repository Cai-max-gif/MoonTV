import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_regex.dart';
import '../constants/app_durations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import '../services/user_data_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../utils/input_validator_utils.dart';
import '../widgets/windows_title_bar.dart';
import 'home_screen.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _verificationCodeController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool _isFormValid = false;

  void _validateForm() {
    setState(() {
      _isFormValid = _usernameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _verificationCodeController.text.isNotEmpty;
    });
  }

  String _parseCookies(http.Response response) {
    List<String> cookies = [];
    final setCookieHeaders = response.headers[AppConfig.headerSetCookie];
    if (setCookieHeaders != null) {
      final cookieParts = setCookieHeaders.split(';');
      if (cookieParts.isNotEmpty) {
        cookies.add(cookieParts[0].trim());
      }
    }
    return cookies.join('; ');
  }

  void _showToast(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FontUtils.poppins(
            color: AppColors.white,
            fontSize: AppDimens.fontSizeMd,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        margin: const EdgeInsets.all(AppDimens.spacingLg),
        duration: AppDurations.toastDuration,
      ),
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _countdownTimer = Timer.periodic(AppDurations.oneSecond, (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          timer.cancel();
        }
      }
    });
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showToast(AppStrings.regHintEmail, AppColors.error);
      return;
    }
    if (!RegExp(AppRegex.email).hasMatch(email)) {
      _showToast(AppStrings.regValidEmailFormat, AppColors.error);
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      String baseUrl = await UserDataService.getServerUrlWithDefault();
      if (!mounted) return;
      // 确保使用HTTPS
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), AppConfig.httpsProtocol);
      String sendCodeUrl = '$secureBaseUrl${AppConfig.sendVerificationCodeEndpoint}';

      final response = await http.post(
        Uri.parse(sendCodeUrl),
        headers: {
          AppConfig.headerContentType: AppConfig.headerAcceptJson,
        },
        body: json.encode({AppConfig.jsonEmail: email}),
      ).timeout(AppConfig.authRequestTimeout);

      if (!mounted) return;
      setState(() {
        _isSendingCode = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          // 检查多种可能的成功标志
          bool isSuccess = responseData[AppConfig.jsonOk] == true ||
              responseData[AppConfig.jsonSuccess] == true ||
              responseData[AppConfig.jsonStatus] == AppConfig.jsonSuccess;

          if (isSuccess) {
            _showToast(AppStrings.regSendCodeSuccess, AppColors.accent);
            _startCountdown();
          } else {
            _showToast(
                responseData[AppConfig.jsonError] ?? responseData[AppConfig.jsonMessage] ?? AppStrings.regSendCodeFailed,
                AppColors.error);
          }
        } catch (e) {
          // 如果JSON解析失败，也认为是成功（服务器可能返回空响应）
          _showToast(AppStrings.regSendCodeSuccess, AppColors.accent);
          _startCountdown();
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          _showToast(
              responseData[AppConfig.jsonError] ?? responseData[AppConfig.jsonMessage] ?? AppStrings.regSendCodeFailed,
              AppColors.error);
        } catch (e) {
          _showToast(
              '${AppStrings.regSendCodeFailed} (${response.statusCode})', AppColors.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
        _showToast(AppStrings.networkRetryLater, AppColors.error);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      _showToast(AppStrings.regFillAll, AppColors.error);
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final verificationCode = _verificationCodeController.text.trim();

    if (!InputValidatorUtils.isRegisterUsernameValid(username)) {
      _showToast(AppStrings.regValidUsernameChars, AppColors.error);
      return;
    }

    if (password.length < 6) {
      _showToast(AppStrings.regValidPasswordMin, AppColors.error);
      return;
    }

    if (password != confirmPassword) {
      _showToast(AppStrings.regValidPasswordMismatch, AppColors.error);
      return;
    }

    // 验证验证码
    if (verificationCode.isEmpty) {
      _showToast(AppStrings.regValidCode, AppColors.error);
      return;
    }

    if (!RegExp(AppRegex.verificationCode).hasMatch(verificationCode)) {
      _showToast(AppStrings.regValidCodeFormatHint, AppColors.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String baseUrl = await UserDataService.getServerUrlWithDefault();
      if (!mounted) return;
      // 确保使用HTTPS
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), AppConfig.httpsProtocol);
      String registerUrl = '$secureBaseUrl${AppConfig.registerEndpoint}';

      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          AppConfig.headerContentType: AppConfig.headerAcceptJson,
        },
        body: json.encode({
          AppConfig.jsonUsername: username,
          AppConfig.jsonEmail: email,
          AppConfig.jsonPassword: password,
          AppConfig.jsonConfirmPassword: confirmPassword,
          AppConfig.jsonVerificationCode: verificationCode,
        }),
      ).timeout(AppConfig.authRequestTimeout);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      switch (response.statusCode) {
        case 200:
          try {
            final responseData = json.decode(response.body);
            final token = responseData[AppConfig.jsonToken] as String?;
            String cookies = _parseCookies(response);

            await UserDataService.saveUserData(
              username: username,
              password: password,
              token: token,
              cookies: cookies,
            );
          } catch (e) {
            String cookies = _parseCookies(response);
            await UserDataService.saveUserData(
              username: username,
              password: password,
              cookies: cookies,
            );
          }

          if (mounted) {
            _showToast(AppStrings.authNewUserSuccess, AppColors.accent);
            await Future.delayed(AppDurations.halfSecond);
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          }
          break;
        case 400:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData[AppConfig.jsonError] ?? AppStrings.authRegisterFailed, AppColors.error);
          } catch (e) {
            _showToast(AppStrings.authRegisterFailed, AppColors.error);
          }
          break;
        case 403:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData[AppConfig.jsonError] ?? AppStrings.authRegisterDisabled, AppColors.error);
          } catch (e) {
            _showToast(AppStrings.authRegisterDisabled, AppColors.error);
          }
          break;
        case 429:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData[AppConfig.jsonError] ?? AppStrings.authTooFrequent, AppColors.error);
          } catch (e) {
            _showToast(AppStrings.authTooFrequent, AppColors.error);
          }
          break;
        case 500:
          _showToast(AppStrings.serverError, AppColors.error);
          break;
        default:
          _showToast(AppStrings.networkError, AppColors.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showToast(AppStrings.networkError, AppColors.error);
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: FontUtils.poppins(
        color: AppColors.textSecondary,
        fontSize: AppDimens.fontSizeMd,
      ),
      hintText: hintText,
      hintStyle: FontUtils.poppins(
        color: AppColors.silver,
        fontSize: AppDimens.fontSizeXl,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.textSecondary,
        size: AppDimens.iconSize20,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: AppColors.white.withValues(alpha: 0.6),
      contentPadding: AppDimens.inputPadding,
    );
  }

  Widget _buildVerificationCodeField() {
    return TextFormField(
      controller: _verificationCodeController,
      keyboardType: TextInputType.number,
      style: FontUtils.poppins(
        fontSize: AppDimens.fontSizeXl,
        color: AppColors.primary,
      ),
      decoration: InputDecoration(
        labelText: AppStrings.regVerificationCode,
        labelStyle: FontUtils.poppins(
          color: AppColors.textSecondary,
          fontSize: AppDimens.fontSizeMd,
        ),
        hintText: AppStrings.regHintCode,
        hintStyle: FontUtils.poppins(
          color: AppColors.silver,
          fontSize: AppDimens.fontSizeXl,
        ),
        prefixIcon: const Icon(
          Icons.verified_user,
          color: AppColors.textSecondary,
          size: AppDimens.iconSize20,
        ),
        suffixIcon: Material(
          color: AppColors.transparent,
          child: TextButton(
            onPressed:
                (_isSendingCode || _countdown > 0) ? null : _handleSendCode,
            style: TextButton.styleFrom(
              padding: AppDimens.paddingHorizontal8Vertical18,
              backgroundColor: AppColors.transparent,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: _isSendingCode
                ? const SizedBox(
                    height: AppDimens.iconMd,
                    width: AppDimens.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: AppDimens.dividerThicknessMd,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Text(
                    _countdown > 0 ? '${_countdown}s' : AppStrings.regGetCode,
                    style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeMd,
                      fontWeight: FontWeight.w500,
                      color: (_countdown > 0)
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.6),
        contentPadding: AppDimens.inputPadding,
      ),
      onChanged: (value) {
        final filtered = InputValidatorUtils.filterVerificationCode(value);
        if (filtered != value) {
          _verificationCodeController.value = TextEditingValue(
            text: filtered,
            selection: TextSelection.collapsed(offset: filtered.length),
          );
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.regValidCode;
        }
        if (!RegExp(AppRegex.verificationCode).hasMatch(value)) {
          return AppStrings.regValidCodeFormat;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceUtils.isTablet(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightBlueBg,
              AppColors.lightBlueBg,
              AppColors.gradMid2,
              AppColors.gradMid3,
              AppColors.gradMid4,
              AppColors.gradEnd,
            ],
            stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
          ),
        ),
        child: Column(
          children: [
            if (Platform.isWindows) const WindowsTitleBar(forceBlack: true),
            Expanded(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: isTablet
                          ? AppDimens.paddingVertical24
                          : AppDimens.paddingHorizontal32Vertical24,
                    child:
                        isTablet ? _buildTabletLayout() : _buildMobileLayout(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          AppConfig.logoImageAsset,
          width: AppDimens.logoSize,
          height: AppDimens.logoSize,
        ),
        Gap.h20,
        Text(
          AppConfig.appName,
          style: FontUtils.sourceCodePro(
            fontSize: AppDimens.fontSizeHero,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        Gap.h8,
        Text(
          AppStrings.regTitle,
          style: FontUtils.poppins(
            fontSize: AppDimens.fontSizeMd,
            color: AppColors.textSecondary,
          ),
        ),
        Gap.h32,
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: AppColors.primary,
                ),
                decoration: _buildInputDecoration(
                  labelText: AppStrings.regUsername,
                  hintText: AppStrings.regHintUsername,
                  prefixIcon: Icons.person,
                ),
                onChanged: (value) {
                  final isValidChar = RegExp(AppRegex.usernameRegister);
                  if (!isValidChar.hasMatch(value)) {
                    final filtered =
                        InputValidatorUtils.filterRegisterUsername(value);
                    if (filtered != value) {
                      _usernameController.value = TextEditingValue(
                        text: filtered,
                        selection:
                            TextSelection.collapsed(offset: filtered.length),
                      );
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.regValidUsername;
                  }
                  if (!InputValidatorUtils.isRegisterUsernameValid(value)) {
                    return AppStrings.regValidUsernameChars;
                  }
                  return null;
                },
              ),
              Gap.h16,
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: AppColors.primary,
                ),
                decoration: _buildInputDecoration(
                  labelText: AppStrings.regEmail,
                  hintText: AppStrings.regHintEmail,
                  prefixIcon: Icons.email,
                ),
                onChanged: (value) {
                  final isValidChar = RegExp(AppRegex.emailInput);
                  if (!isValidChar.hasMatch(value)) {
                    final filtered = InputValidatorUtils.filterEmail(value);
                    if (filtered != value) {
                      _emailController.value = TextEditingValue(
                        text: filtered,
                        selection:
                            TextSelection.collapsed(offset: filtered.length),
                      );
                    }
                  }
                },
                validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.regValidEmail;
                    }
                    if (!RegExp(AppRegex.email).hasMatch(value)) {
                      return AppStrings.regValidEmailFormat;
                    }
                    final domain = value.split('@').last.toLowerCase();
                    if (!AppStrings.allowedEmailDomains.contains(domain)) {
                      return AppStrings.regValidEmailDomain;
                    }
                    return null;
                  },
                ),
                Gap.h16,
                _buildVerificationCodeField(),
              Gap.h16,
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: AppColors.primary,
                ),
                decoration: _buildInputDecoration(
                  labelText: AppStrings.authPassword,
                  hintText: AppStrings.regHintPassword,
                  prefixIcon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: AppDimens.iconSize20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  final filtered = InputValidatorUtils.filterPassword(value);
                  if (filtered != value) {
                    _passwordController.value = TextEditingValue(
                      text: filtered,
                      selection:
                          TextSelection.collapsed(offset: filtered.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.regValidPassword;
                  }
                  if (value.length < 6) {
                    return AppStrings.regValidPasswordMin;
                  }
                  return null;
                },
              ),
              Gap.h16,
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: AppColors.primary,
                ),
                decoration: _buildInputDecoration(
                  labelText: AppStrings.regConfirmPassword,
                  hintText: AppStrings.regHintConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: AppDimens.iconSize20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  final filtered = InputValidatorUtils.filterPassword(value);
                  if (filtered != value) {
                    _confirmPasswordController.value = TextEditingValue(
                      text: filtered,
                      selection:
                          TextSelection.collapsed(offset: filtered.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.regValidConfirmPassword;
                  }
                  if (value != _passwordController.text) {
                    return AppStrings.regValidPasswordMismatch;
                  }
                  return null;
                },
              ),
              Gap.h32,
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading
                      ? AppColors.silver
                      : AppColors.primary,
                  foregroundColor:
                      _isLoading ? AppColors.textSecondary : AppColors.white,
                  padding: AppDimens.paddingVertical18,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  ),
                  elevation: AppDimens.elevationNone,
                  shadowColor: AppColors.transparent,
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: AppDimens.iconMd,
                            width: AppDimens.iconMd,
                            child: CircularProgressIndicator(
                              strokeWidth: AppDimens.dividerThicknessMd,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          ),
                          Gap.w12,
                          Text(
                            AppStrings.regBtnRegistering,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXl,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        AppStrings.regBtnRegister,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
              Gap.h24,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.regAlreadyHaveAccount,
                    style: FontUtils.poppins(
                      fontSize: AppDimens.fontSizeMd,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppStrings.regLoginNow,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeMd,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppDimens.filterDialogWidth),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingXxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConfig.logoImageAsset,
            width: AppDimens.logoSize,
            height: AppDimens.logoSize,
          ),
          Gap.h20,
          Text(
            AppConfig.appName,
            style: FontUtils.sourceCodePro(
              fontSize: AppDimens.fontSizeHero,
              fontWeight: FontWeight.w400,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          Gap.h8,
          Text(
            AppStrings.regTitle,
            style: FontUtils.poppins(
              fontSize: AppDimens.fontSizeMd,
              color: AppColors.textSecondary,
            ),
          ),
          Gap.h32,
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: _buildInputDecoration(
                  labelText: AppStrings.regUsername,
                  hintText: AppStrings.regHintUsername,
                    prefixIcon: Icons.person,
                  ),
                  onChanged: (value) {
                    final isValidChar = RegExp(AppRegex.usernameRegister);
                    if (!isValidChar.hasMatch(value)) {
                      final filtered =
                          InputValidatorUtils.filterRegisterUsername(value);
                      if (filtered != value) {
                        _usernameController.value = TextEditingValue(
                          text: filtered,
                          selection:
                              TextSelection.collapsed(offset: filtered.length),
                        );
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                    return AppStrings.regValidUsername;
                    }
                    if (!InputValidatorUtils.isRegisterUsernameValid(value)) {
                      return AppStrings.regValidUsernameChars;
                    }
                    return null;
                  },
                ),
                Gap.h16,
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: AppStrings.regEmail,
                    hintText: AppStrings.regHintEmail,
                    prefixIcon: Icons.email,
                  ),
                  onChanged: (value) {
                    final isValidChar = RegExp(AppRegex.emailInput);
                    if (!isValidChar.hasMatch(value)) {
                      final filtered = InputValidatorUtils.filterEmail(value);
                      if (filtered != value) {
                        _emailController.value = TextEditingValue(
                          text: filtered,
                          selection:
                              TextSelection.collapsed(offset: filtered.length),
                        );
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.regValidEmail;
                    }
                    if (!RegExp(AppRegex.email).hasMatch(value)) {
                      return AppStrings.regValidEmailFormat;
                    }
                    final domain = value.split('@').last.toLowerCase();
                    if (!AppStrings.allowedEmailDomains.contains(domain)) {
                      return AppStrings.regValidEmailDomain;
                    }
                    return null;
                  },
                ),
                Gap.h16,
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: AppStrings.regHintPassword,
                    hintText: AppStrings.regHintPassword,
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                        size: AppDimens.iconSize20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    final filtered = InputValidatorUtils.filterPassword(value);
                    if (filtered != value) {
                      _passwordController.value = TextEditingValue(
                        text: filtered,
                        selection:
                            TextSelection.collapsed(offset: filtered.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.regValidPassword;
                    }
                    if (value.length < 6) {
                      return AppStrings.regValidPasswordMin;
                    }
                    return null;
                  },
                ),
                Gap.h16,
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: AppStrings.regConfirmPassword,
                    hintText: AppStrings.regHintConfirmPassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                        size: AppDimens.iconSize20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    final filtered = InputValidatorUtils.filterPassword(value);
                    if (filtered != value) {
                      _confirmPasswordController.value = TextEditingValue(
                        text: filtered,
                        selection:
                            TextSelection.collapsed(offset: filtered.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.regValidConfirmPassword;
                    }
                    if (value != _passwordController.text) {
                      return AppStrings.regValidPasswordMismatch;
                    }
                    return null;
                  },
                ),
                Gap.h16,
                _buildVerificationCodeField(),
                Gap.h32,
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? AppColors.silver
                        : AppColors.primary,
                    foregroundColor:
                        _isLoading ? AppColors.textSecondary : AppColors.white,
                    padding: AppDimens.paddingVertical18,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    elevation: AppDimens.elevationNone,
                    shadowColor: AppColors.transparent,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: AppDimens.iconMd,
                              width: AppDimens.iconMd,
                              child: CircularProgressIndicator(
                                strokeWidth: AppDimens.dividerThicknessMd,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            ),
                            Gap.w12,
                            Text(
                              AppStrings.regBtnRegistering,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeXl,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                        AppStrings.regBtnRegister,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXl,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
                Gap.h24,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.regAlreadyHaveAccount,
                      style: FontUtils.poppins(
                        fontSize: AppDimens.fontSizeMd,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        AppStrings.regLoginNow,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
