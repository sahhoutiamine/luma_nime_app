import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class VideoUrlExtractor {
  static Future<String?> extractVideoUrl(String episodeUrl) async {
    final completer = Completer<String?>();

    // Declare the controller first
    final webViewController = WebViewController();

    // Then configure it
    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            try {
              final videoUrl = await webViewController.runJavaScriptReturningResult(
                  "document.querySelector('video#video_html5_api')?.src || ''"
              ) as String?;

              if (videoUrl != null && videoUrl.isNotEmpty && videoUrl != 'null') {
                completer.complete(videoUrl);
              } else {
                completer.complete(null);
              }
            } catch (e) {
              completer.complete(null);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(episodeUrl));

    return completer.future;
  }
}