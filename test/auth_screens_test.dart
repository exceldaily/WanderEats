import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wanderbites/app/theme/wb_theme.dart';
import 'package:wanderbites/features/authentication/presentation/sign_in_screen.dart';

/// Auth screens run against a stub router so navigation targets exist
/// without a live Supabase session.
Widget _appWith(Widget home) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(path: '/map', name: 'map', builder: (_, _) => const Placeholder()),
    GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, _) => const Placeholder()),
  ]);
  return ProviderScope(
    child: MaterialApp.router(theme: WbTheme.light(), routerConfig: router),
  );
}

void main() {
  group('SignInScreen', () {
    testWidgets('validates empty form before hitting the network',
        (tester) async {
      await tester.pumpWidget(_appWith(const SignInScreen()));
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('rejects malformed email', (tester) async {
      await tester.pumpWidget(_appWith(const SignInScreen()));
      await tester.enterText(
          find.byType(TextFormField).first, 'not-an-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Enter your password'), findsNothing);
    });

    testWidgets('links to forgot password', (tester) async {
      await tester.pumpWidget(_appWith(const SignInScreen()));
      expect(find.text('Forgot password?'), findsOneWidget);
    });
  });
}
