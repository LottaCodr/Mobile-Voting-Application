// // test/integration/app_test.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:mobile_voting_applicaition/main.dart' as app;

// void main() {
//   //IntegrationTestWidgetsFlutterBinding.ensureInitialized();

//   testWidgets('User can sign up and navigate to dashboard', (WidgetTester tester) async {
//     app.main();
//     await tester.pumpAndSettle();

//     // Find sign-up fields and enter data
//     await tester.enterText(find.byKey(Key('email')), 'test@example.com');
//     await tester.enterText(find.byKey(Key('password')), 'password123');
//     await tester.tap(find.byKey(Key('signUpButton')));
    
//     await tester.pumpAndSettle();

//     // Verify navigation to dashboard
//     expect(find.text('Dashboard'), findsOneWidget);
//   });
// }
