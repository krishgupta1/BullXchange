import 'package:bullxchange/features/auth/screens/onboarding_page_1.1.dart';
import 'package:bullxchange/features/auth/screens/login_page.dart';
import 'package:bullxchange/features/auth/screens/signup_page.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class OnboardingPage12 extends StatelessWidget {
  const OnboardingPage12({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- ⭐️ FIX: Check if Dark Mode is active ---
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomBackButton(
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pushReplacement(
                                  _slideLeftToRight(const OnboardingPage()),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AspectRatio(
                            aspectRatio: 1.2,
                            child: Center(
                              child: Image.asset(
                                'assets/images/splashBottom.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Get Started with BullXchange',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Discover India’s top stocks and F&O to trade and learn.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: textTheme.bodySmall?.color,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  _slideLeftToRight(const OnboardingPage()),
                                );
                              },
                              child: const _Dot(active: false),
                            ),
                            const SizedBox(width: 8),
                            const _Dot(active: true, isLong: true),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              slideRightToLeft(SignupPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get Started',
                            style: Theme.of(context).textTheme.titleLarge!
                                .copyWith(color: colorScheme.onPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- ⭐️ SIGN IN BUTTON FIX ---
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              slideRightToLeft(LoginPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: colorScheme.surface,
                            // Hint color for ripples
                            foregroundColor: isDarkMode
                                ? Colors.white
                                : colorScheme.primary,
                            side: BorderSide(
                              // Ensure border is visible in dark mode too
                              color: isDarkMode
                                  ? Colors.white38
                                  : colorScheme.secondary,
                            ),
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Sign in',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              // ⭐️ FIX: If Dark Mode -> White, Else -> Primary Blue
                              color: isDarkMode
                                  ? Colors.white
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- (Route transition remains unchanged) ---
Route _slideLeftToRight(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, this.isLong = false});

  final bool active;
  final bool isLong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color activeColor = colorScheme.primary;
    final Color inactiveColor = theme.dividerColor.withOpacity(0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 8,
      width: isLong ? 24 : 8,
      decoration: BoxDecoration(
        color: active ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
