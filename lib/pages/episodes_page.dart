import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/core/models/anime_episodes.dart';

import '../core/services/anime_episodes_scraper_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.seasonTitle),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Episode>>(
        future: _futureEpisodes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في جلب الحلقات', style: TextStyle(color: Colors.white)));
          }

          final episodes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return Card(
                color: Colors.grey[900],
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: CachedNetworkImage(
                    imageUrl: episode.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                  ),
                  title: Text(
                    episode.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("رقم الحلقة: ${episode.number}", style: const TextStyle(color: Colors.grey)),
                      if (episode.date != null)
                        Text("تاريخ النشر: ${episode.date}", style: const TextStyle(color: Colors.grey)),
                      if (episode.duration != null)
                        Text("المدة: ${episode.duration}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    // TODO: تنفيذ مشاهدة الحلقة
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
