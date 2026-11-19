import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'webview_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Palette – pink + sky blue on deep cosmic navy, gold accents
// ─────────────────────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0B1B3A); // matches native splash
  static const deep = Color(0xFF050B1E);
  static const pink = Color(0xFFFF4FA3);
  static const softPink = Color(0xFFFFB6D9);
  static const sky = Color(0xFF4FC3F7);
  static const skyLight = Color(0xFF9BE7FF);
  static const violet = Color(0xFF8E6CFF);
  static const gold = Color(0xFFFFD27A);
  static const mint = Color(0xFF7CF5C8);
}

Color _a(Color c, double o) => c.withOpacity(o.clamp(0.0, 1.0));

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  // One-shot intro (reveal, logo pop, text, progress)
  late final AnimationController _intro;
  // Seamless endless loop (rotation, twinkle, shimmer, pulse)
  late final AnimationController _loop;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subFade;
  late final Animation<double> _tagFade;
  late final Animation<double> _progress;

  late final List<_Star> _stars;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    final rnd = math.Random(108); // 108 – a sacred number 🙂
    _stars = List.generate(110, (_) => _Star.random(rnd));

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _logoFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.12, 0.40, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.12, 0.65, curve: Curves.elasticOut),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 0.78, curve: Curves.easeOutCubic),
    ));
    _subFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
    );
    _tagFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(parent: _intro, curve: Curves.easeInOut);

    // Navigate once the intro has played + a short hold
    _navTimer = Timer(const Duration(milliseconds: 4200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WebViewScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wheel = math.min(size.width * 0.88, size.height * 0.42);

    return Scaffold(
      backgroundColor: _C.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Nebula, stars, shooting stars ──
          RepaintBoundary(
            child: CustomPaint(
              painter: _CosmosPainter(_intro, _loop, _stars),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zodiac mandala + logo
                  SizedBox(
                    width: wheel,
                    height: wheel,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: Size(wheel, wheel),
                            painter: _MandalaPainter(_intro, _loop),
                          ),
                        ),
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: wheel * 0.34,
                              height: wheel * 0.34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _a(_C.pink, 0.45),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: _a(_C.sky, 0.35),
                                    blurRadius: 60,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.auto_awesome,
                                      size: 70,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Title with shimmer
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context, child) {
                          final p = (_loop.value * 2) % 1.0;
                          return ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => LinearGradient(
                              colors: const [
                                _C.pink,
                                _C.skyLight,
                                Colors.white,
                                _C.skyLight,
                                _C.pink,
                              ],
                              tileMode: TileMode.repeated,
                              transform: _SlideGradient(p),
                            ).createShader(bounds),
                            child: child,
                          );
                        },
                        child: const Text(
                          'DSJV App 2.0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  FadeTransition(
                    opacity: _subFade,
                    child: Text(
                      'V E D I C   A S T R O L O G Y',
                      style: TextStyle(
                        color: _a(_C.softPink, 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Sanskrit tagline
                  FadeTransition(
                    opacity: _tagFade,
                    child: Text(
                      'ஜோதிடம் • வழிகாட்டும் ஒளி',
                      style: TextStyle(
                        color: _a(_C.gold, 0.9),
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Gradient progress line
                  FadeTransition(
                    opacity: _subFade,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return Container(
                          width: 160,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _a(Colors.white, 0.10),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  colors: [_C.pink, _C.violet, _C.sky],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _a(_C.pink, 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Slides a repeating gradient horizontally (for the title shimmer)
class _SlideGradient extends GradientTransform {
  final double percent;
  const _SlideGradient(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}

// ─────────────────────────────────────────────────────────────
//  Stars
// ─────────────────────────────────────────────────────────────
class _Star {
  final double x, y, radius, phase;
  final int freq;
  final Color color;

  _Star(this.x, this.y, this.radius, this.phase, this.freq, this.color);

  factory _Star.random(math.Random r) {
    const colors = [
      Colors.white,
      _C.skyLight,
      _C.softPink,
      _C.gold,
      _C.sky,
      _C.pink,
    ];
    return _Star(
      r.nextDouble(),
      r.nextDouble(),
      0.5 + r.nextDouble() * 1.4,
      r.nextDouble(),
      1 + r.nextInt(3),
      colors[r.nextInt(colors.length)],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Constellations
// ─────────────────────────────────────────────────────────────
class _Constellation {
  final List<Offset> pts;
  final List<List<int>> edges;
  final Offset anchor; // fraction of screen
  final double scale; // fraction of screen width
  final double phase;
  final Color color;

  const _Constellation(
      this.pts, this.edges, this.anchor, this.scale, this.phase, this.color);
}

const _constellations = <_Constellation>[
  // Saptarishi Mandalam (Ursa Major) – top left
  _Constellation(
    [
      Offset(0.00, 0.00),
      Offset(0.16, 0.10),
      Offset(0.32, 0.18),
      Offset(0.50, 0.30),
      Offset(0.78, 0.34),
      Offset(0.82, 0.62),
      Offset(0.52, 0.58),
    ],
    [
      [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 3],
    ],
    Offset(0.06, 0.06),
    0.30,
    0.00,
    _C.skyLight,
  ),
  // Cassiopeia – top right
  _Constellation(
    [
      Offset(0.00, 0.30),
      Offset(0.20, 0.80),
      Offset(0.45, 0.40),
      Offset(0.70, 0.85),
      Offset(0.95, 0.20),
    ],
    [
      [0, 1], [1, 2], [2, 3], [3, 4],
    ],
    Offset(0.66, 0.05),
    0.26,
    0.25,
    _C.softPink,
  ),
  // Mrigashirsha / Orion – bottom left
  _Constellation(
    [
      Offset(0.00, 0.00),
      Offset(0.55, 0.05),
      Offset(0.20, 0.50),
      Offset(0.35, 0.52),
      Offset(0.50, 0.54),
      Offset(0.05, 1.00),
      Offset(0.58, 1.00),
    ],
    [
      [0, 1], [0, 2], [1, 4], [2, 3], [3, 4], [2, 5], [4, 6],
    ],
    Offset(0.07, 0.74),
    0.22,
    0.50,
    _C.pink,
  ),
  // Vrischika (Scorpius) – bottom right
  _Constellation(
    [
      Offset(0.00, 0.00),
      Offset(0.10, 0.12),
      Offset(0.20, 0.22),
      Offset(0.30, 0.35),
      Offset(0.38, 0.50),
      Offset(0.50, 0.62),
      Offset(0.65, 0.65),
      Offset(0.78, 0.55),
      Offset(0.82, 0.40),
    ],
    [
      [0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8],
    ],
    Offset(0.60, 0.76),
    0.30,
    0.75,
    _C.sky,
  ),
];

// ─────────────────────────────────────────────────────────────
//  Background: nebula glows, twinkling stars, constellations
// ─────────────────────────────────────────────────────────────
class _CosmosPainter extends CustomPainter {
  final Animation<double> intro;
  final Animation<double> loop;
  final List<_Star> stars;

  _CosmosPainter(this.intro, this.loop, this.stars)
      : super(repaint: Listenable.merge([intro, loop]));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = loop.value;
    final fade = Curves.easeOut.transform(intro.value.clamp(0.0, 1.0));

    // Deep gradient base
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_C.deep, _C.navy, Color(0xFF14123D)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Drifting nebula glows
    void glow(Offset c, double r, Color col, double o) {
      final p = Paint()
        ..shader = RadialGradient(
          colors: [_a(col, o * fade), _a(col, 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, p);
    }

    final s1 = math.sin(2 * math.pi * t);
    final c1 = math.cos(2 * math.pi * t);
    glow(Offset(w * (0.15 + 0.05 * s1), h * (0.18 + 0.03 * c1)), w * 0.75,
        _C.pink, 0.30);
    glow(Offset(w * (0.88 - 0.05 * s1), h * (0.82 - 0.03 * c1)), w * 0.85,
        _C.sky, 0.28);
    glow(Offset(w * 0.5, h * 0.42), w * 0.65, _C.violet, 0.20);

    // Twinkling stars
    final sp = Paint();
    for (final s in stars) {
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (s.freq * t + s.phase));
      final o = (0.25 + 0.75 * tw) * fade;
      final pos = Offset(s.x * w, s.y * h);
      sp.color = _a(s.color, o);
      canvas.drawCircle(pos, s.radius, sp);
      if (s.radius > 1.5) {
        // little four-point sparkle
        final len = s.radius * 3.2 * tw;
        final lp = Paint()
          ..color = _a(s.color, o * 0.8)
          ..strokeWidth = 0.8;
        canvas.drawLine(pos - Offset(len, 0), pos + Offset(len, 0), lp);
        canvas.drawLine(pos - Offset(0, len), pos + Offset(0, len), lp);
      }
    }

    // Auspicious constellations drifting gently (no comets / shooting stars)
    final cr = Curves.easeOut
        .transform(((intro.value - 0.08) / 0.55).clamp(0.0, 1.0));
    for (final c in _constellations) {
      _drawConstellation(canvas, size, c, t, cr);
    }
  }

  void _drawConstellation(
      Canvas canvas, Size size, _Constellation c, double t, double reveal) {
    final w = size.width, h = size.height;
    final ang = 2 * math.pi * (t + c.phase);
    final drift = Offset(math.sin(ang), math.cos(ang)) * (w * 0.018);
    final origin = Offset(c.anchor.dx * w, c.anchor.dy * h) + drift;
    final k = w * c.scale;

    Offset pt(int i) => origin + Offset(c.pts[i].dx * k, c.pts[i].dy * k);

    // Lines draw themselves in, one after another
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = _a(c.color, 0.40);
    for (int e = 0; e < c.edges.length; e++) {
      final local = (reveal * c.edges.length - e).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final p1 = pt(c.edges[e][0]);
      final p2 = pt(c.edges[e][1]);
      canvas.drawLine(p1, p1 + (p2 - p1) * local, linePaint);
    }

    // Glowing star nodes with soft twinkle
    for (int i = 0; i < c.pts.length; i++) {
      final tw = 0.6 + 0.4 * math.sin(2 * math.pi * (t * 2 + i * 0.17));
      final p = pt(i);
      canvas.drawCircle(
        p,
        6 * tw * reveal,
        Paint()
          ..color = _a(c.color, 0.45 * reveal)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
          p, 2.2 * reveal, Paint()..color = _a(Colors.white, 0.95 * reveal));
    }
  }

  @override
  bool shouldRepaint(covariant _CosmosPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
//  Zodiac mandala: ring, ticks, 12 rashis, lotus petals,
//  8-point star and 9 Navagraha orbs
// ─────────────────────────────────────────────────────────────
class _MandalaPainter extends CustomPainter {
  final Animation<double> intro;
  final Animation<double> loop;

  _MandalaPainter(this.intro, this.loop)
      : super(repaint: Listenable.merge([intro, loop]));

  static const _planets = [
    _C.gold, // Surya
    Color(0xFFE6F6FF), // Chandra
    Color(0xFFFF5C8A), // Mangala
    _C.mint, // Budha
    _C.gold, // Guru
    _C.softPink, // Shukra
    _C.skyLight, // Shani
    _C.violet, // Rahu
    _C.sky, // Ketu
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2;
    final R = half * 0.86;
    final lt = loop.value;
    final reveal =
        Curves.easeOutCubic.transform((intro.value / 0.7).clamp(0.0, 1.0));
    final spin = (1 - reveal) * 2.2; // spiral-in on entry
    final rot = lt * 2 * math.pi + spin;

    canvas.save();
    canvas.translate(half, half);
    canvas.scale(0.7 + 0.3 * reveal);

    // Pulsing core glow
    final pulse = 1 + 0.08 * math.sin(2 * math.pi * lt * 2);
    final coreR = R * 0.62 * pulse;
    canvas.drawCircle(
      Offset.zero,
      coreR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _a(_C.pink, 0.40 * reveal),
            _a(_C.violet, 0.18 * reveal),
            _a(_C.sky, 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: coreR)),
    );

    // Faint guide circles
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _a(Colors.white, 0.10 * reveal);
    canvas.drawCircle(Offset.zero, R * 0.86, guide);
    canvas.drawCircle(Offset.zero, R * 0.44, guide);
    canvas.drawCircle(Offset.zero, R * 1.10, guide);

    // Outer sweep ring (draws itself in)
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: R);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [_C.pink, _C.sky, _C.violet, _C.pink],
        transform: GradientRotation(rot),
      ).createShader(ringRect);
    canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * reveal, false, ring);

    // Tick marks
    final n = (72 * reveal).floor();
    final tickP = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < n; i++) {
      final ang = i * 2 * math.pi / 72 + rot;
      final long = i % 6 == 0;
      tickP
        ..strokeWidth = long ? 2.0 : 1.0
        ..color = long ? _a(_C.pink, 0.9) : _a(_C.skyLight, 0.55);
      canvas.drawLine(
        Offset.fromDirection(ang, R * (long ? 0.91 : 0.94)),
        Offset.fromDirection(ang, R * 0.98),
        tickP,
      );
    }

    // 12 Rashi markers (counter-rotating)
    for (int i = 0; i < 12; i++) {
      final ang = i * 2 * math.pi / 12 - rot;
      final pos = Offset.fromDirection(ang, R * 0.86);
      final col = i.isEven ? _C.pink : _C.sky;
      canvas.drawCircle(
        pos,
        9 * reveal,
        Paint()
          ..color = _a(col, 0.55 * reveal)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      final d = 5.0 * reveal;
      final path = Path()
        ..moveTo(pos.dx, pos.dy - d)
        ..lineTo(pos.dx + d, pos.dy)
        ..lineTo(pos.dx, pos.dy + d)
        ..lineTo(pos.dx - d, pos.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _a(Colors.white, 0.95 * reveal));
    }

    // Lotus petals – outer layer (counter-rotating) + inner layer
    _petals(canvas, R, 12, -rot * 0.5, 1.0, _C.pink, _C.sky, reveal);
    _petals(canvas, R, 12, rot * 0.5 + math.pi / 12, 0.72, _C.sky, _C.pink,
        reveal);

    // 8-pointed star (two squares) – Ashtakavarga vibes
    final starP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _a(_C.gold, 0.75 * reveal);
    for (int k = 0; k < 2; k++) {
      canvas.save();
      canvas.rotate(rot * 2 + k * math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: R * 0.56, height: R * 0.56),
        starP,
      );
      canvas.restore();
    }

    // 9 Navagraha orbs orbiting
    final orbitR = R * 1.10;
    for (int i = 0; i < 9; i++) {
      final ang = i * 2 * math.pi / 9 + lt * 2 * math.pi;
      final pos = Offset.fromDirection(ang, orbitR);
      final col = _planets[i];
      final tw = 0.7 + 0.3 * math.sin(2 * math.pi * (lt * 3 + i / 9));

      canvas.drawCircle(
        pos,
        8 * tw * reveal,
        Paint()
          ..color = _a(col, 0.65 * reveal)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
          pos, 3.6 * reveal, Paint()..color = _a(Colors.white, reveal));
      canvas.drawCircle(
          pos, 2.2 * reveal, Paint()..color = _a(col, reveal));
    }

    canvas.restore();
  }

  void _petals(Canvas canvas, double R, int count, double rotation,
      double scale, Color c1, Color c2, double reveal) {
    final path = Path()
      ..moveTo(0, -0.46 * R)
      ..cubicTo(0.17 * R, -0.58 * R, 0.13 * R, -0.72 * R, 0, -0.80 * R)
      ..cubicTo(-0.13 * R, -0.72 * R, -0.17 * R, -0.58 * R, 0, -0.46 * R)
      ..close();

    final rect = Rect.fromLTRB(-0.17 * R, -0.80 * R, 0.17 * R, -0.46 * R);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_a(c1, 0.30 * reveal), _a(c2, 0.05 * reveal)],
      ).createShader(rect);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_a(c1, 0.95 * reveal), _a(c2, 0.35 * reveal)],
      ).createShader(rect);

    canvas.save();
    canvas.rotate(rotation);
    canvas.scale(scale);
    for (int i = 0; i < count; i++) {
      canvas.save();
      canvas.rotate(i * 2 * math.pi / count);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter old) => false;
}