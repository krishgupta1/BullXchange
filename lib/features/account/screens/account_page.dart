import 'package:bullxchange/features/account/screens/add_fund.dart';
import 'package:bullxchange/features/account/screens/billing_payement_page.dart';
import 'package:bullxchange/features/account/screens/edit_profile_page.dart';
import 'package:bullxchange/features/account/screens/faq_page.dart';
import 'package:bullxchange/features/account/screens/referralcodepage.dart';
import 'package:bullxchange/features/account/screens/settings_page.dart';
import 'package:bullxchange/features/auth/screens/login_page.dart'; // ⭐️ Import Login Page
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  // --- ⭐️ LOGOUT FUNCTION ---
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 1. Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Log Out",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                "Log Out",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 3. Navigate to Login Page & Clear Stack (User can't go back)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error logging out: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: _buildAppBar(context, userId),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "User data not found.",
                style: TextStyle(color: colorScheme.onSurface),
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'No Name';
          String email = userData['emailId'] ?? 'No Email';
          double balance = (userData['availableFunds'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(context, name, email),
                  const SizedBox(height: 24),
                  _buildWalletCard(context, balance),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReferralCodePage(),
                        ),
                      );
                    },
                    child: _buildReferralCard(context),
                  ),
                  const SizedBox(height: 24),
                  _buildOptionList(context),
                  const SizedBox(height: 24),
                  _buildFeedbackCard(context),
                  const SizedBox(height: 20),

                  // --- ⭐️ NEW LOGOUT BUTTON ---
                  _buildLogoutButton(context),

                  const SizedBox(height: 40), // Extra space at bottom
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ... (Keep _buildAppBar, _buildProfileHeader, _buildWalletCard, _buildReferralCard as they were) ...
  // Paste your previous helper widgets here or keep them if they are in the file.

  // --- Re-pasting helper widgets for completeness ---

  Widget _buildAppBar(BuildContext context, String userId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Account',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
                  color: colorScheme.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
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
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            getInitials(name),
            style:
                Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ) ??
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletCard(BuildContext context, double balance) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String formattedBalance = '₹${balance.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primary,
            child: Icon(
              Icons.account_balance_wallet,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedBalance,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFundPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Add Fund',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.secondary,
            child: Icon(
              Icons.card_giftcard,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share your friend get \$20 of free stocks',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildOptionList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildOptionItem(
            context,
            icon: Icons.payment,
            color: colorScheme.secondary,
            text: 'Wallet History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundsHistoryPage(),
                ),
              );
            },
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          _buildOptionItem(
            context,
            icon: Icons.settings,
            color: colorScheme.primary,
            text: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),
          _buildOptionItem(
            context,
            icon: Icons.quiz,
            color: Colors.orange,
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

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
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
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
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

  Widget _buildFeedbackCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.onPrimary,
            child: Icon(Icons.headphones, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "We'd love to hear your feedback!",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: colorScheme.onPrimary, size: 16),
        ],
      ),
    );
  }

  // --- ⭐️ 6. NEW LOGOUT BUTTON WIDGET ---
  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _handleLogout(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Use Error color with low opacity for background
          color: colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: colorScheme.error, // ⭐️ Adaptive Red
            ),
            const SizedBox(width: 8),
            Text(
              "Log Out",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: colorScheme.error, // ⭐️ Adaptive Red
              ),
            ),
          ],
        ),
      ),
    );
  }
}
