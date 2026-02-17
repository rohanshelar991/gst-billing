import 'package:flutter/material.dart';

import '../widgets/invoice_tile.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final List<String> _filters = <String>['All', 'Paid', 'Pending', 'Overdue'];
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<Map<String, dynamic>> _invoices = <Map<String, dynamic>>[
    <String, dynamic>{
      'number': 'INV-2031',
      'client': 'Apex Interiors',
      'status': 'Pending',
      'date': DateTime(2026, 2, 12),
      'discountPercent': 5.0,
      'gstType': 'CGST+SGST',
      'gstPercent': 12.0,
      'timelineStep': 2,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'product': 'Office Chair',
          'qty': 10,
          'price': 2200.0,
        },
        <String, dynamic>{'product': 'Desk Unit', 'qty': 5, 'price': 5400.0},
      ],
    },
    <String, dynamic>{
      'number': 'INV-2030',
      'client': 'Urban Pulse Media',
      'status': 'Paid',
      'date': DateTime(2026, 2, 10),
      'discountPercent': 2.5,
      'gstType': 'IGST',
      'gstPercent': 18.0,
      'timelineStep': 3,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'product': 'Campaign Design',
          'qty': 1,
          'price': 30000.0,
        },
        <String, dynamic>{'product': 'Ad Placement', 'qty': 2, 'price': 7600.0},
      ],
    },
    <String, dynamic>{
      'number': 'INV-2029',
      'client': 'Nova Fabricators',
      'status': 'Overdue',
      'date': DateTime(2026, 2, 4),
      'discountPercent': 0.0,
      'gstType': 'CGST+SGST',
      'gstPercent': 12.0,
      'timelineStep': 1,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'product': 'Steel Sheet', 'qty': 30, 'price': 450.0},
        <String, dynamic>{'product': 'Welding Kit', 'qty': 5, 'price': 1250.0},
      ],
    },
    <String, dynamic>{
      'number': 'INV-2028',
      'client': 'Skyline Traders',
      'status': 'Pending',
      'date': DateTime(2026, 1, 28),
      'discountPercent': 4.0,
      'gstType': 'No GST',
      'gstPercent': 0.0,
      'timelineStep': 1,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'product': 'Packaging Box',
          'qty': 120,
          'price': 80.0,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filtered = _invoices.where((
      Map<String, dynamic> invoice,
    ) {
      if (_selectedFilter == 'All') {
        return true;
      }
      return (invoice['status'] as String).toLowerCase() ==
          _selectedFilter.toLowerCase();
    }).toList();

    filtered.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      if (_selectedSort == 'Amount (High to Low)') {
        final double totalA = _totalAmount(a);
        final double totalB = _totalAmount(b);
        return totalB.compareTo(totalA);
      }
      if (_selectedSort == 'Amount (Low to High)') {
        final double totalA = _totalAmount(a);
        final double totalB = _totalAmount(b);
        return totalA.compareTo(totalB);
      }
      final DateTime dateA = a['date'] as DateTime;
      final DateTime dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((String filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: <Widget>[
              const Icon(Icons.sort, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSort,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'Newest',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Amount (High to Low)',
                      child: Text('Amount (High to Low)'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Amount (Low to High)',
                      child: Text('Amount (Low to High)'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedSort = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _InvoicesEmptyState(
                  onReset: () {
                    setState(() {
                      _selectedFilter = 'All';
                      _selectedSort = 'Newest';
                    });
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> invoice = filtered[index];
                    return InvoiceTile(
                      invoiceNo: invoice['number'] as String,
                      clientName: invoice['client'] as String,
                      amount: _money(_totalAmount(invoice)),
                      status: invoice['status'] as String,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                InvoiceDetailScreen(invoice: invoice),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  double _totalAmount(Map<String, dynamic> invoice) {
    final List<Map<String, dynamic>> items = (invoice['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    double subtotal = 0;
    for (final Map<String, dynamic> item in items) {
      subtotal += (item['qty'] as int) * (item['price'] as double);
    }
    final double discount =
        subtotal * ((invoice['discountPercent'] as double) / 100);
    final double taxable = subtotal - discount;
    final double gst = taxable * ((invoice['gstPercent'] as double) / 100);
    return taxable + gst;
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
}

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final Map<String, dynamic> invoice;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = (invoice['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    double subtotal = 0;
    for (final Map<String, dynamic> item in items) {
      subtotal += (item['qty'] as int) * (item['price'] as double);
    }

    final double discountPercent = invoice['discountPercent'] as double;
    final double discountAmount = subtotal * (discountPercent / 100);
    final double taxableAmount = subtotal - discountAmount;
    final double gstPercent = invoice['gstPercent'] as double;
    final double gstAmount = taxableAmount * (gstPercent / 100);

    final String gstType = invoice['gstType'] as String;
    final double cgst = gstType == 'CGST+SGST' ? gstAmount / 2 : 0;
    final double sgst = gstType == 'CGST+SGST' ? gstAmount / 2 : 0;
    final double igst = gstType == 'IGST' ? gstAmount : 0;
    final double grandTotal = taxableAmount + gstAmount;

    return Scaffold(
      appBar: AppBar(title: Text(invoice['number'] as String)),
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
                    _row('Invoice number', invoice['number'] as String),
                    _row('Client', invoice['client'] as String),
                    _row('Status', invoice['status'] as String),
                    const SizedBox(height: 10),
                    _statusTimeline(context, invoice['timelineStep'] as int),
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
                      'Itemized Invoice Table',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Total')),
                        ],
                        rows: items.map((Map<String, dynamic> item) {
                          final int qty = item['qty'] as int;
                          final double price = item['price'] as double;
                          final double total = qty * price;
                          return DataRow(
                            cells: <DataCell>[
                              DataCell(Text(item['product'] as String)),
                              DataCell(Text('$qty')),
                              DataCell(Text(_money(price))),
                              DataCell(Text(_money(total))),
                            ],
                          );
                        }).toList(),
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
                      'Tax Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row('Subtotal', _money(subtotal)),
                    _row('Discount', '- ${_money(discountAmount)}'),
                    _row('CGST', _money(cgst)),
                    _row('SGST', _money(sgst)),
                    _row('IGST', _money(igst)),
                    const Divider(height: 18),
                    _row('Grand Total', _money(grandTotal), emphasize: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice marked as paid (UI only).'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Paid'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Download PDF action (UI only).'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTimeline(BuildContext context, int activeIndex) {
    const List<String> labels = <String>['Created', 'Sent', 'Viewed', 'Paid'];

    return Row(
      children: List<Widget>.generate(labels.length, (int index) {
        final bool active = index <= activeIndex;
        return Expanded(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (index != 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: active
                            ? Colors.green
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? Colors.green
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  if (index == 0) const Expanded(child: SizedBox.shrink()),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String key, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(key),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 17 : 14,
              color: emphasize ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
}

class _InvoicesEmptyState extends StatelessWidget {
  const _InvoicesEmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.receipt_long_outlined, size: 48),
              const SizedBox(height: 8),
              const Text('No invoices for selected filter'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onReset,
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
