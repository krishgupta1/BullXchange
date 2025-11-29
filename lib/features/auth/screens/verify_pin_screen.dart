import 'package:bullxchange/features/auth/screens/password_confirmation_screen.dart';
import 'package:bullxchange/features/home/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
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
        // --- SETUP MODE: User is confirming the new PIN ---
        if (pin == widget.expectedPin) {
          // Save to Firebase
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
        // --- LOGIN MODE: Verify against Firebase ---
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
    } catch (e) {
      // Handle network errors or permission issues
      setState(
        () => _error = 'Verification failed. Please check your internet.',
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle:
          textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ) ??
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
    );

    final submittedPinTheme = focusedPinTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                        width: 56,
                        height: 56,
                        child: Center(
                          child: CustomBackButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const SetupPinScreen(),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
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
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Image.asset(
                            'assets/images/lock.png',
                            fit: BoxFit.contain,
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
                        style: textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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
                        style: textTheme.bodyMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
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
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
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
                                      colorScheme.onPrimary,
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
