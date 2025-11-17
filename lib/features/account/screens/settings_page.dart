import 'package:bullxchange/features/account/screens/privacy_policy_page.dart';
import 'package:bullxchange/features/account/screens/terms_and_conditions_page.dart';
import 'package:bullxchange/features/auth/screens/reset_password_page.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:bullxchange/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // --- Theme se colors aur provider lo ---
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- ⭐️ YEH CHECK KAREGA KI DARK MODE ON HAI YA NAHI ---
    // (System mode ko 'light' maanega)
    final bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  // General Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'General',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  //
                  // --- ⭐️⭐️ YAHAN TOGGLE BUTTON LAGA DIYA HAI ⭐️⭐️ ---
                  //
                  _buildSettingsTile(
                    'Dark Mode',
                    onTap: () {
                      // Row pe click karne se bhi toggle hoga
                      themeNotifier.setThemeMode(
                        isDarkMode ? ThemeMode.light : ThemeMode.dark,
                      );
                    },
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (bool value) {
                        // Switch se toggle karne par
                        themeNotifier.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                      // activeColor AppTheme se automatically set ho jayega
                    ),
                  ),
                  // --- ⭐️⭐️ END OF SECTION ⭐️⭐️ ---

                  // --- NOTIFICATIONS TILE ---
                  _buildSettingsTile(
                    'Notifications',
                    onTap: () {
                      setState(() {
                        _notificationsEnabled = !_notificationsEnabled;
                      });
                    },
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      // --- MERGE CONFLICT RESOLVED ---
                      // Removed the hardcoded 'activeThumbColor: Colors.pink'
                      // to allow the theme to control the switch color.
                    ),
                  ),

                  _buildSettingsTile(
                    'Contact Us',
                    onTap: () {
                      // Handle contact us tap
                    },
                  ),
                  const SizedBox(height: 30),

                  // Security Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    'Change Login PIN',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SetupPinScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Privacy & Legal Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Privacy & Legal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    'Privacy Policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                    subtitle: 'Choose what data you share with us',
                  ),
                  _buildSettingsTile(
                    'Legal',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndConditionsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Footer text
            Text(
              '© 2025 BullXchange • Ver 1.0',
              style: TextStyle(
                color: textTheme.bodySmall?.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget (Ab theme se color lega)
  // Helper widget (Ab theme se color lega)
  Widget _buildSettingsTile(
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'EudoxusSans',
              fontSize: 18,
              // --- ⭐️⭐️ FIX: 'onSurface' (Black/White) ko 'primary' (Blue) kar diya ---
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'EudoxusSans',
                    fontSize: 13,
                    color: textTheme.bodySmall?.color, // Yeh grey hi rahega
                  ),
                )
              : null,
          trailing:
              trailing ??
              Icon(
                Icons.arrow_forward_ios,
                color: textTheme.bodySmall?.color, // Yeh bhi grey rahega
                size: 18,
              ),
          onTap: onTap,
        ),
      ],
    );
  }
}
