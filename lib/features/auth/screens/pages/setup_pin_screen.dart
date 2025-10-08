// lib/features/auth/screens/pages/setup_pin_screen.dart

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:bullxchange/features/auth/screens/pages/verify_pin_screen.dart';

/// Screen to set a new PIN. After entering a PIN this navigates to
/// VerifyPinScreen(expectedPin: pin) where the user confirms it.
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _navigateToConfirm(String pin) {
    // Replace the setup screen with the confirm screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VerifyPinScreen(expectedPin: pin)),
    );
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Please enter a 4-digit PIN');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    // Navigate to confirm screen which will actually store the PIN on success.
    _navigateToConfirm(pin);

    // No long-running work here — confirmation screen handles saving.
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F2B46),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              SizedBox(width: 40, height: 40),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1EEFF),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Image.asset(
                      'assets/images/lock.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Create PIN',
                  style: TextStyle(
                    fontFamily: 'EudoxusSans',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2B46),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Enter a 4-digit PIN to secure your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'EudoxusSans',
                    fontSize: 16,
                    color: Color(0xFF8AA0B2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Pinput(
                  controller: _pinController,
                  length: 4,
                  defaultPinTheme: defaultPinTheme,
                  obscureText: true,
                  obscuringCharacter: '•',
                  keyboardType: TextInputType.number,
                  onCompleted: (_) => _submit(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Next'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
