import 'package:flutter/material.dart';
import 'package:gopark_app/core/theme.dart';
import 'package:gopark_app/core/api_service.dart';
import 'package:gopark_app/core/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _unitController = TextEditingController();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // List of controllers for multiple vehicles
  final List<TextEditingController> _plateControllers = [TextEditingController()];
  
  String _selectedTitle = 'Mr';
  final List<String> _titles = ['Mr', 'Mrs', 'Ms', 'Dr', 'Dato\'', 'Datin', 'Tan Sri', 'Puan Sri'];
  
  bool _isLoading = false;
  
  int? _communityId;
  String? _communityName;
  bool _isFetchingLocation = false;
  
  String? _extractedIcNumber;
  final TextEditingController _icNumberController = TextEditingController();
  bool _isExtracting = false;
  String? _icPhotoUrl;
  String? _extractionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPrompt();
    });
  }

  void _showLocationPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Required', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        content: const Text('To ensure you are registered to the correct Gated Community, please make sure you are physically at your house right now.\n\nWe will use your GPS location to automatically find your community.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back if they refuse
            },
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchCommunityLocation();
            },
            child: const Text('I AM AT HOME', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCommunityLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final response = await ApiService.get('community/get_communities.php?lat=${position.latitude}&lng=${position.longitude}');
      
      if (response['status'] == 'success' && response['data'] != null && response['data']['community'] != null) {
        setState(() {
          _communityId = response['data']['community']['id'];
          _communityName = response['data']['community']['name'];
          _isFetchingLocation = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Could not match location to a community.');
      }
    } catch (e) {
      setState(() => _isFetchingLocation = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Cancel reg
                },
                child: const Text('CANCEL REGISTRATION'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showLocationPrompt(); // Try again
                },
                child: const Text('RETRY'),
              ),
            ],
          )
        );
      }
    }
  }

  @override
  void dispose() {
    _unitController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _icNumberController.dispose();
    for (var controller in _plateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addVehicleField() {
    setState(() {
      _plateControllers.add(TextEditingController());
    });
  }

  void _removeVehicleField(int index) {
    setState(() {
      _plateControllers[index].dispose();
      _plateControllers.removeAt(index);
    });
  }

  Future<void> _pickIcPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _isExtracting = true;
        _extractionError = null; // Clear previous error
      });
      _extractIcNumber(image);
    }
  }

  Future<void> _extractIcNumber(XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/community/extract_ic.php'));
      request.files.add(await http.MultipartFile.fromPath('ic_photo', imageFile.path));
      request.fields['full_name'] = _nameController.text;
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (jsonResponse['status'] == 'success') {
        setState(() {
          _extractedIcNumber = jsonResponse['data']['ic_number'];
          _icNumberController.text = _extractedIcNumber!;
          
          // Auto-fill name if it was empty or extracted
          String extractedName = jsonResponse['data']['full_name'] ?? '';
          if (extractedName.isNotEmpty) {
            _nameController.text = extractedName;
          }
          
          _icPhotoUrl = jsonResponse['data']['ic_photo_url'];
          _isExtracting = false;
        });
      } else {
        // Reset state on error so user can retake
        setState(() {
          _isExtracting = false;
          _extractionError = jsonResponse['message'] ?? 'Failed to extract IC. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _extractionError = 'Connection Error: ${e.toString()}';
      });
    }
  }

  void _register() async {
    // Extract non-empty plates
    List<String> validPlates = _plateControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (_communityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please allow location access to verify your community')));
      return;
    }

    if (_unitController.text.isEmpty || _nameController.text.isEmpty || 
        _extractedIcNumber == null || _passwordController.text.isEmpty || 
        validPlates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please scan your IC and fill all required fields.')));
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.post('community/register.php', {
      'community_id': _communityId,
      'unit_number': _unitController.text,
      'title': _selectedTitle,
      'full_name': _nameController.text,
      'contact_number': _contactController.text,
      'ic_number': _icNumberController.text,
      'ic_photo_url': _icPhotoUrl,
      'username': _icNumberController.text,
      'password': _passwordController.text,
      'license_plates': validPlates, // Sending array
      'photo_url': 'pending_upload.jpg', // Placeholder for now
    });

    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('Your household has been registered. Your vehicles are pending Association Approval.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to login
                },
                child: const Text('OK'),
              )
            ],
          )
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Registration failed'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Register Household', style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.black),
      ),
      body: Stack(
        children: [
          // Light Theme Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFEAF5FF),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isFetchingLocation)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue)),
                            SizedBox(width: 15),
                            Expanded(child: Text('Finding your community via GPS...', style: TextStyle(color: AppTheme.primaryBlue, fontStyle: FontStyle.italic))),
                          ],
                        )
                      )
                    else if (_communityName != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 28),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('COMMUNITY MATCHED:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                                  Text(_communityName!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 16)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                              onPressed: _fetchCommunityLocation,
                              tooltip: 'Refresh Location',
                            )
                          ],
                        )
                      ),
                    
                    const SizedBox(height: 30),
                    Text('IC Identity Verification', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.black)),
                    const SizedBox(height: 10),
                    Text('Take a clear photo of the front of your IC. We will use AI to verify your identity.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 15),

                    if (_extractionError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_extractionError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                    
                    if (_isExtracting)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue)),
                            SizedBox(width: 15),
                            Expanded(child: Text('AI is extracting your IC number...', style: TextStyle(color: AppTheme.primaryBlue, fontStyle: FontStyle.italic))),
                          ],
                        ),
                      )
                    else if (_extractedIcNumber != null)
                      TextField(
                        controller: _icNumberController,
                        readOnly: true,
                        style: const TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        decoration: InputDecoration(
                          labelText: 'Extracted IC Number',
                          prefixIcon: const Icon(Icons.verified_user, color: Colors.green),
                          filled: true,
                          fillColor: Colors.green.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                        onPressed: _pickIcPhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('CAPTURE IC FRONT PHOTO'),
                      ),

                    const SizedBox(height: 30),
                    // TODO:
                    // - [x] Use extracted IC as login username (Remove manual field)
                    // - [x] Inform user about IC username in UI
                    // - [x] Expand form width (Reduce horizontal padding)
                    // - [x] Reorder UI: IC Verification above Resident Details
                    // - [ ] Enforce AI-only entry (Full Name & IC read-only)
                    Text('Primary Resident Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.black)),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTitle,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: AppTheme.black),
                      items: _titles.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTitle = val);
                      },
                      decoration: InputDecoration(
                        labelText: 'Title',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      readOnly: true,
                      style: const TextStyle(color: AppTheme.black),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Will be filled by scanning IC',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryBlue),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _unitController,
                      style: const TextStyle(color: AppTheme.black),
                      decoration: InputDecoration(
                        labelText: 'Unit / House Number', 
                        prefixIcon: const Icon(Icons.home, color: AppTheme.primaryBlue),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _contactController,
                      style: const TextStyle(color: AppTheme.black),
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryBlue),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Text('Account Login', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.black)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your login username will be your IC Number.',
                              style: TextStyle(color: AppTheme.primaryBlue.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.black),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryBlue),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vehicles', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.black)),
                        TextButton.icon(
                          onPressed: _addVehicleField,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Vehicle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _plateControllers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _plateControllers[index],
                                  style: const TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  decoration: InputDecoration(
                                    labelText: 'License Plate (e.g. WAA1234)',
                                    prefixIcon: const Icon(Icons.directions_car, color: AppTheme.primaryBlue),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                ),
                              ),
                              if (_plateControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removeVehicleField(index),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    Text('* Registration places these vehicles in Pending Association Approval status.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    
                    const SizedBox(height: 40),
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            elevation: 5,
                            shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          ),
                          onPressed: _register,
                          child: const Text('SUBMIT REGISTRATION', style: TextStyle(letterSpacing: 1.2, color: Colors.white)),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
