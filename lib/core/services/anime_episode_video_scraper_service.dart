import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/server_player.dart';
import 'dart:convert';

class VideoScraperService {
  static const String baseUrl = 'https://web.animerco.org';

  static Future<List<VideoServer>> fetchVideoServers(String episodeUrl) async {
    try {
      print('Fetching servers from: $episodeUrl');

      final response = await http.get(
        Uri.parse(episodeUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'ar,en-US;q=0.7,en;q=0.3',
          'Accept-Encoding': 'gzip, deflate',
          'DNT': '1',
          'Connection': 'keep-alive',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final List<VideoServer> servers = [];

        // البحث عن الخوادم في عدة أماكن محتملة
        final serverSelectors = [
          '.server-list li a',
          '.servers-list li a',
          '.episode-servers li a',
          'ul.list-server-items li a',
          '.player-servers li a',
        ];

        for (String selector in serverSelectors) {
          final serverElements = document.querySelectorAll(selector);

          if (serverElements.isNotEmpty) {
            print('Found ${serverElements.length} servers with selector: $selector');

            for (var element in serverElements) {
              final serverName = element.querySelector('.server')?.text.trim() ??
                  element.text.trim() ??
                  'Unknown Server';

              final serverId = element.attributes['data-nume'] ??
                  element.attributes['data-server'] ??
                  element.attributes['data-id'] ??
                  '';

              final type = element.attributes['data-type'] ??
                  element.attributes['data-server-type'] ??
                  'direct';

              final postId = element.attributes['data-post'] ??
                  element.attributes['data-episode'] ??
                  '';

              final href = element.attributes['href'] ?? '';

              if (serverName.isNotEmpty && (serverId.isNotEmpty || href.isNotEmpty)) {
                servers.add(VideoServer(
                  name: serverName,
                  serverId: serverId.isNotEmpty ? serverId : href,
                  type: type,
                  postId: postId,
                ));
              }
            }

            if (servers.isNotEmpty) break; // إذا وجدنا خوادم، توقف عن البحث
          }
        }

        // إذا لم نجد خوادم، حاول طريقة أخرى
        if (servers.isEmpty) {
          // البحث عن أزرار التشغيل
          final playButtons = document.querySelectorAll('button[data-server], a[data-server], .play-btn');

          for (var button in playButtons) {
            final serverName = button.text.trim();
            final serverId = button.attributes['data-server'] ??
                button.attributes['data-nume'] ??
                button.attributes['href'] ?? '';

            if (serverName.isNotEmpty && serverId.isNotEmpty) {
              servers.add(VideoServer(
                name: serverName,
                serverId: serverId,
                type: 'direct',
                postId: '',
              ));
            }
          }
        }

        // إضافة خادم افتراضي إذا لم نجد أي خوادم
        if (servers.isEmpty) {
          servers.add(VideoServer(
            name: 'خادم افتراضي',
            serverId: 'default',
            type: 'direct',
            postId: '',
          ));
        }

        print('Found ${servers.length} servers total');
        return servers;
      } else {
        print('Failed to fetch servers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching video servers: $e');
    }

    return [];
  }

  static Future<String?> getVideoUrl(
      String episodeUrl,
      String serverId,
      String type,
      String postId
      ) async {
    try {
      print('Getting video URL for server: $serverId, type: $type');

      // إذا كان serverId يحتوي على رابط مباشر
      if (serverId.startsWith('http')) {
        return await _extractDirectVideoUrl(serverId);
      }

      // إذا كان لدينا معرف الخادم والنوع
      if (serverId.isNotEmpty && type.isNotEmpty) {
        return await _getVideoUrlByAjax(episodeUrl, serverId, type, postId);
      }

      // محاولة استخراج الفيديو من الصفحة مباشرة
      return await _extractVideoFromPage(episodeUrl);

    } catch (e) {
      print('Error getting video URL: $e');
      return null;
    }
  }

  static Future<String?> _extractDirectVideoUrl(String videoPageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(videoPageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': baseUrl,
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // البحث عن عنصر الفيديو
        final videoElement = document.querySelector('video source, video');
        if (videoElement != null) {
          final src = videoElement.attributes['src'];
          if (src != null && src.isNotEmpty) {
            return _makeAbsoluteUrl(src, videoPageUrl);
          }
        }

        // البحث في iframe
        final iframe = document.querySelector('iframe');
        if (iframe != null) {
          final src = iframe.attributes['src'];
          if (src != null && src.isNotEmpty) {
            return await _extractVideoFromIframe(_makeAbsoluteUrl(src, videoPageUrl));
          }
        }
      }
    } catch (e) {
      print('Error extracting direct video URL: $e');
    }

    return null;
  }

  static Future<String?> _getVideoUrlByAjax(
      String episodeUrl,
      String serverId,
      String type,
      String postId
      ) async {
    try {
      // محاولة الحصول على الفيديو عبر AJAX
      final ajaxUrl = '$baseUrl/wp-admin/admin-ajax.php';

      final response = await http.post(
        Uri.parse(ajaxUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['embed_url'] != null) {
          return await _extractVideoFromIframe(data['embed_url']);
        }

        if (data['type'] == 'video' && data['result'] != null) {
          return data['result'];
        }
      }
    } catch (e) {
      print('Error getting video URL by AJAX: $e');
    }

    return null;
  }

  static Future<String?> _extractVideoFromPage(String episodeUrl) async {
    try {
      final response = await http.get(
        Uri.parse(episodeUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // البحث عن روابط الفيديو في الصفحة
        final videoSelectors = [
          'video source[src]',
          'video[src]',
          'iframe[src*="player"]',
          'iframe[src*="embed"]',
          '.video-player iframe',
          '#player iframe',
        ];

        for (String selector in videoSelectors) {
          final element = document.querySelector(selector);
          if (element != null) {
            final src = element.attributes['src'];
            if (src != null && src.isNotEmpty) {
              if (src.contains('.mp4') || src.contains('.m3u8')) {
                return _makeAbsoluteUrl(src, episodeUrl);
              } else {
                // إذا كان iframe، حاول استخراج الفيديو منه
                return await _extractVideoFromIframe(_makeAbsoluteUrl(src, episodeUrl));
              }
            }
          }
        }

        // البحث في JavaScript للحصول على روابط الفيديو
        final scriptTags = document.querySelectorAll('script');
        for (var script in scriptTags) {
          final content = script.text;

          // البحث عن أنماط روابط الفيديو الشائعة
          final videoUrlPatterns = [
            RegExp(r'"(https?://[^"]*\.mp4[^"]*)"'),
            RegExp(r'"(https?://[^"]*\.m3u8[^"]*)"'),
            RegExp(r"'(https?://[^']*\.mp4[^']*)'"),
            RegExp(r"'(https?://[^']*\.m3u8[^']*)'"),
          ];

          for (var pattern in videoUrlPatterns) {
            final match = pattern.firstMatch(content);
            if (match != null) {
              return match.group(1);
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting video from page: $e');
    }

    return null;
  }

  static Future<String?> _extractVideoFromIframe(String iframeUrl) async {
    try {
      final response = await http.get(
        Uri.parse(iframeUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': baseUrl,
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // البحث عن عنصر الفيديو في iframe
        final videoElement = document.querySelector('video source, video');
        if (videoElement != null) {
          final src = videoElement.attributes['src'];
          if (src != null && src.isNotEmpty) {
            return _makeAbsoluteUrl(src, iframeUrl);
          }
        }

        // البحث في JavaScript
        final scriptTags = document.querySelectorAll('script');
        for (var script in scriptTags) {
          final content = script.text;

          final videoUrlPatterns = [
            RegExp(r'"(https?://[^"]*\.mp4[^"]*)"'),
            RegExp(r'"(https?://[^"]*\.m3u8[^"]*)"'),
            RegExp(r"'(https?://[^']*\.mp4[^']*)'"),
            RegExp(r"'(https?://[^']*\.m3u8[^']*)'"),
          ];

          for (var pattern in videoUrlPatterns) {
            final match = pattern.firstMatch(content);
            if (match != null) {
              return match.group(1);
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting video from iframe: $e');
    }

    return null;
  }

  static String _makeAbsoluteUrl(String url, String baseUrl) {
    if (url.startsWith('http')) {
      return url;
    }

    final base = Uri.parse(baseUrl);
    if (url.startsWith('/')) {
      return '${base.scheme}://${base.host}$url';
    } else {
      return '${base.scheme}://${base.host}${base.path.substring(0, base.path.lastIndexOf('/') + 1)}$url';
    }
  }
}