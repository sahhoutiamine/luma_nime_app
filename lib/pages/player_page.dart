import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:luma_nome_app/core/models/server_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String episodeTitle;
  final String? serverName;
  final List<VideoServer>? alternativeServers;
  final Function(VideoServer)? onServerChanged;

  const VideoPlayerPage({
    required this.videoUrl,
    required this.episodeTitle,
    this.serverName,
    this.alternativeServers,
    this.onServerChanged,
    Key? key,
  }) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFullScreen = false;
  bool _showServerOptions = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayer() async {
    try {
      print('Initializing video player with URL: ${widget.videoUrl}');

      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // تحديد نوع الفيديو بناء على الرابط
      final formatHint = widget.videoUrl.contains('.m3u8')
          ? VideoFormat.hls
          : (widget.videoUrl.contains('.mpd') ? VideoFormat.dash : null);

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        formatHint: formatHint,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://web.animerco.org/',
        },
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
        customControls: const CupertinoControls(
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Colors.white,
        ),
      );

      _chewieController!.addListener(_chewieListener);

      setState(() {
        _isLoading = false;
      });

      print('Video player initialized successfully');
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _chewieListener() {
    if (_chewieController != null) {
      final isFullScreen = _chewieController!.isFullScreen;
      if (_isFullScreen != isFullScreen) {
        setState(() {
          _isFullScreen = isFullScreen;
        });

        if (isFullScreen) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        }
      }
    }
  }

  void _retryInitialization() {
    _dispose();
    _initializePlayer();
  }

  void _dispose() {
    _chewieController?.removeListener(_chewieListener);
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    _chewieController = null;
  }

  @override
  void dispose() {
    _dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
        title: Text(
          widget.episodeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF14152A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.alternativeServers != null &&
              widget.alternativeServers!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => setState(() {
                _showServerOptions = !_showServerOptions;
              }),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showVideoInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_showServerOptions && widget.alternativeServers != null)
            _buildServerOptions(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'جاري تحميل الفيديو...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ]),
      );
    }

    if (_hasError) {
      return _buildErrorWidget(_errorMessage);
    }

    if (_chewieController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoPlayerController.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    return const Center(
      child: Text('خطأ غير متوقع', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'تعذر تحميل الفيديو',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.serverName != null)
              Text(
                'الخادم: ${widget.serverName}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _retryInitialization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('العودة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerOptions() {
    return Positioned(
      top: 80,
      right: 20,
      left: 20,
      child: Material(
        color: const Color(0xFF14152A),
        borderRadius: BorderRadius.circular(8),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر خادم تشغيل آخر:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.alternativeServers!.map((server) {
                return ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
                  title: Text(
                    server.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'نوع الخادم: ${server.type}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    setState(() {
                      _showServerOptions = false;
                    });
                    if (widget.onServerChanged != null) {
                      widget.onServerChanged!(server);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14152A),
          title: const Text(
            'معلومات الحلقة',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('العنوان:', widget.episodeTitle),
                if (widget.serverName != null)
                  _buildInfoRow('الخادم:', widget.serverName!),
                _buildInfoRow('رابط التشغيل:', widget.videoUrl),
                if (_videoPlayerController.value.isInitialized) ...[
                  _buildInfoRow(
                    'المدة:',
                    _formatDuration(_videoPlayerController.value.duration),
                  ),
                  _buildInfoRow(
                    'الجودة:',
                    _getVideoQuality(_videoPlayerController.value.size),
                  ),
                ],
                if (widget.alternativeServers != null)
                  _buildInfoRow(
                    'الخوادم المتاحة:',
                    widget.alternativeServers!.length.toString(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إغلاق',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  String _getVideoQuality(Size size) {
    final height = size.height;
    if (height >= 1080) return 'FHD (1080p)';
    if (height >= 720) return 'HD (720p)';
    if (height >= 480) return 'SD (480p)';
    return '${height.toInt()}p';
  }
}