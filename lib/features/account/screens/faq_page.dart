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
                          : Colors.green.withOpacity(0.1),
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
                          : colorScheme.secondary.withOpacity(0.1),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          // --- ⭐️ MODIFIED: Theme text color ---
                          color: colorScheme.onSurface,
                        ),
                  ),
                  // ⭐️ REMOVED: "View all" TextButton
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
    // --- ⭐️ Theme se colors lo ---
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
                  fontSize: 10,
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
          'BullXChange ek paper trading simulation app hai jisme users stock market trading ka practice kar sakte hain using virtual currency.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is this real trading?',
          'Nahi. App me real trading, demat linking, ya brokerage operations nahi hote.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'What is virtual currency?',
          'App ke andar jo funds milte hain woh 100% virtual hote hain. Inka koi real monetary value nahi hota.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Can I top-up virtual currency?',
          'Haan. Jab balance khatam ho jaye, users UPI ke through virtual credits top-up kar sakte hain. \n\n⚠️ Virtual currency non-withdrawable, non-refundable, aur non-convertible hoti hai.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Are stock prices real?',
          'Real Indian stock market data par based price simulation use hota hai (slight delay possible).',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Do I need a Demat account?',
          'Nahi. Ye sirf educational purpose ke liye hai.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Can I withdraw my virtual profits?',
          'Nahi. Saare profits/losses virtual hote hain.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is BullXChange linked to any broker?',
          'Nahi. App Groww, Angel One, Zerodha, Upstox ya kisi broker se affiliated nahi hai.',
        ),
        _buildExpansionTile(
          context, // ⭐️ Pass context
          'Is my data safe?',
          'Haan. Hum personal data ko secure rakhte hain aur third parties ko sell nahi karte.',
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
            fontSize: 10,
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
                      ? colorScheme.secondary // Pink
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
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}



