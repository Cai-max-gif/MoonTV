import '../constants/app_regex.dart';

/// HTML 处理工具类
class HtmlUtils {
  HtmlUtils._();

  static const Map<String, String> _htmlEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
    '&hellip;': '…',
    '&mdash;': '—',
    '&ndash;': '–',
    '&lsquo;': "'",
    '&rsquo;': "'",
    '&ldquo;': '"',
    '&rdquo;': '"',
    '&bull;': '•',
    '&middot;': '·',
  };

  static String decodeEntities(String text) {
    if (text.isEmpty) return text;

    String result = text;
    _htmlEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });

    result = result.replaceAllMapped(
      RegExp(AppRegex.htmlNumericEntity),
      (match) => String.fromCharCode(int.parse(match.group(1)!))
    );

    result = result.replaceAllMapped(
      RegExp(AppRegex.htmlHexEntity),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16))
    );

    return result;
  }

  static String stripTags(String text) {
    return text.replaceAll(RegExp(AppRegex.htmlTag), '');
  }

  static String trimNewlines(String text) {
    return text.replaceAll(RegExp(AppRegex.trimNewlines), '');
  }
}
