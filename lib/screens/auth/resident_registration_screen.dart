import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  final TextEditingController unitController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final List<TextEditingController> plateControllers = [TextEditingController()];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController icController = TextEditingController();
  
  bool isLoading = false;
  bool isExtracting = false;
  bool isLocating = false;
  
  int? communityId;
  String? communityName;
  String? icPhotoUrl;

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
      
      // Call backend to get community based on GPS
      final response = await ApiService.get('community/get_communities.php?lat=${position.latitude}&lng=${position.longitude}');
      
      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          communityId = response['data']['community']['id'];
          communityName = response['data']['community']['name'];
        });
      } else {
        throw response['message'] ?? 'Failed to detect community';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLocating = false);
    }
  }

  Future<void> _pickAndExtractIC() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) return;

    setState(() => isExtracting = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/community/extract_ic.php'));
      request.files.add(await http.MultipartFile.fromPath('ic_photo', image.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var result = json.decode(response.body);

      if (result['status'] == 'success') {
        setState(() {
          nameController.text = result['data']['full_name'];
          icController.text = result['data']['ic_number'];
          icPhotoUrl = result['data']['ic_photo_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IC Details Extracted!'), backgroundColor: Colors.green));
      } else {
        throw result['message'] ?? 'Failed to extract IC';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => isExtracting = false);
    }
  }

  void _addPlateField() {
    setState(() {
      plateControllers.add(TextEditingController());
    });
  }

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
    for (var controller in plateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleResidentRegister() async {
    List<String> plates = plateControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    if (unitController.text.isEmpty || contactController.text.isEmpty || plates.isEmpty || communityId == null || nameController.text.isEmpty || icController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and add at least one vehicle')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // Updated to use the correct register.php in community folder
      final response = await ApiService.post('community/register.php', {
        'app_user_id': widget.user['id'],
        'community_id': communityId,
        'unit_number': unitController.text,
        'full_name': nameController.text,
        'ic_number': icController.text,
        'ic_photo_url': icPhotoUrl,
        'contact_number': contactController.text,
        'license_plates': plates,
      });

      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Successfully registered!'),
              backgroundColor: Colors.green.shade400,
            ),
          );
          
          // Navigate to HomeScreen with updated status
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
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
              content: Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Resident Setup'),
        backgroundColor: AppTheme.white,
        elevation: 0,
        foregroundColor: AppTheme.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete your profile',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join your community to access resident features.',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // IC Extraction Section
              _buildSectionTitle('Primary Resident Identity'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    if (isExtracting)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _pickAndExtractIC,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('SCAN MYKAD / IC'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    if (nameController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildReadOnlyField('Extracted Full Name', nameController),
                      const SizedBox(height: 12),
                      _buildReadOnlyField('Extracted IC Number', icController),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Community/GPS Section
              _buildSectionTitle('Community Location'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    if (isLocating)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _detectLocation,
                        icon: const Icon(Icons.location_on_rounded),
                        label: Text(communityName != null ? 'CHANGE LOCATION' : 'DETECT MY COMMUNITY'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    if (communityName != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                communityName!,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Unit & Contact'),
              const SizedBox(height: 12),
              _buildField('Unit Number (e.g., NO 77)', unitController, Icons.home_work_outlined, capitalization: TextCapitalization.characters),
              const SizedBox(height: 20),
              _buildField('Contact Number', contactController, Icons.phone_outlined),
              const SizedBox(height: 32),

              _buildSectionTitle('Vehicles'),
              const SizedBox(height: 12),
              ...plateControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                TextEditingController ctrl = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildField('Vehicle Plate Number ${idx + 1}', ctrl, Icons.directions_car_outlined, capitalization: TextCapitalization.characters),
                      ),
                      if (plateControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () => _removePlateField(idx),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addPlateField,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('ADD ANOTHER VEHICLE'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleResidentRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'REGISTER AS RESIDENT',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.black),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextCapitalization capitalization = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.black),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: capitalization,
          inputFormatters: capitalization == TextCapitalization.characters
              ? [UpperCaseTextFormatter()]
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
