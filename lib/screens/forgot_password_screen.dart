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
import '../utils/font_utils.dart';
import '../utils/input_validator_utils.dart';
import '../widgets/windows_title_bar.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../constants/app_config.dart';
import '../constants/app_strings.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isFormValid = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _verificationCodeController.addListener(_validateForm);
    _newPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _emailController.text.isNotEmpty &&
          _verificationCodeController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty;
    });
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
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), 'https://');
      String sendCodeUrl = '$secureBaseUrl${AppConfig.sendVerificationCodeEndpoint}';

      final response = await http.post(
        Uri.parse(sendCodeUrl),
        headers: {
          'Content-Type': AppStrings.contentTypeJson,
        },
        body: json.encode({'email': email, 'type': 'reset'}),
      ).timeout(AppConfig.authRequestTimeout);

      if (!mounted) return;
      setState(() {
        _isSendingCode = false;
      });

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          bool isSuccess = responseData['ok'] == true ||
              responseData['success'] == true ||
              responseData['status'] == 'success';

          if (isSuccess) {
            _showToast(AppStrings.regSendCodeSuccess, AppColors.accent);
            _startCountdown();
          } else {
            _showToast(
                responseData['error'] ?? responseData['message'] ?? AppStrings.regSendCodeFailed,
                AppColors.error);
          }
        } catch (e) {
          _showToast(AppStrings.forgotServerResponseError, AppColors.error);
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          _showToast(
              responseData['error'] ?? responseData['message'] ?? AppStrings.regSendCodeFailed,
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      _showToast(AppStrings.forgotFillAll, AppColors.error);
      return;
    }

    final email = _emailController.text.trim();
    final verificationCode = _verificationCodeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (!RegExp(AppRegex.email).hasMatch(email)) {
      _showToast(AppStrings.regValidEmailFormat, AppColors.error);
      return;
    }

    if (newPassword.length < 6) {
      _showToast(AppStrings.regValidPasswordMin, AppColors.error);
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
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), 'https://');
      String resetUrl = '$secureBaseUrl${AppConfig.resetPasswordEndpoint}';

      final response = await http.post(
        Uri.parse(resetUrl),
        headers: {
          'Content-Type': AppStrings.contentTypeJson,
        },
        body: json.encode({
          'email': email,
          'verificationCode': verificationCode,
          'newPassword': newPassword,
        }),
      ).timeout(AppConfig.authRequestTimeout);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      switch (response.statusCode) {
        case 200:
          _showToast(AppStrings.forgotResetSuccess, AppColors.accent);
          await Future.delayed(AppDurations.halfSecond);
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          break;
        case 400:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData['error'] ?? responseData['message'] ?? AppStrings.forgotResetFailed,
                AppColors.error);
          } catch (e) {
            _showToast(AppStrings.forgotResetFailed, AppColors.error);
          }
          break;
        case 404:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData['error'] ?? responseData['message'] ?? AppStrings.forgotEmailNotRegistered,
                AppColors.error);
          } catch (e) {
            _showToast(AppStrings.forgotEmailNotRegistered, AppColors.error);
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
        size: 20,
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
          size: 20,
        ),
        suffixIcon: Material(
          color: AppColors.transparent,
          child: TextButton(
            onPressed:
                (_isSendingCode || _countdown > 0) ? null : _handleSendCode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              backgroundColor: AppColors.transparent,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: _isSendingCode
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 24.0,
                    ),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo/logo.png',
            width: 100,
            height: 100,
          ),
          Gap.h20,
          Text(
            'MoonTV',
            style: FontUtils.sourceCodePro(
              fontSize: AppDimens.fontSizeHero,
              fontWeight: FontWeight.w400,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          Gap.h8,
          Text(
            AppStrings.forgotTitle,
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
                      return AppStrings.regHintEmail;
                    }
                    if (!RegExp(AppRegex.email).hasMatch(value)) {
                      return AppStrings.regValidEmailFormat;
                    }
                    return null;
                  },
                ),
                Gap.h16,
                _buildVerificationCodeField(),
                Gap.h16,
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: _buildInputDecoration(
                    labelText: AppStrings.forgotNewPassword,
                    hintText: AppStrings.authHintPassword,
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    final filtered = InputValidatorUtils.filterPassword(value);
                    if (filtered != value) {
                      _newPasswordController.value = TextEditingValue(
                        text: filtered,
                        selection:
                            TextSelection.collapsed(offset: filtered.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.forgotHintNewPassword;
                    }
                    if (value.length < 6) {
                      return AppStrings.regValidPasswordMin;
                    }
                    return null;
                  },
                ),
                Gap.h12,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppStrings.authLogin,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Gap.w20,
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(AppStrings.authRegister,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeMd,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap.h12,
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? AppColors.silver
                        : AppColors.primary,
                    foregroundColor:
                        _isLoading ? AppColors.textSecondary : AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
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
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            ),
                            Gap.w12,
                            Text(
                              AppStrings.forgotBtnResetting,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeXl,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          AppStrings.forgotBtnReset,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXl,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
