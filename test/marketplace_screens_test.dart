import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmigo/core/theme/app_theme.dart';
import 'package:farmigo/features/marketplace/presentation/screens/add_product_screen.dart';
import 'package:farmigo/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:farmigo/models/product_model.dart';

void main() {
  group('AddProductScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AddProductScreen(),
      );
    }

    testWidgets('renders all required form fields and dropdowns', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify Screen Title
      expect(find.text('Add Product'), findsOneWidget);

      // Verify form fields
      expect(find.byKey(const Key('product_name_field')), findsOneWidget);
      expect(find.byKey(const Key('product_category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('product_description_field')), findsOneWidget);
      expect(find.byKey(const Key('product_price_field')), findsOneWidget);
      expect(find.byKey(const Key('product_quantity_field')), findsOneWidget);
      expect(find.byKey(const Key('product_unit_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('submit_product_button')), findsOneWidget);

      // Verify default dropdown selections
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final submitBtn = find.byKey(const Key('submit_product_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      // Check validation error texts
      expect(find.text('Please enter a product name'), findsOneWidget);
      expect(find.text('Please enter a product description'), findsOneWidget);
      expect(find.text('Enter price'), findsOneWidget);
      expect(find.text('Enter quantity'), findsOneWidget);
    });

    testWidgets('allows category and unit dropdown selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Test category selection
      final categoryDropdown = find.byKey(const Key('product_category_dropdown'));
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();

      // Verify all categories in dropdown
      expect(find.text('Vegetables').hitTestable(), findsWidgets);
      expect(find.text('Fruits').hitTestable(), findsOneWidget);
      expect(find.text('Grains').hitTestable(), findsOneWidget);
      expect(find.text('Dairy').hitTestable(), findsOneWidget);
      expect(find.text('Other').hitTestable(), findsOneWidget);

      // Select 'Dairy'
      await tester.tap(find.text('Dairy').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Dairy'), findsOneWidget);

      // Test unit selection
      final unitDropdown = find.byKey(const Key('product_unit_dropdown'));
      await tester.tap(unitDropdown);
      await tester.pumpAndSettle();

      // Verify all units in dropdown
      expect(find.text('kg').hitTestable(), findsWidgets);
      expect(find.text('g').hitTestable(), findsOneWidget);
      expect(find.text('litre').hitTestable(), findsOneWidget);
      expect(find.text('dozen').hitTestable(), findsOneWidget);
      expect(find.text('piece').hitTestable(), findsOneWidget);

      // Select 'litre'
      await tester.tap(find.text('litre').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('litre'), findsOneWidget);
    });
  });

  group('MarketplaceScreen Widget Tests', () {
    testWidgets('renders app bar, category chips, and FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MarketplaceScreen(),
        ),
      );

      // AppBar title
      expect(find.text('Marketplace'), findsOneWidget);

      // Category chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Fruits'), findsOneWidget);
      expect(find.text('Grains'), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Floating Action Button
      final fab = find.byKey(const Key('add_product_fab'));
      expect(fab, findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);
    });

    testWidgets('FAB navigates to AddProductScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MarketplaceScreen(),
        ),
      );

      final fab = find.byKey(const Key('add_product_fab'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify AddProductScreen is now pushed
      expect(find.byType(AddProductScreen), findsOneWidget);
      expect(find.byKey(const Key('submit_product_button')), findsOneWidget);
    });
  });

  group('ProductModel Marketplace Integration Tests', () {
    test('ProductModel toMap and fromMap handles marketplace product fields correctly', () {
      final now = DateTime.now();
      final product = ProductModel(
        productId: 'prod_999',
        vendorId: 'vendor_farmer_123',
        name: 'Fresh Cow Milk',
        description: 'Pure and farm-fresh organic milk',
        category: 'Dairy',
        price: 65.0,
        quantity: 20.0,
        unit: 'litre',
        available: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = product.toMap();
      expect(map['productId'], 'prod_999');
      expect(map['vendorId'], 'vendor_farmer_123');
      expect(map['name'], 'Fresh Cow Milk');
      expect(map['category'], 'Dairy');
      expect(map['price'], 65.0);
      expect(map['quantity'], 20.0);
      expect(map['unit'], 'litre');
      expect(map['available'], true);
      expect(map['createdAt'], isNotNull);

      final restored = ProductModel.fromMap(map, 'prod_999');
      expect(restored.productId, 'prod_999');
      expect(restored.vendorId, 'vendor_farmer_123');
      expect(restored.name, 'Fresh Cow Milk');
      expect(restored.category, 'Dairy');
      expect(restored.price, 65.0);
      expect(restored.quantity, 20.0);
      expect(restored.unit, 'litre');
      expect(restored.available, true);
    });
  });
}
