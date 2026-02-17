import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final AuthService? authService = context.read<AuthService?>();
    if (authService == null) {
      return;
    }
    await authService.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    final AuthService? authService = context.read<AuthService?>();
    final String fallbackName =
        authService?.currentUser?.displayName ?? 'Business Owner';
    final String fallbackEmail = authService?.currentUser?.email ?? '';
    if (firestore == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile service unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: firestore.streamUserProfile(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<Map<String, dynamic>?> userSnapshot,
            ) {
              return StreamBuilder<CompanyRecord?>(
                stream: firestore.streamActiveCompany(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<CompanyRecord?> companySnapshot,
                    ) {
                      final Map<String, dynamic>? userProfile =
                          userSnapshot.data;
                      final CompanyRecord? company = companySnapshot.data;
                      final String name =
                          userProfile?['name'] as String? ?? fallbackName;
                      final String email =
                          userProfile?['email'] as String? ?? fallbackEmail;
                      final String phone =
                          userProfile?['phone'] as String? ?? '';

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 46,
                              child: Text(
                                name.isEmpty ? '?' : name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (phone.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                phone,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 14),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: <Widget>[
                                    _row(
                                      context,
                                      'Role',
                                      (userProfile?['role'] as String? ??
                                              'admin')
                                          .toUpperCase(),
                                    ),
                                    _row(
                                      context,
                                      'Company',
                                      company?.name ?? 'Not selected',
                                    ),
                                    _row(
                                      context,
                                      'GST',
                                      company?.gstNumber.isNotEmpty == true
                                          ? company!.gstNumber
                                          : 'Not set',
                                    ),
                                    _row(
                                      context,
                                      'Invoice Prefix',
                                      company?.invoicePrefix ?? 'INV',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _logout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              );
            },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
