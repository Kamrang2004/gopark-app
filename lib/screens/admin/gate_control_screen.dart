import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gopark_app/core/api_service.dart';

class GateControlScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const GateControlScreen({super.key, required this.adminData});

  @override
  State<GateControlScreen> createState() => _GateControlScreenState();
}

class _GateControlScreenState extends State<GateControlScreen> {
  bool _isLoading = true;
  List<dynamic> _gates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGates();
  }

  Future<void> _fetchGates() async {
    try {
      final data = await ApiService.post('community/get_gates.php', {
        'community_id': widget.adminData['community_id'],
        'hub_id': widget.adminData['hub_id'],
        'user_id': widget.adminData['user_id'],
      });

      if (data['status'] == 'success') {
        setState(() {
          _gates = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load gates: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerBarrier(int machineId, String action) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final data = await ApiService.post('community/trigger_barrier.php', {
        'community_id': widget.adminData['community_id'],
        'hub_id': widget.adminData['hub_id'],
        'user_id': widget.adminData['user_id'],
        'machine_id': machineId,
        'action': action,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (data['status'] == 'success') {
        _showStatusSnackBar(data['message'], Colors.green);
      } else {
        _showStatusSnackBar(data['message'], Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showStatusSnackBar("Connection error", Colors.red);
    }
  }

  void _showStatusSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showControlOptions(dynamic gate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              gate['logical_label'] ?? gate['functional_role'] ?? 'Unnamed Gate',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Security Zone: ${widget.adminData['hub_id'] != null ? "HUB #" + widget.adminData['hub_id'].toString() : "COMM #" + widget.adminData['community_id'].toString()}',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'OPEN BARRIER',
                    const Color(0xFF22C55E),
                    Icons.lock_open_rounded,
                    () {
                      Navigator.pop(context);
                      _triggerBarrier(int.parse(gate['machine_id'].toString()), 'OPEN');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    'CLOSE BARRIER',
                    const Color(0xFFEF4444),
                    Icons.lock_rounded,
                    () {
                      Navigator.pop(context);
                      _triggerBarrier(int.parse(gate['machine_id'].toString()), 'CLOSE');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          'Gate Control',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchGates();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_gates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.door_sliding_rounded, color: Colors.grey.shade300, size: 80),
            const SizedBox(height: 16),
            Text('No barriers allocated to this community.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _gates.length,
      itemBuilder: (context, index) {
        final gate = _gates[index];
        return _buildGateCard(gate);
      },
    );
  }

  Widget _buildGateCard(dynamic gate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () => _showControlOptions(gate),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.door_sliding_rounded, color: Color(0xFF0EA5E9), size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          gate['logical_label'] ?? gate['functional_role'] ?? 'Unnamed Gate',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ((gate['functional_role']?.toString().toLowerCase().contains('entry') ?? false) 
                                ? Colors.green 
                                : Colors.orange).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (gate['functional_role']?.toString().toLowerCase().contains('entry') ?? false) ? 'ENTRY' : 'EXIT',
                            style: GoogleFonts.outfit(
                              fontSize: 10, 
                              fontWeight: FontWeight.w800, 
                              color: (gate['functional_role']?.toString().toLowerCase().contains('entry') ?? false) ? Colors.green : Colors.orange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SN: ${gate['machine_sn_mac']}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}
