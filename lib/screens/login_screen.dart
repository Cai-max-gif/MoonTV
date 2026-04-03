import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import '../services/user_data_service.dart';
import '../services/local_mode_storage_service.dart';
import '../services/subscription_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../widgets/windows_title_bar.dart';
import 'home_screen.dart';
import 'register_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _loadSavedUserData();
  }

  void _loadSavedUserData() async {
    final userData = await UserDataService.getAllUserData();
    bool hasData = false;

    if (userData['username'] != null) {
      _usernameController.text = userData['username']!;
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _usernameController.text.isNotEmpty;
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
    final setCookieHeaders = response.headers['set-cookie'];
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

  void _handleLogin() async {
    if (_formKey.currentState!.validate() &&
        _isFormValid &&
        _passwordController.text.isNotEmpty) {
      // 检查账户是否被锁定
      bool isLocked = await UserDataService.isAccountLocked();
      if (isLocked) {
        final remainingTime =
            await UserDataService.getAccountLockRemainingTime();
        if (remainingTime != null) {
          final minutes = remainingTime.inMinutes;
          _showToast('账户已被锁定，请${minutes}分钟后再试', const Color(0xFFe74c3c));
        } else {
          _showToast('账户已被锁定，请稍后再试', const Color(0xFFe74c3c));
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
            baseUrl.replaceAll(RegExp(r'^http://'), 'https://');
        String loginUrl = '$secureBaseUrl/api/login';

        // 发送登录请求
        final response = await http.post(
          Uri.parse(loginUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'username': _usernameController.text,
            'password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        // 根据状态码显示不同的消息
        switch (response.statusCode) {
          case 200:
            try {
              // 尝试解析响应获取令牌
              final responseData = json.decode(response.body);
              final token = responseData['token'] as String?;

              // 解析 cookies
              String cookies = _parseCookies(response);

              // 保存用户数据，优先使用令牌
              await UserDataService.saveUserData(
                username: _usernameController.text,
                password: _passwordController.text, // 保留密码用于自动登录
                token: token,
                cookies: cookies,
              );
            } catch (e) {
              // 如果解析失败，回退到传统的 cookies 方式
              String cookies = _parseCookies(response);

              // 保存用户数据
              await UserDataService.saveUserData(
                username: _usernameController.text,
                password: _passwordController.text,
                cookies: cookies,
              );
            }

            // 保存模式状态为服务器模式
            await UserDataService.saveIsLocalMode(false);

            // 跳转到首页，并清除所有路由栈（强制销毁所有旧页面）
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
            break;
          case 401:
            // 记录登录失败
            await UserDataService.recordLoginFailure();

            // 检查是否被锁定
            isLocked = await UserDataService.isAccountLocked();
            if (isLocked) {
              final remainingTime =
                  await UserDataService.getAccountLockRemainingTime();
              if (remainingTime != null) {
                final minutes = remainingTime.inMinutes;
                _showToast('用户名或密码错误，账户已被锁定，请${minutes}分钟后再试',
                    const Color(0xFFe74c3c));
              } else {
                _showToast('用户名或密码错误，账户已被锁定，请稍后再试', const Color(0xFFe74c3c));
              }
            } else {
              final attempts = await UserDataService.getLoginAttempts();
              final remainingAttempts = 5 - attempts;
              _showToast('用户名或密码错误，还有${remainingAttempts}次尝试机会',
                  const Color(0xFFe74c3c));
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
        // 记录登录失败
        await UserDataService.recordLoginFailure();
        _showToast('网络异常', const Color(0xFFe74c3c));
      }
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
              Color(0xFFe6f3fb), // #e6f3fb 0%
              Color(0xFFeaf3f7), // #eaf3f7 18%
              Color(0xFFf7f7f3), // #f7f7f3 38%
              Color(0xFFe9ecef), // #e9ecef 60%
              Color(0xFFdbe3ea), // #dbe3ea 80%
              Color(0xFFd3dde6), // #d3dde6 100%
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

  // 手机端布局（保持原样）
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo 图标
        Image.asset(
          'logo.png',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 20),
        // MoonTV 标题
        Text(
          'MoonTV',
          style: FontUtils.sourceCodePro(
            fontSize: 42,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF2c3e50),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 40),

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
                  fontSize: 16,
                  color: const Color(0xFF2c3e50),
                ),
                decoration: InputDecoration(
                  labelText: '用户名',
                  labelStyle: FontUtils.poppins(
                    color: const Color(0xFF7f8c8d),
                    fontSize: 14,
                  ),
                  hintText: '请输入用户名',
                  hintStyle: FontUtils.poppins(
                    color: const Color(0xFFbdc3c7),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF7f8c8d),
                    size: 20,
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
                  fillColor: Colors.white.withOpacity(0.6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 20),

              // 密码输入框
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: FontUtils.poppins(
                  fontSize: 16,
                  color: const Color(0xFF2c3e50),
                ),
                decoration: InputDecoration(
                  labelText: '密码',
                  labelStyle: FontUtils.poppins(
                    color: const Color(0xFF7f8c8d),
                    fontSize: 14,
                  ),
                  hintText: '请输入密码',
                  hintStyle: FontUtils.poppins(
                    color: const Color(0xFFbdc3c7),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: Color(0xFF7f8c8d),
                    size: 20,
                  ),
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
                  fillColor: Colors.white.withOpacity(0.6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 32),

              // 登录按钮
              ElevatedButton(
                onPressed: (_isLoading ||
                        !_isFormValid ||
                        _passwordController.text.isEmpty)
                    ? null
                    : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid &&
                          !_isLoading &&
                          _passwordController.text.isNotEmpty
                      ? const Color(0xFF2c3e50) // 与MoonTV logo相同的颜色
                      : const Color(0xFFbdc3c7), // 禁用时的浅灰色
                  foregroundColor: _isFormValid &&
                          !_isLoading &&
                          _passwordController.text.isNotEmpty
                      ? Colors.white
                      : const Color(0xFF7f8c8d), // 禁用时的文字颜色
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
                          SizedBox(
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
                            '登录中...',
                            style: FontUtils.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '登录',
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有账户？',
              style: FontUtils.poppins(
                fontSize: 14,
                color: const Color(0xFF7f8c8d),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen()),
                );
              },
              child: Text(
                '立即注册',
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
    );
  }

  // 平板端布局（与手机端风格一致，只是限制宽度）
  Widget _buildTabletLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo 图标
          Image.asset(
            'logo.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 20),
          // MoonTV 标题
          Text(
            'MoonTV',
            style: FontUtils.sourceCodePro(
              fontSize: 42,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2c3e50),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 40),

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
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: InputDecoration(
                    labelText: '用户名',
                    labelStyle: FontUtils.poppins(
                      color: const Color(0xFF7f8c8d),
                      fontSize: 14,
                    ),
                    hintText: '请输入用户名',
                    hintStyle: FontUtils.poppins(
                      color: const Color(0xFFbdc3c7),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFF7f8c8d),
                      size: 20,
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
                    fillColor: Colors.white.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: 20),

                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: FontUtils.poppins(
                    fontSize: 16,
                    color: const Color(0xFF2c3e50),
                  ),
                  decoration: InputDecoration(
                    labelText: '密码',
                    labelStyle: FontUtils.poppins(
                      color: const Color(0xFF7f8c8d),
                      fontSize: 14,
                    ),
                    hintText: '请输入密码',
                    hintStyle: FontUtils.poppins(
                      color: const Color(0xFFbdc3c7),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFF7f8c8d),
                      size: 20,
                    ),
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
                    fillColor: Colors.white.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                ),
                const SizedBox(height: 32),

                // 登录按钮
                ElevatedButton(
                  onPressed: (_isLoading ||
                          !_isFormValid ||
                          _passwordController.text.isEmpty)
                      ? null
                      : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid &&
                            !_isLoading &&
                            _passwordController.text.isNotEmpty
                        ? const Color(0xFF2c3e50)
                        : const Color(0xFFbdc3c7),
                    foregroundColor: _isFormValid &&
                            !_isLoading &&
                            _passwordController.text.isNotEmpty
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
                              '登录中...',
                              style: FontUtils.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '登录',
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '没有账户？',
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7f8c8d),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: Text(
                  '立即注册',
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
    );
  }
}
