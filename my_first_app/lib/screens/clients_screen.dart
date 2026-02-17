import 'package:flutter/material.dart';

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

  final List<Map<String, dynamic>> _clients = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Apex Interiors',
      'email': 'finance@apexinteriors.com',
      'phone': '+91 98200 12345',
      'pending': '₹27,500',
      'invoices': 14,
      'isActive': true,
      'segment': 'Corporate',
      'creditLimit': 300000.0,
      'usedCredit': 157000.0,
      'history': <String>['INV-2031', 'INV-2022', 'INV-2018'],
    },
    <String, dynamic>{
      'name': 'Urban Pulse Media',
      'email': 'accounts@urbanpulse.media',
      'phone': '+91 97665 30303',
      'pending': '₹0',
      'invoices': 8,
      'isActive': true,
      'segment': 'Retail',
      'creditLimit': 150000.0,
      'usedCredit': 38000.0,
      'history': <String>['INV-2030', 'INV-2024', 'INV-2017'],
    },
    <String, dynamic>{
      'name': 'Nova Fabricators',
      'email': 'office@novafab.in',
      'phone': '+91 99871 55667',
      'pending': '₹18,750',
      'invoices': 11,
      'isActive': false,
      'segment': 'Wholesale',
      'creditLimit': 220000.0,
      'usedCredit': 198000.0,
      'history': <String>['INV-2029', 'INV-2020', 'INV-2015'],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> filtered = _clients.where((
      Map<String, dynamic> client,
    ) {
      final String name = (client['name'] as String).toLowerCase();
      final String email = (client['email'] as String).toLowerCase();
      final bool segmentMatch =
          _selectedSegment == 'All' || client['segment'] == _selectedSegment;
      return segmentMatch && (name.contains(query) || email.contains(query));
    }).toList();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    final Map<String, dynamic> client = filtered[index];
                    return ClientTile(
                      name: client['name'] as String,
                      email: '${client['email']}  •  ${client['segment']}',
                      pendingAmount: client['pending'] as String,
                      isActive: client['isActive'] as bool,
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
  }
}

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({super.key, required this.client});

  final Map<String, dynamic> client;

  String _money(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final List<String> history = (client['history'] as List<dynamic>)
        .cast<String>();
    final double creditLimit = client['creditLimit'] as double;
    final double usedCredit = client['usedCredit'] as double;
    final double remainingCredit = (creditLimit - usedCredit).clamp(
      0,
      creditLimit,
    );
    final double usedRatio = creditLimit == 0
        ? 0
        : (usedCredit / creditLimit).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(client['name'] as String)),
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
                    _infoRow(Icons.email_outlined, client['email'] as String),
                    const SizedBox(height: 8),
                    _infoRow(Icons.phone_outlined, client['phone'] as String),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.business_outlined,
                      client['segment'] as String,
                    ),
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
                        value: '${client['invoices']}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricCard(
                        context,
                        title: 'Pending amount',
                        value: client['pending'] as String,
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
                      'Client Credit Limit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _creditRow('Credit limit', _money(creditLimit)),
                    _creditRow('Used credit', _money(usedCredit)),
                    _creditRow('Remaining credit', _money(remainingCredit)),
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
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Invoice History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final String invoice in history)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(invoice),
                        trailing: const Icon(Icons.chevron_right),
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
    return Center(
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
    );
  }
}
