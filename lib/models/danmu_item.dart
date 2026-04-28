import 'dart:ui';

enum DanmuMode {
  scroll(0),
  top(1),
  bottom(2);

  final int value;
  const DanmuMode(this.value);

  static DanmuMode fromValue(int v) {
    switch (v) {
      case 1:
      case 4:
        return DanmuMode.top;
      case 2:
      case 5:
        return DanmuMode.bottom;
      default:
        return DanmuMode.scroll;
    }
  }
}

class DanmuItem {
  final String text;
  final double time;
  final Color? color;
  final DanmuMode mode;

  DanmuItem({
    required this.text,
    required this.time,
    this.color,
    this.mode = DanmuMode.scroll,
  });

  factory DanmuItem.fromJson(Map<String, dynamic> json) {
    return DanmuItem(
      text: json['text'] as String,
      time: (json['time'] as num).toDouble(),
      color: json['color'] != null
          ? _parseColor(json['color'] as String)
          : null,
      mode: DanmuMode.fromValue(json['mode'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'time': time,
      'color': color != null
          ? '#${color!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
          : null,
      'mode': mode.value,
    };
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
