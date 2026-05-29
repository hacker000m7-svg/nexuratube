import 'import_helper.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DownloadEngine {
  final Dio _dio = Dio();
  
  /// محرك التنزيل الخارق: يقسم الملف إلى 4 أجزاء متوازية لكسر سرعة السيرفر
  Future<void> startChunkedDownload({
    required String url,
    required String fileName,
    required Function(double progress, double speedInKB) onProgress,
    required Function(String filePath) onComplete,
    required Function(String error) onError,
  }) async {
    
    // 1. طلب الصلاحيات الصارمة وإيقاف العملية فوراً إذا تم الرفض لتجنب الانهيار
    if (await Permission.manageExternalStorage.request().isDenied) {
      if (await Permission.storage.request().isDenied) {
        onError("تم رفض صلاحيات التخزين الجذرية، لا يمكن إنشاء أو حفظ الملف.");
        return;
      }
    }

    final String rootPath = '/storage/emulated/0/Nexuratube';
    final Directory appDir = Directory(rootPath);
    
    try {
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      
      final String savePath = "$rootPath/$fileName";
      final File targetFile = File(savePath);
      
      // قراءة إعدادات الخنق (Throttling) من قاعدة البيانات المحلية
      final box = Hive.box('settingsBox');
      final bool isSpeedLimited = box.get('limitSpeed', defaultValue: false);
      final int maxSpeedKB = box.get('maxSpeedValue', defaultValue: 1024);

      // جلب الحجم الكلي للملف (Content-Length)
      Response headResponse = await _dio.head(url);
      int totalBytes = int.parse(headResponse.headers.value('content-length') ?? '0');
      
      // إذا كان السيرفر يخفي الحجم، نستخدم التنزيل بمسار واحد متصل
      if (totalBytes <= 0) {
        await _dio.download(url, savePath, onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total, 0.0);
        });
        onComplete(savePath);
        return;
      }

      // 2. هندسة تقسيم الملف (Chunking Engine)
      int numThreads = 4;
      int chunkSize = (totalBytes / numThreads).ceil();
      List<Future<Response>> downloadTasks = [];
      List<String> tempChunksPaths = [];

      DateTime startTime = DateTime.now();
      int totalReceivedBytes = 0;

      for (int i = 0; i < numThreads; i++) {
        int start = i * chunkSize;
        int end = (i == numThreads - 1) ? totalBytes - 1 : (start + chunkSize) - 1;
        String chunkPath = "$savePath.chunk$i";
        tempChunksPaths.add(chunkPath);

        // إطلاق مسارات التنزيل المتوازية
        downloadTasks.add(_dio.download(
          url,
          chunkPath,
          options: Options(headers: {'Range': 'bytes=$start-$end'}),
          onReceiveProgress: (received, total) async { 
            totalReceivedBytes += received;
            double progress = totalReceivedBytes / totalBytes;
            
            // حساب السرعة الفعلي بالـ KB/s
            double elapsedSeconds = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
            double speedKB = elapsedSeconds > 0 ? (totalReceivedBytes / 1024) / elapsedSeconds : 0.0;

            // خنق السرعة برمجياً بدون تجميد واجهة المستخدم (Non-blocking delay)
            if (isSpeedLimited && speedKB > maxSpeedKB) {
              int delayMs = ((speedKB - maxSpeedKB) * 10).round();
              await Future.delayed(Duration(milliseconds: delayMs > 100 ? 100 : delayMs));
            }

            onProgress(progress > 1.0 ? 1.0 : progress, speedKB);
          },
        ));
      }

      // انتظار اكتمال جميع المسارات الأربعة
      await Future.wait(downloadTasks);

      // 3. دمج الأجزاء (Stream Merging) في الملف النهائي
      var outputSink = targetFile.openWrite(mode: FileMode.write);
      for (String chunkPath in tempChunksPaths) {
        File chunkFile = File(chunkPath);
        if (await chunkFile.exists()) {
          await outputSink.addStream(chunkFile.openRead());
          await chunkFile.delete(); // مسح المخلفات لتنظيف الذاكرة
        }
      }
      await outputSink.close();

      // أرشفة عملية التنزيل
      final historyBox = Hive.box('downloadHistoryBox');
      historyBox.add({'name': fileName, 'path': savePath, 'date': DateTime.now().toString()});

      onComplete(savePath);
    } catch (e) {
      onError("فشل المحرك أثناء سحب الحزم: ${e.toString()}");
    }
  }
}