import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/Sign-in-up/login_page.dart';
import 'package:luma_nome_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'package:shimmer/shimmer.dart';
import 'details_page.dart';
import 'package:luma_nome_app/core/models/anime.dart';
import 'package:luma_nome_app/core/services/anime_scraper_service.dart';
import 'list_page.dart';

const Color _backgroundColor = Color(0xFF121215);
const Color _primaryColor = Color(0xFF7C4CFE);
const Color _textColor = Colors.white;
const Color _shimmerBaseColor = Color(0xFF1E1E1E);
const Color _shimmerHighlightColor = Color(0xFF2D2D2D);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AnimeScraperService _service = AnimeScraperService();

  late Future<List<Anime>> _trendingAnimes;
  late Future<List<Anime>> _topRatedAnimes;
  Anime? _featuredAnime;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _trendingAnimes = _service.fetchAnimes(AnimeScraperService.releaseDateUrl);
    _topRatedAnimes = _service.fetchAnimes(AnimeScraperService.ratingsUrl);

    _service.fetchAnimes(AnimeScraperService.releaseDateUrl).then((list) {
      setState(() {
        _featuredAnime = (list..shuffle()).first;
      });
    });
  }

  void logout(BuildContext context) async {
    final _firebaseAuth = AuthService();
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isUserLoggedIn', false);
      await _firebaseAuth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Logout Failed"),
          content: Text(e.toString()),
        ),
      );
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
  pinned: true,
  floating: true,
  expandedHeight: 480,
  flexibleSpace: FlexibleSpaceBar(
    background: _buildFeaturedAnimeBanner(),
  ),
  backgroundColor: _backgroundColor,
  elevation: 0,
  title: _buildSearchBar(),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      tooltip: 'تسجيل الخروج',
      onPressed: () {
       logout(context);
      },
    ),
  ],
),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAnimeSection("🔥 الأكثر شعبية", _trendingAnimes, AnimeScraperService.releaseDateUrl),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAnimeSection("🌟 الأعلى تقييماً", _topRatedAnimes, AnimeScraperService.ratingsUrl),
              ),
              const SizedBox(height: 30),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: _primaryColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: _textColor),
                  decoration: const InputDecoration(
                    hintText: "ابحث عن أنمي...",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedAnimeBanner() {
    if (_featuredAnime == null) {
      return Shimmer.fromColors(
        baseColor: _shimmerBaseColor,
        highlightColor: _shimmerHighlightColor,
        child: Container(
          height: 480,
          width: double.infinity,
          color: Colors.grey.shade900,
        ),
      );
    }

    final imageUrl = _featuredAnime!.imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeDetailPage(url: _featuredAnime!.link),
          ),
        );
      },
      child: SizedBox(
        height: 480,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: _shimmerBaseColor,
                highlightColor: _shimmerHighlightColor,
                child: Container(
                  color: Colors.grey.shade900,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white70, size: 50),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x80121215),
                    Color(0xFF121215),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _featuredAnime!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _featuredAnime!.year,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimeSection(String title, Future<List<Anime>> futureList, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeListPage(title: title, url: url),
                  ),
                );
              },
              child: const Text(
                "عرض الكل",
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<Anime>>(
            future: futureList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading();
              } else if (snapshot.hasError) {
                return Center(
                  child: Text("فشل التحميل", style: TextStyle(color: Colors.red[300])),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text("لا توجد بيانات", style: TextStyle(color: Colors.grey[400])),
                );
              }

              final animes = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: animes.length,
                itemBuilder: (context, index) {
                  return _buildAnimeCard(animes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AnimeDetailPage(url: anime.link)),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: anime.imageUrl,
                height: 220,
                width: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    color: Colors.grey.shade800,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}