import 'package:flutter/material.dart';
import 'widgets/clipboard_detector.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("أهلاً بك في", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    Text("NEXURATUBE", style: TextStyle(color: Color(0xFF00FFCC), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
              
              // كاشف ومحلل الحافظة التلقائي الذكي
              const ClipboardDetector(),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text("المنصات المدعومة سريعة الوصول:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPlatformCard("YouTube", Icons.video_library, Colors.red),
                  _buildPlatformCard("TikTok", Icons.music_note, Colors.cyan),
                  _buildPlatformCard("Instagram", Icons.camera_alt, Colors.pink),
                  _buildPlatformCard("Facebook", Icons.facebook, Colors.blue),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformCard(String name, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF1C1C23), borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}