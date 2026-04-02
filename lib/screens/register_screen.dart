import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import '../services/user_data_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../widgets/windows_title_bar.dart';
import 'home_screen.dart';

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
    final setCookieHeaders = response.headers['set-cookie'];
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
      String sendCodeUrl = '$baseUrl/api/register/send-code';

      final response = await http.post(
        Uri.parse(sendCodeUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      setState(() {
        _isSendingCode = false;
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['ok'] == true) {
          _showToast('验证码已发送到您的邮箱', const Color(0xFF27ae60));
          _startCountdown();
        } else {
          _showToast(
              responseData['error'] ?? '发送验证码失败', const Color(0xFFe74c3c));
        }
      } else {
        final responseData = json.decode(response.body);
        _showToast(responseData['error'] ?? '发送验证码失败', const Color(0xFFe74c3c));
      }
    } catch (e) {
      setState(() {
        _isSendingCode = false;
      });
      _showToast('网络异常，请稍后重试', const Color(0xFFe74c3c));
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final verificationCode = _verificationCodeController.text.trim();

    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      _showToast('用户名只能包含字母、数字和下划线，长度3-20位', const Color(0xFFe74c3c));
      return;
    }

    if (password.length < 6) {
      _showToast('密码长度至少6位', const Color(0xFFe74c3c));
      return;
    }

    if (password != confirmPassword) {
      _showToast('两次输入的密码不一致', const Color(0xFFe74c3c));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String baseUrl = await UserDataService.getServerUrlWithDefault();
      String registerUrl = '$baseUrl/api/register';

      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'verificationCode': verificationCode,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      switch (response.statusCode) {
        case 200:
          try {
            final responseData = json.decode(response.body);
            final token = responseData['token'] as String?;
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

          await UserDataService.saveIsLocalMode(false);

          if (mounted) {
            _showToast('注册成功！', const Color(0xFF27ae60));
            await Future.delayed(const Duration(milliseconds: 500));
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
                responseData['error'] ?? '注册失败', const Color(0xFFe74c3c));
          } catch (e) {
            _showToast('注册失败', const Color(0xFFe74c3c));
          }
          break;
        case 403:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData['error'] ?? '注册功能已关闭', const Color(0xFFe74c3c));
          } catch (e) {
            _showToast('注册功能已关闭', const Color(0xFFe74c3c));
          }
          break;
        case 429:
          try {
            final responseData = json.decode(response.body);
            _showToast(
                responseData['error'] ?? '操作过于频繁', const Color(0xFFe74c3c));
          } catch (e) {
            _showToast('操作过于频繁', const Color(0xFFe74c3c));
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextFormField(
              controller: _verificationCodeController,
              keyboardType: TextInputType.number,
              style: FontUtils.poppins(
                fontSize: 16,
                color: const Color(0xFF2c3e50),
              ),
              decoration: _buildInputDecoration(
                labelText: '验证码',
                hintText: '请输入验证码',
                prefixIcon: Icons.verified_user,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入验证码';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed:
                (_isSendingCode || _countdown > 0) ? null : _handleSendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isSendingCode || _countdown > 0)
                  ? const Color(0xFFbdc3c7)
                  : const Color(0xFF2c3e50),
              foregroundColor: (_isSendingCode || _countdown > 0)
                  ? const Color(0xFF7f8c8d)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isSendingCode
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _countdown > 0 ? '${_countdown}s' : '获取验证码',
                    style: FontUtils.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 0 : 32.0,
                      vertical: 24.0,
                    ),
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
          '创建您的新账户',
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
                controller: _usernameController,
                style: FontUtils.poppins(
                  fontSize: 16,
                  color: const Color(0xFF2c3e50),
                ),
                decoration: _buildInputDecoration(
                  labelText: '用户名',
                  hintText: '3-20位字母数字下划线',
                  prefixIcon: Icons.person,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
                    return '用户名只能包含字母、数字和下划线，长度3-20位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱地址';
                  }
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                    return '请输入有效的邮箱地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildVerificationCodeField(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: FontUtils.poppins(
                  fontSize: 16,
                  color: const Color(0xFF2c3e50),
                ),
                decoration: _buildInputDecoration(
                  labelText: '密码',
                  hintText: '至少6位字符',
                  prefixIcon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF7f8c8d),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码长度至少6位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: FontUtils.poppins(
                  fontSize: 16,
                  color: const Color(0xFF2c3e50),
                ),
                decoration: _buildInputDecoration(
                  labelText: '确认密码',
                  hintText: '再次输入密码',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF7f8c8d),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请再次输入密码';
                  }
                  if (value != _passwordController.text) {
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    (_isLoading || !_isFormValid) ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid && !_isLoading
                      ? const Color(0xFF2c3e50)
                      : const Color(0xFFbdc3c7),
                  foregroundColor: _isFormValid && !_isLoading
                      ? Colors.white
                      : const Color(0xFF7f8c8d),
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
                            '注册中...',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '注册',
                        style: FontUtils.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '已有账户？',
                    style: FontUtils.poppins(
                      fontSize: 14,
                      color: const Color(0xFF7f8c8d),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '立即登录',
                      style: FontUtils.poppins(
                        fontSize: 14,
                        color: const Color(0xFF2c3e50),
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
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
            '创建您的新账户',
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
                  controller: _usernameController,
                  style: FontUtils.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: _buildInputDecoration(
                    labelText: '用户名',
                    hintText: '3-20位字母数字下划线',
                    prefixIcon: Icons.person,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value)) {
                      return '用户名只能包含字母、数字和下划线，长度3-20位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: _buildInputDecoration(
                    labelText: '密码',
                    hintText: '至少6位字符',
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF7f8c8d),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 6) {
                      return '密码长度至少6位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: _buildInputDecoration(
                    labelText: '确认密码',
                    hintText: '再次输入密码',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF7f8c8d),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请再次输入密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildVerificationCodeField(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed:
                      (_isLoading || !_isFormValid) ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid && !_isLoading
                        ? const Color(0xFF2c3e50)
                        : const Color(0xFFbdc3c7),
                    foregroundColor: _isFormValid && !_isLoading
                        ? Colors.white
                        : const Color(0xFF7f8c8d),
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
                              '注册中...',
                              style: FontUtils.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '注册',
                          style: FontUtils.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '已有账户？',
                      style: FontUtils.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7f8c8d),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        '立即登录',
                        style: FontUtils.poppins(
                          fontSize: 14,
                          color: const Color(0xFF2c3e50),
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
