import 'package:flutter/material.dart';
import 'package:carsbuzz/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

class ReferAndEarnWidget extends StatelessWidget {
  final VoidCallback? onReferNowTapped;

  const ReferAndEarnWidget({
    Key? key,
    this.onReferNowTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          Text(
            'Refer & Earn ₹1000!',
            style: AppTextStyles.heading3,
          ),
          
          // Subtitle Text
          const SizedBox(height: 4),
          Text(
            'Invite your friends and get rewarded when they service their car with us.',
            style: AppTextStyles.bodyMedium,
          ),
          
          // Refer Now Button
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: onReferNowTapped ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refer Now clicked!'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Green color
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Refer Now',
                  style: AppTextStyles.buttonTextSmall,
                ),
              ),
            ),
          ),
          
          // Referral Image - Full width and prominent like in Android XML
          Container(
            width: double.infinity,
            height: 300, // 300dp height as in Android XML
            margin: const EdgeInsets.only(top: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/referral_removebg_preview.png',
                fit: BoxFit.cover, // Changed to cover for better display
                errorBuilder: (context, error, stackTrace) {
                  // Fallback widget when image is not found
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Refer & Earn',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹1000 Reward',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}