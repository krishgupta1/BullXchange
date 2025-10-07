import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bullxchange/features/auth/screens/pages/login_page.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 🔎 Optional: Check if user exists in Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No account found with this email.'),
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      // ✅ Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset link sent. Check your email.'),
        ),
      );

      // Go back to login
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        slideLeftToRight(const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Email not found'),
            content:
                const Text('No account exists with this email address.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to send reset link.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found, try again or please create an account')
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        slideLeftToRight(const LoginPage()),
                      );
                    },
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

              // Title
              const Text(
                'Password Recovery',
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F2B46),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Enter your email to recover your password',
                style: TextStyle(
                  fontFamily: 'EudoxusSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8AA0B2),
                ),
              ),

              const SizedBox(height: 32),

              // Email Field
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Email address',
                  style: TextStyle(
                    fontFamily: 'EudoxusSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'username@mail.com',
                  hintStyle: const TextStyle(
                    fontFamily: 'EudoxusSans',
                    color: Color(0xFF0F2B46),
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFBDB2FF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFBDB2FF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF4318FF)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send Reset Password Link',
                          style: TextStyle(
                            fontFamily: 'EudoxusSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
