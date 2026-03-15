import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../utils/app_theme.dart';
import '../widgets/video_player_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;
  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  int _photoIndex = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final hasPhotos = m.imagePaths.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── Photo sliver app bar ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.bgLight,
            foregroundColor: AppColors.textDark,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  hasPhotos
                      ? PageView.builder(
                          controller: _pageCtrl,
                          itemCount: m.imagePaths.length,
                          onPageChanged: (i) => setState(() => _photoIndex = i),
                          itemBuilder: (_, i) => _buildPhoto(m.imagePaths[i]),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3D5A6B), Color(0xFF1E3A4B)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.favorite, color: Colors.white24, size: 80),
                          ),
                        ),
                  // Gradient bottom fade
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.bgLight],
                        ),
                      ),
                    ),
                  ),
                  // Photo dots
                  if (m.imagePaths.length > 1)
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(m.imagePaths.length, (i) =>
                          GestureDetector(
                            onTap: () => _pageCtrl.animateToPage(i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: i == _photoIndex ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: i == _photoIndex
                                    ? AppColors.primary
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Body content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    DateFormat('MMMM d, yyyy').format(m.date).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    m.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),

                  // Location
                  if (m.locationName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 15, color: AppColors.textMid),
                        const SizedBox(width: 4),
                        Text(
                          m.locationName,
                          style: TextStyle(color: AppColors.textMid, fontSize: 14),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  Divider(color: AppColors.textMid.withOpacity(0.15)),
                  const SizedBox(height: 20),

                  // Story
                  Text(
                    '"${m.story}"',
                    style: GoogleFonts.playfairDisplay(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: AppColors.textDark.withOpacity(0.8),
                      height: 1.8,
                    ),
                  ),

                  // ── Photo gallery strip ──────────────────────────────
                  if (m.imagePaths.length > 1) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'GALLERY',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: m.imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () {
                            _pageCtrl.animateToPage(i,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut);
                            setState(() => _photoIndex = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: i == _photoIndex
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: _buildPhoto(m.imagePaths[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Videos ──────────────────────────────────────────
                  if (m.videoPaths.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'VIDEOS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...m.videoPaths.map((url) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: VideoPlayerWidget(url: url),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF3D5A6B)));
    }
    final file = File(path);
    if (!kIsWeb && file.existsSync()) return Image.file(file, fit: BoxFit.cover);
    return Container(color: const Color(0xFF3D5A6B));
  }
}
