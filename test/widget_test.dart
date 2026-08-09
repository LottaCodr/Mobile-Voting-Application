import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_voting_application/app.dart';

void main() {
  testWidgets('a local build clearly labels and enters the demo experience', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Your voice, ready when you are.'), findsOneWidget);
    expect(find.text('Explore demo ballot'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exploreDemoButton')));
    await tester.pumpAndSettle();

    expect(find.text('Your election hub'), findsOneWidget);
    expect(find.textContaining('Demo mode'), findsWidgets);
  });
}
