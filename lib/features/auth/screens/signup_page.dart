import 'package:bullxchange/features/auth/screens/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/screens/login_page.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:bullxchange/features/auth/widgets/app_back_button.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  // 1. Add Mobile Number Controller
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Use the updated model-based UserService
  final UserService _usersService = UserService();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  final Color primaryBlue = const Color(0xFF4318FF);
  final Color secondaryText = const Color(0xFF8AA0B2);
  final Color titleText = const Color(0xFF0F2B46);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    // 2. Dispose Mobile Number Controller
    _mobileController.dispose();
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

  // ✅ Popup error dialog (matches LoginPage style)
  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Signup Failed',
          style: TextStyle(color: titleText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(color: secondaryText, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Okay',
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Signup flow
  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final mobileNo = _mobileController.text.trim(); // 3a. Get mobile number
    final password = _passwordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        mobileNo.isEmpty ||
        password.isEmpty) {
      _showErrorDialog('Please fill all fields, including your mobile number.');
      return;
    }

    // Simple mobile number validation (10 digits)
    if (mobileNo.length != 10 || int.tryParse(mobileNo) == null) {
      _showErrorDialog('Please enter a valid 10-digit mobile number.');
      return;
    }

    if (!_agreedToTerms) {
      _showErrorDialog('You must agree to the Terms of Service.');
      return;
    }

    setState(() => _isSubmitting = true);

    final isRealEmail = await validateEmailWithAPI(email);
    if (!isRealEmail) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Please enter a valid, real email address.');
      return;
    }

    if (password.length < 6) {
      setState(() => _isSubmitting = false);
      _showErrorDialog('Password must be at least 6 characters.');
      return;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Call the model-based addUserProfile method
        await _usersService.addUserProfile(
          uid: user.uid,
          name: fullName,
          emailId: email,
          mobileNo: mobileNo, // 3b. Pass actual mobile number
        );

        if (!mounted) return;

        // Go to PIN setup after successful signup
        Navigator.pushReplacement(
          context,
          slideRightToLeft(const SetupPinScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Try logging in.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Try something stronger.';
          break;
        default:
          errorMessage = 'Signup failed. Please try again later.';
      }
      await _showErrorDialog(errorMessage);
    } catch (e) {
      await _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
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
                  color: Color(0xFF0F2B46),
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                "Create an account to continue!",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8AA0B2),
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

              // 4. Mobile Number Text Field
              _buildTextFieldWithLabel(
                label: 'Mobile Number',
                controller: _mobileController,
                hintText: '10-digit Mobile Number',
                keyboardType: TextInputType.phone,
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
                        style: TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 14,
                          color: secondaryText,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
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
                    style: TextStyle(
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
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
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
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
