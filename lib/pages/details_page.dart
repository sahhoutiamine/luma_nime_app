import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/core/models/anime_detail.dart';
import 'package:luma_nome_app/core/services/anime_detail_scraper_service.dart';
import 'package:luma_nome_app/pages/episodes_page.dart'; // افترض أن هذا هو اسم الصفحة الصحيح للمواسم

// تعريف الألوان المطلوبة كمتغيرات لتسهيل استخدامها
const Color _appBarColor = Color(0xFF14152A);
const Color _backgroundColor = Color(0xFF20202C);
const Color _titleAndGenreColor = Color(0xFF7C4CFE);
final Color _ratingColor = Colors.yellow[700]!; // درجة لون أصفر للتقييم
const Color _cardBackgroundColor = Color(0xFF2A2A2A); // لون خلفية البطاقات والكروت
const Color _cardBorderColor = Color(0xFF404040); // لون حدود البطاقات

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

  // Helper function to get icon for info chips
  IconData _getIconForInfo(String label) {
    switch (label) {
      case 'النوع':
        return Icons.merge_type_outlined;
      case 'الحلقات':
        return Icons.format_list_numbered_rtl_outlined;
      case 'المدة':
        return Icons.timer_outlined;
      case 'سنة العرض':
        return Icons.calendar_today_outlined;
      case 'الاستوديو':
        return Icons.movie_creation_outlined;
      default:
        return Icons.info_outline;
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
            return _buildLoadingScreen();
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            print(snapshot.stackTrace);
            return _buildErrorScreen();
          }
          final anime = snapshot.data!;
          return _buildAnimeDetailContent(anime);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_titleAndGenreColor),
          ),
          SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 16),
          ),
        ],
      ),
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
              placeholder: (context, url) => Container(
                color: _backgroundColor.withAlpha((0.5 * 255).round()), // 128
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_titleAndGenreColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: _backgroundColor.withAlpha((0.5 * 255).round()), // 128
                child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _appBarColor.withAlpha((0.3 * 255).round()), // 77
                      _appBarColor.withAlpha((0.9 * 255).round()), // 230
                    ],
                    stops: [0.5, 0.8, 1.0]),
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.6 * 255).round()), // 153
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
            color: Colors.black.withAlpha((0.6 * 255).round()), // 153
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.white, size: 22),
            onPressed: () {
              // إضافة للمفضلة
            },
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
                color: Colors.black.withAlpha((0.5 * 255).round()), // 128
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
              placeholder: (context, url) => Container(color: _cardBackgroundColor),
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
            mainAxisAlignment: MainAxisAlignment.start,
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
                      color: _ratingColor.withAlpha((0.6 * 255).round()), // 153
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
            color: _titleAndGenreColor,
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
                border: Border.all(color: _cardBorderColor.withAlpha((0.7 * 255).round()), width: 1), // 179
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
                          // TextSpan for label, e.g., white with 80% opacity
                          TextSpan(text: '$label: ', style: TextStyle(color: Colors.white.withAlpha((0.8 * 255).round()))), // 204
                          TextSpan(text: value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ]),
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
            color: _titleAndGenreColor,
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
              color: _titleAndGenreColor.withAlpha((0.15 * 255).round()), // 38
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _titleAndGenreColor, width: 1),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: _titleAndGenreColor,
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
            color: _titleAndGenreColor,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorderColor.withAlpha((0.7 * 255).round()), width: 1), // 179
          ),
          child: Text(
            anime.description.isNotEmpty ? anime.description : 'لا يوجد وصف متوفر حالياً.',
            style: TextStyle(
              color: Colors.white.withAlpha((0.85 * 255).round()), // 217
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
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: _cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorderColor.withAlpha((0.7 * 255).round()), width: 1), // 179
        ),
        child: Column(
          children: [
            Icon(Icons.movie_filter_outlined, color: Colors.grey[600], size: 36),
            SizedBox(height: 12),
            Text(
              'لا توجد مواسم متاحة لهذا الأنمي',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
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
                color: _titleAndGenreColor,
              ),
            ),
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
        SizedBox(
          height: 155, // Adjust this height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: anime.seasonImages.length,
            itemBuilder: (context, index) {
              final seasonUrl = anime.seasonUrls.length > index ? anime.seasonUrls[index] : '';
              final seasonTitle = 'موسم ${index + 1}'; // Or use actual season name if available

              return InkWell(
                onTap: () {
                  if (seasonUrl.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeasonEpisodesPage(
                          seasonTitle: seasonTitle,
                          seasonUrl: seasonUrl,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('رابط الموسم غير متوفر أو غير صالح')),
                    );
                  }
                },
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.4 * 255).round()), // 102
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: anime.seasonImages[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: _cardBackgroundColor),
                            errorWidget: (context, url, error) => Container(
                              color: _cardBackgroundColor,
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        seasonTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}