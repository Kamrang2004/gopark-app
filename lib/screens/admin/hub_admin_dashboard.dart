import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:intl/intl.dart';
import 'whitelist_management_screen.dart';
import 'gate_control_screen.dart';
import 'hub_employee_directory_screen.dart';
import 'hub_entry_logs_screen.dart';

class HubAdminDashboard extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const HubAdminDashboard({super.key, required this.adminData});

  @override
  State<HubAdminDashboard> createState() => _HubAdminDashboardState();
}

class _HubAdminDashboardState extends State<HubAdminDashboard> {
  late Map<String, dynamic> _adminData;
  bool _isRefreshing = false;
  int _employeeCount = 0;
  int _visitorCount = 0;
  List<dynamic> _recentLogs = [];
  bool _isLoadingLogs = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminData = Map<String, dynamic>.from(widget.adminData);
    _fetchDashboardData();
  }

  bool _hasPerm(String key) {
    var val = _adminData[key];
    if (val == null) return false;
    String s = val.toString();
    return s == '1' || s.toLowerCase() == 'true';
  }

  Future<void> _fetchDashboardData() async {
    _fetchMetrics();
    _fetchRecentLogs();
  }

  Future<void> _refreshAll() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    
    try {
      await Future.wait([
        _fetchMetrics(),
        _fetchRecentLogs(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard refreshed'),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _fetchMetrics() async {
    final res = await ApiService.post('hub/get_hub_metrics.php', {
      'hub_id': _adminData['hub_id'],
    });

    if (res['status'] == 'success') {
      if (mounted) {
        setState(() {
          _employeeCount = res['data']['employees_count'] ?? 0;
          _visitorCount = res['data']['visitors_count'] ?? 0;
        });
      }
    }
  }

  Future<void> _fetchRecentLogs() async {
    try {
      final res = await ApiService.post('hub/get_hub_logs.php', {
        'hub_id': _adminData['hub_id'],
        'user_id': _adminData['user_id'] ?? 0,
      });

      if (res['status'] == 'success') {
        if (mounted) {
          setState(() {
            final allLogs = res['data']['logs'] ?? [];
            _recentLogs = allLogs.take(3).toList();
            _isLoadingLogs = false;
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = res['message'];
            _isLoadingLogs = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection failed';
          _isLoadingLogs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E293B),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: const Color(0xFF1E293B),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('RECENT ACTIVITY'),
                        const SizedBox(height: 16),
                        _buildActivityPreview(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('WORKSPACE CONTROLS'),
                        const SizedBox(height: 16),
                        _buildToolsGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HUB ADMIN',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Workspace Portal',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(_employeeCount.toString(), 'Employees', const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        _buildStatItem(_visitorCount.toString(), 'Visitors', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(val, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildActivityPreview() {
    if (_isLoadingLogs) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF1E293B))),
      );
    }

    if (_error != null && _recentLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 32),
            const SizedBox(height: 12),
            Text('Could not load logs', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () {
                setState(() => _isLoadingLogs = true);
                _fetchRecentLogs();
              },
              child: const Text('Retry Now'),
            )
          ],
        ),
      );
    }

    if (_recentLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hub activity recorded',
              style: GoogleFonts.outfit(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(_recentLogs.length, (index) {
          final log = _recentLogs[index];
          final isEntry = log['direction'].toString().toLowerCase() == 'entry';
          final time = DateFormat('h:mm a').format(DateTime.parse(log['log_time']));
          
          return Column(
            children: [
              _buildLogPreviewItem(
                log['plate_number'], 
                isEntry ? 'Entry' : 'Exit', 
                time,
                type: log['vehicle_type'] ?? 'Guest',
              ),
              if (index < _recentLogs.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogPreviewItem(String plate, String action, String time, {String type = 'Guest'}) {
    final bool isEntry = action == 'Entry';
    Color typeColor = type == 'Employee' ? const Color(0xFF6366F1) : Colors.green;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isEntry ? Colors.green : Colors.orange),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plate, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(type.toUpperCase(), style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: typeColor, letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(time, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          Text(action, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: isEntry ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        if (_hasPerm('hub_employees'))
          _buildToolCard('Employees', 'Staff Roster', Icons.badge_rounded, const Color(0xFF6366F1), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => HubEmployeeDirectoryScreen(adminData: _adminData)));
          }),
        if (_hasPerm('hub_gate'))
          _buildToolCard('Barrier Control', 'Manual Access', Icons.settings_power_rounded, const Color(0xFFF59E0B), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => GateControlScreen(adminData: _adminData)));
          }),
        _buildToolCard('ALPR Whitelist', 'Auto Entry', Icons.directions_car_rounded, const Color(0xFF8B5CF6), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => WhitelistManagementScreen(adminData: _adminData, moduleType: 'hub')));
        }),
        if (_hasPerm('hub_logs'))
          _buildToolCard('Entry Logs', 'History', Icons.analytics_rounded, const Color(0xFF64748B), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => HubEntryLogsScreen(adminData: _adminData)));
          }),
      ],
    );
  }

  Widget _buildToolCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            Text(sub, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
