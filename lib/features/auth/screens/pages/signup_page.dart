import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers for the input fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State for password visibility and terms checkbox
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Common input decoration consistent with the login page style
  InputDecoration _buildInputDecoration(String hintText, {Widget? suffixIcon}) {
    // Define the common border style
    const borderSide = BorderSide(color: Color(0xFFE5E5E5));
    final outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: borderSide,
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'EudoxusSans',
        color: Color(0xFF8AA0B2),
        fontSize: 16,
      ),
      border: outlineInputBorder,
      enabledBorder: outlineInputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4318FF)), // Focused color
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define main colors for better readability
    const Color primaryBlue = Color(0xFF4318FF);
    const Color secondaryText = Color(0xFF8AA0B2);
    const Color titleText = Color(0xFF0F2B46);
    const Color termsLinkColor = Color(
      0xFF00BFA5,
    ); // Teal/Green from Login's Sign up link

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // Wrap the content in SingleChildScrollView to prevent overflow
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Back button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                ),
                child: Center(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      // Using the same red color as the login page back button
                      color: Color(0xFFE53E3E),
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Logo and App Name
              Row(
                children: [
                  // Logo container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4318FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  // App Name
                  const Text(
                    'BullXchange', // Keeping App Name consistent with LoginPage
                    style: TextStyle(
                      fontFamily: 'EudoxusSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Title: "Getting Started"
              const Text(
                "Getting Started",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: titleText,
                ),
              ),
              const SizedBox(height: 8),

              // Welcome message: "Create an account to continue!"
              const Text(
                "Create an account to continue!",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 40),

              // --- Input Fields ---

              // 1. Full Name field
              _buildTextFieldWithLabel(
                'Full Name',
                _fullNameController,
                'Full Name',
                TextInputType.name,
              ),
              const SizedBox(height: 16),

              // 2. Email field
              _buildTextFieldWithLabel(
                'Email Address',
                _emailController,
                'Email Address',
                TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // 3. Password field
              _buildTextFieldWithLabel(
                'Password',
                _passwordController,
                'Password', // Placeholder text
                TextInputType.visiblePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Terms of Service Checkbox ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _agreedToTerms = newValue ?? false;
                        });
                      },
                      activeColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFE5E5E5),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(
                                fontFamily: 'EudoxusSans',
                                fontSize: 14,
                                color: secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                fontFamily: 'EudoxusSans',
                                fontSize: 14,
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // TODO: Handle navigation to Terms of Service
                                },
                            ),
                            const TextSpan(
                              text: ' and ',
                              style: TextStyle(
                                fontFamily: 'EudoxusSans',
                                fontSize: 14,
                                color: secondaryText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                fontFamily: 'EudoxusSans',
                                fontSize: 14,
                                color: primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // TODO: Handle navigation to Privacy Policy
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- "Start" button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _agreedToTerms
                      ? () {
                          // TODO: Implement sign up logic
                        }
                      : null, // Disable button if terms not agreed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      fontFamily: 'EudoxusSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Sign In link ---
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryText,
                        ),
                      ),
                      TextSpan(
                        text: 'Sign in',
                        style: const TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: termsLinkColor, // Using the accent color
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // TODO: Implement navigation back to LoginPage
                            Navigator.of(context).pop();
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the label + text field combination
  Widget _buildTextFieldWithLabel(
    String label,
    TextEditingController controller,
    String hintText,
    TextInputType keyboardType, {
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'EudoxusSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F2B46),
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: _buildInputDecoration(hintText, suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}
