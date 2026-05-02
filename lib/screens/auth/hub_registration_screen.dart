import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HubRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HubRegistrationScreen({super.key, required this.user});

  @override
  State<HubRegistrationScreen> createState() => _HubRegistrationScreenState();
}

class _HubRegistrationScreenState extends State<HubRegistrationScreen> {
  final TextEditingController plateController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();

  bool isLoading = false;
  bool isFetchingHubs = true;

  int? selectedHubId;
  String? selectedHubName;
  List<dynamic> hubs = [];

  @override
  void initState() {
    super.initState();
    _fetchHubs();
  }

  Future<void> _fetchHubs() async {
    setState(() => isFetchingHubs = true);
    try {
      final res = await ApiService.get('hub/get_my_hubs.php?user_id=${widget.user['id']}');
      if (res['status'] == 'success') {
        setState(() {
          hubs = res['data'] ?? [];
          if (hubs.length == 1) {
            selectedHubId = hubs[0]['hub_id'];
            selectedHubName = hubs[0]['hub_name'];
          }
        });
      }
    } catch (_) {}
    setState(() => isFetchingHubs = false);
  }

  void _handleSubmit() async {
    if (selectedHubId == null || plateController.text.isEmpty || purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a workplace and enter vehicle details')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.post('hub/register_vehicle.php', {
        'user_id': widget.user['id'],
        'hub_id': selectedHubId,
        'hub_plate_number': plateController.text.trim().toUpperCase(),
        'hub_vehicle_model': modelController.text.trim(),
        'hub_purpose': purposeController.text.trim(),
      });

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration submitted for approval!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        throw response['message'] ?? 'Failed to submit';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workplace\nAccess.',
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D1117),
                          letterSpacing: -1.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Register your vehicle to your workplace hub for authorized entry.',
                        style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
                      if (hubs.isEmpty && !isFetchingHubs)
                        _buildEmptyState()
                      else ...[
                        _buildSectionLabel('Step 1: Select Workplace'),
                        _buildHubSelector(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Step 2: Vehicle Details'),
                        _buildField('Plate Number', 'e.g., ABC 1234', plateController, Icons.directions_car_rounded, true),
                        const SizedBox(height: 14),
                        _buildField('Vehicle Model', 'e.g., Proton X50', modelController, Icons.model_training_rounded),
                        const SizedBox(height: 14),
                        _buildField('Purpose/Department', 'e.g., Logistics / IT Dept', purposeController, Icons.work_rounded),
                        const SizedBox(height: 40),
                        _buildSubmitButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.domain_disabled_rounded, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            'No Workplace Assigned',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t been assigned to a Hub site yet. Please contact your manager or GoPark administrator to be added to a workplace.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Go Back', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const Spacer(),
          Text('Hub Setup', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildHubSelector() {
    if (hubs.length <= 1 && selectedHubId != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.business_rounded, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 14),
            Text(
              selectedHubName ?? 'Assigned Workplace',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedHubId,
          hint: Text('Choose your site...', style: GoogleFonts.outfit(color: Colors.grey.shade400)),
          isExpanded: true,
          items: hubs.map((h) {
            return DropdownMenuItem<int>(
              value: h['hub_id'],
              child: Text(h['hub_name'], style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedHubId = val;
              selectedHubName = hubs.firstWhere((h) => h['hub_id'] == val)['hub_name'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, IconData icon, [bool upper = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: TextField(
            controller: ctrl,
            textCapitalization: upper ? TextCapitalization.characters : TextCapitalization.words,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade400),
              prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A5C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text('Submit Registration', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
