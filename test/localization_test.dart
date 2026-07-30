import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/l10n/app_localizations.dart';
import 'package:wanderbites/l10n/app_localizations_en.dart';
import 'package:wanderbites/l10n/app_localizations_th.dart';

void main() {
  test('Thai is registered as a supported locale', () {
    // The whole point of this pass was Thai as the flagship locale - if this
    // regresses, the app silently falls back to English for Thai devices.
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('th')),
    );
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('en')),
    );
  });

  test('every English string has a Thai counterpart, and vice versa', () {
    final en = AppLocalizationsEn();
    final th = AppLocalizationsTh();

    // A blank/missing translation falls back silently in production, so the
    // useful check here is that neither locale returns empty for a key the
    // other one answers.
    for (final value in [
      en.welcomeTagline,
      en.continueWithGoogle,
      en.signUpWithEmail,
      en.alreadyHaveAccount,
      en.justBrowsing,
      en.navMap,
      en.navDiscover,
      en.navCreate,
      en.navActivity,
      en.navProfile,
      en.settingsTitle,
      en.settingsDeleteAccount,
      en.deleteAccountDialogBody,
    ]) {
      expect(value, isNotEmpty);
    }

    for (final value in [
      th.welcomeTagline,
      th.continueWithGoogle,
      th.signUpWithEmail,
      th.alreadyHaveAccount,
      th.justBrowsing,
      th.navMap,
      th.navDiscover,
      th.navCreate,
      th.navActivity,
      th.navProfile,
      th.settingsTitle,
      th.settingsDeleteAccount,
      th.deleteAccountDialogBody,
    ]) {
      expect(value, isNotEmpty);
    }

    // Thai translations must actually be Thai, not a copy-paste of English -
    // this would pass the isNotEmpty checks above but ship an untranslated
    // app, which is worse than not localizing at all.
    expect(th.navMap, isNot(en.navMap));
    expect(th.settingsTitle, isNot(en.settingsTitle));
  });

  testWidgets('AppLocalizations resolves under a Thai locale', (
    tester,
  ) async {
    late AppLocalizations resolved;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            resolved = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(resolved, isA<AppLocalizationsTh>());
    expect(resolved.navMap, 'แผนที่');
  });
}
