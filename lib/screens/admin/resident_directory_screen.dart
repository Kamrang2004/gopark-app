import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ResidentDirectoryScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const ResidentDirectoryScreen({super.key, required this.adminData});

  @override
  State<ResidentDirectoryScreen> createState() => _ResidentDirectoryScreenState();
}

class _ResidentDirectoryScreenState extends State<ResidentDirectoryScreen> {
  final List<TextEditingController> _plateControllers = [TextEditingController()];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  
  List<dynamic> _residents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResidents();
  }

  @override
  void dispose() {
    for (var c in _plateControllers) {
      c.dispose();
    }
    _emailController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _addPlateField() {
    setState(() {
      _plateControllers.add(TextEditingController());
    });
  }

  void _removePlateField(int index) {
    if (_plateControllers.length > 1) {
      final plateNumber = _plateControllers[index].text.trim();
      
      // If the plate field is not empty, ask for confirmation
      if (plateNumber.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Remove Plate?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            content: Text('Are you sure you want to remove the plate "$plateNumber" from this form?', 
                           style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _plateControllers[index].dispose();
                    _plateControllers.removeAt(index);
                  });
                },
                child: Text('Remove', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _plateControllers[index].dispose();
        _plateControllers.removeAt(index);
      });
    }
  }

  Future<void> _addResident() async {
    final List<String> plates = _plateControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final email = _emailController.text.trim();
    final unit = _unitController.text.trim();

    if (plates.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one plate and email are required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post('community/manage_whitelist.php', {
        'community_id': widget.adminData['community_id'],
        'action': 'add',
        'resident_email': email,
        'unit_number': unit,
        'plate_numbers': plates,
      });

      if (res['status'] == 'success') {
        if (!mounted) return;
        _emailController.clear();
        _unitController.clear();
        for (var controller in _plateControllers) {
          controller.clear();
        }
        if (_plateControllers.length > 1) {
          setState(() {
            for (int i = 1; i < _plateControllers.length; i++) {
              _plateControllers[i].dispose();
            }
            _plateControllers.removeRange(1, _plateControllers.length);
          });
        }
        _fetchResidents();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident added successfully'), backgroundColor: Colors.green));
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

  Future<void> _fetchResidents() async {
    try {
      final res = await ApiService.post('community/residents.php', {
        'community_id': widget.adminData['community_id'],
        'action': 'list',
      });

      if (res['status'] == 'success') {
        setState(() {
          _residents = res['data']['residents'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResident(int residentId) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('community/residents.php', {
        'community_id': widget.adminData['community_id'],
        'action': 'delete',
        'resident_id': residentId,
      });

      if (res['status'] == 'success') {
        _fetchResidents();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident removed successfully'), backgroundColor: Colors.green));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to delete'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server error'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }
  
  void _showEditPlatesDialog(dynamic resident) {
    List<String> curPlates = (resident['plates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    if (curPlates.isEmpty) curPlates = [''];
    
    final List<TextEditingController> controllers = curPlates.map((p) => TextEditingController(text: p)).toList();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Manage Plates', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Resident Information (Locked)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(resident['full_name'] ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                            Text('${resident['app_email'] ?? 'No email'} • Unit ${resident['unit_number'] ?? '—'}', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 32),
                Text('VEHICLE PLATES', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1)),
                const SizedBox(height: 16),
                ...List.generate(controllers.length, (idx) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTextField(
                    controller: controllers[idx],
                    label: idx == 0 ? 'Primary Plate' : 'Additional Plate',
                    icon: Icons.directions_car_rounded,
                    hint: 'ABC 1234',
                    textCapitalization: TextCapitalization.characters,
                    trailing: InkWell(
                        onTap: () {
                          final plateNum = controllers[idx].text.trim();
                          if (plateNum.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text('Remove Plate?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                                content: Text('Remove "$plateNum" from this resident?', 
                                               style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('No', style: GoogleFonts.outfit(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (controllers.length > 1) {
                                        setModalState(() => controllers.removeAt(idx).dispose());
                                      } else {
                                        controllers[0].clear();
                                      }
                                    },
                                    child: Text('Yes, Remove', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            if (controllers.length > 1) {
                              setModalState(() => controllers.removeAt(idx).dispose());
                            } else {
                              controllers[0].clear();
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.remove_circle_rounded, color: Colors.redAccent, size: 20),
                        ),
                      ),
                  ),
                )),
                TextButton.icon(
                  onPressed: () => setModalState(() => controllers.add(TextEditingController())),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: Text('Add another plate', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      final plates = controllers.map((c) => c.text.trim().toUpperCase()).where((p) => p.isNotEmpty).toList();
                      setModalState(() => isSaving = true);
                      try {
                        final res = await ApiService.post('community/manage_whitelist.php', {
                          'community_id': widget.adminData['community_id'],
                          'action': 'update_resident_plates',
                          'app_user_id': resident['app_user_id'],
                          'plate_numbers': plates,
                        });
                        
                        if (res['status'] == 'success') {
                          _fetchResidents();
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plates updated successfully'), backgroundColor: Colors.green));
                        } else {
                          setModalState(() => isSaving = false);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Update failed'), backgroundColor: Colors.red));
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: _isLoading && _residents.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAddResidentForm(),
                            if (_residents.isEmpty && !_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text('No residents registered yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                                  ],
                                ),
                              )
                            else
                              _buildResidentList(),
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
                'COMMUNITY ADMIN',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF38BDF8),
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Resident Directory',
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

  Widget _buildResidentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _residents.length,
      itemBuilder: (context, index) {
        final resident = _residents[index];
        final List<dynamic> plates = resident['plates'] ?? [];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _showEditPlatesDialog(resident),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          Text(
                            resident['full_name'] ?? 'Unknown',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.home_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text('Unit ${resident['unit_number'] ?? '—'}', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: [
                              Icon(Icons.directions_car_rounded, size: 13, color: plates.isEmpty ? Colors.grey : AppTheme.primaryBlue),
                              Text(
                                plates.isEmpty ? 'No plates registered' : '${plates.length} Plate${plates.length > 1 ? "s" : ""} registered',
                                style: GoogleFonts.outfit(
                                  color: plates.isEmpty ? Colors.grey : AppTheme.primaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (resident['role'] ?? 'resident').toUpperCase(),
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue, letterSpacing: 0.5),
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
                                   'Are you sure you want to remove ${resident['full_name']} and all associated vehicle plates?',
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
                                      _deleteResident(int.parse(resident['id'].toString()));
                                    },
                                    child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddResidentForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADD NEW RESIDENT',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Resident Email',
            icon: Icons.alternate_email_rounded,
            hint: 'e.g. resident@email.com',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _unitController,
            label: 'Unit Info',
            icon: Icons.home_rounded,
            hint: 'e.g. Unit 77',
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),
          Text(
            'VEHICLE PLATES',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_plateControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTextField(
                controller: _plateControllers[index],
                label: index == 0 ? 'Primary Plate' : 'Additional Plate',
                icon: Icons.directions_car_rounded,
                hint: 'e.g. ABC 1234',
                textCapitalization: TextCapitalization.characters,
                trailing: InkWell(
                    onTap: () => _removePlateField(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove_circle_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addPlateField,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text('Add another plate', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _addResident,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                '+ Add Resident',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: controller,
                  textCapitalization: textCapitalization,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                    prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ],
    );
  }
}
