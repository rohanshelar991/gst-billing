import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Total Revenue Graph',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0x1A2F6FED), Color(0x332F6FED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.26),
                        ),
                      ),
                      child: const Center(
                        child: Text('Revenue Chart Placeholder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Payment Distribution Chart',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: <Color>[
                                    Colors.green,
                                    Colors.orange,
                                    primaryBlue,
                                    Colors.green,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white,
                                  child: Text('UI'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Paid: 64%'),
                                SizedBox(height: 4),
                                Text('Pending: 24%'),
                                SizedBox(height: 4),
                                Text('Overdue: 12%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _infoCard(
                    context,
                    title: 'GST Collected This Month',
                    value: '₹82,500',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCard(
                    context,
                    title: 'Income Tax Estimate',
                    value: '₹1,24,300',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
