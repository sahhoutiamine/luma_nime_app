import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

import 'package:luma_nome_app/core/models/anime.dart';

class AnimeScraperService {
  // URLs
  static const String trendingUrl = 'https://web.animerco.org/trending/';
  static const String ratingsUrl = 'https://web.animerco.org/ratings/';
  static const String allUrl = 'https://web.animerco.org/animes/';

  Future<List<Anime>> fetchAnimes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('.anime-card');

        return elements.map((element) {
          final imageElement = element.querySelector('a.image');
          final titleElement = element.querySelector('h3');
          final extraInfo = element.querySelector('.extra');
          final link = imageElement?.attributes['href'] ?? '';

          final imageUrl = _extractImageUrl(imageElement!);
          final title = titleElement?.text.trim() ?? 'بدون عنوان';
          final type = extraInfo?.querySelector('.anime-type')?.text.trim() ?? '';
          final year = extraInfo?.querySelector('.anime-aired')?.text.trim() ?? '';

          return Anime(
            title: title,
            imageUrl: imageUrl ?? '',
            link: link,
            type: type,
            year: year,
          );
        }).toList();
      } else {
        throw Exception('فشل تحميل البيانات من $url');
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب البيانات: $e');
    }
  }

  String? _extractImageUrl(Element element) {
    final dataSrc = element.attributes['data-src'];
    if (dataSrc != null && dataSrc.startsWith('http')) {
      return dataSrc;
    }

    final style = element.attributes['style'];
    if (style != null && style.contains('background-image')) {
      final regex = RegExp(r'url\(["\"]?(.*?)["\"]?\)');
      final match = regex.firstMatch(style);
      if (match != null && match.group(1)!.startsWith('http')) {
        return match.group(1);
      }
    }

    return null;
  }
}