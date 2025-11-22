import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard ke liye

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ⭐️ Theme se colors lo ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // --- Theme background ---
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colorScheme.secondary,
          ), // Pink
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Us',
          style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Hero Icon ---
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                // Light mode mein halka blue, Dark mein transparent/dark blue
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 60,
                color: colorScheme.primary, // Blue
              ),
            ),
            const SizedBox(height: 24),

            // --- Title & Subtitle ---
            Text(
              "We're here to help!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Have questions or need support? Reach out to us anytime.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textTheme.bodySmall?.color, // Grey
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // --- Contact Cards ---
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              title: "Email Support",
              subtitle: "support@bullxchange.in",
              onTap: () {
                // Yahan email app kholne ka logic aa sakta hai
                _copyToClipboard(context, "support@bullxchange.in");
              },
            ),
            const SizedBox(height: 16),

            _buildContactCard(
              context,
              icon: Icons.phone_in_talk_outlined,
              title: "Call Us",
              subtitle: "+91 12345 67890",
              onTap: () {
                // Yahan phone dialer kholne ka logic aa sakta hai
                _copyToClipboard(context, "+91 12345 67890");
              },
            ),
            const SizedBox(height: 16),

            _buildContactCard(
              context,
              icon: Icons.location_on_outlined,
              title: "Office",
              subtitle: "BullXchange Tech, Cyber City, Gurugram, India",
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // --- Social Media Footer ---
            Text(
              "Follow us",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(context, Icons.facebook),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  context,
                  Icons.alternate_email,
                ), // Placeholder for Twitter/X
                const SizedBox(width: 20),
                _buildSocialIcon(
                  context,
                  Icons.camera_alt_outlined,
                ), // Placeholder for Insta
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        // Theme surface color (Light: White, Dark: Dark Grey)
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // Theme accent color (Pink) with opacity
            color: colorScheme.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.secondary, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(color: textTheme.bodySmall?.color, fontSize: 14),
          ),
        ),
        trailing: Icon(
          Icons.copy, // Copy icon to indicate action
          color: textTheme.bodySmall?.color,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Icon(
          icon,
          color: colorScheme.onSurface.withOpacity(0.7),
          size: 24,
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied: $text"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
