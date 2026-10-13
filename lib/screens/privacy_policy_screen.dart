import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Easy PDF',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Effective Date: October 04, 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              theme,
              '1. Introduction',
              'Welcome to Easy PDF - Document Scanner & Maker ("Easy PDF", "we", "our", or "us"). We are committed to protecting your privacy and ensuring you have a secure experience when using our application.',
            ),
            _buildSection(
              theme,
              '2. Information Collection and Storage',
              '• Local Document Processing (100% On-Device): Camera and photo library access are used solely to capture physical documents or import photos for PDF conversion. All scanned documents and PDF files are stored strictly on local device storage and are never uploaded, transmitted, or stored on our servers.\n\n• Advertising Data (Google AdMob): Our app displays rewarded video ads. Google AdMob may collect non-personally identifiable identifiers (such as Advertising ID) for ad delivery and performance metrics.',
            ),
            _buildSection(
              theme,
              '3. Third-Party Services',
              'We integrate trusted SDKs including Google ML Kit Document Scanner (on-device processing) and Google Mobile Ads (AdMob) for monetization.',
            ),
            _buildSection(
              theme,
              '4. User Data Control',
              'All PDF documents reside locally on your device. You have full control to view, share, rename, or delete any file at any time. You can also revoke permissions via your device settings.',
            ),
            _buildSection(
              theme,
              '5. Contact Us',
              'For any questions regarding privacy, please contact us at kssoftonfotech@gmail.com.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
