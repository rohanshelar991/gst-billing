import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InvoiceTile extends StatelessWidget {
  const InvoiceTile({
    super.key,
    required this.invoiceNo,
    required this.clientName,
    required this.amount,
    required this.status,
    this.onTap,
  });

  final String invoiceNo;
  final String clientName;
  final String amount;
  final String status;
  final VoidCallback? onTap;

  Color _badgeColor() {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color badge = _badgeColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withValues(alpha: 0.12),
          child: const Icon(Icons.receipt_long_outlined, color: primaryBlue),
        ),
        title: Text(
          invoiceNo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(clientName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badge.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: badge,
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
