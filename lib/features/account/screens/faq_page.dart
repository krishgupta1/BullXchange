import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure the background is white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Updated: Top Image/Icon
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100], // Light grey background
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      // Replace this with your actual image asset
                      child: Image.asset(
                        'assets/images/FAQ.png', // <-- Make sure this path is correct
                        height: 70, // Adjust size as needed
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
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Updated: Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search topics or questions...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                    ), // Search icon as prefix
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Horizontal Topic Cards
              SizedBox(
                height: 120, // Maintain a fixed height for the cards
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTopicCard(
                      icon: Icons.notifications_none_rounded,
                      text:
                          'Questions about\nGetting Started', // Text adjusted for two lines
                      color: const Color(0xFFF0F5FF), // Light blue background
                      iconColor: const Color(0xFF5B71DA), // Darker blue icon
                    ),
                    const SizedBox(width: 12), // Space between cards
                    _buildTopicCard(
                      icon: Icons.insights_outlined, // Line graph icon
                      text:
                          'Questions about\nHow to Invest', // Text adjusted for two lines
                      color: const Color(0xFFE6FFF2), // Light green background
                      iconColor: const Color(0xFF1E8D5F), // Darker green icon
                    ),
                    const SizedBox(width: 12),
                    _buildTopicCard(
                      icon: Icons.credit_card_outlined, // Payment icon
                      text:
                          'Questions about\nPayments', // This card is off-screen as in the image
                      color: const Color(0xFFFFF0F5), // Light pink background
                      iconColor: const Color(0xFFDA5B71), // Darker pink icon
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
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: Colors.pink.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // FAQ List
              _buildFaqList(),
              const SizedBox(height: 20), // Padding at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the horizontal topic cards
  Widget _buildTopicCard({
    required IconData icon,
    required String text,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: 160, // Slightly wider cards to fit text
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 8),
          Flexible(
            // Ensures text wraps if it's too long
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
                height: 1.3, // Line height for multi-line text
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the FAQ list
  Widget _buildFaqList() {
    return Column(
      children: [
        _buildExpansionTile(
          'How to create a account?',
          'Open the Tradebase app to get started and follow the steps. Tradebase doesn\'t charge a fee to create or maintain your Tradebase account.',
        ),
        _buildExpansionTile(
          'How to add a payment method?',
          'You can add a payment method by navigating to your "Wallet" or "Profile" section and selecting "Add Payment Method". We support various options including bank transfers and debit/credit cards.',
        ),
        _buildExpansionTile(
          'Is Tradebase secure?',
          'Yes, Tradebase uses industry-standard encryption and security protocols to protect your data and transactions. Your security is our top priority.',
        ),
        _buildExpansionTile(
          'What is KYC verification?',
          'KYC (Know Your Customer) verification is a mandatory process to verify your identity. This helps us comply with financial regulations and ensures a safe trading environment for everyone.',
        ),
      ],
    );
  }

  // Helper widget for a single FAQ item with +/- icons
  Widget _buildExpansionTile(String title, String answer) {
    return Theme(
      data: ThemeData().copyWith(
        dividerColor: Colors.transparent,
      ), // Remove default divider
      child: ExpansionTile(
        key: PageStorageKey(
          title,
        ), // Important for state management if list is long
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        initiallyExpanded:
            title ==
            'How to create a account?', // Make this one expanded by default
        trailing: Builder(
          builder: (context) {
            final ExpansionTileController controller =
                ExpansionTileController.of(context);
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Icon(
                  controller.isExpanded ? Icons.remove : Icons.add,
                  color: controller.isExpanded
                      ? Colors.pink.shade400
                      : Colors.grey.shade600,
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
              color: Colors.black.withOpacity(0.7),
              fontSize: 14,
              height: 1.5, // Line height
            ),
          ),
        ],
      ),
    );
  }
}
