import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:luma_nome_app/pages/player_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:luma_nome_app/core/models/anime_episodes.dart';
import 'package:luma_nome_app/core/services/anime_episodes_scraper_service.dart';

const Color _backgroundColor = Color(0xFF0A0A0A);
const Color _surfaceColor = Color(0xFF1A1A1A);
const Color _cardColor = Color(0xFF2A2A2A);
const Color _accentColor = Color(0xFF6C63FF);
const Color _secondaryAccent = Color(0xFF00D4AA);
const Color _errorColor = Color(0xFFFF6B6B);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFFB0B0B0);
const Color _textTertiary = Color(0xFF707070);

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

class _SeasonEpisodesPageState extends State<SeasonEpisodesPage>
    with TickerProviderStateMixin {
  late Future<List<Episode>> _futureEpisodes;
  late Future<String?> _futureDownloadUrl;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _sortDescending = false;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _futureEpisodes = EpisodeScraper.fetchEpisodes(widget.seasonUrl);
    _futureDownloadUrl = EpisodeScraper.fetchDownloadAllUrl(widget.seasonUrl);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _refreshEpisodes() {
    setState(() {
      _futureEpisodes = EpisodeScraper.fetchEpisodes(widget.seasonUrl);
    });
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
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
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          _buildEpisodesContent(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: _backgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _accentColor.withOpacity(0.1),
                _backgroundColor,
              ],
            ),
          ),
        ),
        title: Text(
          'حلقات ${widget.seasonTitle}',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _surfaceColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surfaceColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, color: _textPrimary),
            onPressed: _refreshEpisodes,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [

          Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              style: TextStyle(color: _textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'ابحث عن حلقة...',
                hintStyle: TextStyle(color: _textSecondary),
                prefixIcon: Container(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.search_rounded, color: _accentColor, size: 24),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: _textSecondary),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          SizedBox(height: 16),

          // شريط الفلاتر
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  icon: _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  label: _sortDescending ? 'الأحدث أولاً' : 'الأقدم أولاً',
                  onTap: () {
                    setState(() {
                      _sortDescending = !_sortDescending;
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              _buildFilterChip(
                icon: _isGridView ? Icons.list : Icons.grid_view,
                label: _isGridView ? 'قائمة' : 'شبكة',
                onTap: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accentColor, size: 18),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
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
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: _isGridView ? _buildGridShimmer() : _buildListShimmer(),
    );
  }

  Widget _buildListShimmer() {
    return Column(
      children: List.generate(6, (index) {
        return Shimmer.fromColors(
          baseColor: _surfaceColor,
          highlightColor: _cardColor,
          child: Container(
            height: 120,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: _surfaceColor,
          highlightColor: _cardColor,
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: _errorColor,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'حدث خطأ في جلب الحلقات',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshEpisodes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'إعادة المحاولة',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesList(List<Episode> episodes) {
    final filteredEpisodes = episodes.where((episode) {
      return episode.title.toLowerCase().contains(_searchQuery);
    }).toList();

    filteredEpisodes.sort((a, b) {
      final aNum = _extractEpisodeNumber(a.title);
      final bNum = _extractEpisodeNumber(b.title);
      return _sortDescending ? bNum.compareTo(aNum) : aNum.compareTo(bNum);
    });

    if (filteredEpisodes.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: _isGridView
          ? _buildGridView(filteredEpisodes)
          : _buildListView(filteredEpisodes),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: _textTertiary,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد حلقات متطابقة',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                color: _textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Episode> episodes) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        return _buildEpisodeCard(episodes[index], index);
      },
    );
  }

  Widget _buildGridView(List<Episode> episodes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        return _buildEpisodeGridCard(episodes[index], index);
      },
    );
  }

  Widget _buildEpisodeCard(Episode episode, int index) {
    if (episode.title.isEmpty) return SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _playEpisode(episode),
                  child: Container(
                    height: 120,
                    child: Row(
                      children: [
                        _buildEpisodeThumbnail(episode.thumbnail),
                        Expanded(child: _buildEpisodeInfo(episode)),
                        _buildPlayButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodeGridCard(Episode episode, int index) {
    if (episode.title.isEmpty) return SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _playEpisode(episode),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            child: _buildGridThumbnail(episode.thumbnail),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                episode.duration,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          episode.title,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildEpisodeThumbnail(String thumbnail) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
      child: Container(
        width: 100,
        height: 120,
        child: thumbnail.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: thumbnail,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: _surfaceColor,
            child: Center(
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: _surfaceColor,
            child: Icon(Icons.broken_image_rounded, color: _textTertiary),
          ),
        )
            : Container(
          color: _surfaceColor,
          child: Icon(Icons.image_rounded, color: _textTertiary),
        ),
      ),
    );
  }

  Widget _buildGridThumbnail(String thumbnail) {
    return Container(
      width: double.infinity,
      child: thumbnail.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: thumbnail,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: _surfaceColor,
          child: Center(
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: _surfaceColor,
          child: Icon(Icons.broken_image_rounded, color: _textTertiary, size: 32),
        ),
      )
          : Container(
        color: _surfaceColor,
        child: Icon(Icons.image_rounded, color: _textTertiary, size: 32),
      ),
    );
  }

  Widget _buildEpisodeInfo(Episode episode) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            episode.title,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: _textSecondary, size: 16),
              SizedBox(width: 4),
              Text(
                episode.duration,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Container(
      margin: EdgeInsets.all(16),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentColor, _secondaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }



  Future<void> _playEpisode(Episode episode) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 16),
            Text('جاري تحميل الفيديو...'),
          ],
        ),
        backgroundColor: _accentColor,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));

    try {
      const videoUrl = "https://files.vid3rb.com/files/0020250277/9f0a0e90-d904-44e7-998d-3ec5a7b16772/480p.mp4?e=1749746061&speed=600&t=Rse2o0BM5_CH2yAH66cJXg&noip=yes";

      if (videoUrl.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('تعذر العثور على رابط الفيديو'),
            backgroundColor: _errorColor,
          ),
        );
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
            videoUrl: videoUrl,
            episodeTitle: episode.title,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل الفيديو'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }
}