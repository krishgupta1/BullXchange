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
    // Get the current user's ID
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Handle case where user is not logged in
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see your account.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        // ⭐️ Pass userId to the AppBar builder
        child: _buildAppBar(context, userId),
      ),
      // --- Use StreamBuilder to listen for live data ---
      body: StreamBuilder<DocumentSnapshot>(
        // !! IMPORTANT !!
        // Adjust 'users' if your collection name is different
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          // --- 1. Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- 2. Handle Error State ---
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          // --- 3. Handle No Data State ---
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found."));
          }

          // --- 4. We have data! ---
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // !! IMPORTANT !!
          // Adjust field names ('name', 'email', 'walletBalance')
          // to match your Firestore document exactly.
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
                  // Pass data to helper widgets
                  _buildProfileHeader(name, email),
                  const SizedBox(height: 24),
                  _buildWalletCard(balance),
                  const SizedBox(height: 16),
                  // ⭐️ Pass context for navigation
                  GestureDetector(
                    onTap: () => {
                      // Navigate to EditProfilePage on tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReferralCodePage(),
                        ),
                      ),
                    },
                    child: _buildReferralCard(),
                  ),
                  const SizedBox(height: 24),
                  //
                  // --- ⭐️ FIX WAS HERE ---
                  //
                  // Before (Error): _buildOptionList(BuildContext context),
                  // After (Fixed): Pass the 'context' variable that
                  //                comes from the StreamBuilder's builder.
                  //
                  _buildOptionList(context),
                  //
                  // --- ⭐️ END OF FIX ---
                  //
                  const SizedBox(height: 24),
                  _buildFeedbackCard(),
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
  /// ⭐️ Now takes context and userId
  Widget _buildAppBar(BuildContext context, String userId) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            TextButton(
              onPressed: () {
                // ⭐️ UPDATED NAVIGATION
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(userId: userId),
                  ),
                );
              },
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Color(0xFFE94560),
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
  /// --- Now accepts name and email as parameters ---
  Widget _buildProfileHeader(String name, String email) {
    // --- Helper function to get initials from a name ---
    String getInitials(String name) {
      if (name.isEmpty) return '?';
      final parts = name.trim().split(' ');
      if (parts.isEmpty) return '?';

      String initials = parts[0][0]; // First letter of the first name
      if (parts.length > 1) {
        initials += parts.last[0]; // First letter of the last name
      }
      return initials.toUpperCase();
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: const Color(0xFFD2CFFF),
          // Show initials instead of a generic icon
          child: Text(
            getInitials(name),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A4AD4),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name, // <-- Use fetched name
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email, // <-- Use fetched email
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the Wallet Balance card
  /// --- Now accepts balance as a parameter ---
  Widget _buildWalletCard(double balance) {
    // Simple formatting, e.g., "₹1234.56"
    String formattedBalance = '₹${balance.toStringAsFixed(2)}';

    // --- Optional: For better currency formatting (e.g., "₹1,234.56") ---
    // final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    // String formattedBalance = currencyFormatter.format(balance);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF), // Light blue background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Wallet Icon
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFF0063F5),
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Balance Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed 'const' to use dynamic data
              const Text(
                'Wallet Balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formattedBalance, // <-- Use fetched balance
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0063F5),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Add Fund Button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A4AD4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: const Text(
              'Add Fund',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Referral Code card
  Widget _buildReferralCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBF0), // Light green background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Gift Icon
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE94560),
            child: Icon(Icons.card_giftcard, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Referral Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Share your friend get \$20 of free stocks',
                  style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildOptionItem(
            icon: Icons.payment,
            color: const Color(0xFFE94560),
            text: 'Billing/Payment',
            onTap: () {},
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F8)),
          _buildOptionItem(
            icon: Icons.settings,
            color: const Color(0xFF0063F5),
            text: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F8)),
          _buildOptionItem(
            icon: Icons.quiz,
            color: const Color(0xFFF5A623),
            text: 'FAQ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Reusable widget for a single item in the options list
  Widget _buildOptionItem({
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the "We'd love to hear" feedback card
  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF5A4AD4), // Dark purple background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.headphones, color: Color(0xFF5A4AD4), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "We'd love to hear your feedback!", // Simpler text
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}
