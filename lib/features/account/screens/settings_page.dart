import 'package:bullxchange/features/account/screens/privacy_policy_page.dart';
import 'package:bullxchange/features/account/screens/terms_and_conditions_page.dart';
import 'package:bullxchange/features/auth/screens/reset_password_page.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:bullxchange/provider/theme_provider.dart';
import 'package:flutter/cupertino.dart';
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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    // Background color for the grouped sections
    final tileColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.grey.shade50;

    // Common background color for icons
    final iconBgColor = colorScheme.primary.withOpacity(0.1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          children: [
            // --- GENERAL SECTION ---
            _buildSectionHeader('General', textTheme),
            _buildGroupContainer(
              color: tileColor,
              children: [
                _buildSettingsTile(
                  title: 'Dark Mode',
                  icon: Icons.dark_mode_outlined,
                  iconColor: Colors.purple,
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
                  title: 'Notifications',
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.orange,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    setState(() {
                      _notificationsEnabled = !_notificationsEnabled;
                    });
                  },
                  trailing: CupertinoSwitch(
                    value: _notificationsEnabled,
                    activeTrackColor: colorScheme.primary,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ),
                _buildDivider(theme),
                _buildSettingsTile(
                  title: 'Contact Us',
                  icon: Icons.mail_outline,
                  iconColor: Colors.blue,
                  iconBgColor: iconBgColor,
                  onTap: () {
                    // Handle contact us logic here
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
                  icon: Icons.lock_outline,
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
                  icon: Icons.key_outlined,
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
                  subtitle: 'Choose what data you share with us',
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
                  title: 'Legal',
                  icon: Icons.gavel_outlined,
                  iconColor: Colors.indigo,
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

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
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
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60, // Indent to allow space for the icon
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textTheme.bodySmall?.color,
                ),
              ),
            )
          : null,

      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: textTheme.bodySmall?.color?.withOpacity(0.5),
            size: 18,
          ),
    );
  }
}
