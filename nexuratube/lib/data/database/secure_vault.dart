import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:local_auth/local_auth.dart';

class SecureVault {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // مفتاح التشفير ومتجه التهيئة (يجب أن يكونا بنفس الطول المطلوب لـ AES-256)
  final _key = encrypt.Key.fromUtf8('N3xur4Tub3Secur3K3y2026M4sh4l12');
  final _iv = encrypt.IV.fromLength(16);

  /// طلب المصادقة عبر البصمة أو التعرف على الوجه
  Future<bool> authenticateUser() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isBiometricSupported = await _localAuth.isDeviceSupported();
    
    if (!canCheckBiometrics || !isBiometricSupported) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك لفتح الخزنة السرية المشفرة',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } catch (e) {
      return false;
    }
  }

  /// قراءة بايتات الملف، تشفيرها بـ AES، وحفظها بلاحقة تالفة ثم مسح الأصل
  Future<void> encryptAndHideFile(String sourcePath, String fileName) async {
    final String vaultPath = '/storage/emulated/0/Nexuratube/.vault';
    final Directory vaultDir = Directory(vaultPath);
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    File sourceFile = File(sourcePath);
    Uint8List fileBytes = await sourceFile.readAsBytes();

    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final encryptedData = encrypter.encryptBytes(fileBytes, iv: _iv);

    File encryptedFile = File("$vaultPath/$fileName.nexura");
    await encryptedFile.writeAsBytes(encryptedData.bytes);
    
    // التدمير الآمن للملف الأصلي المكشوف
    await sourceFile.delete();
  }

  /// فك التشفير العكسي للملف من الخزنة وإعادته للمعرض المحلي
  Future<String> decryptAndRestoreFile(String fileName) async {
    final String vaultFile = '/storage/emulated/0/Nexuratube/.vault/$fileName.nexura';
    final String targetPath = '/storage/emulated/0/Nexuratube/$fileName';

    File fileToDecrypt = File(vaultFile);
    Uint8List encryptedBytes = await fileToDecrypt.readAsBytes();

    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: _iv);

    File restoredFile = File(targetPath);
    await restoredFile.writeAsBytes(decryptedBytes);
    
    // مسح النسخة المشفرة بعد استعادتها بنجاح
    await fileToDecrypt.delete();

    return targetPath;
  }
}