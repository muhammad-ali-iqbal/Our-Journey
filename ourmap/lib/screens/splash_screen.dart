import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'map_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _sealCtrl;

  late Animation<double> _floatAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _sealScaleAnim;
  late Animation<double> _sealOpacityAnim;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _sealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _floatAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );

    _sealScaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _sealCtrl, curve: Curves.easeOutBack),
    );

    _sealOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _sealCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    _sealCtrl.dispose();
    super.dispose();
  }

  void _openEnvelope() async {
    await _sealCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const MapScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Title ────────────────────────────────────────────────────
              Column(
                children: [
                  Text(
                    'A Gift for My Iko',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF4A443F),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OUR MAP',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF8C847C),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // ── Floating Envelope ────────────────────────────────────────
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: child,
                ),
                child: SizedBox(
                  width: 280,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Envelope body
                      Container(
                        width: 280,
                        height: 190,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFE5E1D8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CustomPaint(
                            painter: _EnvelopePainter(),
                          ),
                        ),
                      ),

                      // Wax seal
                      AnimatedBuilder(
                        animation: _sealCtrl,
                        builder: (context, child) => Transform.scale(
                          scale: _sealScaleAnim.value,
                          child: Opacity(
                            opacity: _sealOpacityAnim.value,
                            child: child,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: _openEnvelope,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold,
                              border: Border.all(
                                color: AppColors.goldDark,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Inner ring
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.goldDark.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                // Heart
                                Icon(
                                  Icons.favorite,
                                  color: const Color(0xFF7B6013),
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tap hint
              const SizedBox(height: 16),
              Text(
                'tap to open',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3,
                  color: const Color(0xFF8C847C).withOpacity(0.6),
                ),
              ),

              const Spacer(flex: 3),

              // ── Footer ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 1,
                      color: const Color(0xFF4A443F).withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'EST. 2023',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 5,
                        color: const Color(0xFF4A443F).withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 1,
                      color: const Color(0xFF4A443F).withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Bottom-left triangle
    paint.color = const Color(0xFFF5F3EF);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, size.height / 2)
        ..lineTo(0, size.height / 2)
        ..close(),
      paint,
    );

    // Bottom-right triangle
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height)
        ..lineTo(size.width / 2, size.height / 2)
        ..lineTo(size.width, size.height / 2)
        ..close(),
      paint,
    );

    // Top flap
    paint.color = const Color(0xFFFAF8F4);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height / 2)
        ..close(),
      paint,
    );

    // Divider lines
    final linePaint = Paint()
      ..color = const Color(0xFFE5E1D8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Flap bottom edge
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width / 2, size.height / 2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => false;
}
