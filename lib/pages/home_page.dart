import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'details_page.dart';
import 'package:luma_nome_app/core/models/anime.dart';
import 'package:luma_nome_app/core/services/anime_scraper_service.dart';

import 'list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AnimeScraperService _service = AnimeScraperService();

  late Future<List<Anime>> _trendingAnimes;
  late Future<List<Anime>> _topRatedAnimes;
  late Future<List<Anime>> _allAnimes;

  @override
  void initState() {
    super.initState();
    _trendingAnimes = _service.fetchAnimes(AnimeScraperService.trendingUrl);
    _topRatedAnimes = _service.fetchAnimes(AnimeScraperService.ratingsUrl);
    _allAnimes = _service.fetchAnimes(AnimeScraperService.allUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("استكشف الأنمي", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildAnimeSection("🔥 الأكثر شعبية", _trendingAnimes, AnimeScraperService.trendingUrl),
          const SizedBox(height: 20),
          _buildAnimeSection("🌟 الأعلى تقييماً", _topRatedAnimes, AnimeScraperService.ratingsUrl),
          const SizedBox(height: 20),
          _buildAnimeSection("📚 كل الأنميات", _allAnimes, AnimeScraperService.allUrl),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.white70),
          hintText: "ابحث عن أنمي...",
          hintStyle: TextStyle(color: Colors.white54),
          border: InputBorder.none,
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
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeListPage(title: title, url: url),
                  ),
                );
              },
              child: const Text(
                "الكل",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<Anime>>(
            future: futureList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              } else if (snapshot.hasError) {
                return Center(
                  child: Text("حدث خطأ أثناء تحميل البيانات", style: TextStyle(color: Colors.red)),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("لا توجد بيانات", style: TextStyle(color: Colors.white)));
              }

              final animes = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: animes.length,
                itemBuilder: (context, index) {
                  final anime = animes[index];
                  return _buildAnimeCard(anime);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
        onTap: () {
          // الانتقال إلى صفحة تفاصيل الأنمي مع تمرير الرابط
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailPage(url: anime.link),
            ),
          );
        },
    child:  Container(
      width: 130,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة الغلاف
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: anime.imageUrl,
              height: 160,
              width: 130,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[800]),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
            ),
          ),
          const SizedBox(height: 6),
          // الاسم
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    ),
    );

  }
}
