import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';

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
  late TextEditingController _phoneController;

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- (Helper functions _getInitials, _loadUserData, _saveProfile unchanged) ---
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    String initials = parts[0][0]; // First letter of the first name
    if (parts.length > 1) {
      initials += parts.last[0]; // First letter of the last name
    }
    return initials.toUpperCase();
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
        _phoneController.text = userProfile.mobileNo;
        // This triggers a rebuild to show initials in the avatar
        setState(() {});
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
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.updateUserProfile(
        uid: widget.userId,
        name: _nameController.text.trim(),
        emailId: _emailController.text.trim(),
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
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // --- ⭐️ MODIFIED: Theme app bar color ---
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: IconButton(
          // --- ⭐️ MODIFIED: Theme icon color (pink) ---
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          // --- ⭐️ MODIFIED: Theme app bar title style ---
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                // --- ⭐️ MODIFIED: Theme error color ---
                style: TextStyle(color: colorScheme.error),
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
                    _buildStyledTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      keyboardType: TextInputType.phone,
                      enabled: false, // Field is not editable
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
                          // --- ⭐️ MODIFIED: Theme button color ---
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            // --- ⭐️ MODIFIED: Theme text color ---
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileAvatar() {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final initials = _getInitials(_nameController.text);

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          // --- ⭐️ MODIFIED: Theme color ---
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              // --- ⭐️ MODIFIED: Theme color ---
              color: colorScheme.primary,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              // TODO: Add logic to pick/upload a new image
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // --- ⭐️ MODIFIED: Theme color ---
                color: colorScheme.secondary,
                // --- ⭐️ MODIFIED: Theme border color ---
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                // --- ⭐️ MODIFIED: Theme text color ---
                color: colorScheme.onSecondary,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
          child: Text(
            label,
            style: TextStyle(
              // --- ⭐️ MODIFIED: Theme text/grey color ---
              color: enabled
                  ? colorScheme.secondary
                  : textTheme.bodySmall?.color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          // --- ⭐️ MODIFIED: Theme text/grey color ---
          style: TextStyle(
            color: enabled ? colorScheme.onSurface : textTheme.bodySmall?.color,
          ),
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 25,
            ),
            filled: !enabled,
            // --- ⭐️ MODIFIED: Theme fill color ---
            fillColor: theme.dividerColor.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                // --- ⭐️ MODIFIED: Theme border color ---
                color: enabled
                    ? colorScheme.primary.withOpacity(0.4)
                    : theme.dividerColor,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                // --- ⭐️ MODIFIED: Theme border color ---
                color: enabled
                    ? colorScheme.primary.withOpacity(0.4)
                    : theme.dividerColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                // --- ⭐️ MODIFIED: Theme border color ---
                color: enabled ? colorScheme.primary : theme.dividerColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              // --- ⭐️ MODIFIED: Theme border color ---
              borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
