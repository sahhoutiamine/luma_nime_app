class VideoServer {
  final String name;
  final String serverId;
  final String type;
  final String postId;
  final String? quality;
  final String? language;

  VideoServer({
    required this.name,
    required this.serverId,
    required this.type,
    required this.postId,
    this.quality,
    this.language,
  });

  factory VideoServer.fromJson(Map<String, dynamic> json) {
    return VideoServer(
      name: json['name'] ?? 'Unknown Server',
      serverId: json['serverId'] ?? '',
      type: json['type'] ?? 'direct',
      postId: json['postId'] ?? '',
      quality: json['quality'],
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'serverId': serverId,
      'type': type,
      'postId': postId,
      'quality': quality,
      'language': language,
    };
  }

  @override
  String toString() {
    return 'VideoServer(name: $name, serverId: $serverId, type: $type, postId: $postId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoServer &&
        other.name == name &&
        other.serverId == serverId &&
        other.type == type &&
        other.postId == postId;
  }

  @override
  int get hashCode {
    return name.hashCode ^
    serverId.hashCode ^
    type.hashCode ^
    postId.hashCode;
  }

  // دوال مساعدة
  bool get isValid => serverId.isNotEmpty && name.isNotEmpty;

  bool get isDirect => type.toLowerCase() == 'direct';

  bool get isEmbed => type.toLowerCase() == 'embed' || type.toLowerCase() == 'iframe';

  String get displayName {
    if (quality != null && quality!.isNotEmpty) {
      return '$name ($quality)';
    }
    return name;
  }
}