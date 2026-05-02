import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gopark_app/core/api_service.dart';

class WhitelistManagementScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  final String moduleType; // 'community', 'parking', 'hub'

  const WhitelistManagementScreen({
    super.key, 
    required this.adminData,
    this.moduleType = 'community',
  });

  @override
  State<WhitelistManagementScreen> createState() => _WhitelistManagementScreenState();
}

class _WhitelistManagementScreenState extends State<WhitelistManagementScreen> {
  List<dynamic> _whitelist = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWhitelist();
  }

  Future<void> _fetchWhitelist() async {
    try {
      final Map<String, dynamic> payload = {
        'action': 'get',
        'module_type': widget.moduleType,
      };
      if (widget.moduleType == 'hub') {
        payload['hub_id'] = widget.adminData['hub_id'];
      } else {
        payload['community_id'] = widget.adminData['community_id'];
      }

      final res = await ApiService.post('community/manage_whitelist.php', payload);

      if (res['status'] == 'success') {
        setState(() {
          _whitelist = res['data']['whitelist'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed';
        _isLoading = false;
      });
    }
  }

  // Add logic removed - moved to Residents tab

  Future<void> _removePlate(int id) async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> payload = {
        'action': 'delete',
        'whitelist_id': id,
        'module_type': widget.moduleType,
      };
      if (widget.moduleType == 'hub') {
        payload['hub_id'] = widget.adminData['hub_id'];
      } else {
        payload['community_id'] = widget.adminData['community_id'];
      }

      final res = await ApiService.post('community/manage_whitelist.php', payload);

      if (res['status'] == 'success') {
        _fetchWhitelist();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String moduleTitle = widget.moduleType[0].toUpperCase() + widget.moduleType.substring(1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: _isLoading && _whitelist.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  _buildHeader(moduleTitle),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('ACTIVE WHITELISTED PLATES'),
                          const SizedBox(height: 16),
                          if (_error != null)
                            Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          else
                            _buildWhitelistList(),
                        ],
                      ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title ADMIN',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF38BDF8),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Whitelisted Plates',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildWhitelistList() {
    if (_whitelist.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(Icons.no_photography_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Whitelisted Plates is empty', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _whitelist.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _whitelist[index];
        return _buildPlateItem(item);
      },
    );
  }

  Widget _buildPlateItem(dynamic item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Text(
              item['plate_number'] ?? '---',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['resident_name'] ?? 'Unknown Resident',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (widget.moduleType != 'hub')
                  Row(
                    children: [
                      const Icon(Icons.home_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Unit: ${item['unit_number'] ?? '---'}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    'Confirm Delete',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  content: Text(
                    'Are you sure you want to remove plate ${item['plate_number']} from the whitelist?',
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _removePlate(int.parse(item['whitelist_id'].toString()));
                      },
                      child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
