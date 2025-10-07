import 'package:bullxchange/features/homepage/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullxchange/features/auth/screens/pages/signup_page.dart';
import 'package:bullxchange/features/auth/screens/pages/reset_password_page.dart';
import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';

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

  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showEmailNotFoundDialog(String email) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Email not found'),
          content: Text('No account exists for "$email".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushReplacement(
                  context,
                  slideRightToLeft(const SignupPage()),
                );
              },
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
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
      // Attempt login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _showSnack('Signed in successfully.');

      // Navigate to home/dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'invalid-email':
          _showSnack('Incorrect email format.');
          break;
        case 'user-disabled':
          _showSnack('This account has been disabled.');
          break;
        case 'user-not-found':
          await _showEmailNotFoundDialog(email);
          break;
        case 'wrong-password':
          _showSnack('Incorrect password.');
          break;
        case 'invalid-credential':
        case 'invalid-login-credentials':
          _showSnack('Invalid email or password.');
          break;
        case 'operation-not-allowed':
          _showSnack('Email/Password sign-in is disabled in Firebase.');
          break;
        case 'network-request-failed':
          _showSnack('Network error. Check your connection and try again.');
          break;
        case 'too-many-requests':
          _showSnack('Too many attempts. Please try again later.');
          break;
        default:
          _showSnack('Login failed. (${e.code})');
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    alignment: Alignment.center,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Logo and App Name
              Row(
                children: [
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

              // Title
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
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(
                    fontFamily: 'EudoxusSans',
                    color: Color(0xFF8AA0B2),
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4318FF)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(
                    fontFamily: 'EudoxusSans',
                    color: Color(0xFF8AA0B2),
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4318FF)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF8AA0B2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Reset Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      slideRightToLeft(const ResetPasswordPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Reset password?',
                    style: TextStyle(
                      fontFamily: 'EudoxusSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: 'EudoxusSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        style: TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8AA0B2),
                        ),
                      ),
                      TextSpan(
                        text: 'Sign up',
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
                              slideRightToLeft(const SignupPage()),
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
}
