import 'package:bullxchange/features/auth/screens/onboarding_page_1.2.dart';
import 'package:bullxchange/features/auth/navigation/route_transitions.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FF),
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
                        const SizedBox(height: 80),
                        // Illustration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AspectRatio(
                            aspectRatio: 1.2,
                            child: Center(
                              child: Image.asset(
                                'assets/images/onboarding.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        // Title
                        Text(
                          'Buy & Trade Top Stock and F&O',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                color: const Color(0xFF0F2B46),
                              ),
                        ),
                        const SizedBox(height: 60),
                        // Description
                        Text(
                          "A platform to practice trading India’s top stocks and F&O with zero risk.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF8AA0B2),
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 60),
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _Dot(active: true),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.of(context).push(
                                  slideRightToLeft(const OnboardingPage12()),
                                );
                              },
                              child: const _Dot(active: false, isLong: true),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Next button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).push(slideRightToLeft(const OnboardingPage12()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4318FF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Next',
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

// Using shared transitions from route_transitions.dart

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
