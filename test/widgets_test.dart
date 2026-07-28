import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/app/theme/wb_theme.dart';
import 'package:wanderbites/app/theme/wb_tokens.dart';
import 'package:wanderbites/core/widgets/wb_states.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: WbTheme.light(),
      darkTheme: WbTheme.dark(),
      home: Scaffold(body: child),
    );

void main() {
  group('WbEmptyState', () {
    testWidgets('renders title, message and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(WbEmptyState(
        icon: Icons.map_outlined,
        title: 'No places here yet',
        message: 'Pan the map.',
        actionLabel: 'Retry',
        onAction: () => tapped = true,
      )));
      expect(find.text('No places here yet'), findsOneWidget);
      expect(find.text('Pan the map.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });
  });

  group('WbErrorState', () {
    testWidgets('shows retry only when handler given', (tester) async {
      await tester.pumpWidget(_wrap(const WbErrorState(message: 'boom')));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('WbSkeleton', () {
    testWidgets('renders statically under reduced motion', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: WbTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: WbSkeleton(height: 20)),
        ),
      ));
      // Scoped to the skeleton: MaterialApp adds its own FadeTransitions.
      expect(
          find.descendant(
              of: find.byType(WbSkeleton),
              matching: find.byType(FadeTransition)),
          findsNothing);
    });

    testWidgets('pulses when motion allowed', (tester) async {
      await tester.pumpWidget(_wrap(const WbSkeleton(height: 20)));
      expect(
          find.descendant(
              of: find.byType(WbSkeleton),
              matching: find.byType(FadeTransition)),
          findsOneWidget);
    });
  });

  group('WbTheme', () {
    test('light and dark themes build with brand colors', () {
      final light = WbTheme.light();
      final dark = WbTheme.dark();
      expect(light.colorScheme.primary, WbColors.voyage);
      expect(dark.colorScheme.primary, WbColors.voyageLight);
      expect(light.colorScheme.secondary, WbColors.ember);
      expect(light.useMaterial3, isTrue);
    });
  });
}
