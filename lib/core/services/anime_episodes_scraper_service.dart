import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:luma_nome_app/core/models/anime_episodes.dart';

class SeasonScraperService {
  static Future<List<Episode>> fetchSeasonEpisodes(String seasonUrl) async {
    try {
      final response = await http.get(Uri.parse(seasonUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load episodes: ${response.statusCode}');
      }

      final doc = parser.parse(response.body);
      final episodes = <Episode>[];

      final episodeItems = doc.querySelectorAll('.episodes-lists li[data-number]');

      for (var item in episodeItems) {
        try {
          final number = item.attributes['data-number'] ?? '0';

          final titleElement = item.querySelector('.title h3');
          final title = titleElement?.text.trim() ?? 'الحلقة $number';

          final url = item.querySelector('a.read-btn')?.attributes['href'] ?? '';

          final imageElement = item.querySelector('.image');
          final imageUrl = imageElement?.attributes['data-src'] ??
              imageElement?.attributes['style']?.split('url("').last.split('")').first ?? '';

          episodes.add(Episode(
            title: title,
            number: number,
            imageUrl: imageUrl,
            url: url,
          ));
        } catch (e) {
          print('Error parsing episode item: $e');
        }
      }

      if (episodes.isEmpty) {
        throw Exception('No episodes found on the page');
      }

      return episodes;
    } catch (e) {
      print('Error fetching season episodes: $e');
      throw Exception('Failed to load episodes: $e');
    }
  }
}