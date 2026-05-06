import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gopark_app/core/constants.dart';
import 'dart:convert';
import '../home_screen.dart';

class ResidentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ResidentRegistrationScreen({super.key, required this.user});

  @override
  State<ResidentRegistrationScreen> createState() => _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState extends State<ResidentRegistrationScreen> {
  final TextEditingController unitController     = TextEditingController();
  late final TextEditingController contactController;
  final TextEditingController nameController     = TextEditingController();
  final TextEditingController icController       = TextEditingController();
  final List<TextEditingController> plateControllers = [TextEditingController()];

  bool isLoading    = false;
  bool isExtracting = false;
  bool isLocating   = false;

  int?    communityId;
  String? communityName;
  String? icPhotoUrl;
  String? icFileName; // NEW: To show PDF/File name in preview

  // ── Location ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    contactController = TextEditingController(text: widget.user['phone']?.toString() ?? '');
  }

  Future<void> _detectLocation() async {
    setState(() => isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }

      Position position = await Geolocator.getCurrentPosition();
      final response = await ApiService.get(
          'community/get_communities.php?lat=${position.latitude}&lng=${position.longitude}');

      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          communityId   = response['data']['community']['id'];
          communityName = response['data']['community']['name'];
        });
      } else {
        throw response['message'] ?? 'Failed to detect community';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => isLocating = false);
    }
  }

  // ── Plates ──────────────────────────────────────────────────────────────────

  // ── Plates ──────────────────────────────────────────────────────────────────

  void _addPlateField() =>
      setState(() => plateControllers.add(TextEditingController()));

  void _removePlateField(int index) {
    if (plateControllers.length > 1) {
      setState(() {
        plateControllers[index].dispose();
        plateControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    unitController.dispose();
    contactController.dispose();
    nameController.dispose();
    icController.dispose();
    for (var c in plateControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  void _handleResidentRegister() async {
    List<String> plates = plateControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (unitController.text.isEmpty ||
        contactController.text.isEmpty ||
        plates.isEmpty ||
        communityId == null ||
        nameController.text.isEmpty ||
        icController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please complete all fields and add at least one vehicle')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await ApiService.post('community/register.php', {
        'app_user_id':    widget.user['id'],
        'community_id':   communityId,
        'unit_number':    unitController.text,
        'full_name':      nameController.text,
        'ic_number':      icController.text,
        'ic_photo_url':   icPhotoUrl,
        'contact_number': contactController.text,
        'license_plates': plates,
      });

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Successfully registered!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                user: widget.user,
                isResident: true,
                residentStatus: 'pending',
              ),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeadline(),
                      const SizedBox(height: 24),
                      _buildLocationCard(),
                      const SizedBox(height: 14),
                      _buildDetailsCard(),
                      const SizedBox(height: 14),
                      _buildVehiclesCard(),
                      const SizedBox(height: 28),
                      _buildSubmitButton(),
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

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF0D1117)),
            ),
          ),
          const Spacer(),
          Text(
            'Resident Setup',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D1117),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  // ── Headline ─────────────────────────────────────────────────────────────────

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join your\ncommunity.',
          style: GoogleFonts.outfit(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0D1117),
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete the steps below to verify your residency.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Step card wrapper ────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStepLabel(String step, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            step,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D1117),
          ),
        ),
      ],
    );
  }

  // ── Card 2: Location ──────────────────────────────────────────────────────────

  // ── Card 2: Location ──────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepLabel('STEP 2', 'Community Location', const Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          if (isLocating)
            _buildLoadingRow('Detecting your location...')
          else if (communityName != null)
            _buildSuccessAction(
              icon: Icons.location_city_rounded,
              color: const Color(0xFFF59E0B),
              title: communityName!,
              subtitle: 'Community detected',
              actionLabel: 'Change',
              onAction: _detectLocation,
            )
          else
            _buildActionButton(
              icon: Icons.my_location_rounded,
              label: 'Detect My Community',
              color: const Color(0xFFF59E0B),
              onTap: _detectLocation,
            ),
        ],
      ),
    );
  }

  // ── Card 3: Unit & contact ────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepLabel('STEP 2', 'Resident Details', const Color(0xFF10B981)),
          const SizedBox(height: 16),
          _buildField(
            label: 'Full Name',
            hint: 'Your Legal Name',
            controller: nameController,
            icon: Icons.person,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'IC Number',
            hint: 'e.g. 900101015555',
            controller: icController,
            icon: Icons.badge,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Unit Number',
            hint: 'e.g., NO 77',
            controller: unitController,
            icon: Icons.home_work_rounded,
            capitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 14),
          _buildField(
            label: 'Contact Number',
            hint: 'e.g., 0123456789',
            controller: contactController,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // ── Card 4: Vehicles ──────────────────────────────────────────────────────────

  Widget _buildVehiclesCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepLabel('STEP 3', 'Vehicles', const Color(0xFF8B5CF6)),
          const SizedBox(height: 16),
          ...plateControllers.asMap().entries.map((entry) {
            final idx  = entry.key;
            final ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Plate ${idx + 1}',
                      hint: 'e.g., ABC 1234',
                      controller: ctrl,
                      icon: Icons.directions_car_rounded,
                      capitalization: TextCapitalization.characters,
                    ),
                  ),
                  if (plateControllers.length > 1) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _removePlateField(idx),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.remove_rounded,
                            color: Colors.red, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          GestureDetector(
            onTap: _addPlateField,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      size: 18, color: const Color(0xFF8B5CF6)),
                  const SizedBox(width: 6),
                  Text(
                    'Add another vehicle',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: isLoading ? null : _handleResidentRegister,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3A5C), Color(0xFF2B6CB0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Submit Registration',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────────

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D1117),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingRow(String message) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(width: 14),
        Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF0)),
          ),
          child: TextField(
            controller: controller,
            textCapitalization: capitalization,
            keyboardType: keyboardType,
            inputFormatters: capitalization == TextCapitalization.characters
                ? [UpperCaseTextFormatter()]
                : null,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1117),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, size: 19, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
