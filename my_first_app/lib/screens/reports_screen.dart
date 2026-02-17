import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/report_record.dart';
import '../services/firestore_service.dart';

enum _ReportRangePreset { all, last30, last90, ytd, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportRangePreset _selectedPreset = _ReportRangePreset.last90;
  DateTimeRange? _customRange;

  DateTimeRange? get _activeRange {
    final DateTime now = DateTime.now();
    switch (_selectedPreset) {
      case _ReportRangePreset.last30:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case _ReportRangePreset.last90:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        );
      case _ReportRangePreset.ytd:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case _ReportRangePreset.custom:
        return _customRange;
      case _ReportRangePreset.all:
        return null;
    }
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  String _monthLabel(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 2) {
      return key;
    }
    final int month = int.tryParse(parts[1]) ?? 1;
    final int year = int.tryParse(parts[0]) ?? DateTime.now().year;
    const List<String> shortMonths = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${shortMonths[month - 1]} ${year.toString().substring(2)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickCustomDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange =
        _customRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 60)), end: now);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initialRange,
      saveText: 'Apply',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedPreset = _ReportRangePreset.custom;
      _customRange = picked;
    });
  }

  Future<void> _showCsv({
    required String title,
    required Future<String> Function() loader,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String csv = await loader();
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext sheetContext) {
          return Container(
            margin: const EdgeInsets.only(top: 22),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            csv,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final NavigatorState navigator = Navigator.of(
                            sheetContext,
                          );
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (!mounted) {
                            return;
                          }
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('CSV copied to clipboard.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_all_outlined),
                        label: const Text('Copy CSV'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Export failed: $error');
    }
  }

  Future<String> _buildFinancialCsv(FirestoreService firestore) async {
    final DateTimeRange? range = _activeRange;
    final DateTime? startDate = range?.start;
    final DateTime? endDate = range?.end;

    final List<MonthlyRevenuePoint> monthly = await firestore
        .streamMonthlyRevenueReport(startDate: startDate, endDate: endDate)
        .first;
    final GstSummaryRecord gst = await firestore
        .streamGstSummaryReport(startDate: startDate, endDate: endDate)
        .first;
    final List<TopClientRecord> clients = await firestore
        .streamTopClientsReport(
          startDate: startDate,
          endDate: endDate,
          limit: 25,
        )
        .first;

    final StringBuffer csv = StringBuffer();
    csv.writeln('section,key,value');
    csv.writeln(
      'meta,range,${range == null ? 'All Time' : '${range.start.toIso8601String()} to ${range.end.toIso8601String()}'}',
    );

    for (final MonthlyRevenuePoint point in monthly) {
      csv.writeln('monthly,${point.monthKey}_total,${point.totalRevenue}');
      csv.writeln('monthly,${point.monthKey}_paid,${point.paidRevenue}');
      csv.writeln('monthly,${point.monthKey}_unpaid,${point.unpaidRevenue}');
      csv.writeln('monthly,${point.monthKey}_growth,${point.growthPercent}');
    }

    csv.writeln('gst,cgst,${gst.cgst}');
    csv.writeln('gst,sgst,${gst.sgst}');
    csv.writeln('gst,igst,${gst.igst}');
    csv.writeln('gst,totalTax,${gst.totalTax}');
    csv.writeln('gst,taxableAmount,${gst.taxableAmount}');
    csv.writeln('gst,taxPayable,${gst.taxPayable}');

    for (final TopClientRecord client in clients) {
      final String key = client.clientId.isEmpty
          ? client.clientName
          : client.clientId;
      csv.writeln('topClients,${key}_name,${client.clientName}');
      csv.writeln('topClients,${key}_invoices,${client.invoiceCount}');
      csv.writeln('topClients,${key}_total,${client.totalAmount}');
      csv.writeln('topClients,${key}_paid,${client.paidAmount}');
      csv.writeln('topClients,${key}_unpaid,${client.unpaidAmount}');
    }
    return csv.toString();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return const Scaffold(
        body: Center(child: Text('Report service unavailable.')),
      );
    }

    final DateTimeRange? activeRange = _activeRange;
    final DateTime? startDate = activeRange?.start;
    final DateTime? endDate = activeRange?.end;

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildRangeSelector(),
          const SizedBox(height: 10),
          StreamBuilder<List<MonthlyRevenuePoint>>(
            stream: firestore.streamMonthlyRevenueReport(
              startDate: startDate,
              endDate: endDate,
            ),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<MonthlyRevenuePoint>> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message: 'Monthly report error: ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const _LoadingCard();
                  }
                  final List<MonthlyRevenuePoint> points =
                      snapshot.data ?? <MonthlyRevenuePoint>[];
                  final double totalRevenue = points.fold<double>(
                    0,
                    (double total, MonthlyRevenuePoint point) =>
                        total + point.totalRevenue,
                  );
                  final double paidRevenue = points.fold<double>(
                    0,
                    (double total, MonthlyRevenuePoint point) =>
                        total + point.paidRevenue,
                  );
                  final double unpaidRevenue = points.fold<double>(
                    0,
                    (double total, MonthlyRevenuePoint point) =>
                        total + point.unpaidRevenue,
                  );
                  final double latestGrowth = points.isEmpty
                      ? 0
                      : points.last.growthPercent;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Monthly Revenue Report',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _MetricChip(
                                label: 'Total Revenue',
                                value: _money(totalRevenue),
                                color: const Color(0xFF0EA5E9),
                              ),
                              _MetricChip(
                                label: 'Paid',
                                value: _money(paidRevenue),
                                color: const Color(0xFF16A34A),
                              ),
                              _MetricChip(
                                label: 'Unpaid',
                                value: _money(unpaidRevenue),
                                color: const Color(0xFFD97706),
                              ),
                              _MetricChip(
                                label: 'Growth',
                                value: '${latestGrowth.toStringAsFixed(1)}%',
                                color: latestGrowth >= 0
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFDC2626),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _RevenueChart(
                            points: points,
                            monthLabelBuilder: _monthLabel,
                            moneyFormatter: _money,
                          ),
                        ],
                      ),
                    ),
                  );
                },
          ),
          const SizedBox(height: 10),
          StreamBuilder<GstSummaryRecord>(
            stream: firestore.streamGstSummaryReport(
              startDate: startDate,
              endDate: endDate,
            ),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<GstSummaryRecord> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message: 'GST report error: ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const _LoadingCard();
                  }
                  final GstSummaryRecord gst = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'GST Summary Report',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          _taxRow('Taxable Amount', _money(gst.taxableAmount)),
                          _taxRow('CGST Collected', _money(gst.cgst)),
                          _taxRow('SGST Collected', _money(gst.sgst)),
                          _taxRow('IGST Collected', _money(gst.igst)),
                          const Divider(height: 18),
                          _taxRow(
                            'Total Tax',
                            _money(gst.totalTax),
                            emphasize: true,
                          ),
                          _taxRow(
                            'Tax Payable',
                            _money(gst.taxPayable),
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  );
                },
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<TopClientRecord>>(
            stream: firestore.streamTopClientsReport(
              startDate: startDate,
              endDate: endDate,
              limit: 7,
            ),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<TopClientRecord>> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message: 'Top clients error: ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const _LoadingCard();
                  }
                  final List<TopClientRecord> topClients =
                      snapshot.data ?? <TopClientRecord>[];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Top Clients Report',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (topClients.isEmpty)
                            const Text('No client billing data in this range.'),
                          for (int i = 0; i < topClients.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 14,
                                    child: Text('${i + 1}'),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          topClients[i].clientName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${topClients[i].invoiceCount} invoices • Paid ${_money(topClients[i].paidAmount)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _money(topClients[i].totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Export Reports',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showCsv(
                      title: 'Financial Summary CSV (Selected Range)',
                      loader: () => _buildFinancialCsv(firestore),
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export Financial Summary CSV'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCsv(
                      title: 'Invoice Export CSV',
                      loader: firestore.exportInvoicesCsv,
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export Invoices CSV'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCsv(
                      title: 'Clients Export CSV',
                      loader: firestore.exportClientsCsv,
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export Clients CSV'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCsv(
                      title: 'Revenue Report CSV',
                      loader: firestore.exportRevenueCsv,
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export Revenue CSV'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Filter by Date Range',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('All Time'),
                  selected: _selectedPreset == _ReportRangePreset.all,
                  onSelected: (_) {
                    setState(() {
                      _selectedPreset = _ReportRangePreset.all;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('30 Days'),
                  selected: _selectedPreset == _ReportRangePreset.last30,
                  onSelected: (_) {
                    setState(() {
                      _selectedPreset = _ReportRangePreset.last30;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('90 Days'),
                  selected: _selectedPreset == _ReportRangePreset.last90,
                  onSelected: (_) {
                    setState(() {
                      _selectedPreset = _ReportRangePreset.last90;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('YTD'),
                  selected: _selectedPreset == _ReportRangePreset.ytd,
                  onSelected: (_) {
                    setState(() {
                      _selectedPreset = _ReportRangePreset.ytd;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text(
                    _selectedPreset == _ReportRangePreset.custom
                        ? 'Custom Applied'
                        : 'Custom',
                  ),
                  selected: _selectedPreset == _ReportRangePreset.custom,
                  onSelected: (_) => _pickCustomDateRange(),
                ),
              ],
            ),
            if (_activeRange != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Active: ${_activeRange!.start.day}/${_activeRange!.start.month}/${_activeRange!.start.year}'
                ' - ${_activeRange!.end.day}/${_activeRange!.end.month}/${_activeRange!.end.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _taxRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({
    required this.points,
    required this.monthLabelBuilder,
    required this.moneyFormatter,
  });

  final List<MonthlyRevenuePoint> points;
  final String Function(String monthKey) monthLabelBuilder;
  final String Function(double value) moneyFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No revenue data for selected range.'),
      );
    }
    final double maxRevenue = points.fold<double>(
      0,
      (double maxValue, MonthlyRevenuePoint point) =>
          math.max(maxValue, point.totalRevenue),
    );
    return Column(
      children: points.map((MonthlyRevenuePoint point) {
        final double paidFlex = maxRevenue == 0
            ? 0
            : point.paidRevenue / maxRevenue;
        final double unpaidFlex = maxRevenue == 0
            ? 0
            : point.unpaidRevenue / maxRevenue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      monthLabelBuilder(point.monthKey),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(moneyFormatter(point.totalRevenue)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        flex: math.max(1, (paidFlex * 1000).round()),
                        child: Container(color: const Color(0xFF16A34A)),
                      ),
                      Flexible(
                        flex: math.max(1, (unpaidFlex * 1000).round()),
                        child: Container(color: const Color(0xFFD97706)),
                      ),
                      if (paidFlex + unpaidFlex < 1)
                        Flexible(
                          flex: math.max(
                            1,
                            ((1 - paidFlex - unpaidFlex) * 1000).round(),
                          ),
                          child: Container(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading report...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
