import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/resident_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isResident;
  final String? residentStatus;

  const HomeScreen({super.key, required this.user, required this.isResident, this.residentStatus});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isResident && widget.residentStatus == 'pending') {
        _showPendingDialog();
      }
    });
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Registration Pending',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your resident registration is currently being reviewed by the community management.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('GOT IT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. Enhanced Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF), Color(0xFFF0F7FF)],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: _buildBlurCircle(450, AppTheme.primaryBlue.withOpacity(0.15)),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _buildBlurCircle(600, const Color(0xFF4CAF50).withOpacity(0.08)),
          ),
          Positioned(
            top: 250,
            left: -50,
            child: _buildBlurCircle(300, const Color(0xFFE91E63).withOpacity(0.05)),
          ),

          // 2. Main Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Refined Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Hero(
                          tag: 'logo',
                          child: Image.asset('assets/images/logo_general.png', width: 130, height: 45, fit: BoxFit.contain),
                        ),
                        Row(
                          children: [
                            _buildCircleIcon(Icons.search_rounded),
                            const SizedBox(width: 12),
                            _buildCircleIcon(Icons.notifications_none_rounded, hasBadge: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Premium Welcome Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting().toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    widget.user['full_name'] ?? 'Guest',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.black,
                                      letterSpacing: -1,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person_rounded, size: 32, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid Section Title with Accent
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          'Service Modules',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '3 ACTIVE',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Modules Grid (Redesigned with Premium Glassmorphism)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildModuleCard(
                      'Resident',
                      widget.residentStatus == 'pending' ? Icons.hourglass_top_rounded : Icons.home_work_rounded,
                      widget.residentStatus == 'pending' ? Colors.orange : AppTheme.primaryBlue,
                      () {
                        if (widget.residentStatus == 'pending') {
                          _showPendingDialog();
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResidentRegistrationScreen(user: widget.user),
                          ),
                        );
                      },
                      subtitle: widget.residentStatus == 'pending' ? 'Pending Approval' : 'Manage Household',
                      isMain: true,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                    children: [
                      _buildModuleCard(
                        'Visitor',
                        Icons.people_alt_rounded,
                        const Color(0xFF4CAF50),
                        () {},
                      ),
                      _buildModuleCard(
                        'Parking',
                        Icons.local_parking_rounded,
                        const Color(0xFF1565C0),
                        () {},
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: AppTheme.black.withOpacity(0.8)),
        ),
        if (hasBadge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModuleCard(String title, IconData icon, Color color, VoidCallback onTap, {String? subtitle, bool isMain = false}) {
    return Container(
      height: isMain ? 150 : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.all(isMain ? 24 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.4),
                    ],
                  ),
                ),
                child: isMain ? _buildMainCardContent(title, icon, color, subtitle) : _buildGridCardContent(title, icon, color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCardContent(String title, IconData icon, Color color, String? subtitle) {
    return Row(
      children: [
        _buildIconBox(icon, color, 64, 32),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.black,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildGridCardContent(String title, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconBox(icon, color, 54, 26),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.black,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildIconBox(IconData icon, Color color, double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }

}
