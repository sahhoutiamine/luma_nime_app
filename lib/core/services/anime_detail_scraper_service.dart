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

    // استخراج الصورة الرئيسية مع تحسينات
    final imageUrl = document.querySelector('img[alt*="صورة"]')?.attributes['src']?.trim() ??
        document.querySelector('.poster img')?.attributes['src']?.trim() ??
        document.querySelector('meta[property="og:image"]')?.attributes['content']?.trim() ?? '';

    // استخراج العنوان الرئيسي
    final titleElement = document.querySelector('h1');
    String title = '';
    String altTitle = '';

    if (titleElement != null) {
      final spanElement = titleElement.querySelector('span[dir="ltr"]');
      if (spanElement != null) {
        title = spanElement.text.trim();
        // البحث عن العنوان البديل من النص المتبقي في h1
        final fullText = titleElement.text.trim();
        final remainingText = fullText.replaceFirst(title, '').trim();
        if (remainingText.contains('(') && remainingText.contains(')')) {
          altTitle = remainingText.replaceAll(RegExp(r'[()]'), '').trim();
        }
      } else {
        title = titleElement.text.trim();
      }
    }

    // استخراج الأنواع (الجانر) مع أخذ أول 4 أنواع وإزالة الأرقام
    final genres = document.querySelectorAll('a[href*="/genre/"]')
        .map((e) => e.text.trim().replaceAll(RegExp(r'\d'), ''))
        .where((genre) => genre.isNotEmpty)
        .take(4)
        .toList();

    // استخراج التقييم
    String rating = '0.0';
    final ratingElements = document.querySelectorAll('p');
    for (var element in ratingElements) {
      final text = element.text.trim();
      if (RegExp(r'^\d+\.\d+$').hasMatch(text)) {
        rating = text;
        break;
      }
    }

    // استخراج المعلومات من الجداول
    Map<String, String> infoMap = {};

    // البحث في الجدول المخفي للموبايل
    final tableRows = document.querySelectorAll('table tr');
    for (var row in tableRows) {
      final cells = row.querySelectorAll('td');
      if (cells.length >= 2) {
        final key = cells[0].text.trim().replaceAll(':', '');
        final value = cells[1].text.trim();
        infoMap[key] = value;
      }
    }

    // البحث في البطاقات الثلاث العلوية
    final infoCards = document.querySelectorAll('.rounded-lg.border');
    for (var card in infoCards) {
      final labelElement = card.querySelector('p.font-light');
      final valueElement = card.querySelector('p.text-lg');
      if (labelElement != null && valueElement != null) {
        final label = labelElement.text.trim();
        final value = valueElement.text.trim();
        infoMap[label] = value;
      }
    }

    // استخراج عدد الحلقات من النص
    String episodes = infoMap['الحلقات'] ?? '1';

    // استخراج الوصف
    final descriptionElements = document.querySelectorAll('p.leading-loose');
    String description = '';
    for (var element in descriptionElements) {
      if (element.text.trim().isNotEmpty) {
        if (description.isEmpty) {
          description = element.text.trim();
        } else {
          description += '\n\n' + element.text.trim();
        }
      }
    }

    // استخراج الأسماء البديلة
    final altNames = document.querySelectorAll('h2.rounded')
        .map((e) => e.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (altNames.isNotEmpty && altTitle.isEmpty) {
      altTitle = altNames.join(' | ');
    }

    // استخراج الاستديو
    final studioElement = document.querySelector('a[href*="/c/studio/"]');
    final studio = studioElement?.text.trim() ?? infoMap['الاستديو'] ?? '';

    return AnimeDetail(
      title: title,
      imageUrl: imageUrl,
      bannerUrl: imageUrl, // استخدام نفس صورة الأنمي كبنر
      status: infoMap['الحالة'] ?? '',
      type: infoMap['النوع'] ?? 'مسلسل',
      releaseYear: infoMap['إصدار'] ?? '',
      rating: rating,
      studio: studio,
      duration: infoMap['المدة'] ?? infoMap['مدة الحلقة'] ?? '',
      episodes: episodes,
      genres: genres,
      description: description,
      altTitle: altTitle,
      seasonsCount: 0,
      seasonImages: [],
      seasonUrls: [],
    );
  }
}