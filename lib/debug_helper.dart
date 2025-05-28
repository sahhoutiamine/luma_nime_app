import 'package:flutter/foundation.dart';

import 'core/models/server_player.dart';

class DebugHelper {
  static const bool _isDebugMode = kDebugMode;

  static void log(String message, [String? tag]) {
    if (_isDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 23);
      final tagString = tag != null ? '[$tag] ' : '';
      print('[$timestamp] $tagString$message');
    }
  }

  static void logError(String error, [String? tag]) {
    if (_isDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 23);
      final tagString = tag != null ? '[$tag] ' : '';
      print('[$timestamp] ${tagString}ERROR: $error');
    }
  }

  static void logVideoServer(VideoServer server) {
    if (_isDebugMode) {
      log('Video Server Details:', 'SERVER');
      log('  Name: ${server.name}', 'SERVER');
      log('  Server ID: ${server.serverId}', 'SERVER');
      log('  Type: ${server.type}', 'SERVER');
      log('  Post ID: ${server.postId}', 'SERVER');
      log('  Is Valid: ${server.isValid}', 'SERVER');
    }
  }

  static void logVideoUrl(String url, [String? context]) {
    if (_isDebugMode) {
      final contextString = context != null ? ' ($context)' : '';
      log('Video URL$contextString: $url', 'VIDEO');
    }
  }

  static void logHttpRequest(String url, [Map<String, String>? headers]) {
    if (_isDebugMode) {
      log('HTTP Request: $url', 'HTTP');
      if (headers != null && headers.isNotEmpty) {
        log('Headers:', 'HTTP');
        headers.forEach((key, value) {
          log('  $key: $value', 'HTTP');
        });
      }
    }
  }

  static void logHttpResponse(int statusCode, String url) {
    if (_isDebugMode) {
      log('HTTP Response: $statusCode for $url', 'HTTP');
    }
  }
}

// إضافة extension للفئات الموجودة
extension VideoServerDebug on VideoServer {
  void logDetails() => DebugHelper.logVideoServer(this);
}

// فئة لمراقبة حالة التطبيق
class AppStateMonitor {
  static void logPageNavigation(String from, String to) {
    DebugHelper.log('Navigation: $from -> $to', 'NAV');
  }

  static void logPlayerState(String state, [String? details]) {
    final detailsString = details != null ? ' - $details' : '';
    DebugHelper.log('Player State: $state$detailsString', 'PLAYER');
  }

  static void logScrapingAttempt(String url, String type) {
    DebugHelper.log('Scraping Attempt: $type from $url', 'SCRAPER');
  }

  static void logScrapingResult(int serversFound, String url) {
    DebugHelper.log('Scraping Result: Found $serversFound servers from $url', 'SCRAPER');
  }
}

class DebugConfig {
  static const bool enableNetworkLogs = true;
  static const bool enablePlayerLogs = true;
  static const bool enableScrapingLogs = true;
  static const bool enableNavigationLogs = true;

  static const Duration httpTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // روابط تجريبية للاختبار
  static const List<String> testVideoUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
  ];

  static String getTestVideoUrl() {
    return testVideoUrls.first;
  }
}