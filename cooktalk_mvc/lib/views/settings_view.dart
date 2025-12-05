import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.dark,  label: Text('Dark')),
          ],
          selected: {app.themeMode},
          onSelectionChanged: (s) => app.setThemeMode(s.first),
        ),
        const SizedBox(height: 24),
        const Text('Version 1.0.0+1'),
      ],
    );
  }
}
