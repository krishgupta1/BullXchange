import 'package:flutter/material.dart';

import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:dotted_border/dotted_border.dart'; // Make sure you have this package

class ReferralCodePage extends StatelessWidget {
  const ReferralCodePage({super.key});

  final String _referralCode = "TRADEBASE";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF0D0D26),
                size: 18,
              ),
            ),
          ),
        ),
        title: const Text(
          'Referral Code',
          style: TextStyle(
            color: Color(0xFF0D0D26),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
                  color: Colors.grey[100],
                  alignment: Alignment.center,
                  child: Text(
                    'Error: Image not found\n at assets/images/refer_page.png',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // --- "Refer & Earn" Title ---
            const Text(
              'Refer & Earn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D0D26),
              ),
            ),
            const SizedBox(height: 16),

            // --- Description Text ---
            const Text(
              'Share this code with your friend and\nboth of you will get \$10 free stocks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8A8A8A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // --- Referral Code Box (with DottedBorder) ---
            DottedBorder(
              color: const Color(0xFFF50057), // Pink color from image
              strokeWidth: 3.0, // <-- BOLDER STROKE
              borderType: BorderType.RRect,
              radius: const Radius.circular(24),
              dashPattern: const [8, 4], // 8px dash, 4px gap
              padding:
                  EdgeInsets.zero, // Let the inner container handle padding
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _referralCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D0D26),
                        letterSpacing: 1.1,
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
                            ),
                          );
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.content_copy,
                              color: Color(0xFFF50057),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Copy Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF50057),
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
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add share logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF4F00F3,
                  ), // Vibrant purple from image
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Fully rounded
                  ),
                ),
                child: const Text(
                  'Refer friend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
