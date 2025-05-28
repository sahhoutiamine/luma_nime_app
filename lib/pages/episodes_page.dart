import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/pages/player_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:luma_nome_app/core/models/anime_episodes.dart';
import '../core/models/server_player.dart';
import '../core/services/anime_episode_video_scraper_service.dart';
import '../core/services/anime_episodes_scraper_service.dart';

const Color _appBarColor = Color(0xFF14152A);
const Color _backgroundColor = Color(0xFF121215);
const Color _cardBackgroundColor = Color(0xCA393939);
const Color _shimmerBaseColor = Color(0xFF1E1E1E);
const Color _shimmerHighlightColor = Color(0xFF2D2D2D);

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

  @override
  void initState() {
    super.initState();
    _futureEpisodes = SeasonScraperService.fetchSeasonEpisodes(widget.seasonUrl);
  }

  void _showServerOptions(BuildContext context, Episode episode) async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final servers = await VideoScraperService.fetchVideoServers(episode.url);

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      if (servers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد خوادم متاحة لهذه الحلقة')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: _backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختر خادم التشغيل',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return Card(
                        color: _cardBackgroundColor,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.blue,
                          ),
                          title: Text(
                            server.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'نوع الخادم: ${server.type}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await _navigateToVideoPlayer(episode, server);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب الخوادم: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToVideoPlayer(Episode episode, VideoServer server) async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: _backgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري تحضير الفيديو...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );

    try {
      // الحصول على رابط الفيديو الفعلي
      final videoUrl = await VideoScraperService.getVideoUrl(
        episode.url,
        server.serverId,
        server.type,
        server.postId,
      );

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      if (videoUrl != null && videoUrl.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              videoUrl: videoUrl,
              episodeTitle: episode.title,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على رابط الفيديو')),
        );
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحضير الفيديو: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.seasonTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Episode>>(
        future: _futureEpisodes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ في جلب الحلقات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureEpisodes = SeasonScraperService.fetchSeasonEpisodes(widget.seasonUrl);
                      });
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final episodes = snapshot.data!;
          if (episodes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد حلقات متاحة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildEpisodesList(episodes);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4),
          child: Shimmer.fromColors(
            baseColor: _shimmerBaseColor,
            highlightColor: _shimmerHighlightColor,
            child: Card(
              color: _cardBackgroundColor,
              child: SizedBox(
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 20,
                              width: double.infinity,
                              color: Colors.grey.shade800,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: 150,
                              color: Colors.grey.shade800,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodesList(List<Episode> episodes) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return InkWell(
          onTap: () => _showServerOptions(context, episode),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4),
            child: Card(
              color: _cardBackgroundColor,
              elevation: 2,
              child: SizedBox(
                height: 120,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: episode.imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: _shimmerBaseColor,
                          highlightColor: _shimmerHighlightColor,
                          child: Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              episode.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'اضغط للمشاهدة',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}