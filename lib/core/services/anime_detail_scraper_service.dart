import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:luma_nome_app/core/models/anime_detail.dart';

class AnimeDetailScraper {
  static Future<AnimeDetail> fetchDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load anime details page: ${response.statusCode}');
    }
    final document = parser.parse(response.body);

    // استخراج البيانات الأساسية
    final imageUrl = document.querySelector('.anime-card .image')?.attributes['data-src']?.trim() ?? '';

    // متغير مساعد لاستخراج رابط البانر من الـ style
    final bannerElementStyle = document.querySelector('.head-box .banner')?.attributes['style'];
    String bannerUrlFromStyle = '';
    if (bannerElementStyle != null && bannerElementStyle.contains('url("')) {
      try {
        // استخدام try-catch هنا لأن .split().elementAt() قد يسبب خطأ إذا لم تكن البنية كما هو متوقع
        bannerUrlFromStyle = bannerElementStyle.split('url("').elementAt(1).split('")').first.trim();
      } catch (e) {
        // print('Error parsing banner URL from style: $e');
        bannerUrlFromStyle = ''; // إعادة تعيين في حالة الخطأ
      }
    }

    // السطر المصحح لـ bannerUrl
    final bannerUrl = document.querySelector('.head-box .banner')?.attributes['data-src']?.trim() ??
        (bannerUrlFromStyle.isNotEmpty ? bannerUrlFromStyle : imageUrl);

    final title = document.querySelector('.media-title h1')?.text.trim() ?? '';
    final altTitle = document.querySelector('.media-title h3')?.text.trim() ?? '';

    // استخراج المعلومات من قائمة media-info
    final infoItems = document.querySelectorAll('.media-info li');
    Map<String, String> infoMap = {};

    for (var item in infoItems) {
      final label = item.text.split(':')[0].trim();
      final value = item.querySelector('span')?.text.trim() ??
          item.querySelector('a')?.text.trim() ??
          item.text.split(':').sublist(1).join(':').trim();
      infoMap[label] = value;
    }

    // استخراج التصنيف
    final rating = document.querySelector('.score')?.text.trim() ?? '0.0';

    // استخراج الأنواع
    final genres = document.querySelectorAll('.genres a').map((e) => e.text.trim()).toList();

    // استخراج الوصف
    final description = document.querySelector('.media-story .content')?.text.trim() ?? '';

    // --- بداية منطق جلب المواسم المعدل ---
    final List<String> currentScrapedSeasonImages = [];
    final List<String> currentScrapedSeasonUrls = [];

    final seasonLiElements = document.querySelectorAll('.media-seasons .episodes-lists li');

    for (var liElement in seasonLiElements) {
      final posterAnchor = liElement.querySelector('a.poster');
      final seasonImage = posterAnchor?.attributes['data-src']?.trim() ?? '';

      String seasonLink = '';
      final readBtnAnchor = liElement.querySelector('a.read-btn');
      seasonLink = readBtnAnchor?.attributes['href']?.trim() ?? '';

      if (seasonLink.isEmpty) {
        final titleAnchor = liElement.querySelector('a.title');
        seasonLink = titleAnchor?.attributes['href']?.trim() ?? '';
      }
      if (seasonLink.isEmpty) {
        seasonLink = posterAnchor?.attributes['href']?.trim() ?? '';
      }

      if (seasonImage.isNotEmpty && seasonLink.isNotEmpty) {
        currentScrapedSeasonImages.add(seasonImage);
        currentScrapedSeasonUrls.add(seasonLink);
      }
    }

    final List<String> finalSeasonImages;
    final List<String> finalSeasonUrls;

    if (currentScrapedSeasonImages.isNotEmpty) {
      finalSeasonImages = currentScrapedSeasonImages;
      finalSeasonUrls = currentScrapedSeasonUrls;
    } else if (imageUrl.isNotEmpty) {
      finalSeasonImages = [imageUrl];
      finalSeasonUrls = [];
    } else {
      finalSeasonImages = [];
      finalSeasonUrls = [];
    }
    // --- نهاية منطق جلب المواسم المعدل ---

    return AnimeDetail(
      title: title,
      imageUrl: imageUrl,
      bannerUrl: bannerUrl,
      status: infoMap['الحالة'] ?? '',
      type: infoMap['النوع'] ?? 'TV',
      releaseYear: infoMap['سنة العرض'] ?? infoMap['بداية العرض'] ?? '',
      rating: rating,
      studio: infoMap['الاستوديو'] ?? '',
      duration: infoMap['المدة'] ?? infoMap['مدة الحلقة'] ?? '',
      episodes: infoMap['الحلقات'] ?? '1',
      genres: genres,
      description: description,
      altTitle: altTitle,
      seasonsCount: finalSeasonImages.length,
      seasonImages: finalSeasonImages,
      seasonUrls: finalSeasonUrls,
    );
  }
}