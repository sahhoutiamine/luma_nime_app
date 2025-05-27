class Episode {
  final String title;
  final String number;
  final String imageUrl;
  final String url;
  final String? duration;
  final String? date;

  Episode({
    required this.title,
    required this.number,
    required this.imageUrl,
    required this.url,
    this.duration,
    this.date,
  });
}