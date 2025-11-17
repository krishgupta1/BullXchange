import 'package:bullxchange/features/auth/screens/onboarding_page_1.1.dart';
import 'package:bullxchange/features/auth/screens/login_page.dart';
import 'package:bullxchange/features/auth/screens/signup_page.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:flutter/material.dart';
// import 'package:bullxchange/features/auth/widgets/app_back_button.dart'; // <-- Ise hata diya, standard BackButton use karenge

class OnboardingPage12 extends StatelessWidget {
  const OnboardingPage12({super.key});

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
                        // --- ⭐️ MODIFIED: Standard BackButton (theme-aware) ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: colorScheme.secondary,
                            ),
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
                        // Illustration
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
                        // Title
                        Text(
                          'Get Started  with BullXchange',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          "Discover India’s top stocks and F&O to trade and learn.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                // --- ⭐️ MODIFIED: Theme grey color ---
                                color: textTheme.bodySmall?.color,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 20),
                        // Page indicators
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
                        // Get Started button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              slideRightToLeft(SignupPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            // --- ⭐️ MODIFIED: Theme button color ---
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary, // White
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              // --- ⭐️⭐️ FIX: Text color ko explicitly white kiya ---
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sign in button (outlined)
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              slideRightToLeft(LoginPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            // --- ⭐️ MODIFIED: Theme colors ---
                            backgroundColor: colorScheme.surface,
                            // --- ⭐️⭐️ FIX: Text color ko blue kiya ---
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(
                              color: colorScheme.secondary,
                            ), // Pink border
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              // --- ⭐️⭐️ FIX: Text color ko explicitly blue kiya ---
                              color: colorScheme.primary,
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

// --- (Route transition function unchanged) ---
Route _slideLeftToRight(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0); // from left
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

// --- ⭐️ MODIFIED: _Dot widget ab theme-aware hai ---
class _Dot extends StatelessWidget {
  const _Dot({required this.active, this.isLong = false});

  final bool active;
  final bool isLong;

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- ⭐️ MODIFIED: Colors ab theme se aa rahe hain ---
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
