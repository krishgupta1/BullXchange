import 'package:bullxchange/features/account/screens/privacy_policy_page.dart';
import 'package:bullxchange/features/account/screens/terms_and_conditions_page.dart';
import 'package:bullxchange/features/auth/screens/reset_password_page.dart';
import 'package:bullxchange/features/auth/screens/setup_pin_screen.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // This state is for the Notification Switch
  bool _notificationsEnabled = true;

  // --- ⭐️ ADDED COLORS TO MATCH IMAGE ---
  static const Color kPrimaryBlue = Color(0xFF072A6C); // Dark blue from image
  static const Color kPrimaryPink = Colors.pink; // Pink/Purple from image
  static const Color kSecondaryGrey = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // --- MODIFIED --- (Changed color)
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryPink),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Settings',
          // --- MODIFIED --- (Changed color and size)
          style: TextStyle(
            color: kPrimaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'General',
                      // --- MODIFIED --- (Changed color and weight)
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // Less bold than titles
                        color: kSecondaryGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  //
                  // --- ⭐️ NOTIFICATIONS TILE WITH SWITCH ---
                  //
                  _buildSettingsTile(
                    'Notifications',
                    onTap: () {
                      // Tapping the row can also toggle the switch
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
                        // Implement logic to update notification settings
                      },
                      activeColor: kPrimaryPink, // Matches image's vibe
                    ),
                  ),
                  //
                  // --- END OF SECTION ---
                  //
                  _buildSettingsTile(
                    'Contact Us',
                    onTap: () {
                      // Handle contact us tap
                    },
                    // No trailing widget, so it defaults to the arrow
                  ),
                  const SizedBox(height: 30),

                  // Security Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Security',
                      // --- MODIFIED --- (Matched 'General' style)
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kSecondaryGrey,
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Privacy & Legal',
                      // --- MODIFIED --- (Matched 'General' style)
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kSecondaryGrey,
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
                  // Handle save logic (e.g., save _notificationsEnabled)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7B8F5), // Light purple
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Updated footer text
            const Text(
              '© 2025 BullXchange • Ver 1.0',
              style: TextStyle(
                color: Colors.grey,
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

  // Helper widget defaults to an arrow if 'trailing' is not specified
  Widget _buildSettingsTile(
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            // --- MODIFIED --- (Applied bold font, size, and primary blue color)
            style: const TextStyle(
              fontSize: 18, // Made larger to match image
              color: kPrimaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: kSecondaryGrey),
                )
              : null,
          trailing:
              trailing ??
              const Icon(
                Icons.arrow_forward_ios,
                color: kSecondaryGrey,
                size: 18,
              ),
          onTap: onTap,
        ),
      ],
    );
  }
}
