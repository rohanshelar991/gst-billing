import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_record.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openProductSheet({ProductRecord? product}) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: product?.name ?? '',
    );
    final TextEditingController hsnController = TextEditingController(
      text: product?.hsnCode ?? '',
    );
    final TextEditingController costController = TextEditingController(
      text: product?.costPrice.toStringAsFixed(2) ?? '',
    );
    final TextEditingController sellingController = TextEditingController(
      text: product?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    final TextEditingController gstController = TextEditingController(
      text: product?.gstRate.toStringAsFixed(0) ?? '18',
    );
    final TextEditingController stockController = TextEditingController(
      text: product?.stockQuantity.toString() ?? '0',
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
                      product == null ? 'Add Product' : 'Edit Product',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved to Firestore users/{uid}/products',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: hsnController,
                      decoration: const InputDecoration(
                        labelText: 'HSN Code',
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter HSN code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: costController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cost Price',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            validator: (String? value) {
                              final double amount =
                                  double.tryParse(value?.trim() ?? '') ?? 0;
                              if (amount <= 0) {
                                return 'Invalid cost';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: sellingController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Selling Price',
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                            validator: (String? value) {
                              final double amount =
                                  double.tryParse(value?.trim() ?? '') ?? 0;
                              if (amount <= 0) {
                                return 'Invalid selling';
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'GST Rate %',
                              prefixIcon: Icon(Icons.percent),
                            ),
                            validator: (String? value) {
                              final double amount =
                                  double.tryParse(value?.trim() ?? '') ?? -1;
                              if (amount < 0) {
                                return 'Invalid GST';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock Quantity',
                              prefixIcon: Icon(Icons.layers_outlined),
                            ),
                            validator: (String? value) {
                              final int amount =
                                  int.tryParse(value?.trim() ?? '') ?? -1;
                              if (amount < 0) {
                                return 'Invalid stock';
                              }
                              return null;
                            },
                          ),
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
                          final double costPrice =
                              double.tryParse(costController.text.trim()) ?? 0;
                          final double sellingPrice =
                              double.tryParse(sellingController.text.trim()) ??
                              0;
                          final double gstRate =
                              double.tryParse(gstController.text.trim()) ?? 0;
                          final int stockQuantity =
                              int.tryParse(stockController.text.trim()) ?? 0;

                          try {
                            if (product == null) {
                              await firestoreService.addProduct(
                                name: nameController.text.trim(),
                                hsnCode: hsnController.text.trim(),
                                costPrice: costPrice,
                                sellingPrice: sellingPrice,
                                gstRate: gstRate,
                                stockQuantity: stockQuantity,
                              );
                              await analyticsService.logEvent('add_product');
                            } else {
                              await firestoreService.updateProduct(
                                productId: product.id,
                                name: nameController.text.trim(),
                                hsnCode: hsnController.text.trim(),
                                costPrice: costPrice,
                                sellingPrice: sellingPrice,
                                gstRate: gstRate,
                                stockQuantity: stockQuantity,
                              );
                              await analyticsService.logEvent('edit_product');
                            }
                            if (!mounted) {
                              return;
                            }
                            navigator.pop();
                            _showMessage(
                              product == null
                                  ? 'Product saved to Firestore.'
                                  : 'Product updated.',
                            );
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            _showMessage('Could not save product: $error');
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          product == null ? 'Save Product' : 'Update Product',
                        ),
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

  Future<void> _deleteProduct(ProductRecord product) async {
    final FirestoreService firestoreService = context.read<FirestoreService>();
    final AnalyticsService analyticsService = context.read<AnalyticsService>();
    try {
      await firestoreService.deleteProduct(productId: product.id);
      await analyticsService.logEvent('delete_product');
      if (!mounted) {
        return;
      }
      _showMessage('Product deleted.');
    } catch (error) {
      _showMessage('Could not delete product: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService? firestoreService = context
        .read<FirestoreService?>();
    return StreamBuilder<List<ProductRecord>>(
      stream:
          firestoreService?.streamProducts() ??
          Stream<List<ProductRecord>>.value(const <ProductRecord>[]),
      builder: (BuildContext context, AsyncSnapshot<List<ProductRecord>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load products: ${snapshot.error}'),
            ),
          );
        }

        final List<ProductRecord> products = snapshot.data ?? <ProductRecord>[];
        final int totalStock = products.fold<int>(
          0,
          (int value, ProductRecord product) => value + product.stockQuantity,
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
                    colors: <Color>[Color(0xFF0891B2), Color(0xFF0E7490)],
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
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Products Inventory',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openProductSheet(),
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
                          child: _metric('Products', '${products.length}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _metric('Stock Units', '$totalStock')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text('No products yet. Add your first product.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: products.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ProductRecord product = products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryBlue.withValues(
                                alpha: 0.14,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: primaryBlue,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'HSN: ${product.hsnCode}  •  GST ${product.gstRate.toStringAsFixed(0)}%',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  _money(product.sellingPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stock: ${product.stockQuantity}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (String value) {
                                    if (value == 'edit') {
                                      _openProductSheet(product: product);
                                      return;
                                    }
                                    if (value == 'delete') {
                                      _deleteProduct(product);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return const <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                          ),
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
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
