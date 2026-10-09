import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewService {
  static Future<void> requestRateApp(BuildContext context) async {
    _showRatingDialog(context);
  }

  static void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rate Easy PDF',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'If you enjoy using Easy PDF, please take a moment to rate us on the Play Store. Your feedback helps us improve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final Uri url = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.kssoft.easy_pdf',
              );
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open Play Store listing')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening store: $e')),
                  );
                }
              }
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }
}
