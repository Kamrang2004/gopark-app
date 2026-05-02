import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/social_auth_service.dart';
import 'package:gopark_app/screens/auth/simple_register_screen.dart';
import 'package:gopark_app/screens/home_screen.dart';
import 'package:gopark_app/screens/director/director_home_screen.dart';
import 'package:gopark_app/screens/auth/phone_confirmation_screen.dart';

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
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
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
      _showError('Please fill all fields');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('login.php', {
        'identifier': _identifierController.text.trim(),
        'password': _passwordController.text,
      });
      if (res['status'] == 'success') {
        _navigateHome(res['data'] ?? {});
      } else {
        _showError(res['message'] ?? 'Login failed');
      }
    } catch (_) {
      _showError('Connection failed. Please check your server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialResponse(Map<String, dynamic>? res) async {
    if (res == null) return;
    if (res['status'] == 'success') {
      _navigateHome(res['data'] ?? {});
    } else {
      _showError(res['message'] ?? 'Social login failed');
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
    final user = data['user'] ?? {};
    final isDirector = data['is_director'] == true;

    // Force phone confirmation for non-director users if missing
    if (!isDirector && (user['phone'] == null || user['phone'].toString().trim().isEmpty)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PhoneConfirmationScreen(
            user: user,
            loginData: data,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isDirector
            ? DirectorHomeScreen(user: user)
            : HomeScreen(
                user: user,
                isResident: data['is_resident'] ?? false,
                residentStatus: data['resident_profile']?['status'],
                communityAdmin: data['community_admin'],
                hubAdmin: data['hub_admin'],
                parkingAdmin: data['parking_admin'],
              ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFD94040),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: Stack(
        children: [
          // ── Subtle brand accent blob — top right ──
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.13),
                    AppTheme.primaryBlue.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                      // ── Greeting ──
                      const Text(
                        'Welcome back.',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A),
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your GoPark account.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Social sign-in (primary path) ──
                      _SocialButton(
                        onPressed: _isLoading ? null : _googleSignIn,
                        icon: SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(painter: _GoogleGPainter()),
                        ),
                        label: 'Continue with Google',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3C4043),
                        borderColor: const Color(0xFFE0E0E0),
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                      ),

                      if (_isAppleAvailable) ...[
                        const SizedBox(height: 12),
                        _SocialButton(
                          onPressed: _isLoading ? null : _appleSignIn,
                          icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                          label: 'Continue with Apple',
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          borderColor: Colors.transparent,
                          shadowColor: Colors.black.withValues(alpha: 0.18),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── OR divider ──
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Email / Phone ──
                      _buildField(
                        controller: _identifierController,
                        hint: 'Email or phone number',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),

                      // ── Password ──
                      _buildField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffix: GestureDetector(
                          onTap: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Forgot password ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Sign in button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isLoading
                            ? Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 32),

                      // ── Sign-up link ──
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SimpleRegisterScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade600),
                              children: [
                                const TextSpan(text: "New to GoPark? "),
                                TextSpan(
                                  text: 'Create an account',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                          ],
                        ),
                      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF0D1B2A),
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: Colors.grey.shade400, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: suffix,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.6), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social sign-in button
// ─────────────────────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color shadowColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
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
          splashColor: foregroundColor.withValues(alpha: 0.06),
          highlightColor: foregroundColor.withValues(alpha: 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4-colour Google "G" logo
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

    p.color = _blue;
    canvas.drawArc(rect, -30 * d, -100 * d, false, p);
    p.color = _red;
    canvas.drawArc(rect, -130 * d, -80 * d, false, p);
    p.color = _yellow;
    canvas.drawArc(rect, -210 * d, -45 * d, false, p);
    p.color = _green;
    canvas.drawArc(rect, -255 * d, -75 * d, false, p);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx + (r + sw / 2) / 2, cy),
        width: r + sw / 2,
        height: sw,
      ),
      Paint()
        ..color = _blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
