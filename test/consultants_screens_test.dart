import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmigo/core/theme/app_theme.dart';
import 'package:farmigo/features/consultants/presentation/screens/consultants_screen.dart';
import 'package:farmigo/features/consultants/presentation/screens/register_consultant_screen.dart';
import 'package:farmigo/models/consultant_model.dart';
import 'package:farmigo/models/consultation_model.dart';

void main() {
  group('RegisterConsultantScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: const RegisterConsultantScreen(),
      );
    }

    testWidgets('renders all required form fields and submit button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify Screen Title
      expect(find.text('Register as Consultant'), findsOneWidget);

      // Verify Form Fields
      expect(find.byKey(const Key('consultant_name_field')), findsOneWidget);
      expect(find.byKey(const Key('consultant_specialization_field')), findsOneWidget);
      expect(find.byKey(const Key('consultant_experience_field')), findsOneWidget);
      expect(find.byKey(const Key('consultant_location_field')), findsOneWidget);
      expect(find.byKey(const Key('consultant_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_consultant_submit_button')), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final submitBtn = find.byKey(const Key('register_consultant_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      // Check validation error messages
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your specialization'), findsOneWidget);
      expect(find.text('Please enter your experience'), findsOneWidget);
      expect(find.text('Please enter your location'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);
    });

    testWidgets('validates invalid experience input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('consultant_name_field')), 'Dr. Ananya');
      await tester.enterText(find.byKey(const Key('consultant_experience_field')), '-5');

      final submitBtn = find.byKey(const Key('register_consultant_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Please enter a valid positive number'), findsOneWidget);
    });
  });

  group('ConsultantsScreen Widget Tests', () {
    testWidgets('renders app bar, search bar, empty state, and FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ConsultantsScreen(),
        ),
      );
      await tester.pump();

      // AppBar title
      expect(find.text('Expert Consultants'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Empty State
      expect(find.text('No consultants registered yet'), findsOneWidget);

      // Floating Action Button
      final fab = find.byKey(const Key('register_consultant_fab'));
      expect(fab, findsOneWidget);
      expect(find.text('Register as Consultant'), findsWidgets);
    });

    testWidgets('FAB navigates to RegisterConsultantScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ConsultantsScreen(),
        ),
      );
      await tester.pump();

      final fab = find.byKey(const Key('register_consultant_fab'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify RegisterConsultantScreen is pushed
      expect(find.byType(RegisterConsultantScreen), findsOneWidget);
      expect(find.byKey(const Key('register_consultant_submit_button')), findsOneWidget);
    });

    testWidgets('renders consultant cards and opens request consultation dialog', (tester) async {
      final sampleConsultants = [
        ConsultantModel(
          consultantId: 'c_001',
          userId: 'u_101',
          name: 'Dr. Ramesh Patel',
          specialization: 'Soil Agronomy',
          experience: 12,
          location: 'Vadodara, Gujarat',
          phone: '+91 9876543210',
          availability: true,
          verified: true,
          createdAt: DateTime.now(),
        ),
        ConsultantModel(
          consultantId: 'c_002',
          userId: 'u_102',
          name: 'Priya Sharma',
          specialization: 'Pest Management',
          experience: 6,
          location: 'Pune, Maharashtra',
          phone: '+91 9876543211',
          availability: true,
          verified: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ConsultantsScreen(initialConsultants: sampleConsultants),
        ),
      );
      await tester.pump();

      // Check both consultants are rendered
      expect(find.text('Dr. Ramesh Patel'), findsOneWidget);
      expect(find.text('Soil Agronomy'), findsOneWidget);
      expect(find.text('12 years exp'), findsOneWidget);
      expect(find.text('Vadodara, Gujarat'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);

      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Pest Management'), findsOneWidget);
      expect(find.text('6 years exp'), findsOneWidget);
      expect(find.text('Pune, Maharashtra'), findsOneWidget);

      // Verify Request Consultation buttons
      final requestBtns = find.text('Request Consultation');
      expect(requestBtns, findsNWidgets(2));

      // Tap first Request Consultation button
      await tester.tap(requestBtns.first);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byKey(const Key('consultation_message_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_consultation_request_button')), findsOneWidget);

      // Submit empty message to verify validation
      await tester.tap(find.byKey(const Key('submit_consultation_request_button')));
      await tester.pump();
      expect(find.text('Please describe your consultation query'), findsOneWidget);

      // Enter message
      await tester.enterText(
        find.byKey(const Key('consultation_message_field')),
        'Need soil testing advice for wheat crop.',
      );

      // Dismiss dialog via Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('filters consultants list with search query', (tester) async {
      final sampleConsultants = [
        ConsultantModel(
          consultantId: 'c_001',
          userId: 'u_101',
          name: 'Dr. Ramesh Patel',
          specialization: 'Soil Agronomy',
          experience: 12,
          location: 'Vadodara, Gujarat',
          phone: '+91 9876543210',
          availability: true,
          verified: true,
          createdAt: DateTime.now(),
        ),
        ConsultantModel(
          consultantId: 'c_002',
          userId: 'u_102',
          name: 'Priya Sharma',
          specialization: 'Pest Management',
          experience: 6,
          location: 'Pune, Maharashtra',
          phone: '+91 9876543211',
          availability: true,
          verified: false,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ConsultantsScreen(initialConsultants: sampleConsultants),
        ),
      );
      await tester.pump();

      // Filter by 'Pest'
      await tester.enterText(find.byType(TextField), 'Pest');
      await tester.pump();

      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Dr. Ramesh Patel'), findsNothing);
    });
  });

  group('Consultant & Consultation Models Tests', () {
    test('ConsultantModel serialization and deserialization', () {
      final now = DateTime.now();
      final consultant = ConsultantModel(
        consultantId: 'c_101',
        userId: 'u_user_99',
        name: 'Dr. Ramesh Patel',
        specialization: 'Soil Agronomy & Micro-irrigation',
        experience: 12,
        location: 'Vadodara, Gujarat',
        phone: '+91 9876543210',
        availability: true,
        verified: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = consultant.toMap();
      expect(map['consultantId'], 'c_101');
      expect(map['userId'], 'u_user_99');
      expect(map['name'], 'Dr. Ramesh Patel');
      expect(map['specialization'], 'Soil Agronomy & Micro-irrigation');
      expect(map['experience'], 12);
      expect(map['location'], 'Vadodara, Gujarat');
      expect(map['phone'], '+91 9876543210');
      expect(map['availability'], true);
      expect(map['verified'], true);

      final fromMap = ConsultantModel.fromMap(map, 'c_101');
      expect(fromMap.consultantId, 'c_101');
      expect(fromMap.name, 'Dr. Ramesh Patel');
      expect(fromMap.experience, 12);
      expect(fromMap.verified, true);
    });

    test('ConsultationModel serialization and deserialization', () {
      final now = DateTime.now();
      final consultation = ConsultationModel(
        consultationId: 'bk_202',
        consultantId: 'c_101',
        farmerId: 'farmer_456',
        message: 'Need advice on yellowing tomato leaves in polyhouse.',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      final map = consultation.toMap();
      expect(map['consultationId'], 'bk_202');
      expect(map['consultantId'], 'c_101');
      expect(map['farmerId'], 'farmer_456');
      expect(map['message'], 'Need advice on yellowing tomato leaves in polyhouse.');
      expect(map['status'], 'pending');

      final fromMap = ConsultationModel.fromMap(map, 'bk_202');
      expect(fromMap.consultationId, 'bk_202');
      expect(fromMap.consultantId, 'c_101');
      expect(fromMap.farmerId, 'farmer_456');
      expect(fromMap.message, 'Need advice on yellowing tomato leaves in polyhouse.');
      expect(fromMap.status, 'pending');
    });
  });
}
