import 'dart:async';

import 'package:flutter/material.dart';

import 'calendar_due_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/action_card.dart';
import '../widgets/invoice_tile.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onQuickActionTabSelected});

  final ValueChanged<int> onQuickActionTabSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  static const int _overdueCount = 3;
  static const double _overdueAmount = 12000;

  final List<Map<String, dynamic>> _topClients = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Apex Interiors',
      'revenue': 182000.0,
      'ratio': 0.88,
    },
    <String, dynamic>{
      'name': 'Urban Pulse Media',
      'revenue': 145500.0,
      'ratio': 0.72,
    },
    <String, dynamic>{
      'name': 'Nova Fabricators',
      'revenue': 93400.0,
      'ratio': 0.58,
    },
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCalendarDueScreen() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CalendarDueScreen(),
      ),
    );
  }

  String _money(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _DashboardSkeleton();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_overdueCount > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_overdueCount Invoices Overdue - ${_money(_overdueAmount)} Pending',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Welcome back, Rohan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _buildRevenueInsightsCard(),
          const SizedBox(height: 16),
          _buildStatCards(),
          const SizedBox(height: 16),
          _buildTopClientsSection(),
          const SizedBox(height: 16),
          _buildIncomeTaxReminderCard(),
          const SizedBox(height: 16),
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.32,
            children: <Widget>[
              ActionCard(
                title: 'Add Client',
                subtitle: 'Create a new client profile',
                icon: Icons.person_add_alt,
                accentColor: const Color(0xFF065F46),
                centerContent: true,
                onTap: () => widget.onQuickActionTabSelected(1),
              ),
              ActionCard(
                title: 'Create Invoice',
                subtitle: 'Prepare and share invoice',
                icon: Icons.description_outlined,
                accentColor: const Color(0xFF1E3A8A),
                centerContent: true,
                onTap: () => widget.onQuickActionTabSelected(2),
              ),
              ActionCard(
                title: 'GST Due Dates',
                subtitle: 'View filing calendar quickly',
                icon: Icons.event_available_outlined,
                accentColor: const Color(0xFF92400E),
                centerContent: true,
                onTap: _openCalendarDueScreen,
              ),
              ActionCard(
                title: 'Send Reminder',
                subtitle: 'Send payment reminders',
                icon: Icons.send_outlined,
                accentColor: const Color(0xFF581C87),
                centerContent: true,
                onTap: () => widget.onQuickActionTabSelected(3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Recent Invoices',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => _showMessage('Opening all invoices.'),
                child: const Text('View All'),
              ),
            ],
          ),
          const InvoiceTile(
            invoiceNo: 'INV-2031',
            clientName: 'Apex Interiors',
            amount: '₹27,500',
            status: 'Pending',
          ),
          const InvoiceTile(
            invoiceNo: 'INV-2030',
            clientName: 'Urban Pulse Media',
            amount: '₹43,200',
            status: 'Paid',
          ),
          const InvoiceTile(
            invoiceNo: 'INV-2029',
            clientName: 'Nova Fabricators',
            amount: '₹18,750',
            status: 'Overdue',
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bar_chart, color: primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Monthly Revenue Summary',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹4,85,300 this month',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '12.8% higher than last month',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueInsightsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Revenue Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withValues(alpha: 0.15),
                  ),
                  child: const Text(
                    '↑ 12%',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _metricBlock('This Month', '₹4,85,300')),
                const SizedBox(width: 8),
                Expanded(child: _metricBlock('Last Month', '₹4,32,900')),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0x1A2F6FED), Color(0x332F6FED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: primaryBlue.withValues(alpha: 0.22)),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrendLinePainter(color: primaryBlue),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Trend Graph (UI)',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return SizedBox(
      height: 132,
      child: Row(
        children: <Widget>[
          Expanded(
            child: StatCard(
              title: 'Total Clients',
              value: '42',
              icon: Icons.people_outline,
              gradient: blueGradient,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              title: 'Pending Invoices',
              value: '9',
              icon: Icons.receipt_long_outlined,
              gradient: orangeGradient,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              title: 'Upcoming Due',
              value: '5',
              icon: Icons.event_note_outlined,
              gradient: greenGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Top Clients',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            for (final Map<String, dynamic> client in _topClients)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            value: client['ratio'] as double,
                            strokeWidth: 5,
                            backgroundColor: Theme.of(context).dividerColor,
                          ),
                          Text(
                            '${((client['ratio'] as double) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            client['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(_money(client['revenue'] as double)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showMessage('Client details opened.'),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTaxReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: purpleGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Income Tax Reminder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Advance tax payment due on 15th March.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showMessage('Reminder acknowledged.'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Mark Done'),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _bar(height: 22, width: 180),
        const SizedBox(height: 8),
        _bar(height: 14, width: 250),
        const SizedBox(height: 16),
        _box(height: 170),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _box(height: 120)),
            const SizedBox(width: 8),
            Expanded(child: _box(height: 120)),
            const SizedBox(width: 8),
            Expanded(child: _box(height: 120)),
          ],
        ),
        const SizedBox(height: 12),
        _box(height: 130),
      ],
    );
  }

  Widget _bar({required double height, required double width}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _box({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.18, size.height * 0.62)
      ..lineTo(size.width * 0.38, size.height * 0.69)
      ..lineTo(size.width * 0.58, size.height * 0.44)
      ..lineTo(size.width * 0.8, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.22);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
