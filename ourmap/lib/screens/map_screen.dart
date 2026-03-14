import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory.dart';
import '../services/memory_service.dart';
import '../utils/app_theme.dart';
import '../widgets/map_pin.dart';
import 'menu_drawer.dart';
import 'quiz_screen.dart';
import 'memory_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _drawerOpen = false;
  List<Memory> _memories = [];
  StreamSubscription<List<Memory>>? _sub;

  // Audio
  final _player = AudioPlayer();
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
    MemoryService().fetchMemories().then((m) {
      if (mounted) setState(() => _memories = m);
    });
    _sub = MemoryService().watchMemories().listen((m) {
      if (mounted) setState(() => _memories = m);
    });
  }

  Future<void> _initAudio() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.4);
    await _player.play(AssetSource('App_Sound.mp3'));
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _player.setVolume(_muted ? 0.0 : 0.4);
  }

  @override
  void dispose() {
    _player.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _openMemory(Memory m) {
    if (m.isUnlocked || m.quiz == null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MemoryDetailScreen(memory: m),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuizScreen(memory: m),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1F),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bar(), const SizedBox(height: 4),
                _bar(), const SizedBox(height: 4),
                _bar(),
              ],
            ),
          ),
        ),
        title: Text(
          'OUR MAP',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.gold,
            letterSpacing: 6,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _muted ? Icons.volume_off : Icons.volume_up,
              color: AppColors.gold.withOpacity(_muted ? 0.4 : 1.0),
              size: 20,
            ),
          ),
        ],
      ),
      drawer: MenuDrawer(
        onClose: () => setState(() => _drawerOpen = false),
        onMemorySelected: (m) {
          Navigator.of(context).pop();
          _openMemory(m);
        },
      ),
      body: _StarCanvas(
        memories: _memories,
        onHeartTap: _openMemory,
      ),
    );
  }

  Widget _bar() => Container(
        width: 22, height: 2,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(1),
        ),
      );
}

// ── STAR CANVAS ────────────────────────────────────────────────────────────────
class _StarCanvas extends StatefulWidget {
  final List<Memory> memories;
  final void Function(Memory) onHeartTap;

  const _StarCanvas({required this.memories, required this.onHeartTap});

  @override
  State<_StarCanvas> createState() => _StarCanvasState();
}

class _StarCanvasState extends State<_StarCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkle;
  late List<_Star> _stars;
  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    final rng = math.Random(42);
    _stars = List.generate(400, (_) => _Star(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      r: rng.nextDouble() * 1.5 + 0.3,
      phase: rng.nextDouble(),
    ));
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  Offset _posFor(Memory m) {
    if (_positions.containsKey(m.id)) return _positions[m.id]!;
    if (m.lat != null && m.lng != null) {
      final o = Offset(m.lng!, m.lat!);
      _positions[m.id] = o;
      return o;
    }
    final rng = math.Random(m.createdAt.millisecondsSinceEpoch);
    final o = Offset(0.1 + rng.nextDouble() * 0.8, 0.12 + rng.nextDouble() * 0.76);
    _positions[m.id] = o;
    return o;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cw = w * 3;
        final ch = h * 3;

        return Container(
          // Background always fills the screen regardless of pan/zoom
          width: w,
          height: h,
          color: const Color(0xFF020810),
          child: Stack(
            children: [
              // ── Full-screen gradient (never moves) ─────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.2, -0.3),
                      radius: 1.4,
                      colors: [
                        Color(0xFF0D1B3E),
                        Color(0xFF060D1F),
                        Color(0xFF020810),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Pannable/zoomable layer ─────────────────────────────────
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.4,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: SizedBox(
                    width: cw,
                    height: ch,
                    child: Stack(
                      children: [
                        // ── Twinkling stars ────────────────────────────────
                        Positioned(
                          left: 0, top: 0,
                          width: cw, height: ch,
                          child: AnimatedBuilder(
                            animation: _twinkle,
                            builder: (_, __) => CustomPaint(
                              size: Size(cw, ch),
                              painter: _StarPainter(_stars, _twinkle.value, cw, ch),
                            ),
                          ),
                        ),

                        // ── Constellation lines ────────────────────────────
                        if (widget.memories.length >= 2)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _LinesPainter(
                                widget.memories.map((m) {
                                  final p = _posFor(m);
                                  return Offset(p.dx * cw, p.dy * ch);
                                }).toList(),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),

                        // ── Heart pins ─────────────────────────────────────
                        ...widget.memories.map((m) {
                          final p = _posFor(m);
                          return Positioned(
                            left: p.dx * cw - 28,
                            top: p.dy * ch - 28,
                            child: MapPin(
                              memory: m,
                              isSelected: false,
                              onTap: () => widget.onHeartTap(m),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Empty state (outside InteractiveViewer) ─────────────────
              if (widget.memories.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border,
                          color: AppColors.gold.withOpacity(0.3), size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Your story begins here',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap ☰ to add your first memory',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Star {
  final double x, y, r, phase;
  const _Star({required this.x, required this.y, required this.r, required this.phase});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  final double canvasW;
  final double canvasH;

  _StarPainter(this.stars, this.t, this.canvasW, this.canvasH);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final opacity = 0.2 + 0.6 * ((math.sin((t + s.phase) * math.pi) + 1) / 2);
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(s.x * canvasW, s.y * canvasH),
        s.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _LinesPainter extends CustomPainter {
  final List<Offset> pts;
  _LinesPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.8..style = PaintingStyle.stroke;
    const threshold = 300.0;
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < threshold) {
          paint.color = AppColors.gold.withOpacity((1 - d / threshold) * 0.45);
          canvas.drawLine(pts[i], pts[j], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => old.pts != pts;
}
