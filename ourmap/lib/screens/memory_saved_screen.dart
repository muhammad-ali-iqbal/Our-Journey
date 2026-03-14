import 'dart:io';
import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MemorySavedScreen extends StatefulWidget {
  final Memory memory;
  const MemorySavedScreen({super.key, required this.memory});

  @override
  State<MemorySavedScreen> createState() => _MemorySavedScreenState();
}

class _MemorySavedScreenState extends State<MemorySavedScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _checkCtrl;
  late AnimationController _wobbleCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _checkScale;
  late Animation<double> _wobbleAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _wobbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.6)),
    );
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
          parent: _entryCtrl,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
    _wobbleAnim = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward().then((_) => _checkCtrl.forward());
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _checkCtrl.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final hasPhoto = m.imagePaths.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.close,
                        color: AppColors.textDark, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    'OUR MAP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: AnimatedBuilder(
                    animation: _slideAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // ── Polaroid with glow ───────────────────────────
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Glow bg
                            Container(
                              width: 280,
                              height: 340,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                  radius: 0.8,
                                ),
                              ),
                            ),
                            // Polaroid
                            AnimatedBuilder(
                              animation: _wobbleAnim,
                              builder: (context, child) => Transform.rotate(
                                angle: _wobbleAnim.value,
                                child: child,
                              ),
                              child: Container(
                                width: 220,
                                height: 270,
                                padding: const EdgeInsets.fromLTRB(
                                    12, 12, 12, 40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Photo
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: hasPhoto
                                              ? _buildPhoto(
                                                  m.imagePaths.first)
                                              : Container(
                                                  color: const Color(
                                                      0xFFE2E8F0),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.favorite,
                                                      color: Color(
                                                          0xFFCBD5E1),
                                                      size: 48,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    // Heart at bottom of polaroid
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Icon(Icons.favorite,
                                          color: AppColors.primary,
                                          size: 22),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Checkmark badge
                            Positioned(
                              bottom: 20,
                              right: 48,
                              child: AnimatedBuilder(
                                animation: _checkScale,
                                builder: (context, child) => Transform.scale(
                                  scale: _checkScale.value,
                                  child: child,
                                ),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.4),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Title ────────────────────────────────────────
                        Text(
                          'Memory Saved to\nYour Map',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 38,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Subtitle ─────────────────────────────────────
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                  text: 'Your beautiful moment in '),
                              TextSpan(
                                text: m.locationName.isNotEmpty
                                    ? m.locationName
                                    : 'your hearts',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                  text:
                                      ' has been preserved forever in your shared journey.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // ── Buttons ──────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .popUntil((r) => r.isFirst),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              'Back to Map',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              // Share functionality can be added with share_plus
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Sharing coming soon!')),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Text(
                              'Share this Memory',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFFE2E8F0)));
    }
    final file = File(path);
    if (file.existsSync()) return Image.file(file, fit: BoxFit.cover);
    return Container(color: const Color(0xFFE2E8F0));
  }
}
