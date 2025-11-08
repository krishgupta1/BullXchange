import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/models/user_profile_data_model.dart'; // Make sure this path is correct
// import 'package:firebase_auth/firebase_auth.dart'; // Uncomment if userId is fetched here

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController; // Still need to display it

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController(); // Initialize
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final UserProfileDataModel? userProfile = await _userService
          .readUserProfile(widget.userId);

      if (userProfile != null) {
        _nameController.text = userProfile.name;
        _emailController.text = userProfile.emailId;
        _phoneController.text = userProfile.mobileNo; // Set phone number
      } else {
        setState(() {
          _errorMessage = 'Could not load user profile.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't save if validation fails
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.updateUserProfile(
        uid: widget.userId,
        name: _nameController.text.trim(),
        emailId: _emailController.text.trim(),
        // Pass the original phone number if it's not editable
        mobileNo: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileAvatar(),
                    const SizedBox(height: 40),
                    // Full Name Field
                    _buildStyledTextField(
                      controller: _nameController,
                      label: 'Full name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Email Address Field
                    _buildStyledTextField(
                      controller: _emailController,
                      label: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Phone Number Field (Disabled)
                    _buildStyledTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                      enabled: false, // Make it disabled/fade out
                      validator: (value) {
                        if (value == null || value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF4B00D1,
                          ), // Deep purple
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        // Placeholder for the user's avatar
        // Using a similar purple avatar to the image
        const CircleAvatar(
          radius: 60,
          backgroundColor: Color(0xFFE0E0E0), // Greyish background
          child: Icon(
            Icons.person, // Or an asset image
            size: 80,
            color: Color(0xFF9C27B0), // Purple icon to mimic the image's avatar
          ),
          // If you have an image URL, use:
          // backgroundImage: NetworkImage(userProfile.imageUrl),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              // TODO: Add logic to pick/upload a new image
            },
            child: Container(
              width: 44, // Matches the radius * 2 for the circle
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD100F7), // Bright pink from image
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ), // White border
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget to create text fields matching your design
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true, // Added enabled property
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? const Color(0xFFF50057)
                  : Colors.grey[600], // Pink for enabled, grey for disabled
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled, // Apply enabled state
          style: TextStyle(
            color: enabled
                ? Colors.black
                : Colors.grey[500], // Text color for enabled/disabled
          ),
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 25,
            ),
            filled: !enabled, // Fill for disabled state
            fillColor: Colors.grey[100], // Light grey fill for disabled
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: enabled
                    ? const Color(0xFFB39DDB)
                    : Colors
                          .grey[300]!, // Light purple for enabled, lighter grey for disabled
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: enabled ? const Color(0xFFB39DDB) : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: enabled
                    ? const Color(0xFF4B00D1)
                    : Colors
                          .grey[300]!, // Deep purple for enabled, lighter grey for disabled
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              // Explicitly define disabled border
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
