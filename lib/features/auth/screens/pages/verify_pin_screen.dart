import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';
import 'package:bullxchange/features/auth/services/pin_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bullxchange/features/auth/screens/pages/login_page.dart';
import 'package:bullxchange/features/auth/screens/pages/setup_pin_screen.dart';

/// Screen to verify stored PIN on app launch or confirm PIN after setup.
class VerifyPinScreen extends StatefulWidget {
  /// If provided, the screen acts in confirmation mode: the user must
  /// re-enter the same PIN. On success, the PIN is saved and user proceeds.
  final String? expectedPin;
  const VerifyPinScreen({super.key, this.expectedPin});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final PinStorageService _pinStorage = PinStorageService();
  final TextEditingController _pinController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final pin = _pinController.text.trim();

    try {
      if (widget.expectedPin != null) {
        // Confirmation mode: compare with expected, then store and flag.
        if (pin == widget.expectedPin) {
          await _pinStorage.setPin(pin);
          // After setting PIN on first setup, sign out and force login
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        } else {
          setState(() => _error = 'PINs do not match');
        }
      } else {
        // Normal unlock mode
        final ok = await _pinStorage.verifyPin(pin);
        if (ok) {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          setState(() => _error = 'Incorrect PIN');
        }
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // Optional biometric login
  Future<void> _tryBiometric() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();
    if (!canCheck || !isSupported) return;

    try {
      final didAuth = await auth.authenticate(
        localizedReason: 'Unlock with biometrics',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuth && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (_) {
      // ignore errors
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
              // Show back button only in confirmation mode
              if (widget.expectedPin != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        // Navigate back to setup pin screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SetupPinScreen()),
                        );
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                    ),
                  ),
                )
              else
                const SizedBox(height: 40), // keep spacing if no back button
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1EEFF),
                  ),
                  child: const Icon(
                    Icons.lock_open,
                    size: 64,
                    color: Color(0xFF4318FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  widget.expectedPin != null ? 'Confirm PIN' : 'Enter PIN',
                  style: const TextStyle(
                    fontFamily: 'EudoxusSans',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2B46),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  widget.expectedPin != null ? 'Re-enter to confirm' : 'Unlock to continue',
                  style: const TextStyle(
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
                  onCompleted: (_) => _verify(),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.expectedPin == null ? _tryBiometric : null,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use biometrics'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4318FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.expectedPin != null ? 'Confirm' : 'Unlock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
