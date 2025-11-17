import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // --- ⭐️ REMOVED HARDCODED COLORS ---
  // static const Color kPrimaryBlue = ...
  // static const Color kPrimaryPink = ...
  // static const Color kSecondaryGrey = ...

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // --- ⭐️ MODIFIED: Theme app bar colors ---
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 3,
        shadowColor: colorScheme.secondary.withOpacity(0.2),
        leading: IconButton(
          // --- ⭐️ MODIFIED: Theme icon color ---
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          // --- ⭐️ MODIFIED: Theme title style ---
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        // --- ⭐️ MODIFIED: Remove hardcoded gradient ---
        // (Page background ab scaffold se aa raha hai)
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- ⭐️ MODIFIED: Pass context ---
            _buildMetaHeader(context),
            const SizedBox(height: 18),
            _buildSection(context, '💡 Overview', [
              'BullXchange is your risk-free stock market playground! 📊',
              'We let you learn, test, and practice trading — all with **virtual money**. No fear. No loss. Just skill-building. 💪',
              'Your privacy matters. Here’s how we protect your data while you grow as a trader. 🛡️',
            ]),
            _buildSection(context, '📥 What We Collect', [
              'We may collect some basic info to make your experience smooth:',
              '• 👤 Name, email, and phone number',
              '• 📈 Your simulated trades & portfolio data',
              '• 💻 Device info (model, OS, IP, crash logs)',
              '• 🎯 Referral data (if you were invited)',
              '⚙️ All trading activity here is **virtual** — nothing involves real money.',
            ]),
            _buildSection(context, '🤖 How We Use Your Data', [
              'We use your info only to:',
              '• 🧠 Improve app performance & insights',
              '• 📊 Track your simulated portfolio',
              '• 🔔 Send trade updates or notifications',
              '• 🧾 Offer AI-based tips & feedback',
              '🚫 We never sell your data. Ever.',
            ]),
            _buildSection(context, '🔗 Data Sharing', [
              'We only share when necessary:',
              '• 💼 With secure analytics or hosting providers',
              '• ⚖️ When required by Indian law',
              '• 🏦 With broker partners (only if YOU opt-in)',
            ]),
            _buildSection(context, '🧱 Security First', [
              'We use 🔐 encryption (HTTPS), secure servers, and limited access.',
              'But remember — no internet system is 100% hack-proof. Stay smart. 🧠',
            ]),
            _buildSection(context, '⚙️ Your Rights', [
              'You’re always in control:',
              '• ✏️ Edit or delete your account anytime',
              '• 💬 Withdraw consent when you wish',
              '• 📧 Mail us at support@bullxchange.in for help',
            ]),
            _buildSection(context, '🧒 Minors', [
              'BullXchange is built for traders **18+** only. 🚫👶',
              'We don’t knowingly collect data from minors.',
            ]),
            _buildSection(context, '🔁 Updates', [
              'We keep things fresh! 💫',
              'If we change this policy, you’ll see a new “Last Updated” date above.',
            ]),
            _buildSection(context, '📩 Contact Us', [
              'Questions? Feedback? We’re all ears! 👂',
              '📧 Email: support@bullxchange.in',
              '🌐 Website: https://www.bullxchange.in',
            ]),
            const SizedBox(height: 20),
            // --- ⭐️ MODIFIED: Pass context ---
            _buildSummary(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // --- Meta Info Card ---
  Widget _buildMetaHeader(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme surface color ---
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // --- ⭐️ MODIFIED: Theme shadow color ---
            color: colorScheme.secondary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ⭐️ MODIFIED: Pass context ---
          _metaLine(context, '🗓️ Last Updated', '[Insert Date]'),
          _metaLine(
            context,
            '🏢 Developer',
            'BullXchange Technologies Pvt. Ltd.',
          ),
          _metaLine(context, '📧 Email', 'support@bullxchange.in'),
          _metaLine(context, '🌐 Website', 'https://www.bullxchange.in'),
        ],
      ),
    );
  }

  Widget _metaLine(BuildContext context, String label, String value) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          // --- ⭐️ MODIFIED: Theme grey color ---
          style: TextStyle(fontSize: 14, color: textTheme.bodySmall?.color),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                // --- ⭐️ MODIFIED: Theme primary color ---
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // --- Policy Section Card ---
  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> points,
  ) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme surface color ---
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        // --- ⭐️ MODIFIED: Theme divider color ---
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            // --- ⭐️ MODIFIED: Theme shadow color ---
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              // --- ⭐️ MODIFIED: Theme primary color ---
              color: colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...points.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Summary Gradient Card ---
  Widget _buildSummary(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // --- ⭐️ MODIFIED: Theme gradient colors ---
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            // --- ⭐️ MODIFIED: Theme shadow color ---
            color: colorScheme.secondary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ TL;DR',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We respect your hustle 💼 and your privacy 🔒. Your data is safe, never sold, and only used to make you a smarter trader. 📈',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }
}
