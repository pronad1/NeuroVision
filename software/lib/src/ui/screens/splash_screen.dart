// lib/src/ui/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _bgRotate;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _bgRotate = Tween<double>(begin: 0, end: 1).animate(_bgController);

    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward().then((_) {
        _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _navigateBasedOnAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    if (user != null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Stack(
        children: [
          // Animated background orbs
          _AnimatedBackground(rotateAnim: _bgRotate, size: size),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top nav bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Row(
                    children: [
                      // Logo mark
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [NVColors.primary, Color(0xFF0090B8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.biotech_rounded, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'NeuroVision AI',
                        style: TextStyle(
                          color: NVColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _NavButton(label: 'Features', onTap: () => _showComingSoonDialog(context, 'Features')),
                      const SizedBox(width: 8),
                      _NavButton(label: 'About', onTap: () => _showComingSoonDialog(context, 'About')),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: _navigateBasedOnAuth,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: NVColors.primary),
                          foregroundColor: NVColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),

                // Hero section
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 80 : 24,
                        vertical: 20,
                      ),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _HeroText(contentFade: _contentFade, contentSlide: _contentSlide, onGetStarted: _navigateBasedOnAuth)),
                                const SizedBox(width: 60),
                                Expanded(child: _HeroVisual(logoScale: _logoScale, logoOpacity: _logoOpacity)),
                              ],
                            )
                          : Column(
                              children: [
                                _HeroVisual(logoScale: _logoScale, logoOpacity: _logoOpacity),
                                const SizedBox(height: 40),
                                _HeroText(contentFade: _contentFade, contentSlide: _contentSlide, onGetStarted: _navigateBasedOnAuth),
                              ],
                            ),
                    ),
                  ),
                ),

                // Feature cards strip
                FadeTransition(
                  opacity: _contentFade,
                  child: const _FeatureStrip(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final VoidCallback onGetStarted;

  const _HeroText({
    required this.contentFade,
    required this.contentSlide,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: contentFade,
      child: SlideTransition(
        position: contentSlide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NVColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NVColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: NVColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Enterprise Medical AI Platform',
                    style: TextStyle(color: NVColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI-Powered\nClinical Imaging\nIntelligence',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: NVColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enterprise-grade medical imaging ecosystem for\nclinical specialists, radiologists, and AI researchers.\nDiagnose, annotate, and monitor with explainable AI.',
              style: TextStyle(
                fontSize: 16,
                color: NVColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onGetStarted,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Access Platform'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NVColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showVideoDemoDialog(context),
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                  label: const Text('Watch Demo'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: NVColors.borderBright),
                    foregroundColor: NVColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            // Role badges
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _RoleBadge(label: 'Doctors', icon: Icons.medical_services_rounded, color: NVColors.doctorColor),
                _RoleBadge(label: 'Radiologists', icon: Icons.scanner_rounded, color: NVColors.radiologistColor),
                _RoleBadge(label: 'Researchers', icon: Icons.science_rounded, color: NVColors.researcherColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;

  const _HeroVisual({required this.logoScale, required this.logoOpacity});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: logoScale,
      child: FadeTransition(
        opacity: logoOpacity,
        child: SizedBox(
          width: 380,
          height: 380,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NVColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NVColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              // Main brain icon container
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      NVColors.primary.withValues(alpha: 0.2),
                      NVColors.bgDeep,
                    ],
                  ),
                  border: Border.all(color: NVColors.primary.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: NVColors.primary.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: NVColors.primary,
                  size: 100,
                ),
              ),
              // Floating metric badges
              Positioned(
                top: 40,
                right: 20,
                child: _FloatingBadge(label: '98.7%', sublabel: 'Accuracy', color: NVColors.accent),
              ),
              Positioned(
                bottom: 50,
                left: 10,
                child: _FloatingBadge(label: '< 2s', sublabel: 'Analysis', color: NVColors.secondary),
              ),
              Positioned(
                top: 120,
                left: 5,
                child: _FloatingBadge(label: 'XAI', sublabel: 'Explainable', color: NVColors.warning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _FloatingBadge({
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NVColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(sublabel, style: const TextStyle(color: NVColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  static const features = [
    (Icons.psychology_rounded, 'Brain MRI Analysis', NVColors.doctorColor),
    (Icons.analytics_rounded, 'Spine Detection', NVColors.accent),
    (Icons.visibility_rounded, 'Grad-CAM XAI', NVColors.warning),
    (Icons.science_rounded, 'Model Tracking', NVColors.secondary),
    (Icons.security_rounded, 'RBAC Security', NVColors.info),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: NVColors.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: features.map((f) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(f.$1, color: f.$2, size: 16),
            const SizedBox(width: 8),
            Text(f.$3, style: const TextStyle(color: NVColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }).toList(),
        ),
      ),
    );
  }
}

void _showComingSoonDialog(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NVColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: NVColors.borderBright),
      ),
      title: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: NVColors.primary),
          const SizedBox(width: 10),
          Text(feature, style: const TextStyle(color: NVColors.textPrimary)),
        ],
      ),
      content: Text(
        '$feature is currently in development and will be available in the next release of NeuroVision AI.',
        style: const TextStyle(color: NVColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Got it', style: TextStyle(color: NVColors.primary)),
        ),
      ],
    ),
  );
}

void _showVideoDemoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 800,
        height: 450,
        decoration: BoxDecoration(
          color: NVColors.bgDeep,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: NVColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: NVColors.primary.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [NVColors.bgCard, NVColors.bgDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(800, 450),
                    painter: _GridPainter(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NVColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: NVColors.primary, size: 64),
            ),
            const Positioned(
              bottom: 40,
              child: Text(
                'Demo Video Placeholder',
                style: TextStyle(color: NVColors.textSecondary, fontSize: 16, letterSpacing: 1.2),
              ),
            ),
            Positioned(
              top: 20, right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: NVColors.textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: NVColors.textSecondary, fontSize: 14)),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  final Animation<double> rotateAnim;
  final Size size;

  const _AnimatedBackground({required this.rotateAnim, required this.size});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> {
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _initParticles();
  }

  void _initParticles() {
    final rand = math.Random();
    _particles = List.generate(40, (i) {
      return _Particle(
        position: Offset(
          rand.nextDouble() * 2000, // Safe estimate, will be clamped on first frame
          rand.nextDouble() * 1000,
        ),
        velocity: Offset(
          (rand.nextDouble() - 0.5) * 1.5,
          (rand.nextDouble() - 0.5) * 1.5,
        ),
        radius: rand.nextDouble() * 2 + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the window is really small, limit particles
    final particleCount = widget.size.width < 800 ? 20 : 40;
    
    return AnimatedBuilder(
      animation: widget.rotateAnim,
      builder: (context, _) {
        return Stack(
          children: [
            // Orb 1 - top right cyan
            Positioned(
              top: -100,
              right: -80,
              child: Transform.rotate(
                angle: widget.rotateAnim.value * 2 * math.pi * 0.3,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        NVColors.primary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Orb 2 - bottom left purple
            Positioned(
              bottom: -80,
              left: -60,
              child: Transform.rotate(
                angle: -widget.rotateAnim.value * 2 * math.pi * 0.2,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        NVColors.secondary.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Grid dots overlay
            CustomPaint(
              size: widget.size,
              painter: _GridPainter(),
            ),
            // Particle network
            CustomPaint(
              size: widget.size,
              painter: _ParticleNetworkPainter(_particles.take(particleCount).toList()),
            ),
          ],
        );
      },
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  final double radius;

  _Particle({required this.position, required this.velocity, required this.radius});
}

class _ParticleNetworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final double maxDistance = 160.0;

  _ParticleNetworkPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    final paint = Paint()
      ..color = NVColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..strokeWidth = 1.0;

    for (var i = 0; i < particles.length; i++) {
      final p1 = particles[i];

      // Update position
      p1.position += p1.velocity;
      
      // Bounce off walls
      if (p1.position.dx < 0 || p1.position.dx > size.width) {
        p1.velocity = Offset(-p1.velocity.dx, p1.velocity.dy);
        p1.position = Offset(p1.position.dx.clamp(0.0, size.width), p1.position.dy);
      }
      if (p1.position.dy < 0 || p1.position.dy > size.height) {
        p1.velocity = Offset(p1.velocity.dx, -p1.velocity.dy);
        p1.position = Offset(p1.position.dx, p1.position.dy.clamp(0.0, size.height));
      }

      canvas.drawCircle(p1.position, p1.radius, paint);

      // Draw connections
      for (var j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dist = (p1.position - p2.position).distance;
        if (dist < maxDistance) {
          linePaint.color = NVColors.primary.withValues(
            alpha: (0.25 * (1 - dist / maxDistance)).clamp(0.0, 1.0)
          );
          canvas.drawLine(p1.position, p2.position, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NVColors.primary.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dot intersections
    final dotPaint = Paint()
      ..color = NVColors.primary.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
