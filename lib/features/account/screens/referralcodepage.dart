import 'dart:math'; // Required for Random
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bullxchange/widgets/custom_back_button.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:dotted_border/dotted_border.dart';
import 'package:share_plus/share_plus.dart';

class ReferralCodePage extends StatefulWidget {
  const ReferralCodePage({super.key});

  @override
  State<ReferralCodePage> createState() => _ReferralCodePageState();
}

class _ReferralCodePageState extends State<ReferralCodePage> {
  // Initial state is loading
  String _referralCode = "LOADING...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReferralCode();
  }

  // ⭐️ LOGIC: Fetch existing code or Generate a new random one if missing
  Future<void> _loadUserReferralCode() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final snapshot = await userDocRef.get();

        if (snapshot.exists) {
          final data = snapshot.data();
          // 1. Check if code already exists in DB
          if (data != null && data.containsKey('myReferralCode')) {
            if (mounted) {
              setState(() {
                _referralCode = data['myReferralCode'];
                _isLoading = false;
              });
            }
          } else {
            // 2. If no code exists (Legacy user), Generate Random & Save it
            String userName = data?['name'] ?? "USER";
            String newCode = _generateRandomCode(userName);

            await userDocRef.update({'myReferralCode': newCode});

            if (mounted) {
              setState(() {
                _referralCode = newCode;
                _isLoading = false;
              });
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _referralCode = "ERROR";
            _isLoading = false;
          });
        }
      }
    }
  }

  // ⭐️ HELPER: Generates "NAME + RANDOM" code
  String _generateRandomCode(String name) {
    String cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (cleanName.length > 4) {
      cleanName = cleanName.substring(0, 4);
    } else if (cleanName.isEmpty) {
      cleanName = "BULL";
    }

    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random rnd = Random();
    String randomSuffix = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    return "$cleanName$randomSuffix";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Referral Code',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18, // ⭐️ Increased from 14 to 18 to match standard pages
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            // --- Illustration ---
            Image.asset(
              'assets/images/refer_page.png',
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: colorScheme.surface,
                  alignment: Alignment.center,
                  child: Text(
                    'Error: Image not found',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // --- "Refer & Earn" Title ---
            Text(
              'Refer & Earn',
              textAlign: TextAlign.center,
              // ⭐️ Changed from displayMedium (huge) to headlineSmall (standard header)
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // ⭐️ Updated Text
            Text(
              'Share this code with your friend.\nThey get 5,000 and you get 10,000 Points!',
              textAlign: TextAlign.center,
              // ⭐️ Changed to bodyMedium for cleaner look
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: textTheme.bodySmall?.color,
                height: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),

            // --- Referral Code Box ---
            DottedBorder(
              color: colorScheme.secondary,
              strokeWidth: 2.0, // Slightly reduced stroke for elegance
              borderType: BorderType.RRect,
              radius: const Radius.circular(16), // Slightly tighter radius
              dashPattern: const [8, 4],
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16, // Slightly reduced padding
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _referralCode,
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Standard input text size
                                  color: colorScheme.onSurface,
                                  letterSpacing: 1.0,
                                ),
                          ),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: _referralCode),
                              ).then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Referral code copied!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.content_copy,
                                    color: colorScheme.secondary,
                                    size: 20, // slightly smaller icon
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Copy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge! // Using labelLarge for action text
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.secondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // --- "Refer friend" Button ---
            SizedBox(
              width: double.infinity,
              height: 52, // Standard button height (usually 48-56)
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        // ⭐️ Share Logic
                        Share.share(
                          'Hey! Join BullXchange and start trading. '
                          'Use my code $_referralCode to get 5,000 Bonus Points! '
                          'Download here: https://bullxchange.com/app',
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Refer friend',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
