import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'details_page.dart';
import 'package:luma_nome_app/core/models/anime.dart';
import 'package:luma_nome_app/core/services/anime_scraper_service.dart';

const Color _shimmerBaseColor = Color(0xFF1E1E1E);
const Color _shimmerHighlightColor = Color(0xFF2D2D2D);
const Color _backgroundColor = Colors.black;
const Color _appBarColor = Colors.black;
const Color _textColor = Colors.white;

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
  bool _isGridView = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPreferences().then((_) {
      _loadAnimes();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = _prefs.getBool('isGridView') ?? false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9 &&
        _hasMore &&
        !_isLoading) {
      _loadAnimes();
    }
  }

  Future<void> _loadAnimes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      List<Anime> newAnimes = [];

      // Determine which method to use based on the URL
      if (widget.url.contains('sort_by=release_date')) {
        newAnimes = await _service.getAnimesByReleaseDate(page: _currentPage);
      } else if (widget.url.contains('sort_by=rate')) {
        newAnimes = await _service.getAnimesByRating(page: _currentPage);
      } else {
        newAnimes = await _service.getTrendingAnimes(page: _currentPage);
      }

      setState(() {
        if (newAnimes.isNotEmpty) {
          _animes.addAll(newAnimes);
          _currentPage++;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });

      // Check if there are more pages available
      if (newAnimes.isNotEmpty) {
        final hasMorePages = await _service.hasMorePages(widget.url, _currentPage - 1);
        setState(() {
          _hasMore = hasMorePages;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (_animes.isEmpty) {
          _hasMore = false;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshAnimes() async {
    setState(() {
      _animes.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadAnimes();
  }

  void _toggleViewMode() async {
    setState(() {
      _isGridView = !_isGridView;
    });
    await _prefs.setBool('isGridView', _isGridView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: _textColor)),
        backgroundColor: _appBarColor,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _textColor,
            ),
            onPressed: _refreshAnimes,
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: _textColor,
            ),
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_animes.isEmpty && _isLoading) {
      return _buildShimmerLoading();
    }

    if (_animes.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد أنميات للعرض',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshAnimes,
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAnimes,
      backgroundColor: _appBarColor,
      color: _textColor,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _animes.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _animes.length) {
          return _buildLoader();
        }
        return _buildAnimeCard(_animes[index]);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: _animes.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _animes.length) {
          return _buildGridLoader();
        }
        return _buildGridItem(_animes[index]);
      },
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () => _navigateToDetail(anime.link),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimeImage(anime.imageUrl, 100, 150),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (anime.type.isNotEmpty)
                      Text(
                        'النوع: ${anime.type}',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (anime.year.isNotEmpty)
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
      ),
    );
  }

  Widget _buildGridItem(Anime anime) {
    return GestureDetector(
      onTap: () => _navigateToDetail(anime.link),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildAnimeImage(anime.imageUrl, double.infinity, double.infinity),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  anime.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimeImage(String imageUrl, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: Container(
            width: width,
            height: height,
            color: Colors.grey[800],
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.movie, color: Colors.white54, size: 32),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return _hasMore || _isLoading
        ? const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    )
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          'لا توجد أنميات أخرى',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGridLoader() {
    return _hasMore || _isLoading
        ? Shimmer.fromColors(
      baseColor: _shimmerBaseColor,
      highlightColor: _shimmerHighlightColor,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  Widget _buildShimmerLoading() {
    return _isGridView ? _buildGridShimmer() : _buildListShimmer();
  }

  Widget _buildListShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      padding: const EdgeInsets.all(8),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetail(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimeDetailPage(url: url),
      ),
    );
  }
}