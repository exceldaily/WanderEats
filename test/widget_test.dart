import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/app/app.dart';

void main() {
  testWidgets('boots into the configuration notice when env is missing',
      (tester) async {
    // Tests run without --dart-define, so Env.isConfigured is false and the
    // app must show the setup notice instead of crashing.
    await tester.pumpWidget(const WanderBitesApp());
    expect(find.text('Configuration missing'), findsOneWidget);
  });
}
