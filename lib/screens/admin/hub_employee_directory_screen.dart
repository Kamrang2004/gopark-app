import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HubEmployeeDirectoryScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const HubEmployeeDirectoryScreen({super.key, required this.adminData});

  @override
  State<HubEmployeeDirectoryScreen> createState() => _HubEmployeeDirectoryScreenState();
}

class _HubEmployeeDirectoryScreenState extends State<HubEmployeeDirectoryScreen> {
  final List<TextEditingController> _plateControllers = [TextEditingController()];
  final TextEditingController _emailController = TextEditingController();

  List<dynamic> _employees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    for (var c in _plateControllers) c.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addPlateField() => setState(() => _plateControllers.add(TextEditingController()));

  void _removePlateField(int index) {
    if (_plateControllers.length <= 1) return;
    final plate = _plateControllers[index].text.trim();
    if (plate.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Remove Plate?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Text('Remove "$plate" from this form?',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
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

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('hub/manage_employees.php', {
        'hub_id': widget.adminData['hub_id'],
        'action': 'list',
      });
      if (res['status'] == 'success') {
        setState(() {
          _employees = res['data']['employees'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load employees';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addEmployee() async {
    final plates = _plateControllers
        .map((c) => c.text.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .toList();
    final email = _emailController.text.trim();

    if (email.isEmpty || plates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email and at least one plate are required')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('hub/manage_employees.php', {
        'hub_id': widget.adminData['hub_id'],
        'action': 'add',
        'employee_email': email,
        'plate_numbers': plates,
      });

      if (res['status'] == 'success') {
        if (!mounted) return;
        _emailController.clear();
        for (var c in _plateControllers) c.clear();
        if (_plateControllers.length > 1) {
          setState(() {
            for (int i = 1; i < _plateControllers.length; i++) {
              _plateControllers[i].dispose();
            }
            _plateControllers.removeRange(1, _plateControllers.length);
          });
        }
        _fetchEmployees();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee registered successfully'), backgroundColor: Colors.green));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to register'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server error'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEmployee(int empId) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('hub/manage_employees.php', {
        'hub_id': widget.adminData['hub_id'],
        'action': 'delete',
        'hub_employee_id': empId,
      });

      if (res['status'] == 'success') {
        _fetchEmployees();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee removed'), backgroundColor: Colors.green));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showEditPlatesDialog(dynamic employee) {
    List<String> curPlates =
        (employee['plates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    if (curPlates.isEmpty) curPlates = [''];

    final List<TextEditingController> controllers =
        curPlates.map((p) => TextEditingController(text: p)).toList();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32), topRight: Radius.circular(32)),
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
                    Text('Manage Plates',
                        style: GoogleFonts.outfit(
                            fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('EMPLOYEE INFO (LOCKED)',
                    style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employee['full_name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                            Text(employee['app_email'] ?? 'No email',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 32),
                Text('VEHICLE PLATES',
                    style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B), letterSpacing: 1)),
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
                        final p = controllers[idx].text.trim();
                        if (p.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text('Remove Plate?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                              content: Text('Remove "$p" from this employee?',
                                  style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx),
                                    child: Text('No', style: GoogleFonts.outfit(color: Colors.grey))),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    if (controllers.length > 1) {
                                      setModalState(() => controllers.removeAt(idx).dispose());
                                    } else {
                                      controllers[0].clear();
                                    }
                                  },
                                  child: Text('Yes, Remove',
                                      style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
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
                            borderRadius: BorderRadius.circular(12)),
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
                      final plates = controllers
                          .map((c) => c.text.trim().toUpperCase())
                          .where((p) => p.isNotEmpty)
                          .toList();
                      setModalState(() => isSaving = true);
                      try {
                        final res = await ApiService.post('hub/manage_employees.php', {
                          'hub_id': widget.adminData['hub_id'],
                          'action': 'update_plates',
                          'user_id': employee['user_id'],
                          'plate_numbers': plates,
                        });

                        if (res['status'] == 'success') {
                          _fetchEmployees();
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Plates updated'), backgroundColor: Colors.green));
                          }
                        } else {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['message'] ?? 'Update failed'), backgroundColor: Colors.red));
                          }
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connection error'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Save Changes',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
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
                child: _isLoading && _employees.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAddEmployeeForm(),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                                    const SizedBox(height: 16),
                                    Text(_error!, style: TextStyle(color: Colors.red.shade400, fontSize: 14), textAlign: TextAlign.center),
                                  ],
                                ),
                              )
                            else if (_employees.isEmpty && !_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Column(
                                  children: [
                                    Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text('No employees registered yet',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                                  ],
                                ),
                              )
                            else
                              _buildEmployeeList(),
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
              Text('HUB ADMIN',
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8), letterSpacing: 1.5)),
              Text('Employee Directory',
                  style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        final List<dynamic> plates = emp['plates'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _showEditPlatesDialog(emp),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: Text(
                        (emp['full_name'] as String? ?? '?')[0].toUpperCase(),
                        style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp['full_name'] ?? 'Unknown',
                              style: GoogleFonts.outfit(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text(emp['app_email'] ?? '—',
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.directions_car_rounded,
                                  size: 13, color: plates.isEmpty ? Colors.grey : AppTheme.primaryBlue),
                              const SizedBox(width: 4),
                              Text(
                                plates.isEmpty
                                    ? 'No plates registered'
                                    : '${plates.length} Plate${plates.length > 1 ? "s" : ""} registered',
                                style: GoogleFonts.outfit(
                                    color: plates.isEmpty ? Colors.grey : AppTheme.primaryBlue,
                                    fontSize: 11, fontWeight: FontWeight.w600),
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
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Confirm Remove',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                            content: Text(
                                'Remove ${emp['full_name']} and all associated vehicle plates?',
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w600))),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteEmployee(int.parse(emp['hub_employee_id'].toString()));
                                },
                                child: Text('Remove',
                                    style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w700)),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddEmployeeForm() {
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
          Text('REGISTER EMPLOYEE',
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B), letterSpacing: 1)),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Employee Email',
            icon: Icons.alternate_email_rounded,
            hint: 'e.g. employee@company.com',
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),
          Text('VEHICLE PLATES',
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B), letterSpacing: 1)),
          const SizedBox(height: 16),
          ...List.generate(_plateControllers.length, (index) => Padding(
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
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.remove_circle_rounded, color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          )),
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
              onPressed: _addEmployee,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('+ Register Employee',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
        Text(label,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
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
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ],
    );
  }
}
