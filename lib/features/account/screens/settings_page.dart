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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
                      activeThumbColor:
                          Colors.pink, // Matches image's switch color
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    'Privacy Policy',
                    onTap: () {
                      // Handle privacy policy tap
                    },
                    subtitle: 'Choose what data you share with us',
                  ),
                  _buildSettingsTile(
                    'Legal',
                    onTap: () {
                      // Handle legal tap
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
              style: TextStyle(color: Colors.grey, fontSize: 13),
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
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                )
              : null,
          trailing:
              trailing ??
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          onTap: onTap,
        ),
      ],
    );
  }
}
