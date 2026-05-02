import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class VisitorManagementScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const VisitorManagementScreen({super.key, required this.adminData});

  @override
  State<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  
  List<dynamic> _visitors = [];
  List<Map<String, dynamic>> _allResidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
    _fetchResidentsForSuggestions();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _hostController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _fetchResidentsForSuggestions() async {
    try {
      final res = await ApiService.post('community/residents.php', {
        'community_id': widget.adminData['community_id'],
        'action': 'list',
      });

      if (res['status'] == 'success') {
        setState(() {
          _allResidents = List<Map<String, dynamic>>.from(res['data']['residents'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching residents for suggestions: $e');
    }
  }

  Future<void> _fetchVisitors() async {
    try {
      final res = await ApiService.get('community/manage_visitors.php?action=list&site_id=${widget.adminData['community_id']}');

      if (res['status'] == 'success') {
        setState(() {
          _visitors = res['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to load visitors'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addVisitor() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plate number is required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post('community/manage_visitors.php?action=add', {
        'site_id': widget.adminData['community_id'],
        'plate_number': plate,
        'visitor_name': _nameController.text.trim(),
        'visitor_phone': _phoneController.text.trim(),
        'host_resident_name': _hostController.text.trim(),
        'unit_number': _unitController.text.trim(),
      });

      if (res['status'] == 'success') {
        _plateController.clear();
        _nameController.clear();
        _phoneController.clear();
        _hostController.clear();
        _unitController.clear();
        _fetchVisitors();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor registered'), backgroundColor: Colors.green));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to add'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server error'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVisitor(int visitorId) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('community/manage_visitors.php?action=delete', {
        'site_id': widget.adminData['community_id'],
        'visitor_id': visitorId,
      });

      if (res['status'] == 'success') {
        _fetchVisitors();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchVisitors,
              color: const Color(0xFF0F172A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildAddVisitorForm(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text(
                            'ACTIVE VISITORS',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_visitors.isEmpty && !_isLoading)
                      _buildEmptyState()
                    else
                      _buildVisitorList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMMUNITY ADMIN',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Visitor Access',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visitors.length,
      itemBuilder: (context, index) {
        final visitor = _visitors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Text(
                  visitor['plate_number'] ?? '---',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor['visitor_name']?.toString().isEmpty ?? true ? 'Guest Visitor' : visitor['visitor_name'],
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visiting: ${visitor['host_resident_name'] ?? '—'} (${visitor['unit_number'] ?? '—'})',
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(visitor),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(dynamic visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Deletion', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Remove access for visitor ${visitor['plate_number']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVisitor(int.parse(visitor['visitor_id'].toString()));
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No active visitors', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAddVisitorForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REGISTER NEW VISITOR',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _plateController,
            label: 'Vehicle Plate',
            icon: Icons.directions_car_outlined,
            hint: 'e.g. BKT 1234',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nameController,
                  label: 'Visitor Name (optional)',
                  icon: Icons.person_outline_rounded,
                  hint: 'Optional',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _unitController,
                  label: 'Unit No.',
                  icon: Icons.home_outlined,
                  hint: 'Required',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Visitor Phone (optional)',
            icon: Icons.phone_android_outlined,
            hint: 'Optional',
          ),
          const SizedBox(height: 16),
          _buildAutocompleteResidentField(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _addVisitor,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Emerald/Green for visitors
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Grand Access',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteResidentField() {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: _hostController,
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return _allResidents.where((Map<String, dynamic> resident) {
          final name = resident['full_name'].toString().toLowerCase();
          final unit = resident['unit_number'].toString().toLowerCase();
          final search = textEditingValue.text.toLowerCase();
          return name.contains(search) || unit.contains(search);
        });
      },
      onSelected: (Map<String, dynamic> resident) {
        setState(() {
          _hostController.text = resident['full_name'] ?? '';
          _unitController.text = resident['unit_number'] ?? '';
        });
      },
      displayStringForOption: (Map<String, dynamic> resident) => resident['full_name'] ?? '',
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return _buildTextField(
          controller: controller,
          focusNode: focusNode,
          label: 'Visiting Resident',
          icon: Icons.people_outline_rounded,
          hint: 'Start typing resident name...',
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width - 64,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final resident = options.elementAt(index);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      resident['full_name'] ?? '',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                    ),
                    subtitle: Text(
                      'Unit ${resident['unit_number'] ?? '—'}',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    onTap: () => onSelected(resident),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: textCapitalization,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
