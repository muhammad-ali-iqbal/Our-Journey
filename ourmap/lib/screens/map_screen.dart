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
  List<Memory> _memories = [];
  StreamSubscription<List<Memory>>? _sub;
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
          builder: (ctx) => IconButton(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_bar(), const SizedBox(height: 4), _bar(), const SizedBox(height: 4), _bar()],
            ),
          ),
        ),
        title: Text('OUR MAP',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w500,
                color: AppColors.gold, letterSpacing: 6)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                color: AppColors.gold.withOpacity(_muted ? 0.4 : 1.0), size: 20),
          ),
        ],
      ),
      drawer: MenuDrawer(
        onClose: () {},
        onMemorySelected: (m) { Navigator.of(context).pop(); _openMemory(m); },
      ),
      body: _ConstellationView(memories: _memories, onHeartTap: _openMemory),
    );
  }

  Widget _bar() => Container(
        width: 22, height: 2,
        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(1)),
      );
}

// ── CONSTELLATION VIEW ─────────────────────────────────────────────────────────
class _ConstellationView extends StatefulWidget {
  final List<Memory> memories;
  final void Function(Memory) onHeartTap;
  const _ConstellationView({required this.memories, required this.onHeartTap});

  @override
  State<_ConstellationView> createState() => _ConstellationViewState();
}

class _ConstellationViewState extends State<_ConstellationView>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkle;
  late List<_Star> _bgStars;
  final Map<String, Offset> _positions = {};

  // Pan/zoom state
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _focalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    final rng = math.Random(42);
    _bgStars = List.generate(300, (_) => _Star(
      x: rng.nextDouble(), y: rng.nextDouble(),
      r: rng.nextDouble() * 1.8 + 0.4, phase: rng.nextDouble(),
    ));
  }

  @override
  void dispose() { _twinkle.dispose(); super.dispose(); }

  Offset _posFor(Memory m, double w, double h) {
    if (_positions.containsKey(m.id)) return _positions[m.id]!;
    if (m.lat != null && m.lng != null &&
        m.lat! > 0 && m.lat! < 1 && m.lng! > 0 && m.lng! < 1) {
      final o = Offset(m.lng! * w, m.lat! * h);
      _positions[m.id] = o;
      return o;
    }
    final rng = math.Random(m.id.hashCode);
    final o = Offset((0.1 + rng.nextDouble() * 0.8) * w, (0.12 + rng.nextDouble() * 0.76) * h);
    _positions[m.id] = o;
    return o;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return GestureDetector(
        onScaleStart: (d) {
          _focalPoint = d.focalPoint;
          _startOffset = _offset;
          _startScale = _scale;
        },
        onScaleUpdate: (d) {
          setState(() {
            _scale = (_startScale * d.scale).clamp(0.3, 5.0);
            _offset = _startOffset + (d.focalPoint - _focalPoint);
          });
        },
        child: ClipRect(
          child: Stack(
            children: [
              // ── Dark background ──────────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [Color(0xFF0D1B3E), Color(0xFF060D1F), Color(0xFF020810)],
                    ),
                  ),
                ),
              ),

              // ── Stars (fixed, don't move with pan) ───────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _twinkle,
                  builder: (_, __) => CustomPaint(
                    painter: _StarPainter(_bgStars, _twinkle.value),
                  ),
                ),
              ),

              // ── Pannable content (lines + hearts) ────────────────────
              Positioned.fill(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(_offset.dx, _offset.dy)
                    ..scale(_scale),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Constellation lines
                      if (widget.memories.length >= 2)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LinesPainter(
                              widget.memories.map((m) => _posFor(m, w, h)).toList(),
                            ),
                          ),
                        ),

                      // Hearts
                      ...widget.memories.map((m) {
                        final p = _posFor(m, w, h);
                        return Positioned(
                          left: p.dx - 28,
                          top: p.dy - 28,
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

              // ── Empty state ───────────────────────────────────────────
              if (widget.memories.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, color: AppColors.gold.withOpacity(0.3), size: 48),
                      const SizedBox(height: 16),
                      Text('Your story begins here',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 22, fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.3))),
                      const SizedBox(height: 8),
                      Text('Tap ☰ to add your first memory',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.2))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _Star {
  final double x, y, r, phase;
  const _Star({required this.x, required this.y, required this.r, required this.phase});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final opacity = 0.15 + 0.7 * ((math.sin((t + s.phase) * math.pi) + 1) / 2);
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, paint);
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
    if (pts.length < 2) return;
    final paint = Paint()..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const threshold = 300.0;
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final d = (pts[i] - pts[j]).distance;
        if (d < threshold) {
          paint.color = AppColors.gold.withOpacity((1 - d / threshold) * 0.5);
          canvas.drawLine(pts[i], pts[j], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => old.pts != old.pts;
}
