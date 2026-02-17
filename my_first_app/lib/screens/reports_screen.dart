import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _show(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Export & Reports UI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate downloadable report templates for accounting workflows.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () =>
                _show(context, 'Monthly report download started (UI only).'),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download Monthly Report'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () =>
                _show(context, 'GST summary export started (UI only).'),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download GST Summary'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () =>
                _show(context, 'Income tax summary export started (UI only).'),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download Income Tax Summary'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _show(context, 'Export as PDF clicked (UI only).'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export as PDF (UI only)'),
          ),
        ],
      ),
    );
  }
}
