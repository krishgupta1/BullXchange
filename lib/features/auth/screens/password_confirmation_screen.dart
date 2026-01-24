import 'package:bullxchange/features/auth/screens/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'setup_pin_screen.dart';

// --- Custom Route Transition Function ---
// (This function has been moved from here, it should be in your `route_transitions.dart` file)
// PageRouteBuilder slideRightToLeft(Widget page) { ... }
// ----------------------------------------

class PasswordConfirmationScreen extends StatefulWidget {
  const PasswordConfirmationScreen({super.key});

  @override
  State<PasswordConfirmationScreen> createState() =>
      _PasswordConfirmationScreenState();
}

class _PasswordConfirmationScreenState
    extends State<PasswordConfirmationScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not logged in.");
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
      );
    } on FirebaseAuthException {
      setState(() {
        _errorMessage = "Invalid password. Please try again.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(
        leading: const CustomBackButton(),
        centerTitle: true,
        title: Text(
          "Confirm Password",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        // --- ⭐️⭐️ FIX: Wrapped Column in SingleChildScrollView ---
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            // --- ⭐️⭐️ FIX: Used IntrinsicHeight so page takes full height ---
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    (AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top),
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // --- ⭐️ MODIFIED: Theme color ---
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Image.asset(
                            'assets/images/lock.png',
                            fit: BoxFit.contain,
                            // --- ⭐️ MODIFIED: Theme color ---
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Enter your account password\nto reset your PIN",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        // --- ⭐️ MODIFIED: Theme text color ---
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      // --- ⭐️ MODIFIED: Theme text color ---
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Enter Password",
                        // --- ⭐️ MODIFIED: Theme hint color ---
                        hintStyle: TextStyle(color: textTheme.bodySmall?.color),
                        // --- ⭐️ MODIFIED: Theme surface color ---
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          // --- ⭐️ MODIFIED: Theme border color ---
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          // --- ⭐️ MODIFIED: Theme primary color ---
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            // --- ⭐️ MODIFIED: Theme grey color ---
                            color: textTheme.bodySmall?.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          // slideRightToLeft(const ResetPasswordPage()), // This should come from your transitions file
                          MaterialPageRoute(
                            builder: (context) => const ResetPasswordPage(),
                          ),
                        ),
                        child: Text(
                          'Reset password?',
                          // --- ⭐️ MODIFIED: Theme primary color ---
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        // --- ⭐️ MODIFIED: Theme error color ---
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    // --- ⭐️⭐️ FIX: Replaced Spacer() with SizedBox ---
                    const Spacer(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPassword,
                        style: ElevatedButton.styleFrom(
                          // --- ⭐️ MODIFIED: Theme button colors ---
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  // --- ⭐️ MODIFIED: Theme text color ---
                                  color: colorScheme.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                "Verify",
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
