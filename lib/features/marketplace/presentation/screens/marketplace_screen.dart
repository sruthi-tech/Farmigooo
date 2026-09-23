import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../models/product_model.dart';
import 'add_product_screen.dart';

/// Screen displaying all produce and marketplace items in a live-updating stream.
class MarketplaceScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? productsStream;

  const MarketplaceScreen({
    super.key,
    this.firestore,
    this.productsStream,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategoryFilter = 'All';

  static const List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Other',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _getProductsStream() {
    if (widget.productsStream != null) {
      return widget.productsStream!;
    }
    try {
      final firestore = widget.firestore ?? FirebaseFirestore.instance;
      return firestore.collection(FirestoreCollections.products).snapshots();
    } catch (e) {
      return const Stream.empty();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return AppColors.primaryGreen;
      case 'fruits':
        return AppColors.accentAmber;
      case 'grains':
        return const Color(0xFF8D6E63);
      case 'dairy':
        return AppColors.info;
      default:
        return const Color(0xFF7E57C2);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco_rounded;
      case 'fruits':
        return Icons.apple_rounded;
      case 'grains':
        return Icons.grass_rounded;
      case 'dairy':
        return Icons.water_drop_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _navigateToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(firestore: widget.firestore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'Add Product',
            onPressed: _navigateToAddProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.paddingMedium,
              vertical: AppColors.paddingSmall,
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryFilter == category;
                return ChoiceChip(
                  key: Key('category_chip_$category'),
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryGreen : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryFilter = category);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Live-Updating Stream of Products
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppColors.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: AppColors.paddingMedium),
                          Text(
                            'Failed to load products',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppColors.paddingSmall),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppColors.paddingMedium),
                        Text('Loading marketplace produce...'),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                // Parse documents using ProductModel.fromMap()
                final allProducts = docs.map((doc) {
                  return ProductModel.fromMap(doc.data(), doc.id);
                }).toList();

                // Apply selected category filter
                final filteredProducts = _selectedCategoryFilter == 'All'
                    ? allProducts
                    : allProducts.where((p) => p.category.toLowerCase() == _selectedCategoryFilter.toLowerCase()).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppColors.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              size: 64,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingMedium),
                          Text(
                            _selectedCategoryFilter == 'All'
                                ? 'No Products Available'
                                : 'No $_selectedCategoryFilter Available',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingSmall),
                          Text(
                            'Farmers can add new produce listings using the button below.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: AppColors.paddingLarge),
                          ElevatedButton.icon(
                            onPressed: _navigateToAddProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppColors.paddingMedium),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppColors.paddingMedium),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final categoryColor = _getCategoryColor(product.category);
                    final categoryIcon = _getCategoryIcon(product.category);

                    return Card(
                      key: Key('product_card_${product.productId}'),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(AppColors.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Category Badge & Availability
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Category Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(categoryIcon, size: 14, color: categoryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: categoryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Stock Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (product.available ? AppColors.success : AppColors.error)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                  ),
                                  child: Text(
                                    product.available ? 'In Stock' : 'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: product.available ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppColors.paddingSmall),

                            // Product Name
                            Text(
                              product.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppColors.paddingMedium),
                            const Divider(height: 1),
                            const SizedBox(height: AppColors.paddingSmall),

                            // Footer: Price and Quantity+Unit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Price
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Price',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${product.price.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // Quantity + Unit
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Quantity Available',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(AppColors.radiusSmall),
                                      ),
                                      child: Text(
                                        '${product.quantity % 1 == 0 ? product.quantity.toInt() : product.quantity} ${product.unit}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_product_fab'),
        onPressed: _navigateToAddProduct,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    );
  }
}
