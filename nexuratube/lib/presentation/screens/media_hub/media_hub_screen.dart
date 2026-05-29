import 'package:flutter/material.dart';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({Key? key}) : super(key: key);

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> {
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocalFiles();
  }

  /// فحص المجلد الحقيقي وعرض الملفات للتشغيل المحلي الشامل
  Future<void> _fetchLocalFiles() async {
    final dir = Directory('/storage/emulated/0/Nexuratube');
    if (await dir.exists()) {
      setState(() {
        _downloadedFiles = dir.listSync().where((file) => !file.path.contains('.vault')).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("معرض ملفات Nexuratube المحلية")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)))
          : _downloadedFiles.isEmpty
              ? const Center(child: Text("لا توجد ملفات محملة حالياً في مجلد Nexuratube"))
              : ListView.builder(
                  itemCount: _downloadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _downloadedFiles[index];
                    final String name = file.path.split('/').last;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1C1C23), borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_fill, color: Color(0xFF00FFCC), size: 36),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text("${(File(file.path).lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB", style: const TextStyle(color: Colors.grey)),
                        onTap: () => _playVideo(file.path),
                      ),
                    );
                  },
                ),
    );
  }

  /// فتح مشغل الفيديو المتقدم المدمج بالتحكم الذكي وحركات الـ PiP
  void _playVideo(String path) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => NexuraInternalPlayer(videoPath: path)));
  }
}

class NexuraInternalPlayer extends StatefulWidget {
  final String videoPath;
  const NexuraInternalPlayer({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<NexuraInternalPlayer> createState() => _NexuraInternalPlayerState();
}

class _NexuraInternalPlayerState extends State<NexuraInternalPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF00FFCC),
        handleColor: const Color(0xFF8A2BE2),
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)));
    );
  }
}