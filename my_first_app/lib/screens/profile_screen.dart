import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: 'Rohan Shelar',
    );
    final TextEditingController emailController = TextEditingController(
      text: 'ui.demo@finpro.app',
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated (UI only).')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const LoginScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: blueGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 54),
            ),
            const SizedBox(height: 12),
            Text(
              'Rohan Shelar',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'ui.demo@finpro.app',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEditDialog(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: const <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.badge_outlined),
                      title: Text('GST Number'),
                      subtitle: Text('27AAPCS1234M1ZT'),
                    ),
                    Divider(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on_outlined),
                      title: Text('Business Address'),
                      subtitle: Text('Pune, Maharashtra, India'),
                    ),
                    Divider(height: 4),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.phone_outlined),
                      title: Text('Contact Number'),
                      subtitle: Text('+91 98765 43210'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
