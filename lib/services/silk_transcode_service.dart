import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// SILK 音频转码服务
/// 将微信语音的 SILK 格式转换为 WAV 格式
class SilkTranscodeService {
  static const int _silkSampleRate = 24000;

  /// 将 SILK 音频缓冲区转换为 WAV 格式
  /// 返回 WAV 缓冲区，如果转码失败则返回 null
  static Future<Uint8List?> silkToWav(Uint8List silkBuf) async {
    try {
      // 尝试使用系统工具进行转码
      final pcmData = await _decodeSilk(silkBuf);
      if (pcmData == null) {
        return null;
      }

      // 将 PCM 数据包装为 WAV 格式
      return _pcmToWav(pcmData, _silkSampleRate);
    } catch (e) {
      return null;
    }
  }

  /// 使用外部工具解码 SILK
  static Future<Uint8List?> _decodeSilk(Uint8List silkBuf) async {
    // 创建临时文件
    final tempDir = Directory.systemTemp;
    final random = Random().nextInt(10000000000);
    final inputFile = File(p.join(tempDir.path, 'input_$random.silk'));
    final outputFile = File(p.join(tempDir.path, 'output_$random.pcm'));

    try {
      // 写入 SILK 文件
      await inputFile.writeAsBytes(silkBuf);

      // 尝试使用 ffmpeg 解码
      final result = await _runFfmpegDecode(inputFile.path, outputFile.path);
      if (result) {
        return await outputFile.readAsBytes();
      }

      // 降级：尝试其他方法或返回 null
      return null;
    } finally {
      // 清理临时文件
      if (inputFile.existsSync()) {
        await inputFile.delete();
      }
      if (outputFile.existsSync()) {
        await outputFile.delete();
      }
    }
  }

  /// 使用 ffmpeg 解码 SILK
  static Future<bool> _runFfmpegDecode(String inputPath, String outputPath) async {
    try {
      final process = await Process.start(
        'ffmpeg',
        [
          '-i', inputPath,
          '-f', 's16le',
          '-ar', '$_silkSampleRate',
          '-ac', '1',
          '-y',
          outputPath,
        ],
      );

      final exitCode = await process.exitCode;
      return exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 将 PCM 数据包装为 WAV 格式
  /// PCM 数据应为单声道、16位、小端序
  static Uint8List _pcmToWav(Uint8List pcmData, int sampleRate) {
    final pcmSize = pcmData.length;
    final totalSize = 44 + pcmSize;
    final buffer = ByteData(totalSize);
    var offset = 0;

    // RIFF 头
    _writeString(buffer, offset, 'RIFF');
    offset += 4;
    buffer.setUint32(offset, totalSize - 8, Endian.little);
    offset += 4;
    _writeString(buffer, offset, 'WAVE');
    offset += 4;

    // fmt 块
    _writeString(buffer, offset, 'fmt ');
    offset += 4;
    buffer.setUint32(offset, 16, Endian.little); // fmt chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM format
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); // byte rate
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little); // block align
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little); // bits per sample
    offset += 2;

    // data 块
    _writeString(buffer, offset, 'data');
    offset += 4;
    buffer.setUint32(offset, pcmSize, Endian.little);
    offset += 4;

    // PCM 数据
    for (int i = 0; i < pcmSize; i++) {
      buffer.setUint8(offset + i, pcmData[i]);
    }

    return buffer.buffer.asUint8List();
  }

  /// 向 ByteData 写入字符串
  static void _writeString(ByteData buffer, int offset, String string) {
    final bytes = utf8.encode(string);
    for (int i = 0; i < bytes.length; i++) {
      buffer.setUint8(offset + i, bytes[i]);
    }
  }
}