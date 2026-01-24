import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

// --- ⭐️ FIX: Class name matched with file ---
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

// --- ⭐️ FIX: Class name matched with file ---
class _FaqPageState extends State<FaqPage> {
  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Get theme colors ---
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
        // Optional: Add title if needed, otherwise kept empty as per design
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
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.help_outline_rounded,
                          size: 60,
                          color: colorScheme.primary,
                        ),
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
                  // ⭐️ UPDATED: Standard Headline Size
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                          : colorScheme.primary.withValues(alpha: 0.1),
                      iconColor: theme.brightness == Brightness.light
                          ? const Color(0xFF5B71DA)
                          : colorScheme.primary,
                      onTap: () {
                        // TODO: Implement filtering or navigation for "Getting Started"
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildTopicCard(
                      context, // ⭐️ Pass context
                      icon: Icons.insights_outlined,
                      text: 'Questions about\nHow to Invest',
                      // --- ⭐️ MODIFIED: Dynamic colors ---
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFE6FFF2)
                          : Colors.green.withValues(alpha: 0.1),
                      iconColor: theme.brightness == Brightness.light
                          ? const Color(0xFF1E8D5F)
                          : Colors.green,
                      onTap: () {
                        // TODO: Implement filtering or navigation for "How to Invest"
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildTopicCard(
                      context, // ⭐️ Pass context
                      icon: Icons.credit_card_outlined,
                      text: 'Questions about\nPayments',
                      // --- ⭐️ MODIFIED: Dynamic colors ---
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFFFF0F5)
                          : colorScheme.secondary.withValues(alpha: 0.1),
                      iconColor: theme.brightness == Brightness.light
                          ? const Color(0xFFDA5B71)
                          : colorScheme.secondary,
                      onTap: () {
                        // TODO: Implement filtering or navigation for "Payments"
                      },
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
                    // ⭐️ UPDATED: Standard Section Header
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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
    VoidCallback? onTap, // ⭐️ Added onTap callback
  }) {
    // --- ⭐️ Get theme colors ---
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap, // ⭐️ Handle tap
      child: Container(
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
                  fontSize: 12, // ⭐️ UPDATED: 10 -> 12
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
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
          'What is BullXChange?',
          'BullXChange is a paper trading simulation app where users can practice stock market trading using virtual currency.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is this real trading?',
          'No. The app does not have real trading, DEMAT linking, or brokerage operations.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'What is virtual currency?',
          'The funds you get in the app are 100% virtual. They have no real monetary value.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Can I top-up virtual currency?',
          'Yes. When balance runs out, users can top-up virtual credits through UPI. \n\n⚠️ Virtual currency is non-withdrawable, non-refundable, and non-convertible.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Are stock prices real?',
          'Price simulation based on real Indian stock market data is used (slight delay possible).',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Do I need a DEMAT account?',
          'No. This is only for educational purposes.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Can I withdraw my virtual profits?',
          'No. All profits/losses are virtual.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is BullXChange linked to any broker?',
          'No. The app is not affiliated with any brokerage firms or trading platforms.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is my data safe?',
          'Yes. We keep personal data secure and do not sell it to third parties.',
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
    // --- ⭐️ Get theme colors ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent, // Use theme divider color
      ),
      child: ExpansionTile(
        key: PageStorageKey(title),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16, // ⭐️ UPDATED: 10 -> 16 (Standard List Title)
            // --- ⭐️ MODIFIED: Theme text color ---
            color: colorScheme.onSurface,
          ),
        ),
        initiallyExpanded: title == 'What is BullXChange?',
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
                  size: 24, // ⭐️ UPDATED: 20 -> 24
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
              // --- ⭐️ MODIFIED: Theme text color (slightly lighter) ---
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 14, // ⭐️ UPDATED: 10 -> 14 (Standard Body)
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
