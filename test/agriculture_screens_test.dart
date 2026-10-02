import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmigo/core/theme/app_theme.dart';
import 'package:farmigo/features/agriculture/presentation/screens/agriculture_updates_screen.dart';
import 'package:farmigo/features/agriculture/presentation/screens/post_update_screen.dart';
import 'package:farmigo/models/agriculture_update_model.dart';

void main() {
  group('PostUpdateScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: const PostUpdateScreen(),
      );
    }

    testWidgets('renders all required form fields and dropdowns', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify Screen Title
      expect(find.text('Post Agriculture Update'), findsOneWidget);

      // Verify form fields
      expect(find.byKey(const Key('update_title_field')), findsOneWidget);
      expect(find.byKey(const Key('update_category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('update_description_field')), findsOneWidget);
      expect(find.byKey(const Key('update_content_field')), findsOneWidget);
      expect(find.byKey(const Key('post_update_submit_button')), findsOneWidget);

      // Verify default category dropdown selection
      expect(find.text('Scheme'), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final submitBtn = find.byKey(const Key('post_update_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      // Check validation error texts
      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter a short description'), findsOneWidget);
      expect(find.text('Please enter the full content details'), findsOneWidget);
    });

    testWidgets('allows category dropdown selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Test category selection
      final categoryDropdown = find.byKey(const Key('update_category_dropdown'));
      await tester.tap(categoryDropdown);
      await tester.pumpAndSettle();

      // Verify all categories in dropdown
      expect(find.text('Scheme').hitTestable(), findsWidgets);
      expect(find.text('Training').hitTestable(), findsOneWidget);
      expect(find.text('Camp').hitTestable(), findsOneWidget);
      expect(find.text('Announcement').hitTestable(), findsOneWidget);
      expect(find.text('Subsidy').hitTestable(), findsOneWidget);
      expect(find.text('Event').hitTestable(), findsOneWidget);

      // Select 'Subsidy'
      await tester.tap(find.text('Subsidy').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Subsidy'), findsOneWidget);
    });
  });

  group('AgricultureUpdatesScreen Widget Tests', () {
    testWidgets('renders app bar, category chips, empty state, and FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AgricultureUpdatesScreen(),
        ),
      );
      await tester.pump();

      // AppBar title
      expect(find.text('Agriculture Updates'), findsOneWidget);

      // Category filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Scheme'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Camp'), findsOneWidget);

      // Empty State
      expect(find.text('No Agriculture Updates Available'), findsOneWidget);

      // Floating Action Button
      final fab = find.byKey(const Key('post_update_fab'));
      expect(fab, findsOneWidget);
      expect(find.text('Post Update'), findsWidgets);
    });

    testWidgets('FAB navigates to PostUpdateScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AgricultureUpdatesScreen(),
        ),
      );
      await tester.pump();

      final fab = find.byKey(const Key('post_update_fab'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify PostUpdateScreen is pushed
      expect(find.byType(PostUpdateScreen), findsOneWidget);
      expect(find.byKey(const Key('post_update_submit_button')), findsOneWidget);
    });

    testWidgets('renders update cards with category badges and handles newest-first sorting', (tester) async {
      final olderDate = DateTime(2026, 9, 20, 10, 0);
      final newerDate = DateTime(2026, 9, 24, 15, 30);

      final sampleUpdates = [
        AgricultureUpdateModel(
          updateId: 'update_001',
          title: 'Drip Irrigation Subsidy 2026',
          description: 'Get up to 75% subsidy on micro-irrigation systems.',
          category: 'Subsidy',
          content: 'Full eligibility requirements and vendor list for micro-irrigation installation.',
          authorId: 'officer_01',
          createdAt: olderDate,
        ),
        AgricultureUpdateModel(
          updateId: 'update_002',
          title: 'Soil Health Card Camp at Krishi Bhavan',
          description: 'Free soil testing camp for all local paddy and vegetable growers.',
          category: 'Camp',
          content: 'Bring 500g of dry soil sample. Tests include N-P-K, micronutrients, and pH levels.',
          authorId: 'officer_02',
          createdAt: newerDate,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AgricultureUpdatesScreen(initialUpdates: sampleUpdates),
        ),
      );
      await tester.pump();

      // Both cards are rendered
      expect(find.text('Soil Health Card Camp at Krishi Bhavan'), findsOneWidget);
      expect(find.text('Drip Irrigation Subsidy 2026'), findsOneWidget);

      // Category Badges
      expect(find.text('Camp'), findsWidgets);
      expect(find.text('Subsidy'), findsWidgets);

      // Verify newest first ordering: newer update appears first in list
      final newerFinder = find.text('Soil Health Card Camp at Krishi Bhavan');
      final olderFinder = find.text('Drip Irrigation Subsidy 2026');
      expect(tester.getTopLeft(newerFinder).dy, lessThan(tester.getTopLeft(olderFinder).dy));
    });

    testWidgets('tapping update card opens detail view with full content', (tester) async {
      final sampleUpdate = AgricultureUpdateModel(
        updateId: 'update_detail_test',
        title: 'Organic Farming Workshop',
        description: 'Hands-on practical training on bio-fertilizers and pest management.',
        category: 'Training',
        content: 'Comprehensive 3-day training on Jeevamrutha preparation, neem decoctions, and vermicompost maintenance.',
        authorId: 'officer_99',
        createdAt: DateTime(2026, 9, 24, 11, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AgricultureUpdatesScreen(initialUpdates: [sampleUpdate]),
        ),
      );
      await tester.pump();

      // Tap card
      final card = find.byKey(const Key('update_card_update_detail_test'));
      expect(card, findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Verify detail screen is displayed
      expect(find.byType(AgricultureUpdateDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('update_detail_title')), findsOneWidget);
      expect(find.text('Organic Farming Workshop'), findsWidgets);
      expect(find.byKey(const Key('update_detail_description')), findsOneWidget);
      expect(find.byKey(const Key('update_detail_content')), findsOneWidget);
      expect(
        find.text(
          'Comprehensive 3-day training on Jeevamrutha preparation, neem decoctions, and vermicompost maintenance.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('filters updates list when category filter chip is selected', (tester) async {
      final sampleUpdates = [
        AgricultureUpdateModel(
          updateId: 'up_scheme',
          title: 'PM-KISAN Scheme Update',
          description: '17th installment disbursement details.',
          category: 'Scheme',
          content: 'Details about e-KYC requirement.',
          authorId: 'off_1',
          createdAt: DateTime(2026, 9, 21),
        ),
        AgricultureUpdateModel(
          updateId: 'up_event',
          title: 'District Krishi Mela 2026',
          description: 'Annual agricultural exhibition and machinery expo.',
          category: 'Event',
          content: 'Free entry for all registered farmers.',
          authorId: 'off_2',
          createdAt: DateTime(2026, 9, 22),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AgricultureUpdatesScreen(initialUpdates: sampleUpdates),
        ),
      );
      await tester.pump();

      expect(find.text('PM-KISAN Scheme Update'), findsOneWidget);
      expect(find.text('District Krishi Mela 2026'), findsOneWidget);

      // Select 'Scheme' filter chip
      await tester.tap(find.byKey(const Key('category_chip_Scheme')));
      await tester.pumpAndSettle();

      expect(find.text('PM-KISAN Scheme Update'), findsOneWidget);
      expect(find.text('District Krishi Mela 2026'), findsNothing);
    });
  });

  group('AgricultureUpdateModel Integration Tests', () {
    test('AgricultureUpdateModel toMap and fromMap serialization', () {
      final now = DateTime(2026, 9, 24, 12, 0);
      final update = AgricultureUpdateModel(
        updateId: 'up_test_100',
        title: 'Solar Pump Scheme',
        description: 'Subsidies up to 60% for PM-KUSUM solar agricultural pumps.',
        category: 'Subsidy',
        content: 'Step by step application procedure via state agriculture portal.',
        imageUrl: 'https://example.com/solar.jpg',
        authorId: 'officer_555',
        createdAt: now,
        updatedAt: now,
      );

      final map = update.toMap();
      expect(map['updateId'], 'up_test_100');
      expect(map['title'], 'Solar Pump Scheme');
      expect(map['description'], 'Subsidies up to 60% for PM-KUSUM solar agricultural pumps.');
      expect(map['category'], 'Subsidy');
      expect(map['content'], 'Step by step application procedure via state agriculture portal.');
      expect(map['imageUrl'], 'https://example.com/solar.jpg');
      expect(map['authorId'], 'officer_555');
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);

      final fromMap = AgricultureUpdateModel.fromMap(map, 'up_test_100');
      expect(fromMap.updateId, 'up_test_100');
      expect(fromMap.title, 'Solar Pump Scheme');
      expect(fromMap.description, 'Subsidies up to 60% for PM-KUSUM solar agricultural pumps.');
      expect(fromMap.category, 'Subsidy');
      expect(fromMap.content, 'Step by step application procedure via state agriculture portal.');
      expect(fromMap.imageUrl, 'https://example.com/solar.jpg');
      expect(fromMap.authorId, 'officer_555');
    });
  });
}
