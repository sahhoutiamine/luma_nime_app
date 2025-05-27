import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/core/models/anime_episodes.dart';

import '../core/services/anime_episodes_scraper_service.dart';


const Color _appBarColor = Color(0xFF14152A);
const Color _backgroundColor = Color(0xFF20202C);
const Color _titleAndGenreColor = Color(0xFF7C4CFE);
const Color _cardBackgroundColor = Color(0xFF2A2A2A); // لون خلفية البطاقات والكروت


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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(widget.seasonTitle),
        backgroundColor: _appBarColor,
        foregroundColor: _titleAndGenreColor,
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4),
                child: Card(
                  color: _cardBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                            topRight: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: episode.imageUrl,
                            width: 120,
                            height: 120, // <-- Match the card's height
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 100,
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, // <-- Center content vertically
                            children: [
                              Text(
                                episode.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("رقم الحلقة: ${episode.number}", style: const TextStyle(color: Colors.grey)),
                              if (episode.date != null)
                                Text("تاريخ النشر: ${episode.date}", style: const TextStyle(color: Colors.grey)),
                              if (episode.duration != null)
                                Text("المدة: ${episode.duration}", style: const TextStyle(color: Colors.grey)),
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
        },
      ),
    );
  }
}
