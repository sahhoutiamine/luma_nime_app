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
const Color _watchButtonColor = Color(0xFF4CAF50);

class AnimeDetailPage extends StatefulWidget {
  final String url;

  const AnimeDetailPage({required this.url, Key? key}) : super(key: key);

  @override
  _AnimeDetailPageState createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late Future<AnimeDetail> _futureDetail;
  bool _showFullDescription = false;

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
      case 'إصدار':
      case 'سنة العرض': return Icons.calendar_today_outlined;
      case 'الاستوديو': return Icons.movie_creation_outlined;
      case 'الحالة': return Icons.info_outline;
      case 'التقييم': return Icons.star_outline;
      case 'التصنيف العمري': return Icons.people_outline;
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
          expandedHeight: 200,
          pinned: true,
          backgroundColor: _appBarColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Shimmer.fromColors(
              baseColor: _shimmerBaseColor,
              highlightColor: _shimmerHighlightColor,
              child: Container(
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(6, (index) => Shimmer.fromColors(
                    baseColor: _shimmerBaseColor,
                    highlightColor: _shimmerHighlightColor,
                    child: Container(
                      width: 120,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  )),
                ),
                SizedBox(height: 24),
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
                SizedBox(height: 24),
                Shimmer.fromColors(
                  baseColor: _shimmerBaseColor,
                  highlightColor: _shimmerHighlightColor,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _futureDetail = AnimeDetailScraper.fetchDetails(widget.url);
              });
            },
            child: Text('إعادة المحاولة'),
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
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _appBarColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill( // هذا سيجعل الصورة تأخذ كامل المساحة المتاحة
              child: anime.bannerUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: anime.bannerUrl,
                fit: BoxFit.cover, // تغطي كامل المساحة مع الحفاظ على نسبة الأبعاد
                placeholder: (context, url) => Container(color: _appBarColor),
                errorWidget: (context, url, error) => Container(
                  color: _appBarColor,
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              )
                  : Container(color: _appBarColor),
            ),
            // Gradient overlay at the bottom
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
          if (anime.genres.isNotEmpty) ...[
            _buildGenres(anime),
            SizedBox(height: 24),
          ],
          _buildDescription(anime),
          SizedBox(height: 24),
          _buildWatchButton(anime),
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
            child: anime.imageUrl.isNotEmpty
                ? CachedNetworkImage(
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
            )
                : Container(
              color: _cardBackgroundColor,
              child: Icon(Icons.image, color: Colors.grey, size: 32),
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
                    color: Colors.white),
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

  Widget _buildWatchButton(AnimeDetail anime) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          String episodesUrl = widget.url;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeasonEpisodesPage(
                seasonTitle: 'حلقات ${anime.title}',
                seasonUrl: episodesUrl,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _watchButtonColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: _watchButtonColor.withAlpha(128),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 24),
            SizedBox(width: 8),
            Text(
              'مشاهدة الأنمي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(AnimeDetail anime) {
    final infos = [
      if (anime.type.isNotEmpty) {'label': 'النوع', 'value': anime.type},
      if (anime.episodes.isNotEmpty) {'label': 'الحلقات', 'value': anime.episodes},
      if (anime.duration.isNotEmpty) {'label': 'المدة', 'value': anime.duration},
      if (anime.releaseYear.isNotEmpty) {'label': 'إصدار', 'value': anime.releaseYear},
      if (anime.studio.isNotEmpty) {'label': 'الاستوديو', 'value': anime.studio},
      if (anime.status.isNotEmpty) {'label': 'الحالة', 'value': anime.status},
    ];

    if (infos.isEmpty) {
      return SizedBox.shrink();
    }

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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorderColor.withAlpha(179), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIconForInfo(label), color: _titleAndGenreColor, size: 16),
                  SizedBox(width: 8),
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
    final displayedGenres = anime.genres.take(4).toList();

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
          children: displayedGenres
              .map((genre) => Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: _titleAndGenreColor.withAlpha(38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _titleAndGenreColor, width: 1),
            ),
            child: Text(
              genre,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
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
    final description = anime.description.isNotEmpty ? anime.description : 'لا يوجد وصف متوفر حالياً.';
    final shortDescription = _showFullDescription
        ? description
        : (description.length > 150
        ? '${description.substring(0, 150)}...'
        : description);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shortDescription,
                style: TextStyle(
                  color: Colors.white.withAlpha(217),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              if (description.length > 150) ...[
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullDescription = !_showFullDescription;
                    });
                  },
                  child: Text(
                    _showFullDescription ? 'عرض أقل' : 'عرض المزيد',
                    style: TextStyle(
                      color: _titleAndGenreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}