import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'details_page.dart';
import 'package:luma_nome_app/core/models/anime.dart';
import 'package:luma_nome_app/core/services/anime_scraper_service.dart';


class AnimeListPage extends StatefulWidget {
  final String title;
  final String url;

  const AnimeListPage({super.key, required this.title, required this.url});

  @override
  State<AnimeListPage> createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> {
  final AnimeScraperService _service = AnimeScraperService();
  final ScrollController _scrollController = ScrollController();
  List<Anime> _animes = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadAnimes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore) {
      _loadAnimes();
    }
  }

  Future<void> _loadAnimes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final newAnimes = await _service.fetchAnimes('${widget.url}page/$_currentPage/');

      setState(() {
        _animes.addAll(newAnimes);
        _currentPage++;
        _hasMore = newAnimes.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification && _scrollController.position.extentAfter == 0) {
            _loadAnimes();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _animes.length + 1,
          itemBuilder: (context, index) {
            if (index < _animes.length) {
              return _buildAnimeCard(_animes[index]);
            } else {
              return _buildLoader();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPage(url: anime.link),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: anime.imageUrl,
                width: 100,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 150,
                  color: Colors.grey[800],
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 150,
                  color: Colors.grey[800],
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'النوع: ${anime.type}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'السنة: ${anime.year}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return _hasMore
        ? const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    )
        : const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'تم عرض كل المحتوى',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}