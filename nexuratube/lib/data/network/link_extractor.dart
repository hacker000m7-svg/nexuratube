import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

/// نموذج بيانات متكامل يمثل دقة وجودة الروابط المستخرجة
class ExtractedMedia {
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String audioUrl;
  final String quality;
  final String extension;
  final int estimatedSizeInBytes;

  ExtractedMedia({
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.audioUrl,
    required this.quality,
    required this.extension,
    required this.estimatedSizeInBytes,
  });
}

class LinkExtractor {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      // محاكاة متصفح كامل لتجاوز جدران الحماية الأمنية ومنع حظر التطبيق كـ Bot
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
    },
  ));

  /// الدالة الرئيسية لتحليل أي رابط ويب في العالم واستخراج جودات الميديا منه دون قفلات
  Future<List<ExtractedMedia>> extractMediaStreams(String sourceUrl) async {
    List<ExtractedMedia> extractedList = [];

    // تنظيف الرابط وفحصه أمنياً قبل المعالجة
    final String cleanUrl = sourceUrl.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith("http")) {
      throw Exception("الرابط المدخل غير صالح أو لا يحتوي على بروتوكول HTTP/HTTPS");
    }

    try {
      if (cleanUrl.contains("youtube.com") || cleanUrl.contains("youtu.be")) {
        extractedList = await _parseYouTubeStream(cleanUrl);
      } else if (cleanUrl.contains("instagram.com")) {
        extractedList = await _parseInstagramStream(cleanUrl);
      } else if (cleanUrl.contains("tiktok.com")) {
        extractedList = await _parseTikTokStream(cleanUrl);
      } else {
        // فحص المواقع العامة عبر بروتوكول Open Graph (OG Video Tags)
        extractedList = await _parseGenericHtmlStream(cleanUrl);
      }
    } catch (e) {
      debugPrint("🚨 خطأ أثناء كشط الرابط $cleanUrl: $e");
      // نمرر خطأ واضح ومفصل للواجهة بدلاً من جعل التطبيق يقفل فجأة
      throw Exception("تعذر تحليل الرابط، قد يكون المقطع خاصاً أو تم تغيير خوارزمية الموقع الأصلية.");
    }

    return extractedList;
  }

  /// معالجة روابط يوتيوب العميقة واستخراج البث المنفصل (الصوت والصورة) بدقة 4K و 1080p
  Future<List<ExtractedMedia>> _parseYouTubeStream(String url) async {
    List<ExtractedMedia> results = [];
    
    // استخراج الـ Video ID عبر RegExp متطور يدعم كافة أشكال روابط يوتيوب
    final regExp = RegExp(
      r'^.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?\=|\&v(?:i)?\=))([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    final videoId = (match != null && match.groupCount >= 1) ? match.group(1) : null;

    if (videoId == null || videoId.length != 11) {
      throw Exception("فشل استخراج معرف فيديو يوتيوب من الرابط المدخل");
    }

    // طلب بيانات الفيديو الأساسية من سيرفر المشغل المدمج ليوتيوب (Youtube Video Info Endpoint)
    final infoUrl = "https://www.youtube.com/get_video_info?video_id=$videoId&el=embedded";
    final response = await _dio.get(infoUrl);

    if (response.statusCode == 200 && response.data != null) {
      final String rawData = response.data.toString();
      
      // فحص جزيئات كود الـ JSON المدمج داخل السيرفر لاستخراج عينات الـ Streaming
      if (rawData.contains("playerResponse")) {
        // فك تشفير البيانات من نمط URL Query إلى JSON حقيقي
        final Map<String, String> params = Uri.splitQueryString(rawData);
        final String playerResponseStr = params["playerResponse"] ?? "";
        final Map<String, dynamic> playerResponse = json.decode(playerResponseStr);
        
        final dynamic streamingData = playerResponse["streamingData"];
        final dynamic videoDetails = playerResponse["videoDetails"];
        
        final String title = videoDetails["title"] ?? "NexuraVideo_$videoId";
        final String thumbnail = videoDetails["thumbnail"]["thumbnails"].last["url"] ?? "";

        // 1. استخراج الروابط المدمجة الجاهزة (Adaptive formats - للصوت والصورة المنفصلين لأعلى دقة)
        if (streamingData != null && streamingData["adaptiveFormats"] != null) {
          for (var format in streamingData["adaptiveFormats"]) {
            final String streamUrl = format["url"] ?? "";
            if (streamUrl.isEmpty) continue;

            final String mimeType = format["mimeType"] ?? "";
            final String quality = format["qualityLabel"] ?? (format["audioQuality"] ?? "Audio");
            final int size = int.tryParse(format["contentLength"] ?? "0") ?? 0;

            results.add(ExtractedMedia(
              title: title,
              thumbnailUrl: thumbnail,
              videoUrl: mimeType.contains("video") ? streamUrl : "",
              audioUrl: mimeType.contains("audio") ? streamUrl : "",
              quality: quality,
              extension: mimeType.contains("video") ? "mp4" : "mp3",
              estimatedSizeInBytes: size,
            ));
          }
        }
      }
    }
    
    // إذا فشلت الطريقة الداخلية، نلجأ فوراً لخطة الإنقاذ الأمنية بطلب بيانات واجهة إنقاذ بديلة
    if (results.isEmpty) {
      results = await _fallbackScraper(videoId, url);
    }

    return results;
  }

  /// خطة الإنقاذ البرمجية لمعالجة يوتيوب في حال تحديث شيفرات المنصة
  Future<List<ExtractedMedia>> _fallbackScraper(String id, String originalUrl) async {
    List<ExtractedMedia> fallbackResults = [];
    // نستخدم محرك الـ API البديل المحاكي للتنزيل بصيغة عزل تامة
    final response = await _dio.post(
      "https://save-from.net/api/convert",
      data: {"url": originalUrl},
    );
    
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data["url"] != null) {
        for (var sub in data["url"]) {
          fallbackResults.add(ExtractedMedia(
            title: data["meta"]["title"] ?? "Nexura_Fallback_$id",
            thumbnailUrl: data["meta"]["thumbnail"] ?? "",
            videoUrl: sub["url"],
            audioUrl: "",
            quality: sub["quality"] ?? "720p",
            extension: sub["ext"] ?? "mp4",
            estimatedSizeInBytes: 0,
          ));
        }
      }
    }
    return fallbackResults;
  }

  /// كاشط روابط إنستغرام الذكي - يحلل بنية بروتوكول Graphql
  Future<List<ExtractedMedia>> _parseInstagramStream(String url) async {
    List<ExtractedMedia> results = [];
    final String cleanUrl = url.replaceAll("/reels/", "/reel/");
    final response = await _dio.get("$cleanUrl?__a=1&__d=dis");

    if (response.statusCode == 200 && response.data != null) {
      final dynamic mediaData = response.data["graphql"]["shortcode_media"];
      final String title = mediaData["edge_media_to_caption"]["edges"][0]["node"]["text"] ?? "Instagram_Reel";
      final String thumbnail = mediaData["display_url"] ?? "";
      final String videoUrl = mediaData["video_url"] ?? "";

      results.add(ExtractedMedia(
        title: title,
        thumbnailUrl: thumbnail,
        videoUrl: videoUrl,
        audioUrl: "",
        quality: "HD",
        extension: "mp4",
        estimatedSizeInBytes: 0,
      ));
    }
    return results;
  }

  /// كاشط روابط تيك توك المتقدم عبر فك تشفير شيفرات HTML وتجاوز حظر الـ CORS
  Future<List<ExtractedMedia>> _parseTikTokStream(String url) async {
    List<ExtractedMedia> results = [];
    // استخدام سيرفر وسيط خارجي ومحلي لفك تشفير حزم تيك توك المعقدة
    final response = await _dio.get("https://api.tikmate.app/api/lookup?url=$url");
    
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data["success"] == true) {
        final String id = data["id"] ?? "TikTok_Video";
        final String videoUrl = "https://tikmate.app/download/${data["token"]}/${id}.mp4";

        results.add(ExtractedMedia(
          title: "TikTok_$id",
          thumbnailUrl: "",
          videoUrl: videoUrl,
          audioUrl: "",
          quality: "HD No Watermark",
          extension: "mp4",
          estimatedSizeInBytes: 0,
        ));
      }
    }
    return results;
  }

  /// الكاشط العام للمواقع عبر ميزة الـ Open Graph HTML Parsing
  Future<List<ExtractedMedia>> _parseGenericHtmlStream(String url) async {
    List<ExtractedMedia> results = [];
    final response = await _dio.get(url);
    
    if (response.statusCode == 200 && response.data != null) {
      final String html = response.data.toString();
      
      // استخراج الروابط المدمجة عبر وسوم og:video و og:title القياسية للأمن والويب
      final titleMatch = RegExp(r'<meta property="og:title" content="(.*?)"').firstMatch(html);
      final videoMatch = RegExp(r'<meta property="og:video" content="(.*?)"').firstMatch(html);
      final thumbMatch = RegExp(r'<meta property="og:image" content="(.*?)"').firstMatch(html);

      final String title = titleMatch != null ? titleMatch.group(1) ?? "WebVideo" : "WebVideo";
      final String videoUrl = videoMatch != null ? videoMatch.group(1) ?? "" : "";
      final String thumbUrl = thumbMatch != null ? thumbMatch.group(1) ?? "" : "";

      if (videoUrl.isNotEmpty) {
        results.add(ExtractedMedia(
          title: title,
          thumbnailUrl: thumbUrl,
          videoUrl: videoUrl,
          audioUrl: "",
          quality: "Source",
          extension: "mp4",
          estimatedSizeInBytes: 0,
        ));
      }
    }
    return results;
  }
}