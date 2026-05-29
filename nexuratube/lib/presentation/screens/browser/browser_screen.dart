import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../data/network/link_extractor.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({Key? key}) : super(key: key);

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  InAppWebViewController? _webViewController;
  String _currentUrl = "https://www.google.com";
  String? _detectedMediaUrl;
  bool _showDownloadFab = false;
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C23), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              hintText: "أدخل رابط موقع أو كلمة بحث...",
              prefixIcon: Icon(Icons.search, color: Color(0xFF00FFCC)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (value) {
              String target = value.trim();
              if (!target.startsWith("http")) {
                target = "https://www.google.com/search?q=$target";
              }
              _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(target)));
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              
              // تهيئة معالج استقبال رسائل الجافاسكريبت من الموقع
              controller.addJavaScriptHandler(
                handlerName: 'mediaDetected', 
                callback: (args) {
                  if (args.isNotEmpty && _detectedMediaUrl != args[0]) {
                    setState(() {
                      _detectedMediaUrl = args[0];
                      _showDownloadFab = true;
                    });
                  }
                }
              );
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _currentUrl = url.toString();
                _urlController.text = _currentUrl;
              });
              
              // حاقن السكربت: يعمل في الخلفية للبحث عن وسوم الفيديو داخل الموقع
              await controller.evaluateJavascript(source: """
                setInterval(function() {
                  var video = document.querySelector('video');
                  if (video && video.src) {
                    window.flutter_inappwebview.callHandler('mediaDetected', video.src);
                  }
                }, 2000);
              """);
            },
          ),
        ],
      ),
      
      // زر عائم يظهر فقط عند التقاط وسائط مخفية في الموقع
      floatingActionButton: _showDownloadFab
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00FFCC),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.downloading),
              label: const Text("تحميل الفيديو المكتشف", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (_detectedMediaUrl != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("الرابط الملتقط: $_detectedMediaUrl"))
                  );
                  // هنا يتم ربط الرابط الملتقط بمحرك التنزيل (DownloadEngine)
                }
              },
            )
          : null,
    );
  }
}