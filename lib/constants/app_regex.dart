/// 应用统一正则表达式常量
class AppRegex {
  AppRegex._();

  /// 邮箱基本格式验证
  static const String email = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';

  /// 验证码（6位数字）
  static const String verificationCode = r'^\d{6}$';

  /// 登录用户名允许的字符（字母、数字、下划线、点、@、中文），至少1个字符
  static const String usernameLogin = r'^[a-zA-Z0-9_.@\u4e00-\u9fa5]+$';

  /// 注册用户名允许的字符（字母、数字、中文），至少1个字符
  static const String usernameRegister = r'^[a-zA-Z0-9\u4e00-\u9fa5]+$';

  /// 邮箱输入框允许的字符
  static const String emailInput = r'^[a-zA-Z0-9.@]*$';

  /// HTTP/HTTPS 开头协议匹配
  static const String httpPrefix = r'^https?://';

  /// 手机号（中国大陆）
  static const String phone = r'^1[3-9]\d{9}$';

  /// 通用URL
  static const String url = r'^https?://[\w\-]+(\.[\w\-]+)+[/#?]?.*$';

  /// 密码强度（至少8位，含字母和数字）
  static const String strongPassword = r'^(?=.*[a-zA-Z])(?=.*\d).{8,}$';

  // ── HTML 实体 ──
  static const String htmlNumericEntity = r'&#(\d+);';
  static const String htmlHexEntity = r'&#x([0-9a-fA-F]+);';

  // ── M3U8 相关 ──
  static const String m3u8Url = r'https?://[^\s<>"]+\.m3u8';
  static const String ffzySource = r'\$(https?://[^"\x27\s]+?/\d{8}/\d+_[a-f0-9]+/index\.m3u8)';
  static const String generalM3u8 = r'\$(https?://[^"\x27\s]+?\.m3u8)';

  // ── 文件名 ──
  static const String invalidFilenameChars = r'[\\/:*?"<>|]';
  static const String tsFilePattern = r'^(.+)_第(\d+)集_(\d+)\.ts$';
  static const String tsFilePatternAlt = r'^(.+)_(\d+)\.ts$';

  // ── 年份 ──
  static const String yearPattern = r'(\d{4})';

  // ── HTML 解析 ──
  static const String htmlTitle = r'<h1[^>]*>([^<]+)</h1>';
  static const String htmlDescription = r'<div[^>]*class=["\x27]sketch["\x27][^>]*>([\s\S]*?)</div>';
  static const String htmlCoverImage = r'(https?://[^"\x27\s]+?\.jpg)';
  static const String htmlYear = r'>(\d{4})<';

  // ── URL 分隔符 ──
  static const String sourceSeparator = r'\$\$\$';
  static const String urlHashSeparator = '#';
  static const String urlDollarSeparator = r'\$';

  // ── HTML 清理 ──
  static const String htmlTag = r'<[^>]+>';
  static const String newlines = r'\n+';
  static const String trimNewlines = r'^\n+|\n+$';
  static const String whitespace = r'[ \t]+';

  // ── 中文字符 ──
  static const String chineseChars = r'[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]';

  // ── 输入过滤 ──
  static const String nonDigits = r'[^0-9]';
  static const String emailInputChars = r'[^a-zA-Z0-9.@]';
  static const String loginUsernameFilterChars = r'[^a-zA-Z0-9_.@\u4e00-\u9fa5]';
  static const String registerUsernameFilterChars = r'[^a-zA-Z0-9\u4e00-\u9fa5]';

  // ── 字符集 ──
  static const String charset = r'charset=([^;]+)';
}
