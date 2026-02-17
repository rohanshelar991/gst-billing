import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_record.dart';
import '../models/invoice_record.dart';
import '../models/reminder_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_card.dart';
import '../widgets/invoice_tile.dart';
import '../widgets/stat_card.dart';
import 'calendar_due_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onQuickActionTabSelected});

  final ValueChanged<int> onQuickActionTabSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  DateTime _lastUpdated = DateTime.now();

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

  Future<void> _refreshDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) {
      return;
    }
    setState(() {
      _lastUpdated = DateTime.now();
    });
  }

  String _lastUpdatedLabel() {
    final String hour = _lastUpdated.hour.toString().padLeft(2, '0');
    final String minute = _lastUpdated.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _DashboardSkeleton();
    }
    final FirestoreService? firestore = context.read<FirestoreService?>();

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildOverdueBanner(firestore),
            _buildDashboardHero(firestore),
            const SizedBox(height: 12),
            StreamBuilder<Map<String, dynamic>?>(
              stream: firestore?.streamUserProfile(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<Map<String, dynamic>?> profileSnapshot,
                  ) {
                    final String fallbackName =
                        context
                            .read<AuthService?>()
                            ?.currentUser
                            ?.displayName ??
                        'Business Owner';
                    final String userName =
                        profileSnapshot.data?['name'] as String? ??
                        fallbackName;
                    return Text(
                      'Welcome back, $userName',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    );
                  },
            ),
            const SizedBox(height: 8),
            _buildRevenueInsightsCard(),
            const SizedBox(height: 16),
            _buildStatCards(firestore),
            const SizedBox(height: 16),
            _buildTopClientsSection(firestore),
            const SizedBox(height: 16),
            _buildIncomeTaxReminderCard(firestore),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated ${_lastUpdatedLabel()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => _showMessage('Opening all invoices.'),
                  child: const Text('View All'),
                ),
              ],
            ),
            _buildRecentInvoices(firestore),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueBanner(FirestoreService? firestore) {
    if (firestore == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<int>(
      stream: firestore.streamOverdueInvoiceCount(),
      builder: (BuildContext context, AsyncSnapshot<int> overdueSnapshot) {
        final int overdueCount = overdueSnapshot.data ?? 0;
        if (overdueCount == 0) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<double>(
          stream: firestore.streamPendingInvoiceAmount(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<double> pendingAmountSnapshot,
              ) {
                final double pendingAmount = pendingAmountSnapshot.data ?? 0;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$overdueCount Invoices Overdue - ${_money(pendingAmount)} Pending',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
        );
      },
    );
  }

  Widget _buildDashboardHero(FirestoreService? firestore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Business Health Snapshot',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Live dashboard updated at ${_lastUpdatedLabel()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              StreamBuilder<double>(
                stream:
                    firestore?.streamPendingInvoiceAmount() ??
                    Stream<double>.value(0),
                builder:
                    (BuildContext context, AsyncSnapshot<double> snapshot) {
                      return Expanded(
                        child: _heroMetric(
                          'Pending',
                          _money(snapshot.data ?? 0),
                        ),
                      );
                    },
              ),
              const SizedBox(width: 8),
              StreamBuilder<int>(
                stream:
                    firestore?.streamPendingInvoiceCount() ??
                    Stream<int>.value(0),
                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  return Expanded(
                    child: _heroMetric('Open Tasks', '${snapshot.data ?? 0}'),
                  );
                },
              ),
              const SizedBox(width: 8),
              StreamBuilder<int>(
                stream:
                    firestore?.streamUpcomingDueCount() ?? Stream<int>.value(0),
                builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                  return Expanded(
                    child: _heroMetric(
                      'Due This Week',
                      '${snapshot.data ?? 0}',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
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
                    'Realtime',
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
                Expanded(child: _metricBlock('Sync', 'Firestore')),
                const SizedBox(width: 8),
                Expanded(child: _metricBlock('Auth', 'Firebase Auth')),
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
                        'Live Data Trend',
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

  Widget _buildStatCards(FirestoreService? firestore) {
    return SizedBox(
      height: 132,
      child: Row(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<int>(
              stream: firestore?.streamClientCount() ?? Stream<int>.value(0),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                return StatCard(
                  title: 'Total Clients',
                  value: '${snapshot.data ?? 0}',
                  icon: Icons.people_outline,
                  gradient: blueGradient,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<int>(
              stream:
                  firestore?.streamPendingInvoiceCount() ??
                  Stream<int>.value(0),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                return StatCard(
                  title: 'Pending Invoices',
                  value: '${snapshot.data ?? 0}',
                  icon: Icons.receipt_long_outlined,
                  gradient: orangeGradient,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<int>(
              stream:
                  firestore?.streamUpcomingDueCount() ?? Stream<int>.value(0),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                return StatCard(
                  title: 'Upcoming Due',
                  value: '${snapshot.data ?? 0}',
                  icon: Icons.event_note_outlined,
                  gradient: greenGradient,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopClientsSection(FirestoreService? firestore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ClientRecord>>(
          stream:
              firestore?.streamTopClients(limit: 3) ??
              Stream<List<ClientRecord>>.value(const <ClientRecord>[]),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<ClientRecord>> snapshot,
              ) {
                final List<ClientRecord> topClients =
                    snapshot.data ?? <ClientRecord>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Top Clients',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (topClients.isEmpty)
                      Text(
                        'No clients yet. Add your first client to see rankings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    for (final ClientRecord client in topClients)
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
                                    value: client.creditUsageRatio,
                                    strokeWidth: 5,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).dividerColor,
                                  ),
                                  Text(
                                    '${(client.creditUsageRatio * 100).toStringAsFixed(0)}%',
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
                                    client.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pending ${_money(client.pendingAmount)}',
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  widget.onQuickActionTabSelected(1),
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
        ),
      ),
    );
  }

  Widget _buildIncomeTaxReminderCard(FirestoreService? firestore) {
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
            child: StreamBuilder<ReminderRecord?>(
              stream:
                  firestore?.streamNextReminder() ??
                  Stream<ReminderRecord?>.value(null),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<ReminderRecord?> snapshot,
                  ) {
                    final ReminderRecord? reminder = snapshot.data;
                    final String title =
                        reminder?.title ?? 'No upcoming reminders';
                    final String description = reminder == null
                        ? 'Create reminders to track dues and alerts.'
                        : '${reminder.type} due on '
                              '${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ],
                    );
                  },
            ),
          ),
          TextButton(
            onPressed: () => widget.onQuickActionTabSelected(3),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(FirestoreService? firestore) {
    return StreamBuilder<List<InvoiceRecord>>(
      stream:
          firestore?.streamRecentInvoices(limit: 3) ??
          Stream<List<InvoiceRecord>>.value(const <InvoiceRecord>[]),
      builder: (BuildContext context, AsyncSnapshot<List<InvoiceRecord>> snapshot) {
        final List<InvoiceRecord> invoices = snapshot.data ?? <InvoiceRecord>[];
        if (invoices.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No invoices yet. Create your first invoice.'),
            ),
          );
        }

        return Column(
          children: invoices.map((InvoiceRecord invoice) {
            return InvoiceTile(
              invoiceNo: invoice.number,
              clientName: invoice.client,
              amount: _money(invoice.totalAmount),
              status: invoice.status,
              dateLabel:
                  '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
              tags: invoice.tags,
            );
          }).toList(),
        );
      },
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
