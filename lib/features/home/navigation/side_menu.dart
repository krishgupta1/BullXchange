import 'package:bullxchange/features/auth/screens/onboarding_page_1.1.dart';
import 'package:bullxchange/features/account/screens/faq_page.dart';
import 'package:bullxchange/features/account/screens/referralcodepage.dart';
import 'package:bullxchange/features/account/screens/settings_page.dart';
import 'package:bullxchange/models/user_profile_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/provider/theme_provider.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String _selectedMenuTitle = "Home";

  void onMenuPress(BuildContext context, String title) {
    Navigator.pop(context);
    if (title == "Home") {
      setState(() {
        _selectedMenuTitle = title;
      });
      return;
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      switch (title) {
        case 'Refer a Friend':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReferralCodePage()),
          );
          break;
        case 'Settings':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
          break;
        case 'Help & FAQ':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaqPage()),
          );
          break;
        case 'Logout':
          _showLogoutDialog(context);
          break;
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text('Logout', style: theme.textTheme.titleLarge),
          ],
        ),
        content: Text(
          'Are you sure you want to log out from your account?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: theme.disabledColor)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Logout'),
            onPressed: () {
              Navigator.of(ctx).pop();
              FirebaseAuth.instance.signOut();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProfile = Provider.of<UserProfileDataModel?>(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      constraints: const BoxConstraints(maxWidth: 288),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Modern Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile?.name ?? "Guest User",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile?.emailId ?? "Welcome back",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Divider ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: theme.dividerColor.withOpacity(0.1)),
            ),
            const SizedBox(height: 16),

            // --- Menu Sections ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    MenuButtonSection(
                      title: "BROWSE",
                      selectedTitle: _selectedMenuTitle,
                      onMenuPress: (title) => onMenuPress(context, title),
                      menuItems: const [
                        {
                          'title': 'Home',
                          'icon': Icons.space_dashboard_rounded,
                        },
                        {
                          'title': 'Refer a Friend',
                          'icon': Icons.card_giftcard_rounded,
                        },
                      ],
                    ),
                    MenuButtonSection(
                      title: "HELP & SETTINGS",
                      selectedTitle: _selectedMenuTitle,
                      onMenuPress: (title) => onMenuPress(context, title),
                      menuItems: const [
                        {'title': 'Settings', 'icon': Icons.settings_rounded},
                        {
                          'title': 'Help & FAQ',
                          'icon': Icons.help_center_rounded,
                        },
                      ],
                    ),

                    // --- Enhanced Theme Switcher ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.05),
                          ),
                        ),
                        child: Consumer<ThemeNotifier>(
                          builder: (context, themeNotifier, child) {
                            final bool isDarkMode =
                                themeNotifier.themeMode == ThemeMode.dark;
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.amber.withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDarkMode
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    color: isDarkMode
                                        ? Colors.amber
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    isDarkMode ? "Dark Mode" : "Light Mode",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: isDarkMode,
                                    activeTrackColor: colorScheme.primary,
                                    onChanged: (value) {
                                      themeNotifier.setThemeMode(
                                        value
                                            ? ThemeMode.dark
                                            : ThemeMode.light,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    MenuButtonSection(
                      title: "ACCOUNT",
                      selectedTitle: _selectedMenuTitle,
                      onMenuPress: (title) => onMenuPress(context, title),
                      menuItems: const [
                        {'title': 'Logout', 'icon': Icons.logout_rounded},
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuButtonSection extends StatelessWidget {
  const MenuButtonSection({
    super.key,
    required this.title,
    required this.menuItems,
    this.selectedTitle = "Home",
    this.onMenuPress,
  });

  final String title;
  final String selectedTitle;
  final List<Map<String, dynamic>> menuItems;
  final Function(String title)? onMenuPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 32,
            right: 24,
            top: 24,
            bottom: 12,
          ),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var item in menuItems) ...[
                MenuRow(
                  title: item['title']!,
                  icon: item['icon']!,
                  isSelected: selectedTitle == item['title'],
                  onMenuPress: () => onMenuPress!(item['title']!),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onMenuPress,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onMenuPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Background Animation
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          height: 56,
          // Dynamically sized to fit parent margins (288 width - 32 margin = 256 approx)
          width: isSelected ? 256 : 0,
          left: 0,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        // Content
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onMenuPress,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? Colors.white
                        : theme.iconTheme.color?.withOpacity(0.7),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                      fontSize: 16,
                      fontFamily: "Inter",
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
