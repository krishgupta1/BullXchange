import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'Email not found. Please check your address.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Back button
              SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: CustomBackButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Title
              Text(
                'Password Recovery',
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your email to recover your password',
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  color: textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 32),
              // Email label
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Email address',
                  style: TextStyle(
                    fontFamily: 'EudoxusSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                // --- ⭐️ MODIFIED: Theme text color ---
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'username@mail.com',
                  // --- ⭐️ MODIFIED: Theme hint color ---
                  hintStyle: TextStyle(
                    fontFamily: 'EudoxusSans',
                    color: textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    // --- ⭐️ MODIFIED: Theme border color ---
                    borderSide: BorderSide(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    // --- ⭐️ MODIFIED: Theme primary color ---
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  filled: true,
                  // --- ⭐️ MODIFIED: Theme surface color ---
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Reset Password button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    // --- ⭐️ MODIFIED: Theme button colors ---
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: colorScheme.onPrimary)
                      : Text(
                          'Send Reset Password Link',
                          style: TextStyle(
                            fontFamily: 'EudoxusSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            // --- ⭐️ MODIFIED: Theme text color ---
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


