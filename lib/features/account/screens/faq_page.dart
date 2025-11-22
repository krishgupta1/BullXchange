import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

// --- ⭐️ FIX: Class ka naam file se match kiya ---
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

// --- ⭐️ FIX: Class ka naam file se match kiya ---
class _FaqPageState extends State<FaqPage> {
  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image/Icon
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      // --- ⭐️ MODIFIED: Theme surface color ---
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/FAQ.png',
                        height: 70,
                        width: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // "How can we help you?" Text
              Center(
                child: Text(
                  'How can we help you?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  // --- ⭐️ MODIFIED: Theme surface color ---
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search topics or questions...',
                    // --- ⭐️ MODIFIED: Theme hint color ---
                    hintStyle: TextStyle(color: textTheme.bodySmall?.color),
                    prefixIcon: Icon(
                      Icons.search,
                      // --- ⭐️ MODIFIED: Theme hint color ---
                      color: textTheme.bodySmall?.color,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Horizontal Topic Cards
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTopicCard(
                      context, // ⭐️ Pass context
                      icon: Icons.notifications_none_rounded,
                      text: 'Questions about\nGetting Started',
                      // --- ⭐️ MODIFIED: Dynamic colors ---
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFF0F5FF)
                          : colorScheme.primary.withOpacity(0.1),
                      iconColor: theme.brightness == Brightness.light
                          ? const Color(0xFF5B71DA)
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildTopicCard(
                      context, // ⭐️ Pass context
                      icon: Icons.insights_outlined,
                      text: 'Questions about\nHow to Invest',
                      // --- ⭐️ MODIFIED: Dynamic colors ---
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFE6FFF2)
                          : Colors.green.withOpacity(0.1),
                      iconColor: theme.brightness == Brightness.light
                          ? const Color(0xFF1E8D5F)
                          : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildTopicCard(
                      context, // ⭐️ Pass context
                      icon: Icons.credit_card_outlined,
                      text: 'Questions about\nPayments',
                      // --- ⭐️ MODIFIED: Dynamic colors ---
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFFFF0F5)
                          : colorScheme.secondary.withOpacity(0.1),
                      iconColor: theme.brightness == Brightness.light
                          ? const Color(0xFFDA5B71)
                          : colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // "Top Questions" Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Questions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      // --- ⭐️ MODIFIED: Theme text color ---
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View all',
                      style: TextStyle(
                        // --- ⭐️ MODIFIED: Theme accent color ---
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // FAQ List
              _buildFaqList(context), // ⭐️ Pass context
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the horizontal topic cards
  Widget _buildTopicCard(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required Color iconColor,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color, // Color ab dynamic hai
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 30), // Icon color dynamic hai
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                // --- ⭐️ MODIFIED: Theme text color ---
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the FAQ list
  Widget _buildFaqList(BuildContext context) {
    // ⭐️ Added context
    return Column(
      children: [
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'How to create a account?',
          'Open the Tradebase app to get started and follow the steps. Tradebase doesn\'t charge a fee to create or maintain your Tradebase account.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'How to add a payment method?',
          'You can add a payment method by navigating to your "Wallet" or "Profile" section and selecting "Add Payment Method". We support various options including bank transfers and debit/credit cards.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is Tradebase secure?',
          'Yes, Tradebase uses industry-standard encryption and security protocols to protect your data and transactions. Your security is our top priority.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'What is KYC verification?',
          'KYC (Know Your Customer) verification is a mandatory process to verify your identity. This helps us comply with financial regulations and ensures a safe trading environment for everyone.',
        ),
      ],
    );
  }

  // Helper widget for a single FAQ item with +/- icons
  Widget _buildExpansionTile(
    BuildContext context,
    String title,
    String answer,
  ) {
    // ⭐️ Added context
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent, // Theme ka divider color use kiya
      ),
      child: ExpansionTile(
        key: PageStorageKey(title),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            // --- ⭐️ MODIFIED: Theme text color ---
            color: colorScheme.onSurface,
          ),
        ),
        initiallyExpanded: title == 'How to create a account?',
        trailing: Builder(
          builder: (context) {
            final ExpansibleController controller = ExpansibleController.of(
              context,
            );
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Icon(
                  controller.isExpanded ? Icons.remove : Icons.add,
                  // --- ⭐️ MODIFIED: Theme colors ---
                  color: controller.isExpanded
                      ? colorScheme
                            .secondary // Pink
                      : textTheme.bodySmall?.color, // Grey
                  size: 20,
                );
              },
            );
          },
        ),
        tilePadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        childrenPadding: const EdgeInsets.only(
          bottom: 16.0,
          top: 0,
          left: 0,
          right: 0,
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              // --- ⭐️ MODIFIED: Theme text color (thoda halka) ---
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
