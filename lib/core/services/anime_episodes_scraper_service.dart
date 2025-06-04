import 'dart:convert';
import 'package:html/parser.dart' as htmlParser;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:luma_nome_app/core/models/anime_episodes.dart';

class EpisodeScraper {

  static Future<String?> fetchVideoUrl(String episodeUrl) async {
    try {
      // 1. تنزيل صفحة الحلقة
      final response = await http.get(Uri.parse(episodeUrl));

      if (response.statusCode != 200) {
        print('Failed to load episode page: ${response.statusCode}');
        return null;
      }

      // 2. تحليل محتوى HTML
      final document = htmlParser.parse(response.body);

      // 3. البحث عن عنصر الفيديو
      final videoElement = document.querySelector('video source');

      if (videoElement != null) {
        final videoUrl = videoElement.attributes['src'];
        if (videoUrl != null && videoUrl.isNotEmpty) {
          return videoUrl;
        }
      }

      // 4. البحث في حال كان الرابط في مكان آخر (مثال: في script)
      final scripts = document.querySelectorAll('script');
      for (final script in scripts) {
        final content = script.innerHtml;
        if (content.contains('video_url') ) {
          final regex = RegExp(r'''video_url["\']?:\s*["\']([^"\']+)["\']''');
          final match = regex.firstMatch(content);
          if (match != null) {
            return match.group(1);
          }
        }
        }

        // 5. المحاولة مع API كخيار احتياطي
        final apiUrl = episodeUrl.replaceFirst('/episode/', '/api/episode/');
        final apiResponse = await http.get(Uri.parse(apiUrl));

        if (apiResponse.statusCode == 200) {
          final jsonData = jsonDecode(apiResponse.body);
          return jsonData['video_url'];
        }

        return null;
      } catch (e) {
      print('Error fetching video URL: $e');
      return null;
    }
  }
  static Future<List<Episode>> fetchEpisodes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load episodes page: ${response.statusCode}');
    }

    final document = parser.parse(response.body);
    final List<Episode> episodes = [];

    // استخراج جميع عناصر الحلقات بما فيها الأخيرة
    final episodeElements = document.querySelectorAll('a.btn.btn-md.btn-light');

    for (var element in episodeElements) {
      final thumbnailElement = element.querySelector('img');
      final durationElement = element.querySelector('.rounded.absolute');
      final titleElement = element.querySelector('.video-data span');

      // تخطي العناصر الفارغة
      if (titleElement == null || titleElement.text.trim().isEmpty) continue;

      final thumbnail = thumbnailElement?.attributes['src']?.trim() ?? '';
      final duration = durationElement?.text.trim() ?? '00:00';
      final title = titleElement.text.trim();
      final episodeUrl = element.attributes['href']?.trim() ?? '';

      // تحديد إذا كانت الحلقة الأخيرة بناء على النص أو الفئة
      final isLastEpisode = title.contains('الأخيرة') ||
          !element.classes.contains('border-b') ||
          episodeElements.length == 1;

      episodes.add(Episode(
        title: title,
        url: episodeUrl,
        thumbnail: thumbnail,
        duration: duration,
        isLastEpisode: isLastEpisode,
      ));
    }

    // إذا كان هناك حلقة واحدة فقط، نعتبرها الأخيرة
    if (episodes.length == 1) {
      episodes[0] = episodes[0].copyWith(isLastEpisode: true);
    }

    return episodes;
  }

  static Future<String?> fetchDownloadAllUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      return null;
    }

    final document = parser.parse(response.body);
    final downloadButton = document.querySelector('a[href*="/download"]');

    return downloadButton?.attributes['href']?.trim();
  }
}