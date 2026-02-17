import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company_record.dart';
import '../services/firestore_service.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openCompanySheet({CompanyRecord? company}) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: company?.name ?? '',
    );
    final TextEditingController gstController = TextEditingController(
      text: company?.gstNumber ?? '',
    );
    final TextEditingController addressController = TextEditingController(
      text: company?.address ?? '',
    );
    final TextEditingController stateController = TextEditingController(
      text: company?.state ?? '',
    );
    final TextEditingController logoController = TextEditingController(
      text: company?.logoUrl ?? '',
    );
    final TextEditingController bankController = TextEditingController(
      text: company?.bankDetails ?? '',
    );
    final TextEditingController prefixController = TextEditingController(
      text: company?.invoicePrefix ?? 'INV',
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
                    Text(
                      company == null ? 'Add Company' : 'Edit Company',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: gstController,
                      decoration: const InputDecoration(
                        labelText: 'GST Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
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
                    TextFormField(
                      controller: stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: logoController,
                      decoration: const InputDecoration(
                        labelText: 'Logo URL',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: bankController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Details',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Prefix',
                        prefixIcon: Icon(Icons.tag_outlined),
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
                          final NavigatorState navigator = Navigator.of(
                            context,
                          );
                          try {
                            if (company == null) {
                              await firestore.addCompany(
                                name: nameController.text.trim(),
                                gstNumber: gstController.text.trim(),
                                address: addressController.text.trim(),
                                state: stateController.text.trim(),
                                logoUrl: logoController.text.trim(),
                                bankDetails: bankController.text.trim(),
                                invoicePrefix: prefixController.text.trim(),
                              );
                              if (!mounted) {
                                return;
                              }
                              _showMessage('Company added.');
                            } else {
                              await firestore.updateCompany(
                                companyId: company.id,
                                name: nameController.text.trim(),
                                gstNumber: gstController.text.trim(),
                                address: addressController.text.trim(),
                                state: stateController.text.trim(),
                                logoUrl: logoController.text.trim(),
                                bankDetails: bankController.text.trim(),
                                invoicePrefix: prefixController.text.trim(),
                              );
                              if (!mounted) {
                                return;
                              }
                              _showMessage('Company updated.');
                            }
                            navigator.pop();
                          } catch (error) {
                            _showMessage('Failed to save company: $error');
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
  }

  Future<void> _deleteCompany(CompanyRecord company) async {
    final FirestoreService firestore = context.read<FirestoreService>();
    try {
      await firestore.deleteCompany(companyId: company.id);
      if (!mounted) {
        return;
      }
      _showMessage('Company deleted.');
    } catch (error) {
      _showMessage('Could not delete company: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return const Scaffold(
        body: Center(child: Text('No company service found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCompanySheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Company'),
      ),
      body: StreamBuilder<String?>(
        stream: firestore.streamActiveCompanyId(),
        builder: (BuildContext context, AsyncSnapshot<String?> activeSnapshot) {
          return StreamBuilder<List<CompanyRecord>>(
            stream: firestore.streamCompanies(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<CompanyRecord>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load companies: ${snapshot.error}',
                      ),
                    );
                  }
                  final List<CompanyRecord> companies =
                      snapshot.data ?? <CompanyRecord>[];
                  if (companies.isEmpty) {
                    return const Center(
                      child: Text(
                        'No companies found. Add your first company.',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: companies.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CompanyRecord company = companies[index];
                      final bool isActive = company.id == activeSnapshot.data;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            company.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${company.gstNumber.isEmpty ? 'No GST' : company.gstNumber} • ${company.state.isEmpty ? 'State not set' : company.state}',
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              company.name.isEmpty ? '?' : company.name[0],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (String value) async {
                              if (value == 'switch') {
                                await firestore.setActiveCompany(company.id);
                                if (!mounted) {
                                  return;
                                }
                                _showMessage('Active company changed.');
                              } else if (value == 'edit') {
                                _openCompanySheet(company: company);
                              } else if (value == 'delete') {
                                await _deleteCompany(company);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'switch',
                                  child: Text('Set Active'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ];
                            },
                          ),
                          isThreeLine: isActive,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          titleAlignment: ListTileTitleAlignment.top,
                          selected: isActive,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.08),
                        ),
                      );
                    },
                  );
                },
          );
        },
      ),
    );
  }
}
