import 'package:flutter/material.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ResidentApprovalsScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const ResidentApprovalsScreen({super.key, required this.adminData});

  @override
  State<ResidentApprovalsScreen> createState() => _ResidentApprovalsScreenState();
}

class _ResidentApprovalsScreenState extends State<ResidentApprovalsScreen> {
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    try {
      final res = await ApiService.post('community/get_pending_residents.php', {
        'community_id': widget.adminData['community_id'],
        'user_id': widget.adminData['user_id'] ?? 0,
      });

      if (res['status'] == 'success') {
        setState(() {
          _residents = res['data']['residents'] ?? [];
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

  Future<void> _updateStatus(int residentId, String action) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('community/approve_resident.php', {
        'resident_id': residentId,
        'action': action,
        'admin_user_id': widget.adminData['user_id'] ?? 0,
        'community_id': widget.adminData['community_id'],
      });

      if (res['status'] == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resident $action successfully'), backgroundColor: action == 'approved' ? Colors.green : Colors.red),
        );
        _fetchPending();
      } else {
        _showError(res['message']);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Failed to process request');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showImageOverlay(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Resident Approvals', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _residents.isEmpty
                  ? const Center(child: Text('No pending registrations'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _residents.length,
                      itemBuilder: (context, index) {
                        final resident = _residents[index];
                        final icPhoto = resident['ic_photo_url'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                      child: Text(
                                        resident['full_name']?[0] ?? '?',
                                        style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(resident['full_name'] ?? 'Unknown', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
                                          Text('Unit: ${resident['unit_number'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (icPhoto != null && icPhoto.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _showImageOverlay(icPhoto),
                                  child: Container(
                                    height: 120,
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(image: NetworkImage(icPhoto), fit: BoxFit.cover),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(30)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [Icon(Icons.visibility, color: Colors.white, size: 16), SizedBox(width: 4), Text('View ID', style: TextStyle(color: Colors.white, fontSize: 12))],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateStatus(resident['id'], 'rejected'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(resident['id'], 'approved'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
