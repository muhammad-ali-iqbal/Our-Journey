import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../utils/app_theme.dart';
import '../screens/quiz_screen.dart';
import '../screens/memory_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryModal extends StatefulWidget {
  final Memory memory;
  final VoidCallback onClose;

  const MemoryModal({super.key, required this.memory, required this.onClose});

  @override
  State<MemoryModal> createState() => _MemoryModalState();
}

class _MemoryModalState extends State<MemoryModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openMemory() {
    if (widget.memory.isUnlocked || widget.memory.quiz == null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MemoryDetailScreen(memory: widget.memory),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuizScreen(memory: widget.memory),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final hasPhotos = m.imagePaths.isNotEmpty;

    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnim.value * 400),
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgDarkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Photo ─────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: hasPhotos
                        ? _buildPhoto(m.imagePaths[_photoIndex])
                        : Container(
                            color: const Color(0xFF1E293B),
                            child: Center(
                              child: Icon(
                                Icons.favorite,
                                color: AppColors.gold.withOpacity(0.3),
                                size: 56,
                              ),
                            ),
                          ),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.bgDarkSurface,
                        ],
                      ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white70, size: 16),
                    ),
                  ),
                ),
                // Lock icon if locked
                if (!m.isUnlocked && m.quiz != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Locked',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    DateFormat('MMMM d, yyyy').format(m.date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    m.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Divider
                  Container(
                    height: 1,
                    color: AppColors.gold.withOpacity(0.12),
                  ),
                  const SizedBox(height: 12),
                  // Story excerpt (first 120 chars)
                  Text(
                    m.isUnlocked || m.quiz == null
                        ? (m.story.length > 120
                            ? '"${m.story.substring(0, 120)}..."'
                            : '"${m.story}"')
                        : 'Unlock this memory to read your story...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _openMemory,
                        child: Text(
                          m.isUnlocked || m.quiz == null
                              ? 'VIEW FULL MEMORY'
                              : 'UNLOCK MEMORY ✦',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            color: AppColors.gold.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Photo dots
                      if (m.imagePaths.length > 1)
                        Row(
                          children: List.generate(
                            m.imagePaths.length,
                            (i) => GestureDetector(
                              onTap: () => setState(() => _photoIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _photoIndex
                                      ? AppColors.gold
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder());
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return _photoPlaceholder();
    }
  }

  Widget _photoPlaceholder() => Container(
        color: const Color(0xFF1E293B),
        child: Icon(Icons.image_not_supported,
            color: AppColors.gold.withOpacity(0.2), size: 48),
      );
}
