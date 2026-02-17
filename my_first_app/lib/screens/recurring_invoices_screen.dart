import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recurring_invoice_record.dart';
import '../services/firestore_service.dart';

class RecurringInvoicesScreen extends StatefulWidget {
  const RecurringInvoicesScreen({super.key});

  @override
  State<RecurringInvoicesScreen> createState() =>
      _RecurringInvoicesScreenState();
}

class _RecurringInvoicesScreenState extends State<RecurringInvoicesScreen> {
  String _dateLabel(DateTime value) {
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteRecurring(RecurringInvoiceRecord recurring) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    try {
      await firestore.deleteRecurringInvoice(recurringId: recurring.id);
      if (!mounted) {
        return;
      }
      _showMessage('Recurring invoice deleted.');
    } catch (error) {
      _showMessage('Could not delete recurring invoice: $error');
    }
  }

  Future<void> _togglePause(RecurringInvoiceRecord recurring) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    try {
      await firestore.updateRecurringInvoice(
        recurringId: recurring.id,
        frequency: recurring.frequency,
        nextInvoiceDate: recurring.nextInvoiceDate,
        autoGenerate: recurring.autoGenerate,
        isPaused: !recurring.isPaused,
      );
      if (!mounted) {
        return;
      }
      _showMessage(
        recurring.isPaused
            ? 'Recurring invoice resumed.'
            : 'Recurring invoice paused.',
      );
    } catch (error) {
      _showMessage('Could not update recurring invoice: $error');
    }
  }

  void _openRecurringSheet({RecurringInvoiceRecord? recurring}) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final Map<String, dynamic> firstItem = recurring?.items.isNotEmpty == true
        ? recurring!.items.first
        : <String, dynamic>{};
    final TextEditingController clientIdController = TextEditingController(
      text: recurring?.clientId ?? '',
    );
    final TextEditingController clientNameController = TextEditingController(
      text: recurring?.clientName ?? '',
    );
    final TextEditingController itemNameController = TextEditingController(
      text: firstItem['name'] as String? ?? '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: ((firstItem['quantity'] as num?)?.toDouble() ?? 1).toString(),
    );
    final TextEditingController priceController = TextEditingController(
      text: ((firstItem['price'] as num?)?.toDouble() ?? 0).toString(),
    );
    final TextEditingController gstController = TextEditingController(
      text: ((firstItem['gstRate'] as num?)?.toDouble() ?? 18).toString(),
    );

    String frequency = recurring?.frequency ?? 'monthly';
    bool autoGenerate = recurring?.autoGenerate ?? true;
    bool isPaused = recurring?.isPaused ?? false;
    DateTime nextDate =
        recurring?.nextInvoiceDate ??
        DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
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
                            Text(
                              recurring == null
                                  ? 'Create Recurring Invoice'
                                  : 'Edit Recurring Invoice',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
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
                            const SizedBox(height: 10),
                            TextFormField(
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
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: itemNameController,
                              decoration: const InputDecoration(
                                labelText: 'Item Name',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter item name';
                                }
                                return null;
                              },
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
                                          double.tryParse(
                                            value?.trim() ?? '',
                                          ) ??
                                          0;
                                      if (parsed <= 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                          double.tryParse(
                                            value?.trim() ?? '',
                                          ) ??
                                          0;
                                      if (parsed <= 0) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: frequency,
                              decoration: const InputDecoration(
                                labelText: 'Frequency',
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
                                  frequency = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: context,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 1),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 3650),
                                      ),
                                      initialDate: nextDate,
                                    );
                                if (pickedDate == null) {
                                  return;
                                }
                                setModalState(() {
                                  nextDate = pickedDate;
                                });
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Next Invoice Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                                child: Text(_dateLabel(nextDate)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile(
                              value: autoGenerate,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Auto Generate'),
                              subtitle: const Text(
                                'Create invoice automatically on due date',
                              ),
                              onChanged: (bool value) {
                                setModalState(() {
                                  autoGenerate = value;
                                });
                              },
                            ),
                            SwitchListTile(
                              value: isPaused,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Pause Subscription'),
                              subtitle: const Text(
                                'Pause invoice generation temporarily',
                              ),
                              onChanged: (bool value) {
                                setModalState(() {
                                  isPaused = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final FirestoreService firestore = context
                                      .read<FirestoreService>();
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
                                      double.tryParse(
                                        gstController.text.trim(),
                                      ) ??
                                      0;
                                  final double subtotal = quantity * price;
                                  final double gstAmount =
                                      subtotal * (gstRate / 100);
                                  final double total = subtotal + gstAmount;

                                  final List<Map<String, dynamic>> items =
                                      <Map<String, dynamic>>[
                                        <String, dynamic>{
                                          'productId': 'recurring_manual',
                                          'name': itemNameController.text
                                              .trim(),
                                          'quantity': quantity,
                                          'price': price,
                                          'gstRate': gstRate,
                                          'gstAmount': gstAmount,
                                          'total': total,
                                        },
                                      ];

                                  try {
                                    if (recurring == null) {
                                      await firestore.addRecurringInvoice(
                                        clientId: clientIdController.text
                                            .trim(),
                                        clientName: clientNameController.text
                                            .trim(),
                                        items: items,
                                        frequency: frequency,
                                        nextInvoiceDate: nextDate,
                                        autoGenerate: autoGenerate,
                                      );
                                    } else {
                                      await firestore.updateRecurringInvoice(
                                        recurringId: recurring.id,
                                        frequency: frequency,
                                        nextInvoiceDate: nextDate,
                                        autoGenerate: autoGenerate,
                                        isPaused: isPaused,
                                      );
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    navigator.pop();
                                    _showMessage(
                                      recurring == null
                                          ? 'Recurring invoice created.'
                                          : 'Recurring invoice updated.',
                                    );
                                  } catch (error) {
                                    _showMessage(
                                      'Could not save recurring invoice: $error',
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save'),
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
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return const Scaffold(
        body: Center(child: Text('Recurring invoice service unavailable.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecurringSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
      body: StreamBuilder<List<RecurringInvoiceRecord>>(
        stream: firestore.streamRecurringInvoices(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<RecurringInvoiceRecord>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load recurring invoices: ${snapshot.error}',
                    ),
                  ),
                );
              }
              final List<RecurringInvoiceRecord> recurringInvoices =
                  snapshot.data ?? <RecurringInvoiceRecord>[];
              if (recurringInvoices.isEmpty) {
                return const Center(
                  child: Text('No recurring invoices yet. Create one now.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recurringInvoices.length,
                itemBuilder: (BuildContext context, int index) {
                  final RecurringInvoiceRecord recurring =
                      recurringInvoices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        recurring.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${recurring.frequency.toUpperCase()} • Next ${_dateLabel(recurring.nextInvoiceDate)}'
                        '\nAuto: ${recurring.autoGenerate ? 'On' : 'Off'} • ${recurring.isPaused ? 'Paused' : 'Active'}',
                      ),
                      isThreeLine: true,
                      leading: CircleAvatar(
                        child: Text(
                          recurring.clientName.isEmpty
                              ? '?'
                              : recurring.clientName[0],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String action) async {
                          if (action == 'edit') {
                            _openRecurringSheet(recurring: recurring);
                            return;
                          }
                          if (action == 'pause') {
                            await _togglePause(recurring);
                            return;
                          }
                          if (action == 'delete') {
                            await _deleteRecurring(recurring);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem<String>(
                              value: 'pause',
                              child: Text(
                                recurring.isPaused ? 'Resume' : 'Pause',
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ];
                        },
                      ),
                    ),
                  );
                },
              );
            },
      ),
    );
  }
}
