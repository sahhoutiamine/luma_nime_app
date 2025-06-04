import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

import 'package:luma_nome_app/core/models/anime.dart';

class AnimeScraperService {
  // URLs - Updated for new website with pagination support
  static const String allUrl = 'https://anime3rb.com/titles/list';
  static const String releaseDateUrl = 'https://anime3rb.com/titles/list?sort_by=release_date';
  static const String ratingsUrl = 'https://anime3rb.com/titles/list?sort_by=rate';

  Future<List<Anime>> fetchAnimes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        // Updated selector for new website structure
        final elements = document.querySelectorAll('.title-card');

        return elements.map((element) {
          // Extract image URL from img src
          final imageElement = element.querySelector('img');
          String imageUrl = imageElement?.attributes['src'] ?? '';

          // Make sure image URL is absolute
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
            imageUrl = 'https://anime3rb.com$imageUrl';
          }

          // Extract title from h2 with class title-name
          final titleElement = element.querySelector('h2.title-name');
          final title = titleElement?.text.trim() ?? 'بدون عنوان';

          // Extract link from the first anchor tag
          final linkElement = element.querySelector('a');
          String link = linkElement?.attributes['href'] ?? '';

          // Make sure link is absolute
          if (link.isNotEmpty && !link.startsWith('http')) {
            link = 'https://anime3rb.com$link';
          }

          // Extract genres
          final genresElement = element.querySelector('.genres');
          final genreSpans = genresElement?.querySelectorAll('span') ?? [];
          final type = genreSpans.isNotEmpty
              ? genreSpans.map((span) => span.text.trim()).join(', ')
              : '';

          // Extract year/season from badge
          final badges = element.querySelectorAll('.badge');
          String year = '';
          for (var badge in badges) {
            final badgeText = badge.text.trim();
            // Look for season/year patterns (like "ربيع 2025")
            if (badgeText.contains(RegExp(r'\d{4}'))) {
              year = badgeText;
              break;
            }
          }

          return Anime(
            title: title,
            imageUrl: imageUrl,
            link: link,
            type: type,
            year: year,
          );
        }).toList();
      } else {
        throw Exception('فشل تحميل البيانات من $url - Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب البيانات: $e');
    }
  }

  // Updated method to build paginated URLs
  String buildPaginatedUrl(String baseUrl, int page) {
    if (page <= 1) return baseUrl;

    // Check if URL already has query parameters
    if (baseUrl.contains('?')) {
      return '$baseUrl&page=$page';
    } else {
      return '$baseUrl?page=$page';
    }
  }

  // Helper methods to get animes with pagination support
  Future<List<Anime>> getTrendingAnimes({int page = 1}) async {
    final url = buildPaginatedUrl(allUrl, page);
    return await fetchAnimes(url);
  }

  Future<List<Anime>> getAnimesByReleaseDate({int page = 1}) async {
    final url = buildPaginatedUrl(releaseDateUrl, page);
    return await fetchAnimes(url);
  }

  Future<List<Anime>> getAnimesByRating({int page = 1}) async {
    final url = buildPaginatedUrl(ratingsUrl, page);
    return await fetchAnimes(url);
  }

  // Method to check if there are more pages available
  Future<bool> hasMorePages(String baseUrl, int currentPage) async {
    try {
      final nextPageUrl = buildPaginatedUrl(baseUrl, currentPage + 1);
      final response = await http.get(Uri.parse(nextPageUrl));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('.title-card');
        return elements.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Method to extract additional details like rating and episode count
  Map<String, String> extractAdditionalInfo(Element element) {
    final badges = element.querySelectorAll('.badge');
    String rating = '';
    String episodes = '';

    for (var badge in badges) {
      final badgeText = badge.text.trim();

      // Extract rating (contains star icon)
      if (badge.querySelector('svg') != null && badgeText.contains(RegExp(r'\d+\.\d+'))) {
        rating = badgeText.replaceAll(RegExp(r'[^\d\.]'), '');
      }

      // Extract episode count (contains "حلقات" or "حلقة")
      if (badgeText.contains('حلقات') || badgeText.contains('حلقة')) {
        episodes = badgeText;
      }
    }

    return {
      'rating': rating,
      'episodes': episodes,
    };
  }
}