import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ClientTile extends StatelessWidget {
  const ClientTile({
    super.key,
    required this.name,
    required this.email,
    required this.pendingAmount,
    required this.isActive,
    this.onTap,
  });

  final String name;
  final String email;
  final String pendingAmount;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = isActive ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withValues(alpha: 0.12),
          child: const Icon(Icons.person_outline, color: primaryBlue),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(email),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              pendingAmount,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
