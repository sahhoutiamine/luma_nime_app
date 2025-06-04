class Episode {
  final String title;
  final String url;
  final String thumbnail;
  final String duration;
  final bool isLastEpisode;

  const Episode({
    required this.title,
    required this.url,
    required this.thumbnail,
    required this.duration,
    required this.isLastEpisode,
  });

  // إضافة دالة copyWith لإنشاء نسخة معدلة من الحلقة
  Episode copyWith({
    String? title,
    String? url,
    String? thumbnail,
    String? duration,
    bool? isLastEpisode,
  }) {
    return Episode(
      title: title ?? this.title,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      isLastEpisode: isLastEpisode ?? this.isLastEpisode,
    );
  }
}