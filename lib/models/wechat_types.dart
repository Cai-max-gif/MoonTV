/// 微信消息类型常量
class WeChatMessageType {
  static const int user = 1;
  static const int bot = 2;
}

/// 微信消息条目类型常量
class WeChatItemType {
  static const int text = 1;
  static const int image = 2;
  static const int voice = 3;
  static const int file = 4;
  static const int video = 5;
}

/// 微信消息状态常量
class WeChatMessageState {
  static const int new_ = 0;
  static const int generating = 1;
  static const int finish = 2;
}

/// CDN媒体上传类型常量
class WeChatUploadMediaType {
  static const int image = 1;
  static const int video = 2;
  static const int file = 3;
  static const int voice = 4;
}

/// Typing状态常量
class WeChatTypingStatus {
  static const int typing = 1;
  static const int cancel = 2;
}

/// 获取配置响应（包含typing_ticket）
class GetConfigResponse {
  final int? ret;
  final String? errmsg;
  final String? typingTicket;

  GetConfigResponse({
    this.ret,
    this.errmsg,
    this.typingTicket,
  });

  factory GetConfigResponse.fromJson(Map<String, dynamic> json) {
    return GetConfigResponse(
      ret: json['ret'] as int?,
      errmsg: json['errmsg'] as String?,
      typingTicket: json['typing_ticket'] as String?,
    );
  }
}

/// 发送Typing响应
class SendTypingResponse {
  final int? ret;
  final String? errmsg;

  SendTypingResponse({
    this.ret,
    this.errmsg,
  });

  factory SendTypingResponse.fromJson(Map<String, dynamic> json) {
    return SendTypingResponse(
      ret: json['ret'] as int?,
      errmsg: json['errmsg'] as String?,
    );
  }
}

/// CDN媒体引用
class CDNMedia {
  final String? encryptQueryParam;
  final String? aesKey;
  final int? encryptType;
  final String? fullUrl;

  CDNMedia({
    this.encryptQueryParam,
    this.aesKey,
    this.encryptType,
    this.fullUrl,
  });

  factory CDNMedia.fromJson(Map<String, dynamic> json) {
    return CDNMedia(
      encryptQueryParam: json['encrypt_query_param'] as String?,
      aesKey: json['aes_key'] as String?,
      encryptType: json['encrypt_type'] as int?,
      fullUrl: json['full_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (encryptQueryParam != null) map['encrypt_query_param'] = encryptQueryParam;
    if (aesKey != null) map['aes_key'] = aesKey;
    if (encryptType != null) map['encrypt_type'] = encryptType;
    if (fullUrl != null) map['full_url'] = fullUrl;
    return map;
  }
}

/// 图片消息条目
class ImageItem {
  final CDNMedia? media;
  final CDNMedia? thumbMedia;
  final String? aesKey;
  final String? url;
  final int? midSize;
  final int? thumbSize;
  final int? thumbHeight;
  final int? thumbWidth;
  final int? hdSize;

  ImageItem({
    this.media,
    this.thumbMedia,
    this.aesKey,
    this.url,
    this.midSize,
    this.thumbSize,
    this.thumbHeight,
    this.thumbWidth,
    this.hdSize,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      media: json['media'] != null ? CDNMedia.fromJson(json['media']) : null,
      thumbMedia: json['thumb_media'] != null ? CDNMedia.fromJson(json['thumb_media']) : null,
      aesKey: json['aeskey'] as String?,
      url: json['url'] as String?,
      midSize: json['mid_size'] as int?,
      thumbSize: json['thumb_size'] as int?,
      thumbHeight: json['thumb_height'] as int?,
      thumbWidth: json['thumb_width'] as int?,
      hdSize: json['hd_size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (media != null) map['media'] = media!.toJson();
    if (thumbMedia != null) map['thumb_media'] = thumbMedia!.toJson();
    if (aesKey != null) map['aeskey'] = aesKey;
    if (url != null) map['url'] = url;
    if (midSize != null) map['mid_size'] = midSize;
    if (thumbSize != null) map['thumb_size'] = thumbSize;
    if (thumbHeight != null) map['thumb_height'] = thumbHeight;
    if (thumbWidth != null) map['thumb_width'] = thumbWidth;
    if (hdSize != null) map['hd_size'] = hdSize;
    return map;
  }
}

/// 语音消息条目
class VoiceItem {
  final CDNMedia? media;
  final int? encodeType;
  final int? bitsPerSample;
  final int? sampleRate;
  final int? playtime;
  final String? text;

  VoiceItem({
    this.media,
    this.encodeType,
    this.bitsPerSample,
    this.sampleRate,
    this.playtime,
    this.text,
  });

  factory VoiceItem.fromJson(Map<String, dynamic> json) {
    return VoiceItem(
      media: json['media'] != null ? CDNMedia.fromJson(json['media']) : null,
      encodeType: json['encode_type'] as int?,
      bitsPerSample: json['bits_per_sample'] as int?,
      sampleRate: json['sample_rate'] as int?,
      playtime: json['playtime'] as int?,
      text: json['text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (media != null) map['media'] = media!.toJson();
    if (encodeType != null) map['encode_type'] = encodeType;
    if (bitsPerSample != null) map['bits_per_sample'] = bitsPerSample;
    if (sampleRate != null) map['sample_rate'] = sampleRate;
    if (playtime != null) map['playtime'] = playtime;
    if (text != null) map['text'] = text;
    return map;
  }
}

/// 文件消息条目
class FileItem {
  final CDNMedia? media;
  final String? fileName;
  final String? md5;
  final String? len;

  FileItem({
    this.media,
    this.fileName,
    this.md5,
    this.len,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      media: json['media'] != null ? CDNMedia.fromJson(json['media']) : null,
      fileName: json['file_name'] as String?,
      md5: json['md5'] as String?,
      len: json['len'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (media != null) map['media'] = media!.toJson();
    if (fileName != null) map['file_name'] = fileName;
    if (md5 != null) map['md5'] = md5;
    if (len != null) map['len'] = len;
    return map;
  }
}

/// 视频消息条目
class VideoItem {
  final CDNMedia? media;
  final int? videoSize;
  final int? playLength;
  final String? videoMd5;
  final CDNMedia? thumbMedia;
  final int? thumbSize;
  final int? thumbHeight;
  final int? thumbWidth;

  VideoItem({
    this.media,
    this.videoSize,
    this.playLength,
    this.videoMd5,
    this.thumbMedia,
    this.thumbSize,
    this.thumbHeight,
    this.thumbWidth,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      media: json['media'] != null ? CDNMedia.fromJson(json['media']) : null,
      videoSize: json['video_size'] as int?,
      playLength: json['play_length'] as int?,
      videoMd5: json['video_md5'] as String?,
      thumbMedia: json['thumb_media'] != null ? CDNMedia.fromJson(json['thumb_media']) : null,
      thumbSize: json['thumb_size'] as int?,
      thumbHeight: json['thumb_height'] as int?,
      thumbWidth: json['thumb_width'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (media != null) map['media'] = media!.toJson();
    if (videoSize != null) map['video_size'] = videoSize;
    if (playLength != null) map['play_length'] = playLength;
    if (videoMd5 != null) map['video_md5'] = videoMd5;
    if (thumbMedia != null) map['thumb_media'] = thumbMedia!.toJson();
    if (thumbSize != null) map['thumb_size'] = thumbSize;
    if (thumbHeight != null) map['thumb_height'] = thumbHeight;
    if (thumbWidth != null) map['thumb_width'] = thumbWidth;
    return map;
  }
}

/// CDN上传URL响应
class GetUploadUrlResponse {
  final String? uploadParam;
  final String? thumbUploadParam;
  final String? uploadFullUrl;

  GetUploadUrlResponse({
    this.uploadParam,
    this.thumbUploadParam,
    this.uploadFullUrl,
  });

  factory GetUploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return GetUploadUrlResponse(
      uploadParam: json['upload_param'] as String?,
      thumbUploadParam: json['thumb_upload_param'] as String?,
      uploadFullUrl: json['upload_full_url'] as String?,
    );
  }
}

/// 已上传文件信息
class UploadedFileInfo {
  final String filekey;
  final String downloadEncryptedQueryParam;
  final String aeskey;
  final int fileSize;
  final int fileSizeCiphertext;

  UploadedFileInfo({
    required this.filekey,
    required this.downloadEncryptedQueryParam,
    required this.aeskey,
    required this.fileSize,
    required this.fileSizeCiphertext,
  });
}

/// 文本消息条目
class TextItem {
  final String? text;

  TextItem({this.text});

  factory TextItem.fromJson(Map<String, dynamic> json) {
    return TextItem(text: json['text'] as String?);
  }

  Map<String, dynamic> toJson() => {'text': text};
}

/// 引用消息
class RefMsg {
  final String? title;
  final MessageItem? messageItem;

  RefMsg({this.title, this.messageItem});

  factory RefMsg.fromJson(Map<String, dynamic> json) {
    return RefMsg(
      title: json['title'] as String?,
      messageItem: json['message_item'] != null
          ? MessageItem.fromJson(json['message_item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (messageItem != null) map['message_item'] = messageItem!.toJson();
    return map;
  }
}

/// 消息条目
class MessageItem {
  final int? type;
  final TextItem? textItem;
  final RefMsg? refMsg;
  final ImageItem? imageItem;
  final VoiceItem? voiceItem;
  final FileItem? fileItem;
  final VideoItem? videoItem;

  MessageItem({
    this.type,
    this.textItem,
    this.refMsg,
    this.imageItem,
    this.voiceItem,
    this.fileItem,
    this.videoItem,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      type: json['type'] as int?,
      textItem: json['text_item'] != null
          ? TextItem.fromJson(json['text_item'] as Map<String, dynamic>)
          : null,
      refMsg: json['ref_msg'] != null
          ? RefMsg.fromJson(json['ref_msg'] as Map<String, dynamic>)
          : null,
      imageItem: json['image_item'] != null
          ? ImageItem.fromJson(json['image_item'] as Map<String, dynamic>)
          : null,
      voiceItem: json['voice_item'] != null
          ? VoiceItem.fromJson(json['voice_item'] as Map<String, dynamic>)
          : null,
      fileItem: json['file_item'] != null
          ? FileItem.fromJson(json['file_item'] as Map<String, dynamic>)
          : null,
      videoItem: json['video_item'] != null
          ? VideoItem.fromJson(json['video_item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (type != null) map['type'] = type;
    if (textItem != null) map['text_item'] = textItem!.toJson();
    if (refMsg != null) map['ref_msg'] = refMsg!.toJson();
    if (imageItem != null) map['image_item'] = imageItem!.toJson();
    if (voiceItem != null) map['voice_item'] = voiceItem!.toJson();
    if (fileItem != null) map['file_item'] = fileItem!.toJson();
    if (videoItem != null) map['video_item'] = videoItem!.toJson();
    return map;
  }
}

/// 微信消息
class WeChatMessage {
  final int? seq;
  final int? messageId;
  final String? fromUserId;
  final String? toUserId;
  final String? clientId;
  final int? createTimeMs;
  final String? sessionId;
  final int? messageType;
  final int? messageState;
  final List<MessageItem>? itemList;
  final String? contextToken;

  WeChatMessage({
    this.seq,
    this.messageId,
    this.fromUserId,
    this.toUserId,
    this.clientId,
    this.createTimeMs,
    this.sessionId,
    this.messageType,
    this.messageState,
    this.itemList,
    this.contextToken,
  });

  factory WeChatMessage.fromJson(Map<String, dynamic> json) {
    return WeChatMessage(
      seq: json['seq'] as int?,
      messageId: json['message_id'] as int?,
      fromUserId: json['from_user_id'] as String?,
      toUserId: json['to_user_id'] as String?,
      clientId: json['client_id'] as String?,
      createTimeMs: json['create_time_ms'] as int?,
      sessionId: json['session_id'] as String?,
      messageType: json['message_type'] as int?,
      messageState: json['message_state'] as int?,
      itemList: (json['item_list'] as List<dynamic>?)
          ?.map((e) => MessageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      contextToken: json['context_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (seq != null) map['seq'] = seq;
    if (messageId != null) map['message_id'] = messageId;
    if (fromUserId != null) map['from_user_id'] = fromUserId;
    if (toUserId != null) map['to_user_id'] = toUserId;
    if (clientId != null) map['client_id'] = clientId;
    if (createTimeMs != null) map['create_time_ms'] = createTimeMs;
    if (sessionId != null) map['session_id'] = sessionId;
    if (messageType != null) map['message_type'] = messageType;
    if (messageState != null) map['message_state'] = messageState;
    if (itemList != null) map['item_list'] = itemList!.map((e) => e.toJson()).toList();
    if (contextToken != null) map['context_token'] = contextToken;
    return map;
  }
}

/// getUpdates API 响应
class GetUpdatesResponse {
  final int? ret;
  final int? errcode;
  final String? errmsg;
  final List<WeChatMessage>? msgs;
  final String? getUpdatesBuf;
  final int? longpollingTimeoutMs;

  GetUpdatesResponse({
    this.ret,
    this.errcode,
    this.errmsg,
    this.msgs,
    this.getUpdatesBuf,
    this.longpollingTimeoutMs,
  });

  factory GetUpdatesResponse.fromJson(Map<String, dynamic> json) {
    return GetUpdatesResponse(
      ret: json['ret'] as int?,
      errcode: json['errcode'] as int?,
      errmsg: json['errmsg'] as String?,
      msgs: (json['msgs'] as List<dynamic>?)
          ?.map((e) => WeChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      getUpdatesBuf: json['get_updates_buf'] as String?,
      longpollingTimeoutMs: json['longpolling_timeout_ms'] as int?,
    );
  }

  bool get isSuccess => ret == null || ret == 0;
}

/// 获取二维码响应
class QRCodeResponse {
  final String qrcode;
  final String qrcodeImgContent;

  QRCodeResponse({required this.qrcode, required this.qrcodeImgContent});

  factory QRCodeResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeResponse(
      qrcode: json['qrcode'] as String,
      qrcodeImgContent: json['qrcode_img_content'] as String,
    );
  }
}

/// 二维码状态
enum QRStatus {
  wait,
  scaned,
  confirmed,
  expired;

  static QRStatus fromString(String s) {
    switch (s) {
      case 'scaned':
        return QRStatus.scaned;
      case 'confirmed':
        return QRStatus.confirmed;
      case 'expired':
        return QRStatus.expired;
      default:
        return QRStatus.wait;
    }
  }
}

/// 二维码状态轮询响应
class QRStatusResponse {
  final QRStatus status;
  final String? botToken;
  final String? ilinkBotId;
  final String? baseurl;
  final String? ilinkUserId;

  QRStatusResponse({
    required this.status,
    this.botToken,
    this.ilinkBotId,
    this.baseurl,
    this.ilinkUserId,
  });

  factory QRStatusResponse.fromJson(Map<String, dynamic> json) {
    return QRStatusResponse(
      status: QRStatus.fromString(json['status'] as String? ?? 'wait'),
      botToken: json['bot_token'] as String?,
      ilinkBotId: json['ilink_bot_id'] as String?,
      baseurl: json['baseurl'] as String?,
      ilinkUserId: json['ilink_user_id'] as String?,
    );
  }
}

/// 登录凭证
class LoginCredentials {
  final String token;
  final String baseUrl;
  final String accountId;
  final String? userId;

  LoginCredentials({
    required this.token,
    required this.baseUrl,
    required this.accountId,
    this.userId,
  });

  factory LoginCredentials.fromJson(Map<String, dynamic> json) {
    return LoginCredentials(
      token: json['token'] as String,
      baseUrl: json['baseUrl'] as String,
      accountId: json['accountId'] as String,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'baseUrl': baseUrl,
        'accountId': accountId,
        'userId': userId,
      };
}
