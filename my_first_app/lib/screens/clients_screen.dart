import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_record.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../widgets/client_tile.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _segments = <String>[
    'All',
    'Retail',
    'Wholesale',
    'Corporate',
  ];

  String _selectedSegment = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _money(double value) => '₹${value.toStringAsFixed(0)}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddClientSheet() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController gstinController = TextEditingController();
    final TextEditingController stateController = TextEditingController(
      text: 'Corporate',
    );
    final TextEditingController creditLimitController = TextEditingController(
      text: '100000',
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
                      'Add Client',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved in users/{uid}/clients',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter phone';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter email';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: gstinController,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter GSTIN';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Segment',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter state';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: creditLimitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Credit Limit',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (String? value) {
                        final double amount =
                            double.tryParse(value?.trim() ?? '') ?? -1;
                        if (amount < 0) {
                          return 'Invalid credit limit';
                        }
                        return null;
                      },
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
                          try {
                            await firestoreService.addClient(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim(),
                              address: addressController.text.trim(),
                              gstin: gstinController.text.trim(),
                              state: stateController.text.trim(),
                              creditLimit:
                                  double.tryParse(
                                    creditLimitController.text.trim(),
                                  ) ??
                                  0,
                            );
                            await analyticsService.logEvent('add_client');
                            if (!mounted) {
                              return;
                            }
                            navigator.pop();
                            _showMessage('Client saved to Firestore.');
                          } catch (error) {
                            _showMessage('Could not save client: $error');
                          }
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Save Client'),
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

  void _showPayload(List<ClientRecord> clients) {
    final String payload = const JsonEncoder.withIndent('  ').convert(
      clients
          .map(
            (ClientRecord client) => <String, dynamic>{
              'id': client.id,
              ...client.toMap(),
            },
          )
          .toList(),
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
                    'Clients Firebase Payload',
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
    final FirestoreService? firestoreService = context
        .read<FirestoreService?>();
    return StreamBuilder<List<ClientRecord>>(
      stream:
          firestoreService?.streamClients() ??
          Stream<List<ClientRecord>>.value(const <ClientRecord>[]),
      builder:
          (BuildContext context, AsyncSnapshot<List<ClientRecord>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load clients: ${snapshot.error}'),
                ),
              );
            }

            final String query = _searchController.text.trim().toLowerCase();
            final List<ClientRecord> clients =
                snapshot.data ?? <ClientRecord>[];
            final List<ClientRecord> filtered = clients.where((
              ClientRecord client,
            ) {
              final bool segmentMatch =
                  _selectedSegment == 'All' ||
                  client.segment == _selectedSegment;
              final bool queryMatch =
                  query.isEmpty ||
                  client.name.toLowerCase().contains(query) ||
                  client.email.toLowerCase().contains(query);
              return segmentMatch && queryMatch;
            }).toList();

            final double totalPending = filtered.fold<double>(
              0,
              (double value, ClientRecord client) =>
                  value + client.pendingAmount,
            );

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
                        colors: <Color>[Color(0xFF1D4ED8), Color(0xFF2563EB)],
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
                              Icons.groups_2_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Client CRM (Realtime)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _showAddClientSheet,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _metric('Clients', '${filtered.length}'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _metric('Pending', _money(totalPending)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: filtered.isEmpty
                                ? null
                                : () => _showPayload(filtered),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            icon: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 18,
                            ),
                            label: const Text('Payload'),
                          ),
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
                      hintText: 'Search clients by name or email',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _segments.map((String segment) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(segment),
                            selected: _selectedSegment == segment,
                            onSelected: (_) {
                              setState(() {
                                _selectedSegment = segment;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? _ClientsEmptyState(
                          segment: _selectedSegment,
                          onReset: () {
                            setState(() {
                              _selectedSegment = 'All';
                              _searchController.clear();
                            });
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ClientRecord client = filtered[index];
                            return ClientTile(
                              name: client.name,
                              email: '${client.email}  •  ${client.segment}',
                              pendingAmount: _money(client.pendingAmount),
                              isActive: client.isActive,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        ClientDetailScreen(client: client),
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

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.client});

  final ClientRecord client;

  String _money(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final double usedRatio = client.creditUsageRatio;

    return Scaffold(
      appBar: AppBar(title: Text(client.name)),
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
                      'Contact Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(Icons.email_outlined, client.email),
                    const SizedBox(height: 8),
                    _infoRow(Icons.phone_outlined, client.phone),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined, client.address),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Total invoices',
                        value: '${client.invoices}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Pending amount',
                        value: _money(client.pendingAmount),
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
                      'Credit Utilization',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _creditRow('Credit limit', _money(client.creditLimit)),
                    _creditRow('Used credit', _money(client.usedCredit)),
                    _creditRow('Available', _money(client.availableCredit)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: usedRatio,
                        minHeight: 10,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(usedRatio * 100).toStringAsFixed(0)}% credit utilized',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
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

  Widget _creditRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(key),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ClientsEmptyState extends StatelessWidget {
  const _ClientsEmptyState({required this.segment, required this.onReset});

  final String segment;
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
                      const Icon(Icons.groups_2_outlined, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'No $segment clients found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text('Try another segment or search term.'),
                      const SizedBox(height: 10),
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
