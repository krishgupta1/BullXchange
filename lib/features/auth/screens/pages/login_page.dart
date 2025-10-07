import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/features/auth/services/pin_storage.dart';
import 'package:bullxchange/features/auth/screens/pages/setup_pin_screen.dart' as setup;
import 'package:bullxchange/features/auth/screens/pages/verify_pin_screen.dart' as verify;
import 'package:bullxchange/features/auth/screens/pages/signup_page.dart';
import 'package:bullxchange/features/auth/screens/pages/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter both email and password.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showSnack('Incorrect email format.');
      return;
    }
    if (password.length < 8) {
      _showSnack('Password should be at least 8 characters.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      _showSnack('Signed in successfully.');

      // ✅ Check PIN status
      final pinService = PinStorageService();
      final hasPin = await pinService.hasPin();

      if (!mounted) return;

      if (hasPin) {
        Navigator.pushReplacement(
          context,
          slideRightToLeft(const verify.VerifyPinScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          slideRightToLeft(const setup.SetupPinScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          _showSnack('No account found for this email.');
          break;
        case 'wrong-password':
          _showSnack('Incorrect password.');
          break;
        case 'invalid-credential':
        case 'invalid-login-credentials':
          _showSnack('Invalid email or password.');
          break;
        case 'operation-not-allowed':
          _showSnack('Email/Password sign-in is disabled.');
          break;
        case 'network-request-failed':
          _showSnack('Network error. Check your connection.');
          break;
        case 'too-many-requests':
          _showSnack('Too many attempts. Try again later.');
          break;
        default:
          _showSnack('Login failed. (${e.code})');
      }
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Logo
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4318FF),
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
                      color: Color(0xFF4318FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              const Text(
                "Let's Sign You In",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F2B46),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Welcome back, you've been missed!",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8AA0B2),
                ),
              ),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration('Password').copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    slideRightToLeft(const ResetPasswordPage()),
                  ),
                  child: const Text('Reset password?'),
                ),
              ),
              const SizedBox(height: 150),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
              ),
              const Spacer(),

              // Signup Link
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Color(0xFF8AA0B2)),
                      ),
                      TextSpan(
                        text: 'Sign up',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.pushReplacement(
                                context,
                                slideRightToLeft(const SignupPage()),
                              ),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4318FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
