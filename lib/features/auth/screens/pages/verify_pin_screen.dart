import 'package:bullxchange/features/auth/screens/pages/password_confirmation_screen.dart';
import 'package:bullxchange/features/homepage/homepage.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:bullxchange/features/auth/services/pin_storage.dart';
import 'package:bullxchange/features/auth/screens/pages/setup_pin_screen.dart';

class VerifyPinScreen extends StatefulWidget {
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
        if (pin == widget.expectedPin) {
          await _pinStorage.setPin(pin);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else {
          setState(() => _error = 'PINs do not match. Please try again.');
        }
      } else {
        final isPinCorrect = await _pinStorage.verifyPin(pin);
        if (isPinCorrect) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        } else {
          setState(() => _error = 'Incorrect PIN');
        }
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
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
              if (widget.expectedPin != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const SetupPinScreen(),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                    ),
                  ),
                )
              else
                const SizedBox(height: 40),
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
                    // --- DEBUG: Temporarily removed custom font ---
                    // fontFamily: 'EudoxusSans',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2B46),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Center(
                child: Text(
                  widget.expectedPin != null
                      ? 'Re-enter to confirm'
                      : 'Unlock to continue',
                  style: const TextStyle(
                    // --- DEBUG: Temporarily removed custom font ---
                    // fontFamily: 'EudoxusSans',
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
              if (widget.expectedPin == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PasswordConfirmationScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Reset PIN?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(
                          0xFF4318FF,
                        ), // same style as login page reset password
                      ),
                    ),
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
                  onPressed: _isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? Center(
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(widget.expectedPin != null ? 'Confirm' : 'Unlock'),
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
