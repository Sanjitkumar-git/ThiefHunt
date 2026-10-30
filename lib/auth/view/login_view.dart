import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:thief_hunt/common/screen/widget/app_font.dart';
import 'package:thief_hunt/common/screen/widget/app_paddings.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../repository/auth_repository.dart';

const double _tau = math.pi * 2;

Color _c(int rgb, [double a = 1]) =>
    Color(0xFF000000 | rgb).withAlpha((a * 255).round().clamp(0, 255));

const int _gold = 0xFFC83D;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(AuthRepository()),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    this.title = 'THIEF HUNT',
    this.subtitle = 'FIND THE THIEF  •  TRUST NO ONE',
    this.gifAsset = 'assets/game_assets/gif/login_landscape.gif',
  });

  final String title;
  final String subtitle;
  final String gifAsset;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final List<_Star> _stars;
  late final List<_Cloud> _clouds;
  late final List<_Fly> _flies;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _stars = List.generate(
      140,
      (_) => _Star(
        r.nextDouble(),
        r.nextDouble(),
        0.6 + r.nextDouble() * 1.4,
        3 + r.nextInt(12),
        r.nextDouble() * _tau,
      ),
    );
    _clouds = List.generate(
      6,
      (_) => _Cloud(
        r.nextDouble(),
        0.08 + r.nextDouble() * 0.37,
        0.8 + r.nextDouble() * 0.8,
        0.05 + r.nextDouble() * 0.07,
      ),
    );
    const flyColors = [0xFFD36B, 0xFF9A5A, 0xFF7EB6];
    _flies = List.generate(
      38,
      (_) => _Fly(
        r.nextDouble(),
        r.nextDouble(),
        1.5 + r.nextDouble() * 2.0,
        3 + r.nextInt(6),
        2 + r.nextInt(5),
        r.nextDouble() * _tau,
        flyColors[r.nextInt(flyColors.length)],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c(0x0A0620),
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _KingdomPainter(_ctrl, _stars, _clouds, _flies),
              ),
            ),
          ),
          SafeArea(
            child: BlocConsumer<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state.status == LoginStatus.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Login successful!')),
                  );
                }
                if (state.status == LoginStatus.failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'Login failed'),
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state.status == LoginStatus.loading;
                return LayoutBuilder(
                  builder: (context, box) {
                    final landscape = box.maxWidth > box.maxHeight;
                    return landscape
                        ? _landscape(context, box, isLoading)
                        : _portrait(context, box, isLoading);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _landscape(BuildContext context, BoxConstraints box, bool isLoading) {
    final h = box.maxHeight;
    final compact = h < 380;
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppPadding.large,
              AppPadding.small,
              AppPadding.small,
              AppPadding.small,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Title(
                  ctrl: _ctrl,
                  title: widget.title,
                  subtitle: widget.subtitle,
                  size: (h * 0.11).clamp(24.0, 60.0),
                ),
                SizedBox(height: compact ? 4 : 12),
                Flexible(
                  child: _Characters(ctrl: _ctrl, asset: widget.gifAsset),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 8,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                40.sp,
                AppPadding.extraSmall,
                AppPadding.large,
                AppPadding.extraSmall,
              ),
              child: _entry(_card(context, compact, isLoading)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _portrait(BuildContext context, BoxConstraints box, bool isLoading) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppPadding.normal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _Title(
                ctrl: _ctrl,
                title: widget.title,
                subtitle: widget.subtitle,
                size: (box.maxWidth * 0.11).clamp(26.0, 56.0),
              ),
            ),
            const SizedBox(height: 12),
            _Characters(ctrl: _ctrl, asset: widget.gifAsset),
            const SizedBox(height: 12),
            Center(child: _entry(_card(context, false, isLoading))),
          ],
        ),
      ),
    );
  }

  Widget _entry(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(40 * (1 - v), 0), child: c),
      ),
      child: child,
    );
  }

  Widget _card(BuildContext context, bool compact, bool isLoading) {
    final gap = SizedBox(height: compact ? 10 : 14);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.all(compact ? 18 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_c(0xFFFFFF, 0.16), _c(0xFFFFFF, 0.05)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _c(0xFFFFFF, 0.22), width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'WELCOME, PLAYER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _c(_gold),
                    fontSize: compact ? 16 : 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Login to start your adventure',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _c(0xFFFFFF, 0.7), fontSize: 12.5),
                ),
                gap,
                _socialButton(
                  imagePath: 'assets/game_assets/images/google.png',
                  imageSize: 17.sp,
                  label: 'Continue with Google',
                  onTap: isLoading
                      ? null
                      : () => context.read<LoginBloc>().add(
                          const GoogleLoginRequested(),
                        ),
                ),
                const SizedBox(height: 12),
                _socialButton(
                  imagePath: 'assets/game_assets/images/facebook.png',
                  imageSize: 17.sp,
                  label: 'Continue with Facebook',
                  onTap: isLoading
                      ? null
                      : () => context.read<LoginBloc>().add(
                          const FacebookLoginRequested(),
                        ),
                ),
                gap,
                Row(
                  children: [
                    Expanded(child: Divider(color: _c(0xFFFFFF, 0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: _c(0xFFFFFF, 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: _c(0xFFFFFF, 0.2))),
                  ],
                ),
                gap,
                _GoldButton(
                  label: 'PLAY AS GUEST',
                  loading: isLoading,
                  onTap: () {
                    // TODO: guest login event yahan add karo
                    // context.read<LoginBloc>().add(const GuestLoginRequested());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String imagePath,
    required String label,
    required VoidCallback? onTap,
    double imageSize = 24,
  }) {
    return SizedBox(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: _c(0xFFFFFF, 0.4),
          backgroundColor: _c(0xFFFFFF, 0.06),
          side: BorderSide(color: _c(0xFFFFFF, 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Title (gold shimmer)
// ─────────────────────────────────────────────────────────────────────────────

class _Title extends StatelessWidget {
  const _Title({
    required this.ctrl,
    required this.title,
    required this.subtitle,
    required this.size,
  });

  final Animation<double> ctrl;
  final String title;
  final String subtitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: size * 0.08,
      height: 1.05,
    );
    Widget line() => Container(
      width: size * 0.8,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_c(_gold, 0), _c(_gold), _c(_gold, 0)],
        ),
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, _) {
              final p = ((ctrl.value * 12) % 1.0) * 2; // 0..2, seamless
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Dark 3D base + glow
                  Transform.translate(
                    offset: Offset(0, size * 0.05),
                    child: Text(
                      title,
                      style: base.copyWith(
                        color: _c(0x3A1A00),
                        shadows: [
                          Shadow(color: _c(0xFF9A1F, 0.7), blurRadius: 26),
                          Shadow(
                            color: _c(0x000000, 0.6),
                            offset: const Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (rect) => LinearGradient(
                      colors: [
                        _c(0xE08A00),
                        _c(0xFFC83D),
                        _c(0xFFF6C7),
                        _c(0xFFC83D),
                        _c(0xE08A00),
                      ],
                      tileMode: TileMode.mirror,
                      transform: _SlideGradient(p),
                    ).createShader(rect),
                    child: Text(
                      title,
                      style: base.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: size * 0.12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              line(),
              const SizedBox(width: 10),
              Text(
                subtitle,
                style: TextStyle(
                  color: _c(0xFFE9B8, 0.95),
                  fontSize: size * 0.28,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              line(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.p);
  final double p;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * p, 0, 0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Characters (GIF floats + glow + ground shadow)
// ─────────────────────────────────────────────────────────────────────────────

class _Characters extends StatelessWidget {
  const _Characters({required this.ctrl, required this.asset});

  final Animation<double> ctrl;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: AspectRatio(
        aspectRatio: 1200 / 520, // GIF ke ratio ke hisaab se change kar lena
        child: LayoutBuilder(
          builder: (context, box) {
            return AnimatedBuilder(
              animation: ctrl,
              builder: (context, _) {
                final t = ctrl.value;
                final bob = math.sin(_tau * 30 * t); // 2 s period
                final pulse = 0.5 + 0.5 * math.sin(_tau * 20 * t);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Golden aura
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 0.55,
                            colors: [
                              _c(_gold, 0.22 + 0.10 * pulse),
                              _c(_gold, 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Soft ground shadow
                    Align(
                      alignment: const Alignment(0, 0.95),
                      child: Transform.scale(
                        scale: 1 - 0.05 * bob,
                        child: FractionallySizedBox(
                          widthFactor: 0.7,
                          child: AspectRatio(
                            aspectRatio: 8,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _c(0x000000, 0.5),
                                        _c(0x000000, 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Floating characters
                    Transform.translate(
                      offset: Offset(0, bob * box.maxHeight * 0.012),
                      child: Image.asset(
                        asset,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        cacheWidth: 1000, // lighter on memory
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold button (shine sweep + press scale + loader)
// ─────────────────────────────────────────────────────────────────────────────

class _GoldButton extends StatefulWidget {
  const _GoldButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  bool _down = false;

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _c(0xFFB300, 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _shine,
            builder: (_, child) {
              final p = _shine.value * 3 - 1.5;
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  colors: [
                    _c(0xFFFFFF, 0),
                    _c(0xFFFFFF, 0.55),
                    _c(0xFFFFFF, 0),
                  ],
                  stops: const [0.4, 0.5, 0.6],
                  transform: _SlideGradient(p),
                ).createShader(rect),
                child: child,
              );
            },
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_c(0xFFE259), _c(0xFFB300), _c(0xFF8F00)],
                ),
                border: Border.all(color: _c(0xFFF3B0, 0.8), width: 1.2),
              ),
              child: widget.loading
                  ? SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: _c(0x4A2A00),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: _c(0x4A2A00), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: _c(0x4A2A00),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated background
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  const _Star(this.x, this.y, this.size, this.rate, this.phase);
  final double x, y, size, phase;
  final int rate;
}

class _Cloud {
  const _Cloud(this.x, this.y, this.scale, this.alpha);
  final double x, y, scale, alpha;
}

class _Fly {
  const _Fly(
    this.x,
    this.y,
    this.r,
    this.speed,
    this.sway,
    this.phase,
    this.color,
  );
  final double x, y, r, phase;
  final int speed, sway, color;
}

class _KingdomPainter extends CustomPainter {
  _KingdomPainter(this.anim, this.stars, this.clouds, this.flies)
    : super(repaint: anim);

  final Animation<double> anim;
  final List<_Star> stars;
  final List<_Cloud> clouds;
  final List<_Fly> flies;

  double _hy(
    double x,
    double w,
    double base,
    double amp,
    double phase,
    double freq,
  ) {
    final k = x / w * _tau * freq;
    return base +
        math.sin(k + phase) * amp +
        math.sin(k * 2.3 + phase * 1.7) * amp * 0.4;
  }

  Path _hills(
    Size s,
    double base,
    double amp,
    double phase,
    double freq,
    double dx,
  ) {
    final path = Path()..moveTo(-10 + dx, s.height + 10);
    for (double x = -10; x <= s.width + 10; x += 8) {
      path.lineTo(x + dx, _hy(x, s.width, base, amp, phase, freq));
    }
    path.lineTo(s.width + 10 + dx, s.height + 10);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = anim.value;
    final m = math.min(w, h);
    final landscape = w > h;
    final rect = Offset.zero & size;
    final p = Paint();

    // Sky
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          [_c(0x0A0620), _c(0x2B1260), _c(0x7A2F78), _c(0xE5775B)],
          [0, 0.5, 0.8, 1],
        ),
    );

    // Stars
    for (final s in stars) {
      final tw = 0.5 + 0.5 * math.sin(_tau * s.rate * t + s.phase);
      p.color = _c(0xFFFFFF, 0.25 + 0.75 * tw);
      canvas.drawCircle(
        Offset(s.x * w, s.y * h * 0.65),
        s.size * (0.7 + 0.5 * tw),
        p,
      );
    }

    // Moon (soft glow + craters)
    final mc =
        Offset(
          landscape ? w * 0.58 : w * 0.78,
          landscape ? h * 0.2 : h * 0.12,
        ) +
        Offset(0, math.sin(_tau * 3 * t) * 3);
    final mr = m * 0.085;
    for (var i = 7; i >= 1; i--) {
      p.color = _c(0xFFE9A8, 0.03);
      canvas.drawCircle(mc, mr * (1 + i * 0.35), p);
    }
    p.color = _c(0xFFF3CF);
    canvas.drawCircle(mc, mr, p);
    p.color = _c(0xE3D3A5, 0.6);
    canvas.drawCircle(mc + Offset(-mr * 0.3, -mr * 0.2), mr * 0.2, p);
    canvas.drawCircle(mc + Offset(mr * 0.35, mr * 0.1), mr * 0.14, p);
    canvas.drawCircle(mc + Offset(-mr * 0.1, mr * 0.45), mr * 0.1, p);

    // Clouds
    for (final c in clouds) {
      final cw = m * 0.5 * c.scale;
      final x = ((c.x + t) % 1.0) * (w + cw * 2) - cw;
      final y = c.y * h;
      p.color = _c(0xC9A8FF, c.alpha);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: cw, height: cw * 0.22),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - cw * 0.2, y - cw * 0.07),
          width: cw * 0.55,
          height: cw * 0.2,
        ),
        p,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + cw * 0.18, y - cw * 0.05),
          width: cw * 0.5,
          height: cw * 0.18,
        ),
        p,
      );
    }

    // Far hills + castle (slow parallax sway)
    final sway1 = math.sin(_tau * 3 * t) * m * 0.006;
    const farBase = 0.64, farAmp = 0.045;
    canvas.drawPath(
      _hills(size, h * farBase, h * farAmp, 1.0, 1.6, sway1),
      Paint()..color = _c(0x3A1B66),
    );
    final cx = landscape ? w * 0.38 : w * 0.5;
    final castleBase =
        _hy(cx, w, h * farBase, h * farAmp, 1.0, 1.6) + m * 0.006;
    _castle(
      canvas,
      Offset(cx + sway1, castleBase),
      m * 0.0125,
      _c(0x2A1250),
      t,
    );

    // Near hills + pines
    final sway2 = math.sin(_tau * 3 * t + 1) * m * 0.012;
    const nearBase = 0.8, nearAmp = 0.035;
    final nearPaint = Paint()..color = _c(0x120728);
    canvas.drawPath(
      _hills(size, h * nearBase, h * nearAmp, 2.4, 2.2, sway2),
      nearPaint,
    );
    for (var i = 0; i < 15; i++) {
      final x = w * (i / 14 + 0.02 * (i % 3));
      final y = _hy(x, w, h * nearBase, h * nearAmp, 2.4, 2.2) + 4;
      final th = m * (0.05 + 0.03 * (((i * 37) % 5) / 4));
      _pine(canvas, Offset(x + sway2, y), th, nearPaint);
    }

    // Ground mist
    final mistRect = Rect.fromLTRB(0, h * 0.7, w, h);
    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = ui.Gradient.linear(
          mistRect.topCenter,
          mistRect.bottomCenter,
          [_c(0x7A2F78, 0), _c(0x1A0A30, 0.75)],
        ),
    );

    // Fireflies
    for (final f in flies) {
      final yf = 1 - ((f.y + t * f.speed) % 1.0);
      final x = (f.x + math.sin(_tau * f.sway * t + f.phase) * 0.02) * w;
      final y = yf * h;
      final a = math.sin(math.pi * yf).clamp(0.0, 1.0);
      final tw = 0.6 + 0.4 * math.sin(_tau * f.sway * 2 * t + f.phase);
      final o = Offset(x, y);
      p.color = _c(f.color, a * 0.10 * tw);
      canvas.drawCircle(o, f.r * 5, p);
      p.color = _c(f.color, a * 0.22 * tw);
      canvas.drawCircle(o, f.r * 2.6, p);
      p.color = _c(0xFFFFFF, a * 0.9 * tw);
      canvas.drawCircle(o, f.r * 0.7, p);
    }

    // Vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          math.max(w, h) * 0.75,
          [_c(0x000000, 0), _c(0x000000, 0.5)],
          [0.55, 1],
        ),
    );
  }

  void _pine(Canvas c, Offset b, double hgt, Paint p) {
    final w = hgt * 0.38;
    for (var i = 0; i < 3; i++) {
      final top = b.dy - hgt + i * hgt * 0.26;
      final bot = top + hgt * 0.46;
      final half = w * (0.45 + 0.28 * i);
      c.drawPath(
        Path()
          ..moveTo(b.dx, top)
          ..lineTo(b.dx - half, bot)
          ..lineTo(b.dx + half, bot)
          ..close(),
        p,
      );
    }
  }

  void _castle(Canvas c, Offset base, double u, Color col, double t) {
    final p = Paint()..color = col;
    Rect r(double l, double top, double rr, double b) => Rect.fromLTRB(
      base.dx + l * u,
      base.dy + top * u,
      base.dx + rr * u,
      base.dy + b * u,
    );

    // Walls, keep, towers
    c.drawRect(r(-22, -6, 22, 3), p);
    c.drawRect(r(-6, -15, 6, 3), p);
    c.drawRect(r(-14, -20, -8, 3), p);
    c.drawRect(r(8, -20, 14, 3), p);
    c.drawRect(r(-2.5, -25, 2.5, -12), p);

    // Merlons
    void merlons(double l, double rr, double top) {
      for (double x = l; x < rr - 1; x += 2.4) {
        c.drawRect(r(x, top - 1.4, x + 1.3, top), p);
      }
    }

    merlons(-22, -14, -6);
    merlons(14, 22, -6);
    merlons(-6, 6, -15);

    // Roofs
    void roof(double cx, double top, double half, double hgt) {
      c.drawPath(
        Path()
          ..moveTo(base.dx + (cx - half) * u, base.dy + top * u)
          ..lineTo(base.dx + cx * u, base.dy + (top - hgt) * u)
          ..lineTo(base.dx + (cx + half) * u, base.dy + top * u)
          ..close(),
        p,
      );
    }

    roof(-11, -20, 4.2, 7);
    roof(11, -20, 4.2, 7);
    roof(0, -25, 3.4, 8);

    // Flag on the tallest roof
    final flap = math.sin(_tau * 30 * t) * 0.6;
    c.drawLine(
      Offset(base.dx, base.dy - 33 * u),
      Offset(base.dx, base.dy - 36.5 * u),
      Paint()
        ..color = col
        ..strokeWidth = math.max(1, u * 0.3),
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - 36.5 * u)
        ..lineTo(base.dx + (3 + flap) * u, base.dy - 35.5 * u)
        ..lineTo(base.dx, base.dy - 34.5 * u)
        ..close(),
      Paint()..color = _c(0xE5575B),
    );

    // Flickering windows
    const windows = [
      Offset(-11, -13),
      Offset(11, -13),
      Offset(0, -20),
      Offset(-3, -9),
      Offset(3, -9),
    ];
    for (var i = 0; i < windows.length; i++) {
      final a = 0.55 + 0.45 * math.sin(_tau * (6 + i * 3) * t + i);
      final o = windows[i];
      c.drawRect(
        r(o.dx - 0.6, o.dy - 1, o.dx + 0.6, o.dy + 1),
        Paint()..color = _c(0xFFC857, a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KingdomPainter old) => false;
}
