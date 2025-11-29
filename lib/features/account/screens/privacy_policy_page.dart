import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const CustomBackButton(),
        title: Text(
          'Privacy Policy',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetaHeader(context),
          const SizedBox(height: 24),

          // --- 1. Information We Collect ---
          _buildSection(
            context,
            'Information We Collect',
            Icons.data_usage_rounded,
            Colors.blueAccent,
            [
              '**a) User Information**',
              '• Name',
              '• Email',
              '• Basic profile details',
              '',
              '**b) Automatically Collected Information**',
              '• Device information',
              '• Usage analytics',
              '• Crash logs',
              '• App events and interactions',
              '',
              '**c) Payment Information (UPI Top-Up)**',
              'During virtual currency top-up, we may collect:',
              '• Transaction ID',
              '• Payment amount',
              '• Payment status',
              '',
              '**We do NOT collect or store:**',
              '• UPI PIN',
              '• Bank account details',
              '• Card details',
              '• Passwords',
            ],
          ),

          // --- 2. How We Use Your Information ---
          _buildSection(
            context,
            'How We Use Data',
            Icons.psychology_rounded,
            Colors.purpleAccent,
            [
              'We use your info strictly to:',
              '• Improve app performance & insights',
              '• Fix bugs and crashes',
              '• Verify virtual currency top-ups',
              '• Personalize your user experience',
              '',
              'We never **sell, trade, or rent** your user data.',
            ],
          ),

          // --- 3. Data Security ---
          _buildSection(
            context,
            'Data Security',
            Icons.security_rounded,
            Colors.green,
            [
              'We protect your data using:',
              '• Firebase security rules',
              '• Encrypted communication',
              '• Secure data storage',
              '',
              '(Note: 100% guaranteed security is not possible on the internet)',
            ],
          ),

          // --- 4. Third-Party Services ---
          _buildSection(
            context,
            'Third-Party Services',
            Icons.handshake_rounded,
            Colors.orangeAccent,
            [
              'The app may use the following third-party services:',
              '• Firebase Analytics',
              '• Crashlytics',
              '• UPI payment processors',
              '',
              'Their respective privacy policies apply to the data they collect.',
            ],
          ),

          // --- 5. Children's Privacy ---
          _buildSection(
            context,
            'Children\'s Privacy',
            Icons.child_care_rounded,
            Colors.pinkAccent,
            ['This app is recommended for users aged **13+**.'],
          ),

          // --- 6. Your Rights ---
          _buildSection(
            context,
            'Your Rights',
            Icons.gavel_rounded,
            Colors.teal,
            [
              'You have the right to:',
              '• Request deletion of your data',
              '• Control app permissions',
            ],
          ),

          // --- 7. Updates to Policy ---
          _buildSection(
            context,
            'Updates to Policy',
            Icons.update_rounded,
            Colors.cyan,
            [
              'This policy may be updated from time to time.',
              'Changes will be reflected within the app.',
            ],
          ),

          // --- 8. Contact ---
          _buildSection(
            context,
            'Contact Us',
            Icons.mail_rounded,
            Colors.indigoAccent,
            [
              'For any privacy-related queries, contact us at:',
              'xchangebull@gmail.com',
              'https://bullxchange.vercel.app/',
            ],
          ),

          const SizedBox(height: 20),
          _buildSummary(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Meta Info Card (Updated Design) ---
  Widget _buildMetaHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "About Policy",
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, // Fixed visibility
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metaLine(context, 'Last Updated', 'November 2025'),
          _metaLine(context, 'Developer', 'BullXchange'),
          _metaLine(context, 'Email', 'xchangebull@gmail.com'),
          _metaLine(context, 'Website', 'bullxchange.vercel.app'),
        ],
      ),
    );
  }

  Widget _metaLine(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Policy Section Card (Updated Design) ---
  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    List<String> points,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.map((text) {
            // Logic to handle bold text marked with **
            final bool isBold = text.contains('**');
            final String cleanText = text.replaceAll('**', '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                cleanText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isBold
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Summary Gradient Card ---
  Widget _buildSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Our Commitment',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'BullXchange is dedicated to user privacy. We respect your data and only use it to enhance your paper trading experience. Your trust is our asset.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
