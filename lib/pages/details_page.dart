import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:luma_nome_app/core/models/anime_detail.dart';
import 'package:luma_nome_app/core/services/anime_detail_scraper_service.dart';
import 'episodes_page.dart';

const Color _appBarColor = Color(0xFF14152A);
const Color _backgroundColor = Color(0xFF121215);
const Color _titleAndGenreColor = Color(0xFF7C4CFE);
final Color _ratingColor = Colors.yellow[700]!;
const Color _cardBackgroundColor = Color(0xCA393939);
const Color _cardBorderColor = Color(0xFF7C4CFE);
const Color _shimmerBaseColor = Color(0xFF1E1E1E);
const Color _shimmerHighlightColor = Color(0xFF2D2D2D);

class AnimeDetailPage extends StatefulWidget {
  final String url;

  const AnimeDetailPage({required this.url, Key? key}) : super(key: key);

  @override
  _AnimeDetailPageState createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late Future<AnimeDetail> _futureDetail;

  @override
  void initState() {
    super.initState();
    _futureDetail = AnimeDetailScraper.fetchDetails(widget.url);
  }

  IconData _getIconForInfo(String label) {
    switch (label) {
      case 'النوع': return Icons.merge_type_outlined;
      case 'الحلقات': return Icons.format_list_numbered_rtl_outlined;
      case 'المدة': return Icons.timer_outlined;
      case 'سنة العرض': return Icons.calendar_today_outlined;
      case 'الاستوديو': return Icons.movie_creation_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: FutureBuilder<AnimeDetail>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }
          if (snapshot.hasError) {
            return _buildErrorScreen();
          }
          final anime = snapshot.data!;
          return _buildAnimeDetailContent(anime);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: Shimmer.fromColors(
            baseColor: _shimmerBaseColor,
            highlightColor: _shimmerHighlightColor,
            child: Container(
              color: Colors.grey.shade800,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section Shimmer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: _shimmerBaseColor,
                      highlightColor: _shimmerHighlightColor,
                      child: Container(
                        width: 100,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: _shimmerBaseColor,
                            highlightColor: _shimmerHighlightColor,
                            child: Container(
                              height: 24,
                              width: double.infinity,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Shimmer.fromColors(
                            baseColor: _shimmerBaseColor,
                            highlightColor: _shimmerHighlightColor,
                            child: Container(
                              height: 18,
                              width: 150,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 16),
                          Shimmer.fromColors(
                            baseColor: _shimmerBaseColor,
                            highlightColor: _shimmerHighlightColor,
                            child: Container(
                              height: 30,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Quick Info Shimmer
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 20,
                    width: 80,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(5, (index) => Shimmer.fromColors(
                    baseColor: _shimmerBaseColor,
                    highlightColor: _shimmerHighlightColor,
                    child: Container(
                      width: 100,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )),
                ),
                SizedBox(height: 24),
                // Genres Shimmer
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 20,
                    width: 80,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(4, (index) => Shimmer.fromColors(
                    baseColor: _shimmerBaseColor,
                    highlightColor: _shimmerHighlightColor,
                    child: Container(
                      width: 70,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )),
                ),
                SizedBox(height: 24),
                // Description Shimmer
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 20,
                    width: 80,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Seasons Shimmer
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 20,
                    width: 80,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: _shimmerBaseColor,
                        highlightColor: _shimmerHighlightColor,
                        child: Container(
                          width: 130,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            'حدث خطأ في جلب التفاصيل',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeDetailContent(AnimeDetail anime) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(anime),
        SliverToBoxAdapter(
          child: _buildContentBody(anime),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(AnimeDetail anime) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: _appBarColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: anime.bannerUrl.isNotEmpty ? anime.bannerUrl : anime.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: _shimmerBaseColor,
                highlightColor: _shimmerHighlightColor,
                child: Container(color: _backgroundColor),
              ),
              errorWidget: (context, url, error) => Container(
                color: _backgroundColor,
                child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
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
          ],
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(153),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.white, size: 22),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildContentBody(AnimeDetail anime) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(anime),
          SizedBox(height: 24),
          _buildQuickInfo(anime),
          SizedBox(height: 24),
          _buildGenres(anime),
          SizedBox(height: 24),
          _buildDescription(anime),
          SizedBox(height: 30),
          _buildSeasonsSection(anime),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTitleSection(AnimeDetail anime) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(128),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
      ),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: CachedNetworkImage(
    imageUrl: anime.imageUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Shimmer.fromColors(
    baseColor: _shimmerBaseColor,
    highlightColor: _shimmerHighlightColor,
    child: Container(color: _cardBackgroundColor),
    ),
    errorWidget: (context, url, error) => Container(
    color: _cardBackgroundColor,
    child: Icon(Icons.image, color: Colors.grey),
    ),
    ),
    ),
    ),
    SizedBox(width: 16),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    anime.title,
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    ),
    if (anime.altTitle.isNotEmpty) ...[
    SizedBox(height: 4),
    Text(
    anime.altTitle,
    style: TextStyle(
    fontSize: 14,
    color: Colors.grey[400],
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    ),
    ],
    SizedBox(height: 12),
    Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
    color: _ratingColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: _ratingColor.withAlpha(153),
    blurRadius: 10,
    spreadRadius: 1,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.star, color: Colors.black87, size: 18),
    SizedBox(width: 5),
    Text(
    anime.rating,
    style: TextStyle(
    color: Colors.black87,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    ],
    );
  }

  Widget _buildQuickInfo(AnimeDetail anime) {
    final infos = [
      {'label': 'النوع', 'value': anime.type},
      {'label': 'الحلقات', 'value': anime.episodes},
      {'label': 'المدة', 'value': anime.duration},
      {'label': 'سنة العرض', 'value': anime.releaseYear},
      if (anime.studio.isNotEmpty) {'label': 'الاستوديو', 'value': anime.studio},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: infos.map((info) {
            String label = info['label'] as String;
            String value = info['value'] as String;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorderColor.withAlpha(179), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconForInfo(label), color: _titleAndGenreColor, size: 15),
                  SizedBox(width: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily),
                      children: [
                        TextSpan(text: '$label: ', style: TextStyle(color: Colors.white.withAlpha(204))),
                        TextSpan(text: value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenres(AnimeDetail anime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأنواع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: anime.genres
              .map((genre) => Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _titleAndGenreColor.withAlpha(38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _titleAndGenreColor, width: 1),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDescription(AnimeDetail anime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'القصة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorderColor.withAlpha(179), width: 1),
          ),
          child: Text(
            anime.description.isNotEmpty ? anime.description : 'لا يوجد وصف متوفر حالياً.',
            style: TextStyle(
              color: Colors.white.withAlpha(217),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsSection(AnimeDetail anime) {
    if (anime.seasonImages.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF404040), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.movie_outlined, color: Colors.grey, size: 32),
            SizedBox(height: 8),
            Text(
              'لا توجد مواسم متاحة',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المواسم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _titleAndGenreColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${anime.seasonImages.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 235,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: anime.seasonImages.length,
            itemBuilder: (context, index) {
              return _buildSeasonCard(anime, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonCard(AnimeDetail anime, int index) {
    final hasValidUrl = index < anime.seasonUrls.length &&
        anime.seasonUrls[index].isNotEmpty;

    return Container(
      width: 130,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: hasValidUrl ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeasonEpisodesPage(
                      seasonTitle: 'الموسم ${index + 1}',
                      seasonUrl: anime.seasonUrls[index],
                    ),
                  ),
                );
              } : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasValidUrl ? _cardBorderColor : Color(0xFF404040),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: anime.seasonImages[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: _shimmerBaseColor,
                          highlightColor: _shimmerHighlightColor,
                          child: Container(color: Color(0xFF2A2A2A)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Color(0xFF2A2A2A),
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      if (!hasValidUrl)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Icon(
                              Icons.lock,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      if (hasValidUrl)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _titleAndGenreColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الموسم ${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    hasValidUrl ? 'متاح' : 'غير متاح',
                    style: TextStyle(
                      color: hasValidUrl ? Color(0xFF4CAF50) : Colors.grey,
                      fontSize: 11,
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
}