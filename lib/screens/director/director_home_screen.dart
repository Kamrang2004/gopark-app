import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';

class DirectorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DirectorHomeScreen({super.key, required this.user});

  @override
  State<DirectorHomeScreen> createState() => _DirectorHomeScreenState();
}

class _DirectorHomeScreenState extends State<DirectorHomeScreen> {
  bool _loading = true;
  Map<String, int> _stats = {
    'communities':       0,
    'parking_sites':     0,
    'households':        0,
    'active_vehicles':   0,
    'pending_approvals': 0,
    'total_users':       0,
  };
  List<dynamic> _pendingList = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.post('director_stats.php', {
        'email': widget.user['email'] ?? '',
      });
      if (res['status'] == 'success') {
        final s = res['data']['stats'] as Map<String, dynamic>;
        setState(() {
          _stats = s.map((k, v) => MapEntry(k, (v as num).toInt()));
          _pendingList = res['data']['pending_list'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFirstName() {
    final full = widget.user['full_name'] ?? 'Director';
    final first = full.toString().split(' ').first;
    if (first.isEmpty) return first;
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: RefreshIndicator(
          onRefresh: _fetchStats,
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildTopBar()),
              SliverToBoxAdapter(child: _buildHeroCard()),
              SliverToBoxAdapter(child: _buildSectionLabel('System Overview')),
              SliverToBoxAdapter(child: _buildStatsGrid()),
              if (_stats['pending_approvals']! > 0) ...[
                SliverToBoxAdapter(child: _buildSectionLabel('Pending Approvals')),
                SliverToBoxAdapter(child: _buildPendingList()),
              ],
              SliverToBoxAdapter(child: _buildSectionLabel('Management')),
              SliverToBoxAdapter(child: _buildManagementGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
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
              height: 38,
              fit: BoxFit.contain,
            ),
            Row(
              children: [
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                  ),
                const SizedBox(width: 12),
                _iconBtn(Icons.notifications_none_rounded),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: _iconBtn(Icons.logout_rounded),
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
          'Are you sure you want to log out of GoPark?',
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

  Widget _iconBtn(IconData icon) {
    return Container(
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
      child: Icon(icon, size: 22, color: const Color(0xFF0D1117)),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF1A3A5C)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1117).withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Director badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 13, color: AppTheme.primaryBlue),
                        const SizedBox(width: 5),
                        Text(
                          'DIRECTOR',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFirstName(),
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Summary pills row
                  Row(
                    children: [
                      _heroPill(
                        '${_stats['communities']} Sites',
                        Icons.location_city_rounded,
                      ),
                      const SizedBox(width: 10),
                      _heroPill(
                        '${_stats['total_users']} Users',
                        Icons.people_rounded,
                      ),
                      if (_stats['pending_approvals']! > 0) ...[
                        const SizedBox(width: 10),
                        _heroPill(
                          '${_stats['pending_approvals']} Pending',
                          Icons.timer_rounded,
                          highlight: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPill(String label, IconData icon, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: highlight
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13,
              color: highlight ? const Color(0xFFF59E0B) : Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: highlight ? const Color(0xFFF59E0B) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0D1117),
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    final items = [
      _StatItem('Communities',     '${_stats['communities']}',     Icons.location_city_rounded,   const Color(0xFF4793C4), 'Residential sites'),
      _StatItem('Hub Sites',       '${_stats['hub_sites'] ?? 0}',  Icons.layers_rounded,           const Color(0xFF8B5CF6), 'Industrial access'),
      _StatItem('Parking Sites',   '${_stats['parking_sites']}',   Icons.local_parking_rounded,   const Color(0xFF7C3AED), 'Commercial sites'),
      _StatItem('Households',      '${_stats['households']}',      Icons.home_work_rounded,        const Color(0xFF10B981), 'Registered units'),
      _StatItem('Active Vehicles', '${_stats['active_vehicles']}', Icons.directions_car_rounded,   const Color(0xFF0EA5E9), 'Passing LPR gates'),
      _StatItem('Total Users',     '${_stats['total_users']}',     Icons.people_alt_rounded,       const Color(0xFFEC4899), 'App users'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.35,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: items.map((item) => _buildStatCard(item)).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: item.color),
              ),
              Text(
                item.value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D1117),
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending approvals list ────────────────────────────────────────────────────

  Widget _buildPendingList() {
    if (_pendingList.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            ..._pendingList.asMap().entries.map((e) {
              final item = e.value as Map<String, dynamic>;
              final isLast = e.key == _pendingList.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 20, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['full_name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D1117),
                                ),
                              ),
                              Text(
                                '${item['community_name'] ?? ''} · Unit ${item['unit_number'] ?? '—'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Pending',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: Colors.grey.shade100, indent: 18, endIndent: 18),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Management grid ───────────────────────────────────────────────────────────

  Widget _buildManagementGrid() {
    final items = [
      _MgmtItem('Communities',      Icons.location_city_rounded,    const Color(0xFF4793C4)),
      _MgmtItem('Hubs',             Icons.layers_rounded,           const Color(0xFF8B5CF6)),
      _MgmtItem('Parking Sites',    Icons.local_parking_rounded,    const Color(0xFF7C3AED)),
      _MgmtItem('Machines',         Icons.devices_rounded,          const Color(0xFF0EA5E9)),
      _MgmtItem('Approvals',        Icons.check_circle_outline_rounded, const Color(0xFF10B981),
          badge: _stats['pending_approvals']! > 0 ? '${_stats['pending_approvals']}' : null),
      _MgmtItem('GoPark Admins',    Icons.admin_panel_settings_rounded, const Color(0xFFEC4899)),
      _MgmtItem('Hub Admins',       Icons.landscape_rounded,         const Color(0xFF8B5CF6)),
      _MgmtItem('Community Admins', Icons.manage_accounts_rounded,  const Color(0xFFF59E0B)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: items.map((item) => _buildMgmtCard(item)).toList(),
      ),
    );
  }

  Widget _buildMgmtCard(_MgmtItem item) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, size: 20, color: item.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D1117),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (item.badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatItem(this.label, this.value, this.icon, this.color, this.subtitle);
}

class _MgmtItem {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;

  const _MgmtItem(this.label, this.icon, this.color, {this.badge});
}
