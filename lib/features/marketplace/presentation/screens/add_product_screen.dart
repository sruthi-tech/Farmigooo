import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/product_model.dart';
import '../../../../widgets/custom_button.dart';

/// Screen allowing a farmer to list new produce/goods on the marketplace.
class AddProductScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const AddProductScreen({
    super.key,
    this.firestore,
    this.auth,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  static const List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Other',
  ];

  static const List<String> _units = [
    'kg',
    'g',
    'litre',
    'dozen',
    'piece',
  ];

  String _selectedCategory = _categories.first;
  String _selectedUnit = _units.first;
  bool _isLoading = false;

  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      final vendorId = currentUser?.uid ?? 'guest_farmer';

      final docRef = _firestore.collection(FirestoreCollections.products).doc();
      final now = DateTime.now();

      final product = ProductModel(
        productId: docRef.id,
        vendorId: vendorId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text.trim()),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        available: true,
        createdAt: now,
        updatedAt: now,
        images: const [],
      );

      await docRef.set(product.toMap());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to Marketplace successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppColors.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Information Banner
                Container(
                  padding: const EdgeInsets.all(AppColors.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppColors.radiusMedium),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primaryGreen,
                        size: 32,
                      ),
                      const SizedBox(width: AppColors.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Marketplace Listing',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'List your produce directly to buyers at transparent prices.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppColors.paddingLarge),

                // Product Name Field
                TextFormField(
                  key: const Key('product_name_field'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g., Organic Red Tomatoes',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  key: const Key('product_category_dropdown'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Description Field
                TextFormField(
                  key: const Key('product_description_field'),
                  controller: _descriptionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe freshness, harvest date, quality...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppColors.paddingMedium),

                // Price and Quantity/Unit Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Field
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        key: const Key('product_price_field'),
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter price';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppColors.paddingMedium),

                    // Quantity Field
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        key: const Key('product_quantity_field'),
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          hintText: '10',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter quantity';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppColors.paddingSmall),

                    // Unit Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        key: const Key('product_unit_dropdown'),
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: AppColors.paddingMedium,
                          ),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppColors.paddingLarge),

                // Submit Button
                CustomButton(
                  key: const Key('submit_product_button'),
                  label: 'Add Product to Marketplace',
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _isLoading ? null : _submitProduct,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
