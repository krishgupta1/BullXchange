import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/screens/pages/login_page.dart';
import 'package:bullxchange/features/auth/screens/pages/setup_pin_screen.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/features/auth/services/auth_service.dart';
import 'package:bullxchange/features/auth/widgets/app_back_button.dart';
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

  // ✅ Email validation via Abstract API
  Future<bool> validateEmailWithAPI(String email) async {
    try {
      final dio = Dio();
      final apiKey = dotenv.env['ABSTRACT_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) return false;

      final response = await dio.get(
        'https://emailvalidation.abstractapi.com/v1/',
        queryParameters: {'api_key': apiKey, 'email': email},
      );

      if (response.statusCode == 200) {
        return response.data['deliverability'] == 'DELIVERABLE';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ✅ Signup flow
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

    final isRealEmail = await validateEmailWithAPI(email);
    if (!isRealEmail) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Please enter a valid, real email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Password must be at least 6 characters.');
      return;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await _usersService.addUser(user.uid, {
          'name': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'hasPin': false,
        });

        if (!mounted) return;

        // Go to PIN setup after successful signup
        Navigator.pushReplacement(
          context,
          slideRightToLeft(const SetupPinScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Signup failed');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4318FF);
    const secondaryText = Color(0xFF8AA0B2);
    const titleText = Color(0xFF0F2B46);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              AppBackButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  slideLeftToRight(const OnboardingPage12()),
                ),
              ),
              const SizedBox(height: 30),

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
              const SizedBox(height: 30),

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

              _buildTextFieldWithLabel(
                label: 'Full Name',
                controller: _fullNameController,
                hintText: 'Full Name',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithLabel(
                label: 'Email Address',
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithLabel(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Password',
                keyboardType: TextInputType.visiblePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) =>
                        setState(() => _agreedToTerms = val ?? false),
                    activeColor: primaryBlue,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 14,
                          color: secondaryText,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _agreedToTerms && !_isSubmitting ? _signUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
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
              const SizedBox(height: 15),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'EudoxusSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: secondaryText,
                    ),
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      TextSpan(
                        text: 'Sign in',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w700),
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
        Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
