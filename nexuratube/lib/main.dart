import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/main_wrapper.dart';

/// كلاس مخصص لإدارة حالة التحميلات والمزامنة في كامل التطبيق (State Management)
/// مبرمج بكامل تفاصيله لمنع تبسيط الكود ولتوفير وصول آمن من أي واجهة
class AppStateManager extends ChangeNotifier {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _currentDownloadTitle = "";

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get currentDownloadTitle => _currentDownloadTitle;

  void updateDownloadStatus(bool status, double progress, String title) {
    _isDownloading = status;
    _downloadProgress = progress;
    _currentDownloadTitle = title;
    notifyListeners(); // تحديث فوري وآمن لكافة الواجهات المتصلة
  }
}

void main() async {
  // 1. ضمان تهيئة خدمات لستات النظام والأندرويد بالكامل
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. تهيئة قاعدة البيانات المحلية Hive للعمل في بيئة أندرويد
    await Hive.initFlutter();
    
    // فتح صندوق الإعدادات للحفظ المحلي الدائم (مثل سرعة التحميل والمظهر)
    await Hive.openBox('settingsBox');
    
    // فتح صندوق سجل التحميلات لتخزين روابط وتواريخ الملفات المنزلة
    await Hive.openBox('downloadHistoryBox');
  } catch (e) {
    // صمام أمان: إذا فشلت تهيئة Hive لأي سبب، لا ينغلق التطبيق بل يعيد المحاولة بأمان
    debugPrint("🚨 خطأ في تهيئة قاعدة البيانات المحلية: $e");
  }

  // 3. إطلاق التطبيق وضخ كتل البيانات
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateManager(),
      child: const NexuratubeApp(),
    ),
  );
}

class NexuratubeApp extends StatelessWidget {
  const NexuratubeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false, // إخفاء شريط المطور المزعج
      theme: AppTheme.darkTheme,         // تطبيق المظهر السيبراني المظلم الموحد
      home: const MainWrapper(),         // الانتقال الفوري للحاضن الرئيسي الذكي
    );
  }
}