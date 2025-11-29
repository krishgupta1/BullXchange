import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:pinput/pinput.dart';
import 'package:bullxchange/features/auth/screens/verify_pin_screen.dart';

class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _navigateToConfirm(String pin) {
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

    _navigateToConfirm(pin);

    if (mounted) {
      setState(() => _isSubmitting = false);
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
        fontSize: 18,
        fontWeight: FontWeight.w600,
        // --- ⭐️ MODIFIED: Theme text color ---
        color: colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme surface color ---
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        // --- ⭐️ MODIFIED: Theme border color ---
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
                minHeight:
                    MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top +
                        MediaQuery.of(context).padding.bottom),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
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
                        'Create PIN',
                        style: TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          // --- ⭐️ MODIFIED: Theme text color ---
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter a 4-digit PIN to secure your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'EudoxusSans',
                          fontSize: 14,
                          // --- ⭐️ MODIFIED: Theme grey color ---
                          color: textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Pinput(
                              controller: _pinController,
                              length: 4,
                              defaultPinTheme: defaultPinTheme,
                              // --- ⭐️ MODIFIED: Focused theme ---
                              focusedPinTheme: focusedPinTheme,
                              obscureText: _obscurePin,
                              obscuringCharacter: '•',
                              keyboardType: TextInputType.number,
                              onCompleted: (_) => _submit(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
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
                          ),
                        ],
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
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          // --- ⭐️ MODIFIED: Theme button color ---
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    // --- ⭐️ MODIFIED: Theme text color ---
                                    colorScheme.onPrimary,
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
          ),
        ),
      ),
    );
  }
}


