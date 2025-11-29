import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
          'Terms & Conditions',
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

          // --- 1. No Real Trading ---
          _buildSection(
            context,
            'No Real Trading',
            Icons.money_off_rounded,
            Colors.redAccent,
            [
              '• BullXChange is a **paper trading simulation** app.',
              '• **No real stocks** are bought or sold.',
              '• The app is NOT linked to any broker, exchange, or demat service.',
              '• We are NOT a SEBI-registered advisor or intermediary.',
            ],
          ),

          // --- 2. Virtual Currency Rules ---
          _buildSection(
            context,
            'Virtual Currency Rules',
            Icons.monetization_on_rounded,
            Colors.amber,
            [
              '• Virtual coins are **NOT real money**.',
              '• UPI top-ups only add **practice credits** to your virtual wallet.',
              '• Virtual coins cannot be **withdrawn, resold, converted, or refunded**.',
              '• Profits and losses in the app are **virtual** and have no real financial value.',
            ],
          ),

          // --- 3. No Investment Advice ---
          _buildSection(
            context,
            'No Investment Advice',
            Icons.campaign_rounded,
            Colors.blueAccent,
            [
              '• The app does **NOT** provide investment advice, stock tips, or buy/sell recommendations.',
              '• All trading decisions are your own responsibility.',
              '• Use this platform strictly for **education & practice**.',
            ],
          ),

          // --- 4. Market Data ---
          _buildSection(
            context,
            'Market Data Accuracy',
            Icons.bar_chart_rounded,
            Colors.purpleAccent,
            [
              '• Market data is simulated based on real Indian stock market trends.',
              '• Prices may be **delayed** or slightly different from real-time markets.',
              '• BullXChange is not responsible for data accuracy or interruptions.',
            ],
          ),

          // --- 5. Limitation of Liability ---
          _buildSection(
            context,
            'Limitation of Liability',
            Icons.gavel_rounded,
            Colors.orangeAccent,
            [
              'BullXChange is NOT liable for:',
              '• Virtual losses incurred during simulation.',
              '• Technical issues, system delays, or data errors.',
              '• Any decisions made in real-life trading based on app usage.',
            ],
          ),

          // --- 6. Educational Purpose Only ---
          _buildSection(
            context,
            'Educational Purpose',
            Icons.school_rounded,
            Colors.teal,
            [
              '• The sole purpose of BullXChange is **learning & practice**.',
              '• It is designed to help you understand market dynamics without financial risk.',
            ],
          ),

          // --- 7. Updates & Contact ---
          _buildSection(
            context,
            'Updates & Contact',
            Icons.update_rounded,
            Colors.indigoAccent,
            [
              '• Terms may be updated from time to time.',
              '• Changes will be reflected in the app.',
              '',
              '📧 For support: **support@bullxchange.in**',
            ],
          ),

          const SizedBox(height: 20),
          _buildSummary(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Meta Info Card ---
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
              Icon(Icons.description_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Legal Information",
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metaLine(context, 'Last Updated', 'November 2025'),
          _metaLine(context, 'Entity', 'BullXChange'),
          _metaLine(context, 'Jurisdiction', 'India 🇮🇳'),
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

  // --- Section Card ---
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
              Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Acceptance',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'By using BullXChange, you acknowledge that all trading is simulated and involves NO real money. Happy Learning! 🚀',
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
