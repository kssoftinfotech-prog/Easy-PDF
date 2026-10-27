import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ThemeService.themeModeNotifier.value;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.palette_outlined),
          SizedBox(width: 10),
          Text('Choose Theme'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('Follow system theme settings'),
            secondary: const Icon(Icons.brightness_auto_rounded),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                ThemeService.setThemeMode(mode);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            subtitle: const Text('Always light background'),
            secondary: const Icon(Icons.light_mode_rounded),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                ThemeService.setThemeMode(mode);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            subtitle: const Text('Always dark background'),
            secondary: const Icon(Icons.dark_mode_rounded),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                ThemeService.setThemeMode(mode);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
