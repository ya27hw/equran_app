import 'dart:math';
import 'dart:ui';

import 'package:equran/home/library.dart' show HomePage;
import 'package:equran/backend/startup_coordinator.dart';
import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  // Staggered animations
  late Animation<double> _drawingAnimation;
  late Animation<double> _fillAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _glowAnimation;

  // Particles list
  final List<FloatingParticle> _particles = [];
  final Random _random = Random();
  final int _particleCount = 35;

  @override
  void initState() {
    super.initState();

    // 1. Setup Controllers
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 2. Setup Staggered Animations
    _drawingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOutCubic),
      ),
    );

    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
      ),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Setup Particles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeParticles();
      _mainController.forward().then((_) => _navigateToHome());
    });

    // 4. Update particles on pulse tick
    _pulseController.addListener(() {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      }
    });
  }

  void _initializeParticles() {
    final Size size = MediaQuery.of(context).size;
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        FloatingParticle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          radius: _random.nextDouble() * 2.2 + 0.8,
          speed: _random.nextDouble() * 0.4 + 0.15,
          opacity: _random.nextDouble() * 0.6 + 0.2,
          angle: _random.nextDouble() * pi * 2,
          waveSpeed: _random.nextDouble() * 0.015 + 0.005,
        ),
      );
    }
  }

  void _updateParticles() {
    final Size size = MediaQuery.of(context).size;
    for (final particle in _particles) {
      particle.y -= particle.speed;
      particle.x += sin(particle.angle) * 0.25;
      particle.angle += particle.waveSpeed;

      // Reset when particle goes off-screen
      if (particle.y < -10) {
        particle.y = size.height + 10;
        particle.x = _random.nextDouble() * size.width;
      }
    }
  }

  Future<void> _navigateToHome() async {
    await StartupCoordinator.instance.startDeferred();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeCurve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          final scaleCurve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: fadeCurve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.06, end: 1.0).animate(scaleCurve),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 850),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EquranColors colors = context.equranColors;
    final Size size = MediaQuery.of(context).size;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Islamic theme colors
    final Color goldAccent = colors.accentGold;
    final Color deepTeal = colors.primaryGradientStart;
    final Color darkBackground = colors.background;

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Sleek Gradient Backdrop with high contrast glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          darkBackground,
                          Color.alphaBlend(
                            deepTeal.withValues(alpha: 0.35),
                            darkBackground,
                          ),
                          darkBackground,
                        ]
                      : [
                          darkBackground,
                          Color.alphaBlend(
                            deepTeal.withValues(alpha: 0.08),
                            darkBackground,
                          ),
                          darkBackground,
                        ],
                ),
              ),
            ),
          ),

          // 2. Animated Twinkling Particles
          CustomPaint(
            size: size,
            painter: ParticlePainter(particles: _particles, color: goldAccent),
          ),

          // 3. Central Ambient Radial Glow
          Center(
            child: AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, child) {
                final double currentGlow =
                    _fillAnimation.value * _glowAnimation.value;
                return Opacity(
                  opacity: _fillAnimation.value * 0.45,
                  child: Container(
                    width: size.width * 0.65 * currentGlow,
                    height: size.width * 0.65 * currentGlow,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          goldAccent.withValues(alpha: 0.25),
                          goldAccent.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Central Geometric Drawing
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: RubElHizbPainter(
                      drawProgress: _drawingAnimation.value,
                      fillOpacity: _fillAnimation.value,
                      primaryColor: deepTeal,
                      goldColor: goldAccent,
                    ),
                  ),
                );
              },
            ),
          ),

          // 5. Staggered Text & Branding
          Positioned(
            bottom: size.height * 0.15,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                final double slideOffset = (1.0 - _textAnimation.value) * 35;
                return Opacity(
                  opacity: _textAnimation.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, slideOffset),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Title
                        Text(
                          "eQuran",
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Sleek Gold Accent Divider line
                        Container(
                          width: 40,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                goldAccent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          "The Holy Quran & Prayer Companion",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.8,
                            color: colors.textSecondary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingParticle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;
  double angle;
  final double waveSpeed;

  FloatingParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.angle,
    required this.waveSpeed,
  });
}

class ParticlePainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final Paint paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(particle.x, particle.y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

class RubElHizbPainter extends CustomPainter {
  final double drawProgress;
  final double fillOpacity;
  final Color primaryColor;
  final Color goldColor;

  RubElHizbPainter({
    required this.drawProgress,
    required this.fillOpacity,
    required this.primaryColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerRadius = size.width / 2 * 0.92;
    final double innerRadius = outerRadius * 0.76536;

    final Paint outlinePaint = Paint()
      ..color = goldColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              goldColor.withValues(alpha: 0.24 * fillOpacity),
              goldColor.withValues(alpha: 0.01 * fillOpacity),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius),
          )
      ..style = PaintingStyle.fill;

    final Paint innerStarPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.48 * fillOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Construct Rub el Hizb 16-sided continuous star path
    final Path starPath = Path();
    for (int i = 0; i < 16; i++) {
      double angle = i * pi / 8 - pi / 2;
      double r = i.isEven ? outerRadius : innerRadius;
      double x = cx + r * cos(angle);
      double y = cy + r * sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    // 2. Draw the filled star background
    if (fillOpacity > 0.0) {
      canvas.drawPath(starPath, fillPaint);
    }

    // 3. Draw the animated outline
    if (drawProgress > 0.0) {
      final Path animatedPath = Path();
      for (final PathMetric metric in starPath.computeMetrics()) {
        animatedPath.addPath(
          metric.extractPath(0.0, metric.length * drawProgress),
          Offset.zero,
        );
      }
      canvas.drawPath(animatedPath, outlinePaint);
    }

    // 4. Draw intricate inner details when filled
    if (fillOpacity > 0.0) {
      // Draw inner circle
      final double circleRadius = innerRadius * 0.8;
      canvas.drawCircle(Offset(cx, cy), circleRadius, innerStarPaint);

      // Draw a smaller inner 8-pointed star
      final Path innerStarPath = Path();
      final double innerOuterR = circleRadius * 0.9;
      final double innerInnerR = innerOuterR * 0.76536;
      for (int i = 0; i < 16; i++) {
        double angle = i * pi / 8 - pi / 2;
        double r = i.isEven ? innerOuterR : innerInnerR;
        double x = cx + r * cos(angle);
        double y = cy + r * sin(angle);
        if (i == 0) {
          innerStarPath.moveTo(x, y);
        } else {
          innerStarPath.lineTo(x, y);
        }
      }
      innerStarPath.close();
      canvas.drawPath(innerStarPath, innerStarPaint);

      // Solid center glowing dot
      final Paint centerDotPaint = Paint()
        ..color = goldColor.withValues(alpha: 0.9 * fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 3.2, centerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RubElHizbPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.fillOpacity != fillOpacity ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.goldColor != goldColor;
  }
}
