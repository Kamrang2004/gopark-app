import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth/hub_registration_screen.dart';
import 'auth/login_screen.dart';
import 'resident/resident_hub_screen.dart';
import 'admin/community_admin_dashboard.dart';
import 'admin/hub_admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isResident;
  final String? residentStatus;
  final Map<String, dynamic>? communityAdmin;
  final Map<String, dynamic>? hubAdmin;
  final Map<String, dynamic>? parkingAdmin;

  const HomeScreen({
    super.key,
    required this.user,
    required this.isResident,
    this.residentStatus,
    this.communityAdmin,
    this.hubAdmin,
    this.parkingAdmin,
  });

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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                  color: const Color(0xFF0D1117),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your resident registration is currently being reviewed by the community management.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotRegisteredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Not Registered',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0D1117)),
            ),
            const SizedBox(height: 12),
            Text(
              'Please contact your Community Management to provide your residency details. No manual registration is required.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Got it', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.rocket_launch_rounded, color: AppTheme.primaryBlue, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Coming Soon',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0D1117)),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is currently under development. Stay tuned for updates!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Got it', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFirstName() {
    final full = widget.user['full_name'] ?? 'Guest';
    final first = full.toString().split(' ').first;
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  Future<void> _launchSupport() async {
    final whatsappUrl = Uri.parse("https://wa.me/60125198267");
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching Support: $e');
    }
  }

  void _showMyCarsPopup() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: ApiService.post('community/residents.php', {
              'action': 'my_status',
              'app_user_id': widget.user['user_id'] ?? widget.user['id'],
              'email': widget.user['email'] ?? '',
            }),
            builder: (context, snapshot) {
              Widget content;

              if (snapshot.connectionState == ConnectionState.waiting) {
                content = const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1A3A5C))),
                );
              } else if (snapshot.hasError || snapshot.data?['status'] == 'error') {
                content = _buildPopupError('Failed to fetch data');
              } else {
                final resident = snapshot.data?['data']['resident'];
                final List plates = resident != null ? (resident['plates'] ?? []) : [];
                
                if (plates.isEmpty) {
                  content = _buildPopupError('No vehicles registered');
                } else {
                  content = Column(
                    children: plates.map((p) => _buildPlateItem(p.toString())).toList(),
                  );
                }
              }

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car_rounded, color: Color(0xFF0EA5E9), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My Vehicles',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Whitelisted plates registered to your account.',
                      style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    content,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPopupError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey.shade300, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateItem(String plate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_rounded, color: Color(0xFF38BDF8), size: 16),
          const SizedBox(width: 12),
          Text(
            plate,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ACTIVE',
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4ADE80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildHeroCard()),
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: _buildSectionTitle('Services')),
            SliverToBoxAdapter(child: _buildServicesGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/logo_transparent.png',
              height: 42,
              fit: BoxFit.contain,
            ),
            Row(
              children: [
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.logout_rounded, size: 22, color: Color(0xFF0D1117)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94040),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero greeting card ────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    final isPending = widget.residentStatus == 'pending';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF2B6CB0)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A3A5C).withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFirstName(),
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPending
                                ? Colors.orange
                                : widget.isResident
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white60,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPending
                              ? 'Pending Approval'
                              : (widget.communityAdmin != null || widget.hubAdmin != null || widget.parkingAdmin != null)
                                  ? [
                                      if (widget.communityAdmin != null) 'Community',
                                      if (widget.hubAdmin != null) 'Hub',
                                      if (widget.parkingAdmin != null) 'Parking'
                                    ].join(' & ') + ' Admin'
                                  : widget.isResident
                                      ? 'Verified Resident'
                                      : 'Registered User',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  // ── Quick actions row ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          _buildQuickAction(
            Icons.directions_car_rounded, 
            'My Car', 
            const Color(0xFF0EA5E9),
            onTap: _showMyCarsPopup,
          ),
          const SizedBox(width: 12),
          _buildQuickAction(
            Icons.support_agent_rounded, 
            'Support', 
            const Color(0xFFF59E0B),
            onTap: _launchSupport,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0D1117),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // ── Services grid ─────────────────────────────────────────────────────────────

  Widget _buildServicesGrid() {
    final isPending = widget.residentStatus == 'pending';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // ── Admin Section (If applicable) ──
          if (widget.communityAdmin != null || widget.hubAdmin != null || widget.parkingAdmin != null) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MANAGEMENT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.communityAdmin != null) ...[
              _AdminToolCard(
                title: 'Community Admin',
                subtitle: 'Approvals · Entry logs · Access control',
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityAdminDashboard(adminData: widget.communityAdmin!))),
              ),
              if (widget.hubAdmin != null) const SizedBox(height: 12),
            ],
            if (widget.hubAdmin != null)
              _AdminToolCard(
                title: 'Hub Admin',
                subtitle: 'Employees · Visitors · Security logs',
                icon: Icons.business_center_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HubAdminDashboard(adminData: widget.hubAdmin!))),
              ),
            if ((widget.communityAdmin != null || widget.hubAdmin != null) && widget.parkingAdmin != null) const SizedBox(height: 12),
            if (widget.parkingAdmin != null)
              _AdminToolCard(
                title: 'Parking Admin',
                subtitle: 'Site details · GPS · Hourly rates',
                icon: Icons.local_parking_rounded,
                onTap: _showComingSoonDialog,
              ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SERVICES',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Resident — full width
          _ServiceCard(
            title: 'Resident',
            subtitle: isPending ? 'Pending Approval' : (widget.isResident ? 'Verified Access' : 'Register Residence'),
            icon: isPending ? Icons.hourglass_top_rounded : Icons.home_work_rounded,
            color: isPending ? const Color(0xFFF59E0B) : AppTheme.primaryBlue,
            isWide: true,
            onTap: () {
              if (isPending) {
                _showPendingDialog();
                return;
              }
              
              if (widget.isResident || widget.communityAdmin != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResidentHubScreen(user: widget.user)),
                );
              } else {
                _showNotRegisteredDialog();
              }
            },
          ),
          const SizedBox(height: 14),
          // Parking — full width
          _ServiceCard(
            title: 'Parking',
            subtitle: 'Book a slot',
            icon: Icons.local_parking_rounded,
            color: const Color(0xFF3B82F6),
            isWide: true,
            onTap: _showComingSoonDialog,
          ),
          const SizedBox(height: 14),
          _ServiceCard(
            title: 'Workplace Hub',
            subtitle: 'Register for industrial access',
            icon: Icons.layers_rounded,
            color: const Color(0xFF8B5CF6),
            isWide: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HubRegistrationScreen(user: widget.user)),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification bell
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// Admin tool card — elevated dark surface for power-user actions
// ─────────────────────────────────────────────────────────────────────────────

class _AdminToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            // Right side: badge + arrow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service card
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isWide;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isWide ? 108 : 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: isWide ? _wideLayout() : _squareLayout(),
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1117),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _squareLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D1117),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
