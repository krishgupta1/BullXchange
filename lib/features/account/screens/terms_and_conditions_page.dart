import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  // --- ⭐️ REMOVED HARDCODED COLORS ---

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const CustomBackButton(),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Container(
        // --- ⭐️ MODIFIED: Gradient hata diya ---
        // (Ab page background theme se aa raha hai)
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMetaHeader(context), // ⭐️ Pass context
            const SizedBox(height: 20),

            _buildSection(context, '✅ Acceptance of Terms', [
              // ⭐️ Pass context
              'By downloading or using BullXchange 📱, you agree to our Terms & Conditions and Privacy Policy.',
              'If you disagree 🚫, kindly stop using the app immediately.',
            ]),
            _buildSection(context, '📊 About BullXchange', [
              // ⭐️ Pass context
              'BullXchange is your **virtual stock market dojo** 🥋 — a paper-trading and learning platform to help you practice without losing real money.',
              'Everything inside the app is simulated 💸 — no real trading happens here.',
            ]),
            _buildSection(context, '🧒 Eligibility', [
              // ⭐️ Pass context
              'You must be **18 years or older** to join the BullXchange community.',
              'Using the app means you meet this age requirement and accept our rules. 🤝',
            ]),
            _buildSection(context, '⚙️ How You Can Use the App', [
              // ⭐️ Pass context
              'By using BullXchange, you agree to:',
              '• 📚 Use it only for learning & non-commercial purposes',
              '• 🧾 Provide accurate info while signing up',
              '• 🚫 Avoid illegal or harmful activities',
              '• 🛠️ Not hack, copy, or reverse-engineer any part of the app',
              'We may suspend or block users who break these rules 🚷',
            ]),
            _buildSection(context, '🎮 Virtual Trading Disclaimer', [
              // ⭐️ Pass context
              '• 💱 All trades are simulated — no real money or stock exchange involved',
              '• 📈 Portfolio and P&L numbers are for **education only**',
              '• ⚠️ We don’t guarantee 100% accuracy of stock data or charts',
              '• 🧾 BullXchange is **not** a SEBI-registered broker or advisor',
            ]),
            _buildSection(context, '🤖 AI Insights & Education', [
              // ⭐️ Pass context
              'Our AI gives you tips, stats, and insights 🧠 — but they’re for **learning only**.',
              'Never treat them as financial advice or use them for real trading decisions 💡.',
            ]),
            _buildSection(context, '💎 Premium Features', [
              // ⭐️ Pass context
              'Some cool tools & AI perks are part of **premium plans** 💰.',
              '• Plans & pricing will be shown clearly before purchase',
              '• Payments are managed by Google Play / App Store',
              '• Refunds only follow respective platform policies',
            ]),
            _buildSection(context, '🎁 Referral & Rewards', [
              // ⭐️ Pass context
              'Invite friends ➕ Earn virtual perks 🪙',
              'All rewards (extra funds, premium trials) are **virtual** — no real cash value.',
              'We can tweak or remove referral rewards anytime 🔄.',
            ]),
            _buildSection(context, '🧠 Intellectual Property', [
              // ⭐️ Pass context
              'All content (logos, UI, code, analytics) belongs to **BullXchange Technologies Pvt. Ltd.** 💼',
              'Please don’t copy or modify any part without our permission 🚫',
            ]),
            _buildSection(context, '⚖️ Limitation of Liability', [
              // ⭐️ Pass context
              'We’re not responsible for:',
              '• 💸 Any financial or learning losses',
              '• 🕒 Delays or data errors from external sources',
              '• 🧾 Your real-life trading decisions based on app simulations',
              'Use BullXchange at your own discretion ⚡',
            ]),
            _buildSection(context, '🌐 Third-Party Integrations', [
              // ⭐️ Pass context
              'Sometimes we link to APIs or partner brokers 🏦.',
              'We don’t control their data policies or actions — read their terms before using them 📑.',
            ]),
            _buildSection(context, '🚪 Account Termination', [
              // ⭐️ Pass context
              'We may restrict or delete accounts if you:',
              '• ❌ Violate laws or our terms',
              '• 🔁 Misuse the referral system',
              '• 💥 Attempt to damage the app or its data',
            ]),
            _buildSection(context, '🔄 Updates', [
              // ⭐️ Pass context
              'We refresh our Terms every now and then 🗓️.',
              'The latest version will always be available on our website or in-app.',
            ]),
            _buildSection(context, '🇮🇳 Governing Law', [
              // ⭐️ Pass context
              'These Terms follow the laws of **India** 🇮🇳.',
              'Disputes fall under the jurisdiction of courts in [Insert City, e.g. Mumbai / Bengaluru].',
            ]),
            _buildSection(context, '📩 Contact Us', [
              // ⭐️ Pass context
              'Questions or concerns? Hit us up anytime 💌',
              '📧 support@bullxchange.in',
              '🏢 BullXchange Technologies Pvt. Ltd.',
            ]),
            _buildSection(context, '⚠️ Disclaimer', [
              // ⭐️ Pass context
              'BullXchange is a **learning simulation**, not a financial advisor 💬.',
              'No real money or earnings happen inside the app.',
              'Your decisions outside BullXchange are entirely your responsibility 💼.',
            ]),

            const SizedBox(height: 25),
            Divider(
              color: colorScheme.secondary.withOpacity(0.3),
              thickness: 1.2,
            ), // ⭐️ MODIFIED
            const SizedBox(height: 15),

            _buildSummaryCard(context), // ⭐️ Pass context
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
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaLine(
            context,
            '🗓️ Last Updated',
            '[Insert Date]',
          ), // ⭐️ Pass context
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
                fontWeight: FontWeight.bold,
                // --- ⭐️ MODIFIED: Theme primary color ---
                color: colorScheme.primary,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // --- Section Card ---
  Widget _buildSection(BuildContext context, String title, List<String> lines) {
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
              fontSize: 18,
              // --- ⭐️ MODIFIED: Theme primary color ---
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
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

  // --- TL;DR Summary Card ---
  Widget _buildSummaryCard(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme gradient ---
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            // --- ⭐️ MODIFIED: Theme shadow color ---
            color: colorScheme.primary.withOpacity(0.25),
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
          SizedBox(height: 10),
          Text(
            'We built BullXchange to help you trade smarter — safely. ⚡ Learn, test, and grow with **virtual money**, not real risk. 💹',
            style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }
}
