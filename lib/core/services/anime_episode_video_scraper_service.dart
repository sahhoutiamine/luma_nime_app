import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'dart:convert';
import '../models/server_player.dart';

class VideoScraperService {
  static const String baseUrl = 'https://web.animerco.org';

  static Future<List<VideoServer>> fetchVideoServers(String episodeUrl) async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse(episodeUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': baseUrl,
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final servers = <VideoServer>[];

        // الطريقة الأساسية لاستخراج الخوادم
        final serverItems = document.querySelectorAll('.server-list li a.option');
        for (final item in serverItems) {
          servers.add(VideoServer(
            name: item.querySelector('.server')?.text.trim() ?? 'غير معروف',
            serverId: item.attributes['data-nume'] ?? '',
            type: item.attributes['data-type'] ?? 'tv',
            postId: item.attributes['data-post'] ?? '',
          ));
        }

        // طريقة احتياطية إذا لم توجد خوادم
        if (servers.isEmpty) {
          final backupItems = document.querySelectorAll('a[data-server]');
          for (final item in backupItems) {
            servers.add(VideoServer(
              name: item.text.trim(),
              serverId: item.attributes['data-server'] ?? '',
              type: item.attributes['data-type'] ?? 'tv',
              postId: item.attributes['data-post'] ?? '',
            ));
          }
        }

        return servers;
      }
    } catch (e) {
      print('حدث خطأ في جلب الخوادم: $e');
    } finally {
      client.close();
    }
    return [];
  }

  static Future<String?> getVideoUrl({
    required String episodeUrl,
    required String serverId,
    required String type,
    required String postId,
  }) async {
    final client = http.Client();
    try {
      // المحاولة الأولى: استخدام API الموقع
      final apiResponse = await client.post(
        Uri.parse('$baseUrl/wp-admin/admin-ajax.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': episodeUrl,
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: {
          'action': 'doo_player_ajax',
          'post': postId,
          'nume': serverId,
          'type': type,
        },
      );

      if (apiResponse.statusCode == 200) {
        final data = jsonDecode(apiResponse.body);

        // تحليل الرد لاستخراج الرابط
        if (data['embed_url'] != null) {
          return await _resolveEmbedUrl(data['embed_url']);
        }

        if (data['embed'] != null) {
          return await _resolveEmbedUrl(data['embed']);
        }

        if (data['url'] != null) {
          return data['url'];
        }
      }

      // المحاولة الثانية: البحث مباشرة في الصفحة
      return await _extractDirectVideoUrl(episodeUrl);
    } catch (e) {
      print('حدث خطأ في جلب رابط الفيديو: $e');
    } finally {
      client.close();
    }
    return null;
  }

  static Future<String?> _resolveEmbedUrl(String embedUrl) async {
    try {
      // إذا كان الرابط يحتوي على mp4 أو m3u8 مباشرة
      if (embedUrl.contains('.mp4') || embedUrl.contains('.m3u8')) {
        return embedUrl;
      }

      // إذا كان iframe نحتاج لاستخراج الرابط منه
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse(embedUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': baseUrl,
          },
        );

        if (response.statusCode == 200) {
          final regex = RegExp(
            r'(https?:\/\/[^\s"]*\.(?:m3u8|mp4)[^\s"]*)',
            caseSensitive: false,
          );
          final match = regex.firstMatch(response.body);
          return match?.group(1);
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('حدث خطأ في تحليل الرابط المضمن: $e');
    }
    return null;
  }

  static Future<String?> _extractDirectVideoUrl(String episodeUrl) async {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse(episodeUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': baseUrl,
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // البحث عن iframes
        final iframes = document.querySelectorAll('iframe');
        for (final iframe in iframes) {
          final src = iframe.attributes['src'];
          if (src != null && src.isNotEmpty) {
            final videoUrl = await _resolveEmbedUrl(src);
            if (videoUrl != null) return videoUrl;
          }
        }

        // البحث عن عناصر فيديو مباشرة
        final videoElements = document.querySelectorAll('video');
        for (final video in videoElements) {
          final src = video.attributes['src'];
          if (src != null && src.isNotEmpty) {
            return src;
          }
        }
      }
    } catch (e) {
      print('حدث خطأ في استخراج الفيديو مباشرة: $e');
    } finally {
      client.close();
    }
    return null;
  }
}