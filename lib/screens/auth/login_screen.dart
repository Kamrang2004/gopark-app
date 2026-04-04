import 'dart:math' show pi;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/social_auth_service.dart';
import 'package:gopark_app/screens/auth/simple_register_screen.dart';
import 'package:gopark_app/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAppleAvailable = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _checkAppleAvailability();
  }

  Future<void> _checkAppleAvailability() async {
    final available = await SocialAuthService.isAppleSignInAvailable();
    if (mounted) setState(() => _isAppleAvailable = available);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Auth handlers ──────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('login.php', {
        'identifier': _identifierController.text,
        'password': _passwordController.text,
      });
      if (response['status'] == 'success') {
        _navigateHome(response['data'] ?? {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Login failed'),
          backgroundColor: Colors.red.shade400,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Please check your server.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialResponse(Map<String, dynamic>? response) async {
    if (response == null) return;
    if (response['status'] == 'success') {
      _navigateHome(response['data'] ?? {});
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'Social login failed'),
        backgroundColor: Colors.red.shade400,
      ));
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _handleSocialResponse(await SocialAuthService.signInWithGoogle());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _handleSocialResponse(await SocialAuthService.signInWithApple());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateHome(Map<String, dynamic> data) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          user: data['user'] ?? {},
          isResident: data['is_resident'] ?? false,
          residentStatus: data['resident_profile']?['status'],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0F7FF), Color(0xFFFFFFFF), Color(0xFFE6F2FF)],
              ),
            ),
          ),

          // Decorative blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.10),
                  AppTheme.primaryBlue.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.07),
                  AppTheme.primaryBlue.withValues(alpha: 0),
                ]),
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/logo_general.png',
                          width: 260,
                          height: 75,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 36),

                        // ── Glassmorphism card (credentials only) ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Welcome Back',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Access your parking & security portal',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 28),

                                  _buildTextField(
                                    controller: _identifierController,
                                    label: 'Email or Phone',
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 8),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text('Forgot Password?',
                                          style: TextStyle(color: AppTheme.primaryBlue)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Login button
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: AppTheme.primaryBlue))
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppTheme.primaryBlue,
                                                Color(0xFF3479A5)
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryBlue
                                                    .withValues(alpha: 0.30),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12)),
                                            ),
                                            onPressed: _login,
                                            child: const Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Sign-up link ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(color: Colors.grey.shade700)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SimpleRegisterScreen()),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── OR divider ──
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    Colors.grey.shade300,
                                  ]),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.grey.shade300,
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Google Sign-In ──
                        _SocialButton(
                          onPressed: _isLoading ? null : _googleSignIn,
                          icon: SizedBox(
                            width: 22,
                            height: 22,
                            child: CustomPaint(painter: _GoogleGPainter()),
                          ),
                          label: 'Continue with Google',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3C4043),
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          borderColor: const Color(0xFFDDDDDD),
                        ),

                        // ── Apple Sign-In (iOS only) ──
                        if (_isAppleAvailable) ...[
                          const SizedBox(height: 12),
                          _SocialButton(
                            onPressed: _isLoading ? null : _appleSignIn,
                            icon: const Icon(Icons.apple,
                                color: Colors.white, size: 22),
                            label: 'Continue with Apple',
                            backgroundColor: const Color(0xFF050505),
                            foregroundColor: Colors.white,
                            shadowColor: Colors.black.withValues(alpha: 0.22),
                            borderColor: Colors.transparent,
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: const Color(0xFFF5F7FA).withValues(alpha: 0.85),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium social sign-in button
// ─────────────────────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color shadowColor;
  final Color borderColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: foregroundColor.withValues(alpha: 0.08),
          highlightColor: foregroundColor.withValues(alpha: 0.04),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Proper 4-colour Google "G" logo via CustomPainter
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.195;
    final r = size.width / 2 - sw / 2 - 0.5;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const d = pi / 180;

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Arc from -30° to 30° going counterclockwise (negative sweep),
    // leaving a 60° gap on the right side where the crossbar sits.
    // Total arc sweep = -300°.
    //   Blue   : -30° → -130° (100°)
    //   Red    : -130° → -210° ( 80°)
    //   Yellow : -210° → -255° ( 45°)
    //   Green  : -255° → -330° ( 75°) [= ends at 30°]

    p.color = _blue;
    canvas.drawArc(rect, -30 * d, -100 * d, false, p);

    p.color = _red;
    canvas.drawArc(rect, -130 * d, -80 * d, false, p);

    p.color = _yellow;
    canvas.drawArc(rect, -210 * d, -45 * d, false, p);

    p.color = _green;
    canvas.drawArc(rect, -255 * d, -75 * d, false, p);

    // Crossbar: blue horizontal bar from center → right edge, at cy
    final bar = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx + (r + sw / 2) / 2, cy),
        width: r + sw / 2,
        height: sw,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
