import 'package:bullxchange/features/auth/screens/password_confirmation_screen.dart';
import 'package:bullxchange/features/home/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:bullxchange/services/firebase/pin_storage.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';

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
  bool _obscurePin = true;

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
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- ⭐️ MODIFIED: Pinput theme ---
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface, // Theme text color
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Theme surface color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: colorScheme.primary,
          width: 2,
        ), // Theme primary color
      ),
    );

    final submittedPinTheme = focusedPinTheme;
    // --- ⭐️ END OF MODIFICATION ---

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        // --- ⭐️⭐️ FIX: Column ko SingleChildScrollView mein wrap kiya ⭐️⭐️ ---
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            // --- ⭐️⭐️ FIX: IntrinsicHeight use kiya taaki page poori height le ⭐️⭐️ ---
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              child: IntrinsicHeight(
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
                            // --- ⭐️ MODIFIED: Theme icon color ---
                            icon: Icon(
                              Icons.arrow_back_ios,
                              size: 18,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 40),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // --- ⭐️ MODIFIED: Theme color ---
                          color: colorScheme.primary.withOpacity(0.1),
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
                    Center(
                      child: Text(
                        widget.expectedPin != null
                            ? 'Confirm PIN'
                            : 'Enter PIN',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          // --- ⭐️ MODIFIED: Theme text color ---
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.expectedPin != null
                            ? 'Re-enter to confirm'
                            : 'Unlock to continue',
                        style: TextStyle(
                          fontSize: 16,
                          // --- ⭐️ MODIFIED: Theme grey color ---
                          color: textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Pinput(
                            controller: _pinController,
                            length: 4,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: submittedPinTheme,
                            obscureText: _obscurePin,
                            obscuringCharacter: '•',
                            keyboardType: TextInputType.number,
                            onCompleted: (_) => _verify(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              // --- ⭐️ MODIFIED: Theme grey color ---
                              color: textTheme.bodySmall?.color,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePin = !_obscurePin;
                              });
                            },
                          ),
                        ],
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
                                builder: (_) =>
                                    const PasswordConfirmationScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Reset PIN?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              // --- ⭐️ MODIFIED: Theme primary color ---
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _error!,
                          // --- ⭐️ MODIFIED: Theme error color ---
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                    // --- ⭐️⭐️ FIX: Spacer() ko SizedBox se replace kiya ⭐️⭐️ ---
                    const Spacer(),
                    const SizedBox(height: 32), // Thoda space diya
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          // --- ⭐️ MODIFIED: Theme button color ---
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary, // White
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                widget.expectedPin != null
                                    ? 'Confirm'
                                    : 'Unlock',
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
