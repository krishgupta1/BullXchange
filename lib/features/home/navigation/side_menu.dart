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
        backgroundColor: colorScheme.surface,
        title: Text('Logout', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('Logout', style: TextStyle(color: colorScheme.error)),
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
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile?.name ?? "Guest User",
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontFamily: "Inter",
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userProfile?.emailId ?? "",
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                            fontFamily: "Inter",
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

            // --- Menu Sections ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    MenuButtonSection(
                      title: "BROWSE",
                      selectedTitle: _selectedMenuTitle,
                      onMenuPress: (title) => onMenuPress(context, title),
                      menuItems: const [
                        {'title': 'Home', 'icon': Icons.home_rounded},
                        {
                          'title': 'Refer a Friend',
                          'icon': Icons.card_giftcard_rounded,
                        },
                      ],
                    ),
                    MenuButtonSection(
                      title: "HELP",
                      selectedTitle: _selectedMenuTitle,
                      onMenuPress: (title) => onMenuPress(context, title),
                      menuItems: const [
                        {'title': 'Settings', 'icon': Icons.settings_rounded},
                        {
                          'title': 'Help & FAQ',
                          'icon': Icons.help_outline_rounded,
                        },
                      ],
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

            // --- Theme Toggle ---
            Consumer<ThemeNotifier>(
              builder: (context, themeNotifier, child) {
                final bool isDarkMode =
                    themeNotifier.themeMode == ThemeMode.dark;

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.brightness_6_outlined,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Theme",
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      CupertinoSwitch(
                        value: isDarkMode,
                        activeTrackColor: colorScheme.primary,
                        onChanged: (value) {
                          themeNotifier.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
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
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 8,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: textTheme.bodySmall?.color,
              fontSize: 12,
              fontFamily: "Inter",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (var item in menuItems) ...[
                MenuRow(
                  title: item['title']!,
                  icon: item['icon']!,
                  isSelected: selectedTitle == item['title'],
                  onMenuPress: () => onMenuPress!(item['title']!),
                ),
                // --- ⭐️ NO DIVIDER HERE ---
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

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          height: 48,
          width: isSelected ? 272 : 0,
          left: 0,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        InkWell(
          onTap: onMenuPress,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface,
                    fontSize: 15,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
