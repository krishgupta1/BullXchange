import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const Color kPrimaryBlue = Color(0xFF072A6C);
  static const Color kPrimaryPink = Colors.pink;
  static const Color kSecondaryGrey = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: kPrimaryPink.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
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
            const SizedBox(height: 18),
            _buildSection('💡 Overview', [
              'BullXchange is your risk-free stock market playground! 📊',
              'We let you learn, test, and practice trading — all with **virtual money**. No fear. No loss. Just skill-building. 💪',
              'Your privacy matters. Here’s how we protect your data while you grow as a trader. 🛡️',
            ]),
            _buildSection('📥 What We Collect', [
              'We may collect some basic info to make your experience smooth:',
              '• 👤 Name, email, and phone number',
              '• 📈 Your simulated trades & portfolio data',
              '• 💻 Device info (model, OS, IP, crash logs)',
              '• 🎯 Referral data (if you were invited)',
              '⚙️ All trading activity here is **virtual** — nothing involves real money.',
            ]),
            _buildSection('🤖 How We Use Your Data', [
              'We use your info only to:',
              '• 🧠 Improve app performance & insights',
              '• 📊 Track your simulated portfolio',
              '• 🔔 Send trade updates or notifications',
              '• 🧾 Offer AI-based tips & feedback',
              '🚫 We never sell your data. Ever.',
            ]),
            _buildSection('🔗 Data Sharing', [
              'We only share when necessary:',
              '• 💼 With secure analytics or hosting providers',
              '• ⚖️ When required by Indian law',
              '• 🏦 With broker partners (only if YOU opt-in)',
            ]),
            _buildSection('🧱 Security First', [
              'We use 🔐 encryption (HTTPS), secure servers, and limited access.',
              'But remember — no internet system is 100% hack-proof. Stay smart. 🧠',
            ]),
            _buildSection('⚙️ Your Rights', [
              'You’re always in control:',
              '• ✏️ Edit or delete your account anytime',
              '• 💬 Withdraw consent when you wish',
              '• 📧 Mail us at support@bullxchange.in for help',
            ]),
            _buildSection('🧒 Minors', [
              'BullXchange is built for traders **18+** only. 🚫👶',
              'We don’t knowingly collect data from minors.',
            ]),
            _buildSection('🔁 Updates', [
              'We keep things fresh! 💫',
              'If we change this policy, you’ll see a new “Last Updated” date above.',
            ]),
            _buildSection('📩 Contact Us', [
              'Questions? Feedback? We’re all ears! 👂',
              '📧 Email: support@bullxchange.in',
              '🌐 Website: https://www.bullxchange.in',
            ]),
            const SizedBox(height: 20),
            _buildSummary(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // --- Meta Info Card ---
  Widget _buildMetaHeader() {
    return Container(
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
      padding: const EdgeInsets.all(16),
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
                color: kPrimaryBlue,
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
  Widget _buildSection(String title, List<String> points) {
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
              color: kPrimaryBlue,
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

  // --- Summary Gradient Card ---
  Widget _buildSummary() {
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
            color: kPrimaryPink.withOpacity(0.3),
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
