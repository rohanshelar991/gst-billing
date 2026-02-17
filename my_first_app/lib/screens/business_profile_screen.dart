import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company_record.dart';
import '../services/firestore_service.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _logoController.dispose();
    _bankController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _populateInitialValues({
    required Map<String, dynamic>? userProfile,
    required CompanyRecord? company,
  }) {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    _ownerNameController.text = (userProfile?['name'] as String? ?? '').trim();
    _emailController.text = (userProfile?['email'] as String? ?? '').trim();
    _phoneController.text = (userProfile?['phone'] as String? ?? '').trim();
    _businessNameController.text = company?.name ?? '';
    _gstController.text = company?.gstNumber ?? '';
    _addressController.text = company?.address ?? '';
    _stateController.text = company?.state ?? '';
    _logoController.text = company?.logoUrl ?? '';
    _bankController.text = company?.bankDetails ?? '';
    _prefixController.text = company?.invoicePrefix ?? 'INV';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final FirestoreService firestore = context.read<FirestoreService>();
    try {
      await firestore.saveBusinessProfile(
        name: _ownerNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        businessName: _businessNameController.text.trim(),
        gstin: _gstController.text.trim(),
        address: _addressController.text.trim(),
        state: _stateController.text.trim(),
        logoUrl: _logoController.text.trim(),
        bankDetails: _bankController.text.trim(),
        invoicePrefix: _prefixController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      _showMessage('Business profile saved.');
    } catch (error) {
      _showMessage('Failed to save profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestore = context.read<FirestoreService?>();
    if (firestore == null) {
      return const Scaffold(
        body: Center(child: Text('No profile service found.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: firestore.streamUserProfile(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<Map<String, dynamic>?> userSnapshot,
            ) {
              return StreamBuilder<CompanyRecord?>(
                stream: firestore.streamActiveCompany(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<CompanyRecord?> companySnapshot,
                    ) {
                      _populateInitialValues(
                        userProfile: userSnapshot.data,
                        company: companySnapshot.data,
                      );
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    controller: _ownerNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Owner Name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter owner name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _businessNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Company Name',
                                      prefixIcon: Icon(Icons.business_outlined),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter company name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _gstController,
                                    decoration: const InputDecoration(
                                      labelText: 'GST Number',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(
                                      labelText: 'Address',
                                      prefixIcon: Icon(
                                        Icons.location_on_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _stateController,
                                    decoration: const InputDecoration(
                                      labelText: 'State',
                                      prefixIcon: Icon(Icons.map_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _logoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Logo URL',
                                      prefixIcon: Icon(Icons.image_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _bankController,
                                    decoration: const InputDecoration(
                                      labelText: 'Bank Details',
                                      prefixIcon: Icon(
                                        Icons.account_balance_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _prefixController,
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice Prefix',
                                      prefixIcon: Icon(Icons.tag_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : _saveProfile,
                                      icon: const Icon(Icons.save_outlined),
                                      label: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save Profile'),
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
      ),
    );
  }
}
