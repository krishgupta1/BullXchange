import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  static const Color kPrimaryBlue = Color(0xFF072A6C);
  static const Color kPrimaryPink = Colors.pink;
  static const Color kSecondaryGrey = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 4,
        shadowColor: kPrimaryPink.withOpacity(0.2),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8FAFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMetaHeader(),
            const SizedBox(height: 20),

            _buildSection('✅ Acceptance of Terms', [
              'By downloading or using BullXchange 📱, you agree to our Terms & Conditions and Privacy Policy.',
              'If you disagree 🚫, kindly stop using the app immediately.',
            ]),
            _buildSection('📊 About BullXchange', [
              'BullXchange is your **virtual stock market dojo** 🥋 — a paper-trading and learning platform to help you practice without losing real money.',
              'Everything inside the app is simulated 💸 — no real trading happens here.',
            ]),
            _buildSection('🧒 Eligibility', [
              'You must be **18 years or older** to join the BullXchange community.',
              'Using the app means you meet this age requirement and accept our rules. 🤝',
            ]),
            _buildSection('⚙️ How You Can Use the App', [
              'By using BullXchange, you agree to:',
              '• 📚 Use it only for learning & non-commercial purposes',
              '• 🧾 Provide accurate info while signing up',
              '• 🚫 Avoid illegal or harmful activities',
              '• 🛠️ Not hack, copy, or reverse-engineer any part of the app',
              'We may suspend or block users who break these rules 🚷',
            ]),
            _buildSection('🎮 Virtual Trading Disclaimer', [
              '• 💱 All trades are simulated — no real money or stock exchange involved',
              '• 📈 Portfolio and P&L numbers are for **education only**',
              '• ⚠️ We don’t guarantee 100% accuracy of stock data or charts',
              '• 🧾 BullXchange is **not** a SEBI-registered broker or advisor',
            ]),
            _buildSection('🤖 AI Insights & Education', [
              'Our AI gives you tips, stats, and insights 🧠 — but they’re for **learning only**.',
              'Never treat them as financial advice or use them for real trading decisions 💡.',
            ]),
            _buildSection('💎 Premium Features', [
              'Some cool tools & AI perks are part of **premium plans** 💰.',
              '• Plans & pricing will be shown clearly before purchase',
              '• Payments are managed by Google Play / App Store',
              '• Refunds only follow respective platform policies',
            ]),
            _buildSection('🎁 Referral & Rewards', [
              'Invite friends ➕ Earn virtual perks 🪙',
              'All rewards (extra funds, premium trials) are **virtual** — no real cash value.',
              'We can tweak or remove referral rewards anytime 🔄.',
            ]),
            _buildSection('🧠 Intellectual Property', [
              'All content (logos, UI, code, analytics) belongs to **BullXchange Technologies Pvt. Ltd.** 💼',
              'Please don’t copy or modify any part without our permission 🚫',
            ]),
            _buildSection('⚖️ Limitation of Liability', [
              'We’re not responsible for:',
              '• 💸 Any financial or learning losses',
              '• 🕒 Delays or data errors from external sources',
              '• 🧾 Your real-life trading decisions based on app simulations',
              'Use BullXchange at your own discretion ⚡',
            ]),
            _buildSection('🌐 Third-Party Integrations', [
              'Sometimes we link to APIs or partner brokers 🏦.',
              'We don’t control their data policies or actions — read their terms before using them 📑.',
            ]),
            _buildSection('🚪 Account Termination', [
              'We may restrict or delete accounts if you:',
              '• ❌ Violate laws or our terms',
              '• 🔁 Misuse the referral system',
              '• 💥 Attempt to damage the app or its data',
            ]),
            _buildSection('🔄 Updates', [
              'We refresh our Terms every now and then 🗓️.',
              'The latest version will always be available on our website or in-app.',
            ]),
            _buildSection('🇮🇳 Governing Law', [
              'These Terms follow the laws of **India** 🇮🇳.',
              'Disputes fall under the jurisdiction of courts in [Insert City, e.g. Mumbai / Bengaluru].',
            ]),
            _buildSection('📩 Contact Us', [
              'Questions or concerns? Hit us up anytime 💌',
              '📧 support@bullxchange.in',
              '🏢 BullXchange Technologies Pvt. Ltd.',
            ]),
            _buildSection('⚠️ Disclaimer', [
              'BullXchange is a **learning simulation**, not a financial advisor 💬.',
              'No real money or earnings happen inside the app.',
              'Your decisions outside BullXchange are entirely your responsibility 💼.',
            ]),

            const SizedBox(height: 25),
            Divider(color: kPrimaryPink.withOpacity(0.3), thickness: 1.2),
            const SizedBox(height: 15),

            _buildSummaryCard(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // --- Meta Info Card ---
  Widget _buildMetaHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryPink.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaLine('🗓️ Last Updated', '[Insert Date]'),
          _metaLine('🏢 Developer', 'BullXchange Technologies Pvt. Ltd.'),
          _metaLine('📧 Email', 'support@bullxchange.in'),
          _metaLine('🌐 Website', 'https://www.bullxchange.in'),
        ],
      ),
    );
  }

  Widget _metaLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: kSecondaryGrey),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryBlue,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // --- Section Card ---
  Widget _buildSection(String title, List<String> lines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.05),
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
            style: const TextStyle(
              fontSize: 18,
              color: kPrimaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
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
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryBlue, kPrimaryPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.25),
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
