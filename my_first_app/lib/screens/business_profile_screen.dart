import 'package:flutter/material.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.image_outlined),
                          SizedBox(height: 4),
                          Text('Logo Upload', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Business Name',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'GST Number',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'PAN Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Bank Details',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Business profile saved (UI only).',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Profile'),
                      ),
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
}
