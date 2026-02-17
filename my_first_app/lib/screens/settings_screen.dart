import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppTheme.themeModeNotifier,
        builder: (BuildContext context, ThemeMode mode, Widget? child) {
          final bool darkModeEnabled = mode == ThemeMode.dark;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      title: const Text('Notification toggle'),
                      subtitle: const Text('Enable invoice and tax alerts'),
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Notifications enabled (UI only).'
                                  : 'Notifications disabled (UI only).',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Dark mode toggle'),
                      subtitle: const Text(
                        'Switch between light and dark theme',
                      ),
                      value: darkModeEnabled,
                      onChanged: (bool value) {
                        AppTheme.setDarkMode(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'App Version Info',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text('Smart Tax & Invoice Manager'),
                      const SizedBox(height: 4),
                      const Text('Version: 1.0.0+1'),
                      const SizedBox(height: 4),
                      Text(
                        'Environment: UI demo build ready for Firebase integration later.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
