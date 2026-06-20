/// 流式 Markdown 过滤器 - 逐字符处理，过滤不支持的 Markdown 语法
///
/// 通过的构造：
/// - 代码块 (```)
/// - 行内代码 (`)
/// - 表格 (|...|)
/// - 分割线 (---, ***, ___)
/// - 粗体 (**)
/// - 斜体/粗斜体包裹的非 CJK 内容
///
/// 过滤的构造（标记被移除，内容保留）：
/// - 包裹 CJK 内容的斜体/粗斜体
/// - H5/H6 标题 (#####, ######)
/// - 图片 (![alt](url)) - 完全移除
///
/// 状态：
/// - **sol** (start-of-line): 检查行首模式 (```, >, #####, 缩进)
/// - **body**: 扫描行内模式 (![, ~~, ***) 并输出安全字符
/// - **fence**: 在代码块内，原样传递直到结束的 ```
/// - **inline**: 累积行内标记对内的内容
class StreamingMarkdownFilter {
  String _buf = '';
  bool _fence = false;
  bool _sol = true;
  _InlineState? _inl;

  /// 传入增量文本，返回过滤后的文本
  String feed(String delta) {
    _buf += delta;
    return _pump(false);
  }

  /// 刷新缓冲区，返回所有剩余文本
  String flush() {
    return _pump(true);
  }

  String _pump(bool eof) {
    String out = '';
    while (_buf.isNotEmpty) {
      final sLen = _buf.length;
      final sSol = _sol;
      final sFence = _fence;
      final sInl = _inl;

      if (_fence) {
        out += _pumpFence(eof);
      } else if (_inl != null) {
        out += _pumpInline(eof);
      } else if (_sol) {
        out += _pumpSOL(eof);
      } else {
        out += _pumpBody(eof);
      }

      if (_buf.length == sLen &&
          _sol == sSol &&
          _fence == sFence &&
          _inl == sInl) {
        break;
      }
    }

    if (eof && _inl != null) {
      final markers = {
        'image': '![',
        'bold3': '***',
        'italic': '*',
        'ubold3': '___',
        'uitalic': '_',
      };
      out += (markers[_inl!.type] ?? '') + _inl!.acc;
      _inl = null;
    }
    return out;
  }

  /// 在代码块内：原样传递内容和标记
  String _pumpFence(bool eof) {
    if (_sol) {
      if (_buf.length < 3 && !eof) return '';
      if (_buf.startsWith('```')) {
        final nl = _buf.indexOf('\n', 3);
        if (nl != -1) {
          _fence = false;
          final line = _buf.substring(0, nl + 1);
          _buf = _buf.substring(nl + 1);
          _sol = true;
          return line;
        }
        if (eof) {
          _fence = false;
          final line = _buf;
          _buf = '';
          return line;
        }
        return '';
      }
      _sol = false;
    }
    final nl = _buf.indexOf('\n');
    if (nl != -1) {
      final chunk = _buf.substring(0, nl + 1);
      _buf = _buf.substring(nl + 1);
      _sol = true;
      return chunk;
    }
    final chunk = _buf;
    _buf = '';
    return chunk;
  }

  /// 在行首：检测和消费行首模式，然后转换到 body
  String _pumpSOL(bool eof) {
    final b = _buf;

    if (b[0] == '\n') {
      _buf = b.substring(1);
      return '\n';
    }

    if (b[0] == '`') {
      if (b.length < 3 && !eof) return '';
      if (b.startsWith('```')) {
        final nl = b.indexOf('\n', 3);
        if (nl != -1) {
          _fence = true;
          final line = b.substring(0, nl + 1);
          _buf = b.substring(nl + 1);
          _sol = true;
          return line;
        }
        if (eof) {
          _buf = '';
          return b;
        }
        return '';
      }
      _sol = false;
      return '';
    }

    if (b[0] == '>') {
      _sol = false;
      return '';
    }

    if (b[0] == '#') {
      int n = 0;
      while (n < b.length && b[n] == '#') {
        n++;
      }
      if (n == b.length && !eof) return '';
      if (n >= 5 && n <= 6 && n < b.length && b[n] == ' ') {
        _buf = b.substring(n + 1);
        _sol = false;
        return '';
      }
      _sol = false;
      return '';
    }

    if (b[0] == ' ' || b[0] == '\t') {
      if (RegExp(r'[^ \t]').hasMatch(b) == false && !eof) return '';
      _sol = false;
      return '';
    }

    if (b[0] == '-' || b[0] == '*' || b[0] == '_') {
      final ch = b[0];
      int j = 0;
      while (j < b.length && (b[j] == ch || b[j] == ' ')) {
        j++;
      }
      if (j == b.length && !eof) return '';
      if (j == b.length || b[j] == '\n') {
        int count = 0;
        for (int k = 0; k < j; k++) {
          if (b[k] == ch) count++;
        }
        if (count >= 3) {
          if (j < b.length) {
            _buf = b.substring(j + 1);
            _sol = true;
            return b.substring(0, j + 1);
          }
          _buf = '';
          return b;
        }
      }
      _sol = false;
      return '';
    }

    _sol = false;
    return '';
  }

  /// 扫描行体以获取内联模式触发器；急切地输出安全字符
  String _pumpBody(bool eof) {
    String out = '';
    int i = 0;
    while (i < _buf.length) {
      final c = _buf[i];
      if (c == '\n') {
        out += _buf.substring(0, i + 1);
        _buf = _buf.substring(i + 1);
        _sol = true;
        return out;
      }
      if (c == '!' && i + 1 < _buf.length && _buf[i + 1] == '[') {
        out += _buf.substring(0, i);
        _buf = _buf.substring(i + 2);
        _inl = _InlineState('image', '');
        return out;
      }
      if (c == '~') {
        i++;
        continue;
      }
      if (c == '*') {
        if (i + 2 < _buf.length && _buf[i + 1] == '*' && _buf[i + 2] == '*') {
          out += _buf.substring(0, i);
          _buf = _buf.substring(i + 3);
          _inl = _InlineState('bold3', '');
          return out;
        }
        if (i + 1 < _buf.length && _buf[i + 1] == '*') {
          i += 2;
          continue;
        }
        if (i + 1 < _buf.length &&
            _buf[i + 1] != ' ' &&
            _buf[i + 1] != '\n') {
          out += _buf.substring(0, i);
          _buf = _buf.substring(i + 1);
          _inl = _InlineState('italic', '');
          return out;
        }
        i++;
        continue;
      }
      if (c == '_') {
        if (i + 2 < _buf.length && _buf[i + 1] == '_' && _buf[i + 2] == '_') {
          out += _buf.substring(0, i);
          _buf = _buf.substring(i + 3);
          _inl = _InlineState('ubold3', '');
          return out;
        }
        if (i + 1 < _buf.length && _buf[i + 1] == '_') {
          i += 2;
          continue;
        }
        if (i + 1 < _buf.length &&
            _buf[i + 1] != ' ' &&
            _buf[i + 1] != '\n') {
          out += _buf.substring(0, i);
          _buf = _buf.substring(i + 1);
          _inl = _InlineState('uitalic', '');
          return out;
        }
        i++;
        continue;
      }
      i++;
    }

    int hold = 0;
    if (!eof) {
      if (_buf.endsWith('**')) {
        hold = 2;
      } else if (_buf.endsWith('__')) {
        hold = 2;
      } else if (_buf.endsWith('*')) {
        hold = 1;
      } else if (_buf.endsWith('_')) {
        hold = 1;
      } else if (_buf.endsWith('!')) {
        hold = 1;
      }
    }
    out += _buf.substring(0, _buf.length - hold);
    _buf = hold > 0 ? _buf.substring(_buf.length - hold) : '';
    return out;
  }

  /// 累积行内内容直到找到结束标记
  String _pumpInline(bool eof) {
    if (_inl == null) return '';
    _inl!.acc += _buf;
    _buf = '';

    switch (_inl!.type) {
      case 'bold3':
        final idx = _inl!.acc.indexOf('***');
        if (idx != -1) {
          final content = _inl!.acc.substring(0, idx);
          _buf = _inl!.acc.substring(idx + 3);
          _inl = null;
          if (_containsCJK(content)) return content;
          return '***$content***';
        }
        return '';

      case 'ubold3':
        final idx = _inl!.acc.indexOf('___');
        if (idx != -1) {
          final content = _inl!.acc.substring(0, idx);
          _buf = _inl!.acc.substring(idx + 3);
          _inl = null;
          if (_containsCJK(content)) return content;
          return '___${content}___';
        }
        return '';

      case 'italic':
        for (int j = 0; j < _inl!.acc.length; j++) {
          if (_inl!.acc[j] == '\n') {
            final r = '*${_inl!.acc.substring(0, j + 1)}';
            _buf = _inl!.acc.substring(j + 1);
            _inl = null;
            _sol = true;
            return r;
          }
          if (_inl!.acc[j] == '*') {
            if (j + 1 < _inl!.acc.length && _inl!.acc[j + 1] == '*') {
              j++;
              continue;
            }
            final content = _inl!.acc.substring(0, j);
            _buf = _inl!.acc.substring(j + 1);
            _inl = null;
            if (_containsCJK(content)) return content;
            return '*$content*';
          }
        }
        return '';

      case 'uitalic':
        for (int j = 0; j < _inl!.acc.length; j++) {
          if (_inl!.acc[j] == '\n') {
            final r = '_${_inl!.acc.substring(0, j + 1)}';
            _buf = _inl!.acc.substring(j + 1);
            _inl = null;
            _sol = true;
            return r;
          }
          if (_inl!.acc[j] == '_') {
            if (j + 1 < _inl!.acc.length && _inl!.acc[j + 1] == '_') {
              j++;
              continue;
            }
            final content = _inl!.acc.substring(0, j);
            _buf = _inl!.acc.substring(j + 1);
            _inl = null;
            if (_containsCJK(content)) return content;
            return '_${content}_';
          }
        }
        return '';

      case 'image':
        final cb = _inl!.acc.indexOf(']');
        if (cb == -1) return '';
        if (cb + 1 >= _inl!.acc.length) return '';
        if (_inl!.acc[cb + 1] != '(') {
          final r = '![${_inl!.acc.substring(0, cb + 1)}';
          _buf = _inl!.acc.substring(cb + 1);
          _inl = null;
          return r;
        }
        final cp = _inl!.acc.indexOf(')', cb + 2);
        if (cp != -1) {
          _buf = _inl!.acc.substring(cp + 1);
          _inl = null;
          return '';
        }
        return '';

      default:
        return '';
    }
  }

  bool _containsCJK(String text) {
    return RegExp(r'[\u2E80-\u9FFF\uAC00-\uD7AF\uF900-\uFAFF]').hasMatch(text);
  }
}

/// 行内状态
class _InlineState {
  final String type;
  String acc;

  _InlineState(this.type, this.acc);
}
