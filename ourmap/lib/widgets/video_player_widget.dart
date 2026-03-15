import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _init();
  }

  Future<void> _init() async {
    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: false,
        looping: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.gold,
          bufferedColor: AppColors.primary.withOpacity(0.3),
          backgroundColor: Colors.white24,
        ),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _shell(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, color: AppColors.gold, size: 36),
          const SizedBox(height: 8),
          Text('Open on mobile to play',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ));
    }
    if (_loading) return _shell(child: const CircularProgressIndicator(color: AppColors.gold));
    if (_error) return _shell(child: const Icon(Icons.error_outline, color: Colors.white38, size: 36));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _videoCtrl!.value.aspectRatio,
        child: Chewie(controller: _chewieCtrl!),
      ),
    );
  }

  Widget _shell({required Widget child}) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      );
}
