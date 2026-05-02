import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/screens/home_screen.dart';

class PhoneConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> loginData;

  const PhoneConfirmationScreen({
    super.key,
    required this.user,
    required this.loginData,
  });

  @override
  State<PhoneConfirmationScreen> createState() => _PhoneConfirmationScreenState();
}

class _PhoneConfirmationScreenState extends State<PhoneConfirmationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = "Please enter your phone number");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.post('update_phone.php', {
        'user_id': widget.user['user_id'],
        'phone': phone,
      });

      if (res['status'] == 'success') {
        // Update user object locally before proceeding
        final updatedUser = Map<String, dynamic>.from(widget.user);
        updatedUser['phone'] = phone;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              user: updatedUser,
              isResident: widget.loginData['is_resident'] ?? false,
              residentStatus: widget.loginData['resident_profile']?['status'],
              communityAdmin: widget.loginData['community_admin'],
              hubAdmin: widget.loginData['hub_admin'],
            ),
          ),
        );
      } else {
        setState(() => _error = res['message']);
      }
    } catch (e) {
      setState(() => _error = "Connection failed. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone_iphone_rounded, color: AppTheme.primaryBlue, size: 32),
              ),
              const SizedBox(height: 32),
              Text(
                'Verify your identity',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please provide your phone number to complete your registration and secure your account.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'PHONE NUMBER',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '+60 12-345 6789',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFFCBD5E1)),
                  prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 48), // Use fixed spacing instead of Spacer
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPhone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Complete Profile',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel and Logout',
                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
