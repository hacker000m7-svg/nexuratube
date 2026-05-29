import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionHelper {
  
  /// دالة ذكية تطلب الإذن المناسب حسب إصدار الأندرويد لتجنب الـ Crashes
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // فحص إذن الإدارة الكاملة (للأندرويد 11 إلى 16)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      // فحص إذن التخزين العادي (للأندرويد 7 إلى 10)
      if (await Permission.storage.isGranted) {
        return true;
      }

      // إذا لم تكن الأذونات ممنوحة، نقوم بالطلب
      // سيقوم النظام تلقائياً بتوجيه الطلب حسب الإصدار بفضل مكتبة permission_handler
      var manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }

      var storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      // إذا تم الرفض النهائي
      return false;
    }
    return false;
  }

  /// طلب إذن الإشعارات (مهم جداً لأندرويد 13 فما فوق)
  static Future<bool> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      var status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }
}