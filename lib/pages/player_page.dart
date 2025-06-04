import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String episodeTitle;

  const VideoPlayerScreen({
    required this.videoUrl,
    required this.episodeTitle,
    Key? key,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          placeholder: Container(color: Colors.black),
          autoInitialize: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.red,
            handleColor: Colors.red,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.withOpacity(0.5),
          ),
      );

          setState(() {
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
    _hasError = true;
    _isLoading = false;
    });
    print('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episodeTitle),
      ),
      body: _buildVideoPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('حدث خطأ في تحميل الفيديو'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}