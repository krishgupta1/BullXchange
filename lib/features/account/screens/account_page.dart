import 'package:bullxchange/features/account/screens/edit_profile_page.dart';
import 'package:bullxchange/features/account/screens/faq_page.dart';
import 'package:bullxchange/features/account/screens/referralcodepage.dart';
import 'package:bullxchange/features/account/screens/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For StreamBuilder
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user
// import 'package:intl/intl.dart'; // Uncomment for advanced currency formatting

// ⭐️ IMPORT THE EDIT PROFILE PAGE

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get the current user's ID
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Handle case where user is not logged in
    if (userId == null) {
      return Scaffold(
        // --- ⭐️ MODIFIED: Theme background aur text color ---
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text(
            "Please log in to see your account.",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      // --- ⭐️ MODIFIED: Theme background color ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: _buildAppBar(context, userId),
      ),
      // --- Use StreamBuilder to listen for live data ---
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          // --- 1. Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          // --- 2. Handle Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          // --- 3. Handle No Data State ---
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "User data not found.",
                style: TextStyle(color: colorScheme.onSurface),
              ),
            );
          }

          // --- 4. We have data! ---
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'No Name';
          String email = userData['emailId'] ?? 'No Email';
          double balance = (userData['availableFunds'] ?? 0.0).toDouble();

          // Build the UI with the fetched data
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- ⭐️ MODIFIED: Pass context ---
                  _buildProfileHeader(context, name, email),
                  const SizedBox(height: 24),
                  // --- ⭐️ MODIFIED: Pass context ---
                  _buildWalletCard(context, balance),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReferralCodePage(),
                        ),
                      ),
                    },
                    // --- ⭐️ MODIFIED: Pass context ---
                    child: _buildReferralCard(context),
                  ),
                  const SizedBox(height: 24),
                  _buildOptionList(context),
                  const SizedBox(height: 24),
                  // --- ⭐️ MODIFIED: Pass context ---
                  _buildFeedbackCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the custom AppBar (Profile title and Edit button)
  Widget _buildAppBar(BuildContext context, String userId) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Container(
        // --- ⭐️ MODIFIED: Theme background color ---
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                // --- ⭐️ MODIFIED: Theme text color ---
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userId: userId),
                  ),
                );
              },
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  // --- ⭐️ MODIFIED: Theme accent color ---
                  color: colorScheme.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the user avatar, name, and email section
  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String getInitials(String name) {
      if (name.isEmpty) return '?';
      final parts = name.trim().split(' ');
      if (parts.isEmpty) return '?';
      String initials = parts[0][0];
      if (parts.length > 1) {
        initials += parts.last[0];
      }
      return initials.toUpperCase();
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          // --- ⭐️ MODIFIED: Theme color ---
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            getInitials(name),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              // --- ⭐️ MODIFIED: Theme color ---
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // --- ⭐️ MODIFIED: Theme text color ---
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              // --- ⭐️ MODIFIED: Theme grey color ---
              style: TextStyle(fontSize: 14, color: textTheme.bodySmall?.color),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the Wallet Balance card
  Widget _buildWalletCard(BuildContext context, double balance) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    String formattedBalance = '₹${balance.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme color ---
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            // --- ⭐️ MODIFIED: Theme color ---
            backgroundColor: colorScheme.primary,
            child: Icon(
              Icons.account_balance_wallet,
              // --- ⭐️ MODIFIED: Theme color ---
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  // --- ⭐️ MODIFIED: Theme text color ---
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedBalance,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  // --- ⭐️ MODIFIED: Theme color ---
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              // --- ⭐️ MODIFIED: Theme color ---
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              'Add Fund',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                // --- ⭐️ MODIFIED: Theme color ---
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Referral Code card
  Widget _buildReferralCard(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme-aware green ---
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            // --- ⭐️ MODIFIED: Theme color ---
            backgroundColor: colorScheme.secondary,
            child: Icon(
              Icons.card_giftcard,
              // --- ⭐️ MODIFIED: Theme color ---
              color: colorScheme.onSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referral Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    // --- ⭐️ MODIFIED: Theme text color ---
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share your friend get \$20 of free stocks',
                  // --- ⭐️ MODIFIED: Theme grey color ---
                  style: TextStyle(
                    fontSize: 13,
                    color: textTheme.bodySmall?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of options (Billing, Settings, FAQ)
  Widget _buildOptionList(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme surface color ---
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildOptionItem(
            context, // ⭐️ Pass context
            icon: Icons.payment,
            // --- ⭐️ MODIFIED: Theme color ---
            color: colorScheme.secondary, // Pink/Red
            text: 'Billing/Payment',
            onTap: () {},
          ),
          // --- ⭐️ MODIFIED: Theme divider color ---
          Divider(
            height: 24,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          _buildOptionItem(
            context, // ⭐️ Pass context
            icon: Icons.settings,
            // --- ⭐️ MODIFIED: Theme color ---
            color: colorScheme.primary, // Blue
            text: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          // --- ⭐️ MODIFIED: Theme divider color ---
          Divider(
            height: 24,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          _buildOptionItem(
            context, // ⭐️ Pass context
            icon: Icons.quiz,
            // --- ⭐️ MODIFIED: Accent color ---
            color: Colors.orange, // Orange
            text: 'FAQ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FaqPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Reusable widget for a single item in the options list
  /// Reusable widget for a single item in the options list
  Widget _buildOptionItem(
    BuildContext context, { // --- ⭐️ FIX: 'context' yahaan add kiya ---
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                // --- ⭐️ MODIFIED: Theme text color ---
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            // --- ⭐️ MODIFIED: Theme icon color ---
            Icon(
              Icons.arrow_forward_ios,
              color: textTheme.bodySmall?.color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "We'd love to hear" feedback card
  Widget _buildFeedbackCard(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // --- ⭐️ MODIFIED: Theme color ---
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            // --- ⭐️ MODIFIED: Theme color ---
            backgroundColor: colorScheme.onPrimary,
            child: Icon(
              Icons.headphones,
              // --- ⭐️ MODIFIED: Theme color ---
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "We'd love to hear your feedback!",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                // --- ⭐️ MODIFIED: Theme color ---
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          // --- ⭐️ MODIFIED: Theme color ---
          Icon(Icons.arrow_forward_ios, color: colorScheme.onPrimary, size: 16),
        ],
      ),
    );
  }
}
