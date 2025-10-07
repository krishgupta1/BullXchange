import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/screens/pages/login_page.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/features/auth/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // ----------------------------
  // Controllers
  // ----------------------------
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UsersService _usersService = UsersService();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------
  // EMAIL VALIDATION - ABSTRACT API
  // ----------------------------
  Future<bool> validateEmailWithAPI(String email) async {
    try {
      final dio = Dio();
      final apiKey = dotenv.env['ABSTRACT_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('❌ API Key is missing.');
        return false;
      }

      final response = await dio.get(
        'https://emailvalidation.abstractapi.com/v1/',
        queryParameters: {
          'api_key': apiKey,
          'email': email,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('✅ Email validation response: $data');

        // Mark email as valid if deliverable
        return data['deliverability'] == 'DELIVERABLE';
      }

      return false;
    } catch (e) {
      debugPrint('❌ Email validation failed: $e');
      return false;
    }
  }

  // ----------------------------
  // SIGNUP FUNCTION
  // ----------------------------
  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill all fields.');
      return;
    }

    if (!_agreedToTerms) {
      _showSnackBar('You must agree to the Terms of Service.');
      return;
    }

    setState(() => _isSubmitting = true);

    // ✅ Validate email
    final isRealEmail = await validateEmailWithAPI(email);
    if (!isRealEmail) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Please enter a valid, real email address.');
      return;
    }

    // ✅ Password length check
    if (password.length < 6) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }

    try {
      // ✅ Create user in Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Send verification email
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('⚠️ Email verification send failed: $e');
        }

        // Save user info in Firestore
        await _usersService.addUser(user.uid, {
          'name': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        _showSnackBar(
          'Signup successful! Please verify your email before logging in.',
        );

        // Navigate to Login Page
        Navigator.pushReplacement(
          context,
          slideLeftToRight(const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message ?? 'Signup failed');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      if (!mounted) return;
      _showSnackBar('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4318FF);
    const Color secondaryText = Color(0xFF8AA0B2);
    const Color titleText = Color(0xFF0F2B46);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Back Button
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: IconButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      slideLeftToRight(const OnboardingPage12()),
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Logo & Name
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.trending_up, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'BullXchange',
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

              // Full Name
              _buildTextFieldWithLabel(
                label: 'Full Name',
                controller: _fullNameController,
                hintText: 'Full Name',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextFieldWithLabel(
                label: 'Email Address',
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              _buildTextFieldWithLabel(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Password',
                keyboardType: TextInputType.visiblePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Terms of Service
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) =>
                        setState(() => _agreedToTerms = val ?? false),
                    activeColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFE5E5E5),
                      width: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
                            recognizer: TapGestureRecognizer()..onTap = () {},
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
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _agreedToTerms && !_isSubmitting ? _signUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Start',
                          style: TextStyle(
                            fontFamily: 'EudoxusSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign In Link
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
                          color: Colors.black,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(
                              context,
                              slideLeftToRight(const LoginPage()),
                            );
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

  // ----------------------------
  // INPUT FIELD BUILDER
  // ----------------------------
  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
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

  InputDecoration _buildInputDecoration(String hintText, {Widget? suffixIcon}) {
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
        borderSide: const BorderSide(color: Color(0xFF4318FF)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }
}
