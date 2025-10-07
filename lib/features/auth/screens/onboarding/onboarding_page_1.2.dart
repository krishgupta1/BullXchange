import 'package:bullxchange/features/auth/screens/onboarding/onboarding_page_1.1.dart';
import 'package:bullxchange/features/auth/screens/pages/login_page.dart';
import 'package:flutter/material.dart';

class OnboardingPage12 extends StatelessWidget {
  const OnboardingPage12({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F2B46)),
          onPressed: () {
            // Use pop to reverse the previously pushed custom animation when possible
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(
                context,
              ).pushReplacement(_slideLeftToRight(const OnboardingPage()));
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
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
                                color: const Color(0xFF0F2B46),
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          "Discover India’s top stocks and F&O to trade and learn.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF8AA0B2),
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
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1541D5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sign in button (outlined, white background)
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F2B46),
                            side: const BorderSide(color: Color(0xFFFD4BC3)),
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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

class _Dot extends StatelessWidget {
  const _Dot({required this.active, this.isLong = false});

  final bool active;
  final bool isLong;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF4318FF);
    final Color inactiveColor = const Color(0xFFC7CFE6);
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
