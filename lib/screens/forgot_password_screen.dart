import 'package:flutter/material.dart';
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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showToast('请输入邮箱地址', const Color(0xFFe74c3c));
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showToast('请输入有效的邮箱地址', const Color(0xFFe74c3c));
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      String baseUrl = await UserDataService.getServerUrlWithDefault();
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(r'^http://'), 'https://');
      String sendCodeUrl = '$secureBaseUrl/api/send-verification-code';

      final response = await http.post(
        Uri.parse(sendCodeUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email, 'type': 'reset'}),
      );

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
            _showToast('验证码已发送到您的邮箱', const Color(0xFF27ae60));
            _startCountdown();
          } else {
            _showToast(
                responseData['error'] ?? responseData['message'] ?? '发送验证码失败',
                const Color(0xFFe74c3c));
          }
        } catch (e) {
          _showToast('服务器响应格式异常', const Color(0xFFe74c3c));
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          _showToast(
              responseData['error'] ?? responseData['message'] ?? '发送验证码失败',
              const Color(0xFFe74c3c));
        } catch (e) {
          _showToast(
              '发送验证码失败 (${response.statusCode})', const Color(0xFFe74c3c));
        }
      }
    } catch (e) {
      setState(() {
        _isSendingCode = false;
      });
      _showToast('网络异常，请稍后重试', const Color(0xFFe74c3c));
    }
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      _showToast('请填写完整的信息', const Color(0xFFe74c3c));
      return;
    }

    final email = _emailController.text.trim();
    final verificationCode = _verificationCodeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showToast('请输入有效的邮箱地址', const Color(0xFFe74c3c));
      return;
    }

    if (newPassword.length < 6) {
      _showToast('密码长度至少6位', const Color(0xFFe74c3c));
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(verificationCode)) {
      _showToast('验证码格式错误，应为6位数字', const Color(0xFFe74c3c));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String baseUrl = await UserDataService.getServerUrlWithDefault();
      String secureBaseUrl =
          baseUrl.replaceAll(RegExp(r'^http://'), 'https://');
      String resetUrl = '$secureBaseUrl/api/reset-password';

      final response = await http.post(
        Uri.parse(resetUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'verificationCode': verificationCode,
          'newPassword': newPassword,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      switch (response.statusCode) {
        case 200:
          _showToast('密码重置成功！', const Color(0xFF27ae60));
          await Future.delayed(const Duration(milliseconds: 500));
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
                responseData['error'] ?? responseData['message'] ?? '重置失败',
                const Color(0xFFe74c3c));
          } catch (e) {
            _showToast('重置失败', const Color(0xFFe74c3c));
          }
          break;
        case 404:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData['error'] ?? responseData['message'] ?? '邮箱未注册',
                const Color(0xFFe74c3c));
          } catch (e) {
            _showToast('邮箱未注册', const Color(0xFFe74c3c));
          }
          break;
        case 500:
          _showToast('服务器错误', const Color(0xFFe74c3c));
          break;
        default:
          _showToast('网络异常', const Color(0xFFe74c3c));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast('网络异常', const Color(0xFFe74c3c));
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
        color: const Color(0xFF7f8c8d),
        fontSize: 14,
      ),
      hintText: hintText,
      hintStyle: FontUtils.poppins(
        color: const Color(0xFFbdc3c7),
        fontSize: 16,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF7f8c8d),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }

  Widget _buildVerificationCodeField() {
    return TextFormField(
      controller: _verificationCodeController,
      keyboardType: TextInputType.number,
      style: FontUtils.poppins(
        fontSize: 16,
        color: const Color(0xFF2c3e50),
      ),
      decoration: InputDecoration(
        labelText: '验证码',
        labelStyle: FontUtils.poppins(
          color: const Color(0xFF7f8c8d),
          fontSize: 14,
        ),
        hintText: '请输入6位数字验证码',
        hintStyle: FontUtils.poppins(
          color: const Color(0xFFbdc3c7),
          fontSize: 16,
        ),
        prefixIcon: const Icon(
          Icons.verified_user,
          color: Color(0xFF7f8c8d),
          size: 20,
        ),
        suffixIcon: Material(
          color: Colors.transparent,
          child: TextButton(
            onPressed:
                (_isSendingCode || _countdown > 0) ? null : _handleSendCode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              backgroundColor: Colors.transparent,
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
                          AlwaysStoppedAnimation<Color>(Color(0xFF2c3e50)),
                    ),
                  )
                : Text(
                    _countdown > 0 ? '${_countdown}s' : '获取验证码',
                    style: FontUtils.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: (_countdown > 0)
                          ? const Color(0xFF7f8c8d)
                          : const Color(0xFF2c3e50),
                    ),
                  ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
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
          return '请输入验证码';
        }
        if (!RegExp(r'^\d{6}$').hasMatch(value)) {
          return '验证码必须为6位数字';
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
              Color(0xFFe6f3fb),
              Color(0xFFeaf3f7),
              Color(0xFFf7f7f3),
              Color(0xFFe9ecef),
              Color(0xFFdbe3ea),
              Color(0xFFd3dde6),
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
            'logo.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 20),
          Text(
            'MoonTV',
            style: FontUtils.sourceCodePro(
              fontSize: 42,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2c3e50),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '重置您的密码',
            style: FontUtils.poppins(
              fontSize: 14,
              color: const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: FontUtils.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: _buildInputDecoration(
                    labelText: '邮箱',
                    hintText: '请输入邮箱地址',
                    prefixIcon: Icons.email,
                  ),
                  onChanged: (value) {
                    final isValidChar = RegExp(r'^[a-zA-Z0-9.@]*$');
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
                      return '请输入邮箱地址';
                    }
                    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(value)) {
                      return '请输入有效的邮箱地址';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildVerificationCodeField(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: _buildInputDecoration(
                    labelText: '新密码',
                    hintText: '请输入密码',
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF7f8c8d),
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
                      return '请输入新密码';
                    }
                    if (value.length < 6) {
                      return '密码长度至少6位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '登录',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: const Color(0xFF2c3e50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        '注册',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: const Color(0xFF2c3e50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? const Color(0xFFbdc3c7)
                        : const Color(0xFF2c3e50),
                    foregroundColor:
                        _isLoading ? const Color(0xFF7f8c8d) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
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
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '重置中...',
                              style: FontUtils.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '重置密码',
                          style: FontUtils.poppins(
                            fontSize: 16,
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
