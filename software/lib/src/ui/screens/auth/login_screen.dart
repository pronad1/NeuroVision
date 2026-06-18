// lib/src/ui/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<NVAuthProvider>(context, listen: false);
    final error = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Determine redirect based on role
      final user = auth.nvUser;
      if (user != null) {
        _navigateByRole(user.role);
      }
    } else {
      _showError(error);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isGoogleLoading = true);

    final auth = Provider.of<NVAuthProvider>(context, listen: false);
    final error = await auth.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (error == null) {
      final user = auth.nvUser;
      if (user != null) _navigateByRole(user.role);
    } else {
      _showError(error);
    }
  }

  void _navigateByRole(String role) {
    final route = switch (role) {
      AppConstants.roleDoctor => '/dashboard/doctor',
      AppConstants.roleRadiologist => '/dashboard/radiologist',
      AppConstants.roleResearcher => '/dashboard/researcher',
      _ => '/dashboard/doctor',
    };
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: NVColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: NVColors.textPrimary))),
          ],
        ),
        backgroundColor: NVColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: NVColors.error, width: 0.5),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: NVColors.bgDeep,
      body: Stack(
        children: [
          // Subtle grid background
          CustomPaint(
            size: size,
            painter: _SubtleGridPainter(),
          ),

          // Glow orbs
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  NVColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  NVColors.secondary.withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
                ),
              ),
            ),
          ),

          // Back to Home Button
          Positioned(
            top: 24, left: 24,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
                icon: const Icon(Icons.arrow_back_rounded, color: NVColors.textSecondary),
                tooltip: 'Back to Home',
                splashRadius: 24,
                hoverColor: NVColors.bgSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left panel - branding
        _BrandPanel(),
        const SizedBox(width: 60),
        // Right panel - form
        SizedBox(width: 440, child: _buildLoginCard()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [NVColors.primary, Color(0xFF0090B8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'NeuroVision AI',
                style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildLoginCard(),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: NVColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NVColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: NVColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to your clinical workspace',
              style: TextStyle(fontSize: 14, color: NVColors.textMuted),
            ),
            const SizedBox(height: 32),

            // Email
            const _FieldLabel(text: 'Email Address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: NVColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'your@institution.org',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password
            const _FieldLabel(text: 'Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              style: const TextStyle(color: NVColors.textPrimary),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: NVColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 12),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: NVColors.primary, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NVColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: NVColors.primary.withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: NVColors.border, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: NVColors.textMuted, fontSize: 13)),
                ),
                Expanded(child: Divider(color: NVColors.border, thickness: 1)),
              ],
            ),
            const SizedBox(height: 20),

            // Google Sign In
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isGoogleLoading ? null : _googleSignIn,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: NVColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: NVColors.bgCard,
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: NVColors.primary),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 18, height: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 22, color: Colors.blue),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(color: NVColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // Sign up link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: NVColors.textMuted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Request Access',
                      style: TextStyle(color: NVColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [NVColors.primary, Color(0xFF0090B8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'NeuroVision AI',
                style: TextStyle(color: NVColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'Your clinical\nintelligence hub',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: NVColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Access AI-powered diagnostic tools, segmentation analysis, and research monitoring — all in one secure platform.',
            style: TextStyle(fontSize: 15, color: NVColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 36),
          ..._buildFeatureList(),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      (Icons.psychology_rounded, NVColors.doctorColor, 'AI Diagnosis Review'),
      (Icons.scanner_rounded, NVColors.radiologistColor, 'DICOM & Annotation'),
      (Icons.science_rounded, NVColors.researcherColor, 'Model Performance Tracking'),
      (Icons.security_rounded, NVColors.info, 'Role-Based Access Control'),
    ];
    return features.map((f) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: f.$2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(f.$1, color: f.$2, size: 16),
            ),
            const SizedBox(width: 12),
            Text(f.$3, style: const TextStyle(color: NVColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }).toList();
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: NVColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NVColors.primary.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
