import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class SplashScreenRadar extends StatefulWidget {
  final Widget nextScreen;
  final String gifPath;

  const SplashScreenRadar({
    super.key,
    required this.nextScreen,
    this.gifPath = 'assets/game_assets/gif/thief_hunt_table_game.gif',
  });

  @override
  State<SplashScreenRadar> createState() => _SplashScreenRadarState();
}

class _SplashScreenRadarState extends State<SplashScreenRadar>
    with TickerProviderStateMixin {
  late final AnimationController _sweep; // radar rotation
  late final AnimationController _pulse; // glow breathing
  late final AnimationController _intro; // title typing / entrance
  late final AnimationController _load; // loader 0 -> 1

  static const _amber = Color(0xFFFFB830);
  static const _cyan = Color(0xFF22E5E0);
  static const _red = Color(0xFFE5251B);
  static const _bg = Color(0xFF070B14);

  static const _status = [
    'Scanning the kingdom...',
    'Locating suspects...',
    'Briefing the police...',
    'Tracking down the thief...',
    'Ready to play!',
  ];

  static const _segments = 14;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _load = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    )..forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => widget.nextScreen,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    _intro.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Grid background ----
          const CustomPaint(painter: _GridPainter()),

          // ---- Vignette ----
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                // ================= LEFT: radar =================
                Expanded(
                  flex: 4,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final d = math.min(c.maxWidth, c.maxHeight) * 0.92;
                        return _buildRadar(d);
                      },
                    ),
                  ),
                ),

                // ================= RIGHT: title + loader =================
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 28, left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCaseTag(),
                        const SizedBox(height: 10),
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildTagline(),
                        const SizedBox(height: 26),
                        _buildLoader(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- RADAR ----------------
  Widget _buildRadar(double d) {
    final gifD = d * 0.56;

    return AnimatedBuilder(
      animation: Listenable.merge([_sweep, _pulse, _intro]),
      builder: (_, _) {
        final t = Curves.easeOutCubic.transform(_intro.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.9 + 0.1 * t,
            child: SizedBox(
              width: d,
              height: d,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // rings + sweep + blips
                  CustomPaint(
                    size: Size(d, d),
                    painter: _RadarPainter(
                      sweep: _sweep.value,
                      pulse: _pulse.value,
                    ),
                  ),
                  // GIF in the center
                  Container(
                    width: gifD,
                    height: gifD,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _amber.withValues(alpha: 0.9),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _amber.withValues(alpha: 0.25 + 0.2 * _pulse.value),
                          blurRadius: 24 + 10 * _pulse.value,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        widget.gifPath,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white38,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- CASE TAG ----------------
  Widget _buildCaseTag() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, _) {
        final o = (_intro.value / 0.3).clamp(0.0, 1.0);
        return Opacity(
          opacity: o,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _red.withValues(alpha: 0.8), width: 1.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'CASE FILE #001  •  TOP SECRET',
              style: TextStyle(
                color: _red,
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- TITLE (letter by letter) ----------------
  Widget _buildTitle() {
    const text = 'THIEF HUNT';

    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _pulse]),
      builder: (_, _) {
        final letters = <Widget>[];
        for (int i = 0; i < text.length; i++) {
          final ch = text[i];
          if (ch == ' ') {
            letters.add(const SizedBox(width: 18));
            continue;
          }
          final start = 0.15 + i * 0.055;
          final p = ((_intro.value - start) / 0.25).clamp(0.0, 1.0);
          final e = Curves.easeOutBack.transform(p);

          letters.add(
            Opacity(
              opacity: p,
              child: Transform.translate(
                offset: Offset(0, (1 - e) * 22),
                child: Text(
                  ch,
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    height: 1.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: _amber.withValues(alpha: 0.55 + 0.3 * _pulse.value),
                        blurRadius: 16 + 8 * _pulse.value,
                      ),
                      Shadow(color: _cyan.withValues(alpha: 0.45), blurRadius: 4),
                      const Shadow(
                        color: Colors.black87,
                        offset: Offset(2, 3),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: letters),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, _) {
        final o = ((_intro.value - 0.6) / 0.4).clamp(0.0, 1.0);
        return Opacity(
          opacity: o,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(colors: [_cyan, _amber]),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'FIND THE THIEF. TRUST NO ONE.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- SEGMENTED LOADER ----------------
  Widget _buildLoader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_load, _pulse]),
      builder: (_, _) {
        final v = Curves.easeInOutCubic.transform(_load.value);
        final idx = (v * _status.length).floor().clamp(0, _status.length - 1);
        final filled = (v * _segments).floor();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Align(
                      key: ValueKey(idx),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '> ${_status[idx]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _cyan.withValues(alpha: 0.9),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${(v * 100).toInt()}%',
                  style: const TextStyle(
                    color: _amber,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(_segments, (i) {
                final on = i < filled;
                final current = i == filled && v < 1.0;
                final k = i / (_segments - 1);
                final color = Color.lerp(_cyan, _red, k)!;

                return Expanded(
                  child: Container(
                    height: 12,
                    margin: EdgeInsets.only(right: i == _segments - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: on
                          ? color
                          : current
                          ? color.withValues(alpha: 0.3 + 0.5 * _pulse.value)
                          : Colors.white.withValues(alpha: 0.08),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.55),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// =====================================================================
// Painters
// =====================================================================

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF22E5E0).withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RadarPainter extends CustomPainter {
  final double sweep; // 0..1
  final double pulse; // 0..1

  _RadarPainter({required this.sweep, required this.pulse});

  static const _cyan = Color(0xFF22E5E0);
  static const _amber = Color(0xFFFFB830);

  // (angle in radians, radius factor 0..1)
  static const _blips = [
    [0.7, 0.86],
    [2.1, 0.92],
    [3.6, 0.8],
    [4.9, 0.94],
    [5.7, 0.84],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // rings
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _cyan.withValues(alpha: 0.28);
    for (final f in [0.6, 0.78, 0.96]) {
      canvas.drawCircle(c, r * f, ring);
    }
    // outer ring (pulsing)
    canvas.drawCircle(
      c,
      r * 0.99,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _cyan.withValues(alpha: 0.35 + 0.25 * pulse),
    );

    // crosshair
    final cross = Paint()
      ..color = _cyan.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), cross);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), cross);

    // tick marks
    final tick = Paint()
      ..color = _cyan.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final len = i % 3 == 0 ? 9.0 : 5.0;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.99, c.dy + math.sin(a) * r * 0.99),
        Offset(
          c.dx + math.cos(a) * (r * 0.99 - len),
          c.dy + math.sin(a) * (r * 0.99 - len),
        ),
        tick,
      );
    }

    // sweep beam
    final angle = sweep * 2 * math.pi;
    final rect = Rect.fromCircle(center: c, radius: r * 0.98);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          Colors.transparent,
          _cyan.withValues(alpha: 0.0),
          _cyan.withValues(alpha: 0.38),
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: GradientRotation(angle - 2 * math.pi),
      ).createShader(rect);
    canvas.drawCircle(c, r * 0.98, sweepPaint);

    // beam leading line
    canvas.drawLine(
      c,
      Offset(
        c.dx + math.cos(angle) * r * 0.98,
        c.dy + math.sin(angle) * r * 0.98,
      ),
      Paint()
        ..color = _cyan.withValues(alpha: 0.9)
        ..strokeWidth = 1.8,
    );

    // blips (fade after the beam passes over them)
    for (final b in _blips) {
      final a = b[0];
      final rf = b[1];
      var diff = (angle - a) % (2 * math.pi);
      if (diff < 0) diff += 2 * math.pi;
      final alpha = (1 - diff / (2 * math.pi)).clamp(0.0, 1.0);
      final pos = Offset(
        c.dx + math.cos(a) * r * rf,
        c.dy + math.sin(a) * r * rf,
      );
      canvas.drawCircle(
        pos,
        9 * alpha + 2,
        Paint()
          ..color = _amber.withValues(alpha: 0.25 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(pos, 3.2, Paint()..color = _amber.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.sweep != sweep || old.pulse != pulse;
}
