import 'package:bullxchange/features/auth/screens/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:bullxchange/features/auth/screens/signup_page.dart';
import 'package:bullxchange/features/auth/screens/reset_password_page.dart';
import 'package:bullxchange/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final loginProvider = Provider.of<LoginProvider>(context);

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
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
                child: Center(
                  child: CustomBackButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      slideLeftToRight(const OnboardingPage12()),
                    ),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      // --- ⭐️ MODIFIED: Theme primary color (Blue) ---
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // --- ⭐️ MODIFIED: Theme text color (White) ---
                    child: Icon(
                      Icons.trending_up,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BullXchange',
                    style: TextStyle(
                      fontFamily: 'EudoxusSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      // --- ⭐️ MODIFIED: Theme primary color (Blue) ---
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                "Let's Sign You In",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Welcome back, you've been missed!",
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  color: textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                // --- ⭐️ MODIFIED: Theme text color ---
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(
                  context,
                  'Email',
                ), // ⭐️ Pass context
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                // --- ⭐️ MODIFIED: Theme text color ---
                style: TextStyle(color: colorScheme.onSurface),
                decoration: _inputDecoration(context, 'Password').copyWith(
                  // ⭐️ Pass context
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      // --- ⭐️ MODIFIED: Theme grey color ---
                      color: textTheme.bodySmall?.color,
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
                  child: Text(
                    'Reset password?',
                    // --- ⭐️ MODIFIED: Text color (Blue) ---
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loginProvider.isLoading
                      ? null
                      : () => loginProvider.handleLogin(
                          context,
                          _emailController.text,
                          _passwordController.text,
                        ),
                  style: ElevatedButton.styleFrom(
                    // --- ⭐️ MODIFIED: Theme button colors ---
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loginProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 150),
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Don't have an account? ",
                        // --- ⭐️ MODIFIED: Theme grey color ---
                        style: TextStyle(color: textTheme.bodySmall?.color),
                      ),
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          // --- ⭐️ MODIFIED: Theme primary color (Blue) ---
                          color: colorScheme.primary,
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

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InputDecoration(
      hintText: hint,
      // --- ⭐️ MODIFIED: Theme hint color ---
      hintStyle: TextStyle(color: textTheme.bodySmall?.color),
      // --- ⭐️ MODIFIED: Theme surface color ---
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // --- ⭐️ MODIFIED: Theme divider color ---
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // --- ⭐️ MODIFIED: Theme primary color ---
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}


