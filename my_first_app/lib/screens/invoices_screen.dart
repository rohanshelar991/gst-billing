import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice_record.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'recurring_invoices_screen.dart';
import '../widgets/invoice_tile.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = <String>['All', 'Paid', 'Pending', 'Overdue'];

  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  String _dateLabel(DateTime date) {
    const List<String> months = <String>[
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCreateInvoiceSheet() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController invoiceNoController = TextEditingController(
      text: 'INV-${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
    final TextEditingController clientIdController = TextEditingController(
      text: '',
    );
    final TextEditingController clientNameController = TextEditingController();
    final TextEditingController itemNameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    final TextEditingController priceController = TextEditingController();
    final TextEditingController gstController = TextEditingController(
      text: '18',
    );

    String paymentStatus = 'Pending';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    bool makeRecurring = false;
    bool recurringAutoGenerate = true;
    String recurringFrequency = 'monthly';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setModalState) {
            return Container(
              margin: const EdgeInsets.only(top: 22),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Create Invoice',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saved in users/{uid}/companies/{companyId}/invoices',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: invoiceNoController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number',
                            prefixIcon: Icon(Icons.tag_outlined),
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter invoice number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: clientIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Client ID',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter client ID';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: clientNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Client Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter client name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: itemNameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  prefixIcon: Icon(Icons.numbers_outlined),
                                ),
                                validator: (String? value) {
                                  final double parsed =
                                      double.tryParse(value?.trim() ?? '') ?? 0;
                                  if (parsed <= 0) {
                                    return 'Invalid qty';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
                                validator: (String? value) {
                                  final double parsed =
                                      double.tryParse(value?.trim() ?? '') ?? 0;
                                  if (parsed <= 0) {
                                    return 'Invalid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: gstController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'GST %',
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                validator: (String? value) {
                                  final double parsed =
                                      double.tryParse(value?.trim() ?? '') ??
                                      -1;
                                  if (parsed < 0) {
                                    return 'Invalid GST';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: paymentStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem<String>(
                                    value: 'Pending',
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'Paid',
                                    child: Text('Paid'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'Overdue',
                                    child: Text('Overdue'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setModalState(() {
                                    paymentStatus = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDate: dueDate,
                            );
                            if (pickedDate == null) {
                              return;
                            }
                            setModalState(() {
                              dueDate = pickedDate;
                            });
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_dateLabel(dueDate)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          value: makeRecurring,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Make Recurring'),
                          subtitle: const Text(
                            'Save this as recurring template for subscription billing',
                          ),
                          onChanged: (bool value) {
                            setModalState(() {
                              makeRecurring = value;
                            });
                          },
                        ),
                        if (makeRecurring)
                          Column(
                            children: <Widget>[
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: recurringFrequency,
                                decoration: const InputDecoration(
                                  labelText: 'Recurring Frequency',
                                  prefixIcon: Icon(Icons.repeat_outlined),
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem<String>(
                                    value: 'weekly',
                                    child: Text('Weekly'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'monthly',
                                    child: Text('Monthly'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'yearly',
                                    child: Text('Yearly'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setModalState(() {
                                    recurringFrequency = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                value: recurringAutoGenerate,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Auto Generate'),
                                subtitle: const Text(
                                  'Automatically generate invoice on schedule',
                                ),
                                onChanged: (bool value) {
                                  setModalState(() {
                                    recurringAutoGenerate = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              final FirestoreService firestoreService = context
                                  .read<FirestoreService>();
                              final AnalyticsService analyticsService = context
                                  .read<AnalyticsService>();
                              final NavigatorState navigator = Navigator.of(
                                context,
                              );

                              final double quantity =
                                  double.tryParse(
                                    quantityController.text.trim(),
                                  ) ??
                                  0;
                              final double price =
                                  double.tryParse(
                                    priceController.text.trim(),
                                  ) ??
                                  0;
                              final double gstRate =
                                  double.tryParse(gstController.text.trim()) ??
                                  0;

                              final double subtotal = quantity * price;
                              final double totalGST =
                                  subtotal * (gstRate / 100);
                              final double totalAmount = subtotal + totalGST;

                              try {
                                await firestoreService.addInvoice(
                                  invoiceNumber: invoiceNoController.text
                                      .trim(),
                                  clientId: clientIdController.text.trim(),
                                  clientName: clientNameController.text.trim(),
                                  items: <Map<String, dynamic>>[
                                    <String, dynamic>{
                                      'productId': 'manual_item',
                                      'name': itemNameController.text.trim(),
                                      'quantity': quantity,
                                      'price': price,
                                      'gstRate': gstRate,
                                      'gstAmount': totalGST,
                                      'total': totalAmount,
                                    },
                                  ],
                                  subtotal: subtotal,
                                  totalGST: totalGST,
                                  totalAmount: totalAmount,
                                  paymentStatus: paymentStatus,
                                  dueDate: dueDate,
                                  gstPercent: gstRate,
                                  gstType: 'CGST+SGST',
                                  timelineStep: paymentStatus == 'Paid' ? 3 : 1,
                                );
                                if (makeRecurring) {
                                  await firestoreService.addRecurringInvoice(
                                    clientId: clientIdController.text.trim(),
                                    clientName: clientNameController.text
                                        .trim(),
                                    items: <Map<String, dynamic>>[
                                      <String, dynamic>{
                                        'productId': 'manual_item',
                                        'name': itemNameController.text.trim(),
                                        'quantity': quantity,
                                        'price': price,
                                        'gstRate': gstRate,
                                        'gstAmount': totalGST,
                                        'total': totalAmount,
                                      },
                                    ],
                                    frequency: recurringFrequency,
                                    nextInvoiceDate: dueDate,
                                    autoGenerate: recurringAutoGenerate,
                                  );
                                }
                                await analyticsService.logEvent(
                                  'create_invoice',
                                );
                                if (!mounted) {
                                  return;
                                }
                                navigator.pop();
                                _showMessage('Invoice saved to Firestore.');
                              } catch (error) {
                                _showMessage('Could not save invoice: $error');
                              }
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Save Invoice'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestoreService = context
        .read<FirestoreService?>();
    return StreamBuilder<List<InvoiceRecord>>(
      stream:
          firestoreService?.streamInvoices() ??
          Stream<List<InvoiceRecord>>.value(const <InvoiceRecord>[]),
      builder:
          (BuildContext context, AsyncSnapshot<List<InvoiceRecord>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load invoices: ${snapshot.error}'),
                ),
              );
            }

            final String query = _searchController.text.trim().toLowerCase();
            final List<InvoiceRecord> invoices =
                snapshot.data ?? <InvoiceRecord>[];
            final List<InvoiceRecord> filtered = invoices.where((
              InvoiceRecord invoice,
            ) {
              final bool statusMatch =
                  _selectedFilter == 'All' || invoice.status == _selectedFilter;
              final bool queryMatch =
                  query.isEmpty ||
                  invoice.number.toLowerCase().contains(query) ||
                  invoice.client.toLowerCase().contains(query);
              return statusMatch && queryMatch;
            }).toList();

            filtered.sort((InvoiceRecord a, InvoiceRecord b) {
              switch (_selectedSort) {
                case 'Amount (High to Low)':
                  return b.totalAmount.compareTo(a.totalAmount);
                case 'Amount (Low to High)':
                  return a.totalAmount.compareTo(b.totalAmount);
                case 'Oldest':
                  return a.date.compareTo(b.date);
                case 'Newest':
                default:
                  return b.date.compareTo(a.date);
              }
            });

            final double pendingTotal = filtered.fold<double>(0, (
              double value,
              InvoiceRecord invoice,
            ) {
              return value + invoice.balanceAmount;
            });

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Invoices (Realtime)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _showCreateInvoiceSheet,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        const RecurringInvoicesScreen(),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.repeat_outlined, size: 18),
                              label: const Text('Recurring'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _metric('Count', '${filtered.length}'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _metric('Pending', _money(pendingTotal)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search by invoice number or client',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                              value: 'Oldest',
                              child: Text('Oldest'),
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
                              _searchController.clear();
                            });
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (BuildContext context, int index) {
                            final InvoiceRecord invoice = filtered[index];
                            return InvoiceTile(
                              invoiceNo: invoice.number,
                              clientName: invoice.client,
                              amount: _money(invoice.totalAmount),
                              status: invoice.status,
                              dateLabel: 'Due ${_dateLabel(invoice.dueDate)}',
                              tags: invoice.tags,
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
          },
    );
  }

  Widget _metric(String label, String value) {
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
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final InvoiceRecord invoice;

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateStatus(
    BuildContext context,
    InvoiceRecord currentInvoice,
    String status,
  ) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    try {
      await firestore.updateInvoicePaymentStatus(
        invoiceId: currentInvoice.id,
        paymentStatus: status,
      );
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Invoice status updated to $status.');
    } catch (error) {
      _showMessage(context, 'Could not update status: $error');
    }
  }

  Future<void> _recordPayment(
    BuildContext context,
    InvoiceRecord currentInvoice, {
    double? presetAmount,
    String method = 'UPI',
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController(
      text: presetAmount == null ? '' : presetAmount.toStringAsFixed(2),
    );
    final TextEditingController methodController = TextEditingController(
      text: method,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Record Payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Balance: ${_money(currentInvoice.balanceAmount)}'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (String? value) {
                        final double amount =
                            double.tryParse(value?.trim() ?? '') ?? 0;
                        if (amount <= 0) {
                          return 'Enter valid amount';
                        }
                        final double maxPayable = currentInvoice.balanceAmount;
                        if (maxPayable <= 0) {
                          return 'Invoice is already fully paid';
                        }
                        if (amount > maxPayable) {
                          return 'Amount cannot exceed ${_money(maxPayable)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: methodController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          final FirestoreService firestore = context
                              .read<FirestoreService>();
                          try {
                            await firestore.recordInvoicePayment(
                              invoiceId: currentInvoice.id,
                              amount:
                                  double.tryParse(
                                    amountController.text.trim(),
                                  ) ??
                                  0,
                              method: methodController.text.trim(),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            _showMessage(context, 'Payment recorded.');
                          } catch (error) {
                            _showMessage(
                              context,
                              'Failed to record payment: $error',
                            );
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _receiveFullBalance(
    BuildContext context,
    InvoiceRecord currentInvoice,
  ) async {
    final double balance = currentInvoice.balanceAmount;
    if (balance <= 0) {
      _showMessage(context, 'No pending balance on this invoice.');
      return;
    }
    await _recordPayment(
      context,
      currentInvoice,
      presetAmount: balance,
      method: 'Settlement',
    );
  }

  Future<void> _deleteInvoice(
    BuildContext context,
    InvoiceRecord currentInvoice,
  ) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    try {
      await firestore.deleteInvoice(invoiceId: currentInvoice.id);
      if (!context.mounted) {
        return;
      }
      _showMessage(context, 'Invoice deleted.');
      Navigator.of(context).pop();
    } catch (error) {
      _showMessage(context, 'Could not delete invoice: $error');
    }
  }

  void _showPayload(BuildContext context, InvoiceRecord currentInvoice) {
    final String payload = const JsonEncoder.withIndent('  ').convert(
      <String, dynamic>{'id': currentInvoice.id, ...currentInvoice.toMap()},
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Invoice Firebase Payload',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          payload,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    return StreamBuilder<List<InvoiceRecord>>(
      stream:
          firestore?.streamInvoices() ??
          Stream<List<InvoiceRecord>>.value(<InvoiceRecord>[invoice]),
      builder: (BuildContext context, AsyncSnapshot<List<InvoiceRecord>> snapshot) {
        final List<InvoiceRecord> invoices =
            snapshot.data ?? <InvoiceRecord>[invoice];
        final InvoiceRecord currentInvoice = invoices.firstWhere(
          (InvoiceRecord value) => value.id == invoice.id,
          orElse: () => invoice,
        );
        return StreamBuilder<String?>(
          stream: firestore?.streamUserRole() ?? Stream<String?>.value('admin'),
          builder: (BuildContext context, AsyncSnapshot<String?> roleSnapshot) {
            final String role = (roleSnapshot.data ?? 'admin').toLowerCase();
            final bool canDeleteInvoice = role == 'admin' || role == 'owner';
            return Scaffold(
              appBar: AppBar(title: Text(currentInvoice.number)),
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
                            _row('Client', currentInvoice.client),
                            _row('Status', currentInvoice.status),
                            _row(
                              'Due Date',
                              '${currentInvoice.dueDate.day}/${currentInvoice.dueDate.month}/${currentInvoice.dueDate.year}',
                            ),
                            _row('Subtotal', _money(currentInvoice.subtotal)),
                            _row('GST', _money(currentInvoice.gstAmount)),
                            const Divider(height: 18),
                            _row(
                              'Total',
                              _money(currentInvoice.totalAmount),
                              emphasize: true,
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
                              'Payment Center',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            _row(
                              'Paid Amount',
                              _money(currentInvoice.paidAmount),
                            ),
                            _row(
                              'Balance Amount',
                              _money(currentInvoice.balanceAmount),
                              emphasize: currentInvoice.balanceAmount > 0,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: currentInvoice.totalAmount <= 0
                                    ? 0
                                    : (currentInvoice.paidAmount /
                                              currentInvoice.totalAmount)
                                          .clamp(0, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () =>
                              _updateStatus(context, currentInvoice, 'Pending'),
                          child: const Text('Mark Pending'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              _updateStatus(context, currentInvoice, 'Paid'),
                          child: const Text('Mark Paid'),
                        ),
                        OutlinedButton(
                          onPressed: currentInvoice.balanceAmount > 0
                              ? () => _recordPayment(context, currentInvoice)
                              : null,
                          child: const Text('Record Payment'),
                        ),
                        if (currentInvoice.balanceAmount > 0)
                          OutlinedButton(
                            onPressed: () =>
                                _receiveFullBalance(context, currentInvoice),
                            child: const Text('Receive Full Balance'),
                          ),
                        if (canDeleteInvoice)
                          OutlinedButton(
                            onPressed: () =>
                                _deleteInvoice(context, currentInvoice),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete Invoice'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Items',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            for (final InvoiceItem item in currentInvoice.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(child: Text(item.product)),
                                    Text('${item.qty} x ${_money(item.price)}'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (currentInvoice.paymentHistory.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Payment History',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              for (final InvoicePaymentEntry entry
                                  in currentInvoice.paymentHistory)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.payments_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${entry.method.isEmpty ? 'Payment' : entry.method} • '
                                          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                        ),
                                      ),
                                      Text(
                                        _money(entry.amount),
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
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPayload(context, currentInvoice),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Firebase Payload'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesEmptyState extends StatelessWidget {
  const _InvoicesEmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
            ),
          ),
        );
      },
    );
  }
}
