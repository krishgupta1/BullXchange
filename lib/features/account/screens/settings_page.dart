import 'package:bullxchange/features/account/screens/contact_us_page.dart';
import 'package:bullxchange/features/account/screens/privacy_policy_page.dart';
import 'package:bullxchange/features/account/screens/terms_and_conditions_page.dart';
import 'package:bullxchange/features/auth/screens/reset_password_page.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:bullxchange/provider/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    // Background color for the grouped sections
    final tileColor = theme.cardColor;

    // Common background color for icons
    final iconBgColor = colorScheme.surfaceContainerHighest.withOpacity(0.4);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          children: [
            // --- GENERAL SECTION ---
            _buildSectionHeader('General', textTheme),
            _buildGroupContainer(
              color: tileColor,
              children: [
                _buildSettingsTile(
                  title: 'Dark Mode',
                  icon: isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: isDarkMode ? Colors.purpleAccent : Colors.orange,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    themeNotifier.setThemeMode(
                      isDarkMode ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                  trailing: CupertinoSwitch(
                    value: isDarkMode,
                    activeTrackColor: colorScheme.primary,
                    onChanged: (bool value) {
                      themeNotifier.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ),
                _buildDivider(theme),
                _buildSettingsTile(
                  title: 'Contact Us',
                  icon: Icons.mail_outline_rounded,
                  iconColor: Colors.blueAccent,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactUsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- SECURITY SECTION ---
            _buildSectionHeader('Security', textTheme),
            _buildGroupContainer(
              color: tileColor,
              children: [
                _buildSettingsTile(
                  title: 'Change Login PIN',
                  icon: Icons.lock_outline_rounded,
                  iconColor: Colors.teal,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SetupPinScreen()),
                    );
                  },
                ),
                _buildDivider(theme),
                _buildSettingsTile(
                  title: 'Change Password',
                  icon: Icons.vpn_key_outlined,
                  iconColor: Colors.redAccent,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- PRIVACY SECTION ---
            _buildSectionHeader('Privacy & Legal', textTheme),
            _buildGroupContainer(
              color: tileColor,
              children: [
                _buildSettingsTile(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.green,
                  iconBgColor: iconBgColor,
                  subtitle: 'Usage & data policies',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                _buildDivider(theme),
                _buildSettingsTile(
                  title: 'Terms & Conditions',
                  icon: Icons.description_outlined,
                  iconColor: Colors.indigoAccent,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndConditionsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- FOOTER ---
            Column(
              children: [
                Text(
                  'BullXchange',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: textTheme.bodySmall?.color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        // Subtle shadow for better separation
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60, // Indent to align with text start
      endIndent: 0,
      color: theme.dividerColor.withOpacity(0.1),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      // Leading Icon Box
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),

      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: textTheme.bodySmall?.color,
                ),
              ),
            )
          : null,

      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: textTheme.bodySmall?.color?.withOpacity(0.4),
            size: 16,
          ),
    );
  }
}
