import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/pages/player_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:luma_nome_app/core/models/anime_episodes.dart';
import 'package:luma_nome_app/core/services/anime_episodes_scraper_service.dart';

const Color _backgroundColor = Color(0xFF121215);
const Color _appBarColor = Color(0xFF14152A);
const Color _cardBackgroundColor = Color(0xCA393939);
const Color _cardBorderColor = Color(0xFF7C4CFE);
const Color _shimmerBaseColor = Color(0xFF1E1E1E);
const Color _shimmerHighlightColor = Color(0xFF2D2D2D);
const Color _downloadButtonColor = Color(0xFF4CAF50);

class SeasonEpisodesPage extends StatefulWidget {
  final String seasonTitle;
  final String seasonUrl;

  const SeasonEpisodesPage({
    required this.seasonTitle,
    required this.seasonUrl,
    Key? key,
  }) : super(key: key);

  @override
  _SeasonEpisodesPageState createState() => _SeasonEpisodesPageState();
}

class _SeasonEpisodesPageState extends State<SeasonEpisodesPage> {
  late Future<List<Episode>> _futureEpisodes;
  late Future<String?> _futureDownloadUrl;
  bool _sortDescending = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureEpisodes = EpisodeScraper.fetchEpisodes(widget.seasonUrl);
    _futureDownloadUrl = EpisodeScraper.fetchDownloadAllUrl(widget.seasonUrl);
  }

  void _refreshEpisodes() {
    setState(() {
      _futureEpisodes = EpisodeScraper.fetchEpisodes(widget.seasonUrl);
    });
  }

  int _extractEpisodeNumber(String title) {
    try {
      final match = RegExp(r'\d+').firstMatch(title);
      if (match != null) {
        return int.parse(match.group(0)!);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(widget.seasonTitle),
        backgroundColor: _appBarColor,
        actions: [
          IconButton(
            icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _sortDescending = !_sortDescending;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshEpisodes,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Episode>>(
              future: _futureEpisodes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }
                if (snapshot.hasError) {
                  return _buildErrorScreen();
                }
                final episodes = snapshot.data!;
                return _buildEpisodesList(episodes);
              },
            ),
          ),
          _buildDownloadAllButton(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'بحث...',
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: _cardBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: _shimmerBaseColor,
          highlightColor: _shimmerHighlightColor,
          child: Container(
            height: 80,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _cardBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'حدث خطأ في جلب الحلقات',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshEpisodes,
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList(List<Episode> episodes) {
    // تصفية الحلقات حسب البحث
    final filteredEpisodes = episodes.where((episode) {
      return episode.title.toLowerCase().contains(_searchQuery);
    }).toList();

    // ترتيب الحلقات رقمياً
    filteredEpisodes.sort((a, b) {
      final aNum = _extractEpisodeNumber(a.title);
      final bNum = _extractEpisodeNumber(b.title);

      if (_sortDescending) {
        return bNum.compareTo(aNum);
      } else {
        return aNum.compareTo(bNum);
      }
    });

    // إضافة رسالة إذا لم يتم العثور على حلقات
    if (filteredEpisodes.isEmpty) {
      return Center(
        child: Text(
          'لا توجد حلقات متطابقة مع بحثك',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEpisodes.length,
      itemBuilder: (context, index) {
        final episode = filteredEpisodes[index];
        return _buildEpisodeCard(episode);
      },
    );
  }

  Widget _buildEpisodeCard(Episode episode) {
    // تخطي الحلقات الفارغة فقط
    if (episode.title.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _cardBorderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('جاري تحميل الفيديو...')),
          );

          try {
            final videoUrl = "https://files.vid3rb.com/files/0020250277/9f0a0e90-d904-44e7-998d-3ec5a7b16772/480p.mp4?e=1749057832&speed=600&t=NC13XmrRpcfavLrLfid1yw&noip=yes";

            if (videoUrl == null || videoUrl.isEmpty) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('تعذر العثور على رابط الفيديو')),
              );
              return;
            }

            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoUrl: videoUrl,
                  episodeTitle: episode.title,
                ),
              ),
            );
          } catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('حدث خطأ أثناء تحميل الفيديو')),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: episode.thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: episode.thumbnail,
                  width: 100,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 60,
                    color: _shimmerBaseColor,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 60,
                    color: _shimmerBaseColor,
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 100,
                  height: 60,
                  color: _shimmerBaseColor,
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      episode.duration,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadAllButton() {
    return FutureBuilder<String?>(
      future: _futureDownloadUrl,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _downloadButtonColor,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // TODO: تنفيذ عملية التحميل
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'تحميل كل الحلقات',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}