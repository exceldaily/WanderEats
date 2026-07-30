import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wanderbites/core/links/safe_link.dart';

void main() {
  group('SafeLink.validate refuses', () {
    test('empty and whitespace', () {
      expect(SafeLink.validate(null).rejection, LinkRejection.empty);
      expect(SafeLink.validate('   ').rejection, LinkRejection.empty);
    });

    test('code-executing and device-reaching schemes', () {
      for (final hostile in [
        'javascript:alert(1)',
        'data:text/html;base64,PHNjcmlwdD4=',
        'file:///etc/passwd',
        'content://com.android.contacts/data/1',
        'intent://scan#Intent;scheme=zxing;end',
      ]) {
        expect(
          SafeLink.validate(hostile).rejection,
          LinkRejection.disallowedScheme,
          reason: hostile,
        );
      }
    });

    test('http(s) with no host', () {
      expect(SafeLink.validate('https://').rejection, LinkRejection.missingHost);
    });

    test('embedded credentials, which disguise the real host', () {
      expect(
        SafeLink.validate('https://trusted.example@evil.example/x').rejection,
        LinkRejection.embeddedCredentials,
      );
    });
  });

  group('SafeLink.validate accepts', () {
    test('ordinary https, preserving path and query', () {
      final r = SafeLink.validate('https://example.com/menu?lang=en');
      expect(r.isOk, isTrue);
      expect(r.uri!.host, 'example.com');
      expect(r.uri!.path, '/menu');
      expect(r.uri!.queryParameters['lang'], 'en');
    });

    test('a bare domain, by assuming https', () {
      final r = SafeLink.validate('example.com/menu');
      expect(r.isOk, isTrue);
      expect(r.uri.toString(), 'https://example.com/menu');
    });

    test('http, upgrading it to https', () {
      final r = SafeLink.validate('http://example.com');
      expect(r.uri!.scheme, 'https');
    });

    test('tel and geo, which the app itself uses', () {
      expect(SafeLink.validate('tel:+66812345678').isOk, isTrue);
      expect(SafeLink.validate('geo:0,0?q=Ma+Cuisine').isOk, isTrue);
    });
  });

  group('SafeLink.open', () {
    test('launches a valid link and reports success', () async {
      Uri? launched;
      final rejection = await SafeLink.open(
        'https://example.com',
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launched = uri;
          return true;
        },
      );
      expect(rejection, isNull);
      expect(launched.toString(), 'https://example.com');
    });

    test('never launches a refused link', () async {
      var called = false;
      final rejection = await SafeLink.open(
        'javascript:alert(1)',
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          called = true;
          return true;
        },
      );
      expect(rejection, LinkRejection.disallowedScheme);
      expect(called, isFalse, reason: 'a refused link must not reach the OS');
    });

    test('reports failure when no app can handle it', () async {
      final rejection = await SafeLink.open(
        'tel:+66812345678',
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async =>
            false,
      );
      expect(rejection, isNotNull);
    });
  });
}
