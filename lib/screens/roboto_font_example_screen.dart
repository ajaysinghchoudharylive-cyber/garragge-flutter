import 'package:flutter/material.dart';
import 'package:carsbuzz/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

/// Example screen demonstrating the various Roboto text styles available
/// This can serve as a reference for how to use Roboto fonts throughout your app
class RobotoFontExampleScreen extends StatelessWidget {
  const RobotoFontExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Roboto Fonts Example', style: AppTextStyles.heading2),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headings Section
            Text('Headings', style: AppTextStyles.heading1),
            const SizedBox(height: 16),
            
            Text('Heading 1 - Main Title', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            
            Text('Heading 2 - Section Title', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            
            Text('Heading 3 - Subsection Title', style: AppTextStyles.heading3),
            const SizedBox(height: 24),

            // Body Text Section
            Text('Body Text', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            
            Text('Body Large - Main content text that provides detailed information.',
                style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            
            Text('Body Medium - Standard content text for descriptions.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            
            Text('Body Small - Smaller text for fine details.',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),

            // Buttons Section
            Text('Buttons', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Primary Button', style: AppTextStyles.buttonText),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Small Button', style: AppTextStyles.buttonTextSmall),
            ),
            const SizedBox(height: 24),

            // Other Text Styles Section
            Text('Special Text Styles', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            
            Text('Label Text', style: AppTextStyles.label),
            const SizedBox(height: 8),
            
            Text('Subtitle - Supporting information', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            
            Text('Caption text for images or small details', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            
            Text('Error message text', style: AppTextStyles.error),
            const SizedBox(height: 8),
            
            Text('Success message text', style: AppTextStyles.success),
            const SizedBox(height: 24),

            // Custom Colors Section
            Text('Custom Colors', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            
            Text('Blue Heading', style: AppTextStyles.heading2WithColor(Colors.blue)),
            const SizedBox(height: 8),
            
            Text('Red Body Text', style: AppTextStyles.bodyLargeWithColor(Colors.red)),
            const SizedBox(height: 8),
            
            Text('Green Medium Text', style: AppTextStyles.bodyMediumWithColor(Colors.green)),
            const SizedBox(height: 24),

            // Using GoogleFonts Directly Section
            Text('Direct GoogleFonts Usage', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            
            Text(
              'Custom Roboto style with direct GoogleFonts',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.purple,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Another custom Roboto style',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}