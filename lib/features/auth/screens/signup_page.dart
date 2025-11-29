import 'package:bullxchange/features/auth/screens/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/screens/login_page.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/services/firebase/user_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _usersService = UserService();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // (validateEmailWithAPI function unchanged)
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

  // ✅ Popup error dialog (Theme-Aware)
  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Signup Failed',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Okay',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
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
    final mobileNo = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Basic Client-Side Validation
    if (fullName.isEmpty ||
        email.isEmpty ||
        mobileNo.isEmpty ||
        password.isEmpty) {
      _showErrorDialog('Please fill all fields, including your mobile number.');
      return;
    }

    if (mobileNo.length != 10 || int.tryParse(mobileNo) == null) {
      _showErrorDialog('Please enter a valid 10-digit mobile number.');
      return;
    }

    if (!_agreedToTerms) {
      _showErrorDialog('You must agree to the Terms of Service.');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 2. ⭐️ CHECK MOBILE UNIQUENESS (New Logic)
      // We check this BEFORE the email API to save API credits and time.
      final bool mobileExists = await _usersService.isMobileNumberRegistered(
        mobileNo,
      );

      if (mobileExists) {
        setState(() => _isSubmitting = false);
        await _showErrorDialog(
          'This mobile number is already registered with another account.',
        );
        return; // Stop execution here
      }

      // 3. Validate Email with API
      final isRealEmail = await validateEmailWithAPI(email);
      if (!isRealEmail) {
        setState(() => _isSubmitting = false);
        _showErrorDialog('Please enter a valid, real email address.');
        return;
      }

      // 4. Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // 5. Add user details to Firestore
        await _usersService.addUserProfile(
          uid: user.uid,
          name: fullName,
          emailId: email,
          mobileNo: mobileNo,
        );

        if (!mounted) return;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              SizedBox(
                width: 56,
                height: 56,
                child: CustomBackButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    slideLeftToRight(const OnboardingPage12()),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BullXchange',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Text(
                "Getting Started",
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Create an account to continue!",
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 40),

              _buildTextFieldWithLabel(
                context: context,
                label: 'Full Name',
                controller: _fullNameController,
                hintText: 'Full Name',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithLabel(
                context: context,
                label: 'Email Address',
                controller: _emailController,
                hintText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithLabel(
                context: context,
                label: 'Mobile Number',
                controller: _mobileController,
                hintText: '10-digit Mobile Number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithLabel(
                context: context,
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
                    color: textTheme.bodySmall?.color,
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
                    activeColor: colorScheme.primary,
                    side: BorderSide(color: textTheme.bodySmall!.color!),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style:
                            textTheme.bodyMedium?.copyWith(
                              color: textTheme.bodySmall?.color,
                            ) ??
                            const TextStyle(fontSize: 13),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: colorScheme.primary,
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
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : Text(
                          'Start',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),

              Center(
                child: RichText(
                  text: TextSpan(
                    style:
                        textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textTheme.bodySmall?.color,
                        ) ??
                        const TextStyle(fontSize: 13),
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                          color: colorScheme.primary,
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
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: textTheme.bodySmall?.color),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
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
