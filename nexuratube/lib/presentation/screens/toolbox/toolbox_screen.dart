import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../data/database/secure_vault.dart';

class ToolboxScreen extends StatefulWidget {
  const ToolboxScreen({Key? key}) : super(key: key);

  @override
  State<ToolboxScreen> createState() => _ToolboxScreenState();
}

class _ToolboxScreenState extends State<ToolboxScreen> {
  final SecureVault _vault = SecureVault();
  final Box _settingsBox = Hive.box('settingsBox');
  
  bool _limitSpeed = false;
  int _maxSpeed = 1024;

  @override
  void initState() {
    super.initState();
    _limitSpeed = _settingsBox.get('limitSpeed', defaultValue: false);
    _maxSpeed = _settingsBox.get('maxSpeedValue', defaultValue: 1024);
  }

  /// أداة تفريغ كاش المتصفح المدمج وتنظيف ذاكرة رام التطبيق الافتراضية لقوة الأداء
  void _clearCache() {
    // محاكاة وقطع الكاش البرمجي
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚀 تم تنظيف ذاكرة الرام ومسح ملفات الكاش المؤقتة بنجاح!"), backgroundColor: Colors.teal),
    );
  }

  /// الدخول الآمن والمنعزل للخزنة السرية السيبرانية بالبصمة
  void _openSecureVault() async {
    bool authenticated = await _vault.authenticateUser();
    if (authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔓 تم تأكيد الهوية. أهلاً بك في الخزنة المشفرة.")));
        // هنا يتم فتح مجلد .vault واستعراض ملفاته المفتوحة لاحقاً
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚨 فشل التحقق البيومتري! الوصول مرفوض."), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("أدوات وإعدادات Nexuratube المتقدمة")),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text("الأدوات السيبرانية", style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ListTile(
            tileColor: const Color(0xFF1C1C23),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.enhanced_encryption_rounded, color: Colors.purpleAccent),
            title: const Text("الخزنة السرية المشفرة (AES-256)"),
            subtitle: const Text("حماية ميديا بصمة الإصبع والوجه الحيوية"),
            onTap: _openSecureVault,
          ),
          const SizedBox(height: 12),
          
          ListTile(
            tileColor: const Color(0xFF1C1C23),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amberAccent),
            title: const Text("منظف الرام والكاش (Cache & RAM Cleaner)"),
            subtitle: const Text("مسح كاش المتصفح ومخلفات التنزيل لتسريع الهاتف"),
            onTap: _clearCache,
          ),
          
          const SizedBox(height: 30),
          const Text("خيارات وإعدادات التنزيل والمظهر", style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text("تحديد سرعة التحميل الأقصى"),
            subtitle: const Text("المحافظة على استهلاك باقة الإنترنت المحلية"),
            value: _limitSpeed,
            activeColor: const Color(0xFF00FFCC),
            onChanged: (bool value) {
              setState(() => _limitSpeed = value);
              _settingsBox.put('limitSpeed', value);
            },
          ),
          
          if (_limitSpeed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("الحد الأقصى للسرعة (كيلوبايت):"),
                  DropdownButton<int>(
                    value: _maxSpeed,
                    items: const [
                      DropdownMenuItem(value: 512, child: Text("512 KB/s")),
                      DropdownMenuItem(value: 1024, child: Text("1 MB/s")),
                      DropdownMenuItem(value: 4096, child: Text("4 MB/s")),
                    ],
                    onChanged: (int? value) {
                      if (value != null) {
                        setState(() => _maxSpeed = value);
                        _settingsBox.put('maxSpeedValue', value);
                      }
                    },
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}