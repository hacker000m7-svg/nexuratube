import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/network/link_extractor.dart';

class ClipboardDetector extends StatefulWidget {
  const ClipboardDetector({Key? key}) : super(key: key);

  @override
  State<ClipboardDetector> createState() => _ClipboardDetectorState();
}

class _ClipboardDetectorState extends State<ClipboardDetector> with WidgetsBindingObserver {
  String _detectedUrl = "";
  bool _isAnalyzing = false;
  final LinkExtractor _extractor = LinkExtractor();

  @override
  void initState() {
    super.override.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboardData(); // فحص الحافظة فور التشغيل
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // إذا رجع المستخدم للتطبيق من الخلفية، نقوم بالفحص الفوري للرابط الجديد
    if (state == AppLifecycleState.resumed) {
      _checkClipboardData();
    }
  }

  /// دالة قراءة الحافظة بأمان تام من النظام وتصفية النصوص لمنع القفلات
  Future<void> _checkClipboardData() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final String text = data.text!.trim();
        // التحقق من توافق الرابط مع المنصات المستهدفة لدينا
        if (text.contains("youtube.com") || 
            text.contains("youtu.be") || 
            text.contains("instagram.com") || 
            text.contains("tiktok.com")) {
          if (mounted && _detectedUrl != text) {
            setState(() {
              _detectedUrl = text;
            });
          }
          return;
        }
      }
      // إذا لم يكن الرابط متوافقاً نقوم بتصفير الحالة بأمان
      if (mounted && _detectedUrl.isNotEmpty) {
        setState(() {
          _detectedUrl = "";
        });
      }
    } catch (e) {
      debugPrint("🚨 فشل فحص نظام الحافظة للأندرويد: $e");
    }
  }

  /// معالجة الرابط عبر محرك الكشط وضخ الجودات المتاحة للمستخدم
  Future<void> _analyzeLink() async {
    if (_detectedUrl.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      List<ExtractedMedia> streams = await _extractor.extractMediaStreams(_detectedUrl);
      if (mounted && streams.isNotEmpty) {
        _showDownloadBottomSheet(context, streams);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_detectedUrl.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C23).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFCC).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF00FFCC), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "رابط مكتشف في الحافظة",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
                Text(
                  _detectedUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyzeLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFCC),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                  )
                : const Text("تحليل 🚀", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  /// نافذة منبثقة عصرية (Material 3 Bottom Sheet) تعرض الخيارات الكاملة للجودات المستخرجة
  void _showDownloadBottomSheet(BuildContext context, List<ExtractedMedia> streams) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                streams.first.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text("خيارات جودة التحميل المتاحة:", style: TextStyle(color: Color(0xFF00FFCC), fontSize: 14)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: streams.length,
                  itemBuilder: (context) {
                    final item = streams[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C23),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Icon(
                          item.extension == "mp3" ? Icons.audiotrack_rounded : Icons.video_collection_rounded,
                          color: const Color(0xFF8A2BE2),
                        ),
                        title: Text("${item.quality} (${item.extension.toUpperCase()})", style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF00FFCC)),
                        onTap: () {
                          Navigator.pop(context);
                          // سيتم ربط زر التنزيل هنا بمحرك التنزيل المتعدد المسارات (DownloadEngine) في الدفعة القادمة
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}