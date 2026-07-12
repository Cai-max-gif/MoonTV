import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_regex.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../services/user_data_service.dart';
import '../services/telegram_auth_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../utils/input_validator_utils.dart';
import '../widgets/windows_title_bar.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import '../constants/app_config.dart';
import '../constants/app_durations.dart';
import 'register_screen.dart';
import '../constants/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isTelegramLoading = false;
  bool _isEmailInput = false;
  String? _telegramStatus;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _loadSavedUserData();
  }

  Future<void> _loadSavedUserData() async {
    final userData = await UserDataService.getAllUserData();
    if (!mounted) return;
    bool hasData = false;

    if (userData[AppConfig.jsonUsername] != null) {
      _usernameController.text = userData[AppConfig.jsonUsername]!;
      hasData = true;
    }
    // 不再自动填充密码，提高安全性
    // if (userData['password'] != null) {
    //   _passwordController.text = userData['password']!;
    //   hasData = true;
    // }

    // 如果有数据被加载，更新UI状态
    if (hasData && mounted) {
      setState(() {
        // 触发表单验证
        _validateForm();
      });
    }
  }

  Future<void> _handleTelegramLogin() async {
    if (_isTelegramLoading) return;

    // 检查账户是否被锁定
    bool isLocked = await UserDataService.isAccountLocked();
    if (!mounted) return;
    if (isLocked) {
      final remainingTime = await UserDataService.getAccountLockRemainingTime();
      if (remainingTime != null) {
        final minutes = remainingTime.inMinutes;
        _showToast(AppStrings.formatLockedMinutesTitle(minutes), AppColors.error);
      } else {
        _showToast(AppStrings.formatLockedLater, AppColors.error);
      }
      return;
    }

    setState(() {
      _isTelegramLoading = true;
      _telegramStatus = AppStrings.authTelegramConnecting;
    });

    final result = await TelegramAuthService.authenticate(
      isMounted: () => mounted,
      onStatusChanged: (status) {
        if (mounted) {
          setState(() {
            _telegramStatus = status;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isTelegramLoading = false;
      _telegramStatus = null;
    });

    if (result.success) {
      if (result.isNewUser) {
        _showToast(AppStrings.authTelegramRegisterSuccess, AppColors.green);
      } else {
        _showToast(AppStrings.authLoginSuccess, AppColors.green);
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // 记录登录失败
      await UserDataService.recordLoginFailure();
      
      // 检查是否被锁定
      bool isLocked = await UserDataService.isAccountLocked();
      if (!mounted) return;
      if (isLocked) {
        final remainingTime = await UserDataService.getAccountLockRemainingTime();
        if (remainingTime != null) {
          final minutes = remainingTime.inMinutes;
          _showToast('${result.error ?? AppStrings.authTelegramLoginFailed}，${AppStrings.authAccountLockedMinutes.replaceAll('%d', '$minutes')}', AppColors.error);
        } else {
          _showToast('${result.error ?? AppStrings.authTelegramLoginFailed}，${AppStrings.formatLockedLater}', AppColors.error);
        }
      } else {
        final attempts = await UserDataService.getLoginAttempts();
        final remainingAttempts = 5 - attempts;
        _showToast('${result.error ?? AppStrings.authTelegramLoginFailed}，${AppStrings.authRemainingAttempts.replaceAll('%d', '$remainingAttempts')}', AppColors.error);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
      _isEmailInput = InputValidatorUtils.isEmail(_usernameController.text);
    });
  }

  // 处理回车键提交
  void _handleSubmit() {
    _handleLogin();
  }

  String _parseCookies(http.Response response) {
    // 解析 Set-Cookie 头部
    List<String> cookies = [];

    // 获取所有 Set-Cookie 头部
    final setCookieHeaders = response.headers[AppConfig.headerSetCookie];
    if (setCookieHeaders != null) {
      // HTTP 头部通常是 String 类型
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
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
        duration: AppDurations.toastDuration,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() ||
        !_isFormValid ||
        _passwordController.text.isEmpty) {
        _showToast(AppStrings.authLoginEmpty, AppColors.error);
      return;
    }

    bool isLocked = await UserDataService.isAccountLocked();
    if (!mounted) return;
    if (isLocked) {
      final remainingTime = await UserDataService.getAccountLockRemainingTime();
      if (remainingTime != null) {
        final minutes = remainingTime.inMinutes;
        _showToast(AppStrings.formatLockedMinutesTitle(minutes), AppColors.error);
      } else {
        _showToast(AppStrings.authAccountLockedLater, AppColors.error);
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 处理 URL
      String baseUrl = await UserDataService.getServerUrlWithDefault();
      // 确保使用HTTPS
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(AppRegex.httpPrefix), AppConfig.httpsProtocol);
      String loginUrl = '$secureBaseUrl${AppConfig.loginEndpoint}';

      // 判断是否为邮箱登录
      bool isEmailLogin = InputValidatorUtils.isEmail(_usernameController.text);

      // 发送登录请求
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          AppConfig.headerContentType: AppConfig.headerAcceptJson,
        },
        body: json.encode({
          AppConfig.jsonUsername: _usernameController.text,
          AppConfig.jsonPassword: _passwordController.text,
          AppConfig.jsonType: isEmailLogin,
        }),
      ).timeout(AppConfig.authRequestTimeout);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // 根据状态码显示不同的消息
      switch (response.statusCode) {
        case 200:
          try {
            // 尝试解析响应获取令牌和真实用户名
            final responseData = json.decode(response.body);
            final token = responseData[AppConfig.jsonToken] as String?;

            // 使用后端返回的真实用户名，如果没有返回则使用用户输入的
            final String realUsername = (responseData[AppConfig.jsonUsername] as String?) ??
                _usernameController.text;

            // 解析 cookies
            String cookies = _parseCookies(response);

            // 保存用户数据，使用真实用户名
            await UserDataService.saveUserData(
              username: realUsername,
              password: _passwordController.text,
              token: token,
              cookies: cookies,
            );
          } catch (e) {
            // 如果解析失败，回退到传统的 cookies 方式
            String cookies = _parseCookies(response);

            // 保存用户数据，使用用户输入的用户名
            await UserDataService.saveUserData(
              username: _usernameController.text,
              password: _passwordController.text,
              cookies: cookies,
            );
          }

          // 跳转到首页，并清除所有路由栈（强制销毁所有旧页面）
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
          break;
        case 401:
          // 解析响应体，检查是否为账号封禁
          String errorMessage = AppStrings.authLoginFailed;
          bool isBanned = false;
          try {
            final responseData = json.decode(response.body);
            if (responseData.containsKey(AppConfig.jsonMessage)) {
              errorMessage = responseData[AppConfig.jsonMessage] as String;
              // 检查是否为账号封禁
              if (errorMessage.contains(AppStrings.authBannedAccount) ||
                  errorMessage.contains(AppStrings.bannedKeyword) ||
                  errorMessage.contains(AppConfig.errorKeywordBanned) ||
                  errorMessage.contains(AppConfig.errorKeywordBan)) {
                isBanned = true;
              }
            } else if (responseData.containsKey(AppConfig.jsonError)) {
              errorMessage = responseData[AppConfig.jsonError] as String;
              // 检查是否为账号封禁
              if (errorMessage.contains(AppStrings.authBannedAccount) ||
                  errorMessage.contains(AppStrings.bannedKeyword) ||
                  errorMessage.contains(AppConfig.errorKeywordBanned) ||
                  errorMessage.contains(AppConfig.errorKeywordBan)) {
                isBanned = true;
              }
            }
          } catch (e) {
            // 解析失败，使用默认错误信息
          }

          // 记录登录失败（如果不是账号封禁）
          if (!isBanned) {
            await UserDataService.recordLoginFailure();
          }

          // 检查是否被锁定
          isLocked = await UserDataService.isAccountLocked();
          if (isBanned) {
            // 账号被封禁，直接显示封禁提示
            _showToast(errorMessage, AppColors.error);
          } else if (isLocked) {
            final remainingTime =
                await UserDataService.getAccountLockRemainingTime();
            if (remainingTime != null) {
              final minutes = remainingTime.inMinutes;
              _showToast('$errorMessage，${AppStrings.authAccountLockedMinutes.replaceAll('%d', '$minutes')}',
                  AppColors.error);
            } else {
              _showToast('$errorMessage，${AppStrings.authAccountLocked}', AppColors.error);
            }
          } else {
            final attempts = await UserDataService.getLoginAttempts();
        final remainingAttempts = AppConfig.maxLoginAttempts - attempts;
            _showToast('$errorMessage，${AppStrings.authRemainingAttempts.replaceAll('%d', '$remainingAttempts')}',
                AppColors.error);
          }
          break;
        case 500:
          _showToast(AppStrings.serverError, AppColors.error);
          break;
        default:
          _showToast(AppStrings.networkError, AppColors.error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // 记录登录失败
      await UserDataService.recordLoginFailure();
      _showToast(AppStrings.networkError, AppColors.error);
    }
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
              AppColors.lightBlueBg, // #e6f3fb 0%
              AppColors.gradMid1, // #eaf3f7 18%
              AppColors.gradMid2, // #f7f7f3 38%
              AppColors.gradMid3, // #e9ecef 60%
              AppColors.gradMid4, // #dbe3ea 80%
              AppColors.gradEnd, // #d3dde6 100%
            ],
            stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Windows 自定义标题栏（透明背景）
            if (Platform.isWindows) const WindowsTitleBar(forceBlack: true),
            // 主要内容
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

  // 手机端布局（保持原样）
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo 图标
        Image.asset(
          AppConfig.logoImageAsset,
          width: AppDimens.logoSize,
          height: AppDimens.logoSize,
        ),
        Gap.h20,
        // MoonTV 标题
        Text(
          AppConfig.appName,
          style: FontUtils.sourceCodePro(
            fontSize: AppDimens.fontSizeHero,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        Gap.h40,

        // 登录表单 - 无边框设计
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 用户名输入框
              TextFormField(
                controller: _usernameController,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  labelText: AppStrings.authUsernameOrEmail,
                  labelStyle: FontUtils.poppins(
                    color: AppColors.textSecondary,
                    fontSize: AppDimens.fontSizeMd,
                  ),
                  hintText: AppStrings.authHintUsernameOrEmail,
                  hintStyle: FontUtils.poppins(
                    color: AppColors.silver,
                    fontSize: AppDimens.fontSizeXl,
                  ),
                  prefixIcon: Icon(
                    _isEmailInput ? Icons.email : Icons.person,
                    color: AppColors.textSecondary,
                    size: AppDimens.iconSize20,
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
                  final isValidChar = RegExp(AppRegex.usernameLogin);
                  if (!isValidChar.hasMatch(value)) {
                    String filtered;
                    if (InputValidatorUtils.isEmail(value)) {
                      filtered = InputValidatorUtils.filterEmail(value);
                    } else {
                      filtered = InputValidatorUtils.filterLoginUsername(value);
                    }
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
                    return AppStrings.authValidUsernameOrEmail;
                  }
                  if (InputValidatorUtils.isEmail(value)) {
                    if (!InputValidatorUtils.isEmailValid(value)) {
                      return AppStrings.authValidEmail;
                    }
                  } else {
                    if (!InputValidatorUtils.isLoginUsernameValid(value)) {
                      return AppStrings.authValidUsernameLength;
                    }
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              Gap.h20,

              // 密码输入框
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: FontUtils.poppins(
                  fontSize: AppDimens.fontSizeXl,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  labelText: AppStrings.authPassword,
                  labelStyle: FontUtils.poppins(
                    color: AppColors.textSecondary,
                    fontSize: AppDimens.fontSizeMd,
                  ),
                  hintText: AppStrings.authHintPassword,
                  hintStyle: FontUtils.poppins(
                    color: AppColors.silver,
                    fontSize: AppDimens.fontSizeXl,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: AppColors.textSecondary,
                    size: AppDimens.iconSize20,
                  ),
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
                    return AppStrings.authValidPassword;
                  }
                  if (!InputValidatorUtils.isPasswordValid(value)) {
                    return AppStrings.authValidPasswordLength;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              Gap.h12,

              // 注册 + 忘记密码
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      AppStrings.authRegister,
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: Text(
                      AppStrings.authForgotPassword,
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

              // 登录按钮
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                            AppStrings.authLoginLoading,
                            style: FontUtils.poppins(
                              fontSize: AppDimens.fontSizeXl,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        AppStrings.authLogin,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXl,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
              Gap.h20,
              // Telegram 登录图标
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _isTelegramLoading ? null : _handleTelegramLogin,
                      child: _isTelegramLoading
                          ? const SizedBox(
                              width: AppDimens.spacingXxxl,
                              height: AppDimens.spacingXxxl,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.linkBlue,
                              ),
                            )
                          : const Icon(
                              Icons.telegram,
                              color: AppColors.linkBlue,
                              size: AppDimens.iconSize40,
                            ),
                    ),
                    if (_telegramStatus != null) ...[
                      Gap.h8,
                      Text(
                        _telegramStatus!,
                        style: FontUtils.poppins(
                          fontSize: AppDimens.fontSizeXs,
                          color: AppColors.textDarkHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 平板端布局（与手机端风格一致，只是限制宽度）
  Widget _buildTabletLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppDimens.filterDialogWidth),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingXxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo 图标
          Image.asset(
            AppConfig.logoImageAsset,
            width: AppDimens.logoSize,
            height: AppDimens.logoSize,
          ),
          Gap.h20,
          // MoonTV 标题
          Text(
            AppConfig.appName,
            style: FontUtils.sourceCodePro(
              fontSize: AppDimens.fontSizeHero,
              fontWeight: FontWeight.w400,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          Gap.h40,

          // 登录表单 - 无边框设计
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.authUsernameOrEmail,
                    labelStyle: FontUtils.poppins(
                      color: AppColors.textSecondary,
                      fontSize: AppDimens.fontSizeMd,
                    ),
                    hintText: AppStrings.authHintUsernameOrEmail,
                    hintStyle: FontUtils.poppins(
                      color: AppColors.silver,
                      fontSize: AppDimens.fontSizeXl,
                    ),
                    prefixIcon: Icon(
                      _isEmailInput ? Icons.email : Icons.person,
                      color: AppColors.textSecondary,
                      size: AppDimens.iconSize20,
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
                    final isValidChar =
                        RegExp(AppRegex.usernameLogin);
                    if (!isValidChar.hasMatch(value)) {
                      String filtered;
                      if (InputValidatorUtils.isEmail(value)) {
                        filtered = InputValidatorUtils.filterEmail(value);
                      } else {
                        filtered =
                            InputValidatorUtils.filterLoginUsername(value);
                      }
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
                      return AppStrings.authValidUsernameOrEmail;
                    }
                    if (InputValidatorUtils.isEmail(value)) {
                      if (!InputValidatorUtils.isEmailValid(value)) {
                        return AppStrings.authValidEmail;
                      }
                    } else {
                      if (!InputValidatorUtils.isLoginUsernameValid(value)) {
                        return AppStrings.authValidUsernameLength;
                      }
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),
                Gap.h20,

                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: AppDimens.fontSizeXl,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.authPassword,
                    labelStyle: FontUtils.poppins(
                      color: AppColors.textSecondary,
                      fontSize: AppDimens.fontSizeMd,
                    ),
                    hintText: AppStrings.authHintPassword,
                    hintStyle: FontUtils.poppins(
                      color: AppColors.silver,
                      fontSize: AppDimens.fontSizeXl,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppColors.textSecondary,
                      size: AppDimens.iconSize20,
                    ),
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
                      return AppStrings.authValidPassword;
                    }
                    if (!InputValidatorUtils.isPasswordValid(value)) {
                      return AppStrings.authValidPasswordLength;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),
                Gap.h12,

                // 注册 + 忘记密码
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                      AppStrings.authRegister,
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        AppStrings.authForgotPassword,
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

                // 登录按钮
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                              AppStrings.authLoginLoading,
                              style: FontUtils.poppins(
                                fontSize: AppDimens.fontSizeXl,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          AppStrings.authLogin,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXl,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
                // Gap.h20,
                // Telegram 登录图标
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _isTelegramLoading ? null : _handleTelegramLogin,
                        child: _isTelegramLoading
                            ? const SizedBox(
                                width: AppDimens.spacingXxxl,
                                height: AppDimens.spacingXxxl,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.linkBlue,
                                ),
                              )
                            : const Icon(
                                Icons.telegram,
                                color: AppColors.linkBlue,
                                size: AppDimens.iconSize40,
                              ),
                      ),
                      if (_telegramStatus != null) ...[
                        Gap.h8,
                        Text(
                          _telegramStatus!,
                          style: FontUtils.poppins(
                            fontSize: AppDimens.fontSizeXs,
                            color: AppColors.textDarkHint,
                          ),
                        ),
                      ],
                    ],
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
