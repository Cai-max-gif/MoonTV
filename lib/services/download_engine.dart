import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pointycastle/export.dart';

class M3U8Segment {
  final String url;
  final double duration;

  M3U8Segment({required this.url, required this.duration});
}

class M3U8ParseResult {
  final List<M3U8Segment> segments;
  final String? keyUrl;
  final Uint8List? keyBytes;
  final String? ivString;

  M3U8ParseResult({
    required this.segments,
    this.keyUrl,
    this.keyBytes,
    this.ivString,
  });

  bool get isEncrypted => keyUrl != null || keyBytes != null;
}

class DownloadEngine {
  final Dio _dio;
  bool _cancelled = false;

  DownloadEngine({Dio? dio, String? referer, String? origin})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': '*/*',
                'Accept-Language': 'zh-CN,zh;q=0.9',
                if (referer != null) 'Referer': referer,
                if (origin != null) 'Origin': origin,
              },
            ));

  void cancel() {
    _cancelled = true;
  }

  Map<String, dynamic> _mergeHeaders(Map<String, String>? customHeaders) {
    final mergedHeaders = <String, dynamic>{..._dio.options.headers};
    if (customHeaders != null) {
      mergedHeaders.addAll(customHeaders);
    }
    return mergedHeaders;
  }

  Future<String> download({
    required String m3u8Url,
    required String savePath,
    required int concurrentThreads,
    required void Function(double progress, int downloadedBytes, int totalBytes)
        onProgress,
    Map<String, String>? headers,
  }) async {
    _cancelled = false;

    final parseResult = await _parseM3U8(m3u8Url, headers: headers);

    if (_cancelled) throw Exception('下载已取消');

    if (parseResult.segments.isEmpty) {
      throw Exception('未解析到任何视频片段，可能不是有效的 M3U8 地址');
    }

    final totalSegments = parseResult.segments.length;

    final tempDir = Directory('${savePath}_temp');
    await _safeCreateDir(tempDir);

    final alreadyDone = <int>{};
    if (await tempDir.exists()) {
      final entries = await tempDir.list().toList();
      for (final entry in entries) {
        if (entry is File) {
          final name = entry.path.split(Platform.pathSeparator).last;
          if (name.startsWith('seg_') && name.endsWith('.ts')) {
            final idxStr = name.substring(4, name.length - 3);
            final idx = int.tryParse(idxStr);
            if (idx != null && idx >= 0 && idx < totalSegments) {
              alreadyDone.add(idx);
            }
          }
        }
      }
    }

    Uint8List? keyBytes;
    if (parseResult.keyUrl != null && parseResult.keyBytes == null) {
      try {
        keyBytes = await _downloadKey(parseResult.keyUrl!, headers: headers);
      } catch (e) {
        await _cleanupTemp(tempDir);
        throw Exception('下载解密密钥失败: $e');
      }
      if (_cancelled) {
        await _cleanupTemp(tempDir);
        throw Exception('下载已取消');
      }
    } else {
      keyBytes = parseResult.keyBytes;
    }

    int totalBytes = 0;
    int downloadedSegments = alreadyDone.length;

    for (final idx in alreadyDone) {
      final f = File(_segmentPath(tempDir, idx));
      if (await f.exists()) {
        totalBytes += await f.length();
      }
    }

    final int initialDone = alreadyDone.length;
    if (initialDone > 0) {
      _safeProgressCallback(
          onProgress, initialDone / totalSegments, totalBytes, totalBytes);
    }

    final semaphore = _Semaphore(concurrentThreads);
    bool hasFailed = false;

    final List<Future<void>> downloadFutures = [];
    for (int i = 0; i < totalSegments; i++) {
      if (alreadyDone.contains(i)) continue;

      final segment = parseResult.segments[i];
      final segmentIndex = i;
      final segmentPath = _segmentPath(tempDir, i);

      final future = semaphore.withPermit(() async {
        if (_cancelled || hasFailed) return;

        int segSize = 0;
        try {
          segSize = await _downloadSegment(
            url: segment.url,
            savePath: segmentPath,
            keyBytes: keyBytes,
            ivString: parseResult.ivString,
            segmentIndex: segmentIndex,
            headers: headers,
          );
        } catch (_) {
          hasFailed = true;
          return;
        }

        if (_cancelled) return;

        totalBytes += segSize;
        downloadedSegments++;

        final progress = downloadedSegments / totalSegments;
        _safeProgressCallback(onProgress, progress, totalBytes, totalBytes);
      });

      downloadFutures.add(future);
    }

    await Future.wait(downloadFutures);

    if (_cancelled) {
      await _cleanupTemp(tempDir);
      throw Exception('下载已取消');
    }

    if (hasFailed) {
      await _cleanupTemp(tempDir);
      throw Exception('下载失败：部分片段下载出错');
    }

    final allSegmentPaths = <String>[];
    for (int i = 0; i < totalSegments; i++) {
      allSegmentPaths.add(_segmentPath(tempDir, i));
    }

    int finalTotalBytes = 0;
    for (final segPath in allSegmentPaths) {
      final f = File(segPath);
      if (await f.exists()) {
        finalTotalBytes += await f.length();
      }
    }

    await _mergeSegments(allSegmentPaths, savePath);
    await _cleanupTemp(tempDir);

    _safeProgressCallback(onProgress, 1.0, finalTotalBytes, finalTotalBytes);
    return savePath;
  }

  String _segmentPath(Directory tempDir, int index) {
    return '${tempDir.path}${Platform.pathSeparator}seg_${index.toString().padLeft(6, '0')}.ts';
  }

  Future<void> _safeCreateDir(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  void _safeProgressCallback(
    void Function(double, int, int) callback,
    double progress,
    int downloaded,
    int total,
  ) {
    callback(progress, downloaded, total);
  }

  Future<M3U8ParseResult> _parseM3U8(String m3u8Url, {int depth = 0, Map<String, String>? headers}) async {
    if (depth > 5) {
      throw Exception('M3U8 解析层级过深，可能存在循环引用');
    }

    final requestOptions = Options(headers: _mergeHeaders(headers));
    final response = await _dio.get(m3u8Url, options: requestOptions);
    final content = response.data.toString();

    if (!content.startsWith('#EXTM3U')) {
      throw Exception('无效的 M3U8 链接');
    }

    if (content.contains('#EXT-X-STREAM-INF')) {
      final subPlaylistUrl = _extractSubPlaylistUrl(content, m3u8Url);
      if (subPlaylistUrl == null) {
        throw Exception('无法从主播放列表提取子播放列表');
      }
      return _parseM3U8(subPlaylistUrl, depth: depth + 1, headers: headers);
    }

    final lines = content.split('\n').map((l) => l.trim()).toList();

    String? keyUrl;
    Uint8List? keyBytes;
    String? ivString;
    final segments = <M3U8Segment>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('#EXT-X-KEY:')) {
        final method = _extractAttr(line, 'METHOD');
        if (method == 'AES-128') {
          keyUrl = _extractAttr(line, 'URI');

          final ivAttr = _extractAttr(line, 'IV');
          if (ivAttr != null) {
            ivString = ivAttr.startsWith('0x') ? ivAttr.substring(2) : ivAttr;
          }

          if (keyUrl != null) {
            keyUrl = _resolveUrl(keyUrl, m3u8Url);
          }
        }
      }

      if (line.startsWith('#EXTINF:')) {
        final duration = double.tryParse(
                line.substring('#EXTINF:'.length).split(',')[0].trim()) ??
            0.0;

        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          if (!nextLine.startsWith('#') && nextLine.isNotEmpty) {
            final resolvedUrl = _resolveUrl(nextLine, m3u8Url);
            segments.add(M3U8Segment(url: resolvedUrl, duration: duration));
          }
        }
      }
    }

    if (segments.isEmpty) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.startsWith('#') && line.isNotEmpty) {
          final resolvedUrl = _resolveUrl(line, m3u8Url);
          segments.add(M3U8Segment(url: resolvedUrl, duration: 0));
        }
      }
    }

    return M3U8ParseResult(
      segments: segments,
      keyUrl: keyUrl,
      keyBytes: keyBytes,
      ivString: ivString,
    );
  }

  String? _extractSubPlaylistUrl(String content, String baseUrl) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    
    String? bestUrl;
    int bestBandwidth = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.startsWith('#EXT-X-STREAM-INF')) {
        final bandwidthMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
        final bandwidth = bandwidthMatch != null 
            ? int.parse(bandwidthMatch.group(1)!) 
            : 0;

        String? url;
        
        final streamInfEnd = line.indexOf(',');
        if (streamInfEnd != -1) {
          final remaining = line.substring(streamInfEnd + 1).trim();
          if (remaining.isNotEmpty && !remaining.startsWith('#')) {
            url = remaining;
          }
        }
        
        if (url == null && i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            url = nextLine;
          }
        }

        if (url != null) {
          final resolvedUrl = _resolveUrl(url, baseUrl);
          if (bandwidth > bestBandwidth) {
            bestBandwidth = bandwidth;
            bestUrl = resolvedUrl;
          }
        }
      }
    }
    
    return bestUrl;
  }

  String? _extractAttr(String line, String attrName) {
    final pattern = RegExp('$attrName=("([^"]*)"|([^,]*))');
    final match = pattern.firstMatch(line);
    if (match != null) {
      return match.group(2) ?? match.group(3);
    }
    return null;
  }

  Future<Uint8List> _downloadKey(String keyUrl, {Map<String, String>? headers}) async {
    final requestOptions = Options(
      responseType: ResponseType.bytes,
      headers: _mergeHeaders(headers),
    );
    final response = await _dio.get(keyUrl, options: requestOptions);
    return Uint8List.fromList(response.data as List<int>);
  }

  Future<int> _downloadSegment({
    required String url,
    required String savePath,
    required Uint8List? keyBytes,
    required String? ivString,
    required int segmentIndex,
    Map<String, String>? headers,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final requestOptions = Options(
          responseType: ResponseType.stream,
          headers: _mergeHeaders(headers),
        );
        final response = await _dio.get(url, options: requestOptions);

        final responseStream = (response.data as ResponseBody).stream;

        if (keyBytes != null) {
          final tempPath = '$savePath._enc';
          await _streamToFile(responseStream, tempPath);
          final encryptedFile = File(tempPath);
          try {
            final encryptedData = await encryptedFile.readAsBytes();
            final decryptedData = _decryptAes128CBC(
                encryptedData, keyBytes, ivString, segmentIndex);
            await File(savePath).writeAsBytes(decryptedData);
            return decryptedData.length;
          } finally {
            if (await encryptedFile.exists()) {
              await encryptedFile.delete();
            }
          }
        } else {
          return await _streamToFile(responseStream, savePath);
        }
      } catch (e) {
        // 清理已创建的部分文件
        await _cleanupPartialFile(savePath);
        
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return 0;
  }
  
  Future<void> _cleanupPartialFile(String savePath) async {
    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }
    final tempPath = '$savePath._enc';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  Future<int> _streamToFile(Stream<List<int>> stream, String path) async {
    final file = File(path);
    final sink = file.openWrite();
    int totalBytes = 0;
    bool hasError = false;
    try {
      await for (final chunk in stream) {
        sink.add(chunk);
        totalBytes += chunk.length;
      }
    } catch (_) {
      hasError = true;
    } finally {
      await sink.close();
      // 如果发生错误或文件为空，删除部分文件
      if (hasError || totalBytes == 0) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    return totalBytes;
  }

  Uint8List _decryptAes128CBC(
      Uint8List data, Uint8List keyBytes, String? ivString, int segmentIndex) {
    final engine = AESEngine();
    engine.init(false, KeyParameter(keyBytes));

    const blockSize = 16;
    final numBlocks = data.length ~/ blockSize;

    Uint8List prevCipher = _buildIvBytes(ivString, segmentIndex);
    final currentIn = Uint8List(blockSize);
    final currentOut = Uint8List(blockSize);

    for (int i = 0; i < numBlocks; i++) {
      final offset = i * blockSize;
      for (int j = 0; j < blockSize; j++) {
        currentIn[j] = data[offset + j];
      }
      engine.processBlock(currentIn, 0, currentOut, 0);
      for (int j = 0; j < blockSize; j++) {
        data[offset + j] = currentOut[j] ^ prevCipher[j];
      }
      for (int j = 0; j < blockSize; j++) {
        prevCipher[j] = currentIn[j];
      }
    }

    final padLen = data[data.length - 1];
    if (padLen > 0 && padLen <= blockSize) {
      bool valid = true;
      for (int i = data.length - padLen; i < data.length; i++) {
        if (data[i] != padLen) {
          valid = false;
          break;
        }
      }
      if (valid) {
        return Uint8List.sublistView(data, 0, data.length - padLen);
      }
    }

    return data;
  }

  Uint8List _buildIvBytes(String? ivString, int segmentIndex) {
    if (ivString != null) {
      final cleanIv = ivString.startsWith('0x') ? ivString.substring(2) : ivString;
      if (cleanIv.length == 32) {
        final iv = Uint8List(16);
        for (int i = 0; i < 16; i++) {
          iv[i] = int.parse(cleanIv.substring(i * 2, i * 2 + 2), radix: 16);
        }
        return iv;
      }
    }
    return _intToBigEndianBytes(segmentIndex);
  }

  Uint8List _intToBigEndianBytes(int value) {
    final bytes = Uint8List(16);
    bytes[12] = (value >> 24) & 0xFF;
    bytes[13] = (value >> 16) & 0xFF;
    bytes[14] = (value >> 8) & 0xFF;
    bytes[15] = value & 0xFF;
    return bytes;
  }

  Future<void> _mergeSegments(
      List<String> segmentPaths, String outputPath) async {
    if (segmentPaths.isEmpty) {
      throw Exception('没有可合并的视频片段');
    }

    int totalSize = 0;
    final validSegments = <String>[];

    for (final segPath in segmentPaths) {
      final segFile = File(segPath);
      if (await segFile.exists()) {
        final size = await segFile.length();
        if (size > 0) {
          validSegments.add(segPath);
          totalSize += size;
        }
      }
    }

    if (validSegments.isEmpty) {
      throw Exception('没有有效的视频片段可合并');
    }

    if (totalSize < 100) {
      throw Exception('合并后的文件大小异常，可能下载失败');
    }

    final outputFile = File(outputPath);
    final output = outputFile.openWrite();
    try {
      for (final segPath in validSegments) {
        final stream = File(segPath).openRead();
        await output.addStream(stream);
      }
    } finally {
      await output.close();
    }
  }

  Future<void> _cleanupTemp(Directory tempDir) async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }

  String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final baseUri = Uri.parse(baseUrl);
    final hostWithPort = baseUri.hasPort
        ? '${baseUri.host}:${baseUri.port}'
        : baseUri.host;

    if (url.startsWith('/')) {
      return '${baseUri.scheme}://$hostWithPort$url';
    } else {
      final basePath =
          baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1);
      return '${baseUri.scheme}://$hostWithPort$basePath$url';
    }
  }

  void dispose() {
    _dio.close();
  }
}

class _Semaphore {
  final int maxPermits;
  int _permits;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this.maxPermits) : _permits = maxPermits;

  Future<void> withPermit(Future<void> Function() action) async {
    await _acquire();
    try {
      await action();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_permits > 0) {
      _permits--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _permits++;
    }
  }
}
