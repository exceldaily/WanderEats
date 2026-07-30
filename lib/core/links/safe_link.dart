/// Validation and launching for outbound links.
///
/// Restaurant URLs are not authored by us: they arrive from Google Places, and
/// later from restaurant owners who have claimed a page. Both are untrusted
/// input. Before this existed the restaurant screen called
/// `launchUrl(Uri.parse(r.website!))` directly, which will happily launch
/// `javascript:`, `intent:` and `file:` URIs.
///
/// The rule is an allow-list, not a block-list: anything not explicitly
/// permitted is refused.
library;

import 'package:url_launcher/url_launcher.dart';

/// Why a link was refused. Callers show this rather than failing silently.
enum LinkRejection {
  empty('That link is empty.'),
  malformed('That link is not a valid address.'),
  disallowedScheme('That link uses an address type we do not open.'),
  missingHost('That link has no destination.'),
  embeddedCredentials('That link contains embedded credentials.');

  const LinkRejection(this.message);
  final String message;
}

class LinkResult {
  const LinkResult.ok(this.uri) : rejection = null;
  const LinkResult.rejected(this.rejection) : uri = null;

  final Uri? uri;
  final LinkRejection? rejection;

  bool get isOk => uri != null;
}

/// Schemes we will hand to the platform.
///
/// `geo` and `tel` are here because the app genuinely uses them for directions
/// and calling. `http` is accepted but upgraded to `https`. Everything else -
/// `javascript`, `data`, `file`, `content`, `intent`, `market` - is refused,
/// because those either execute code or reach inside the device.
const _allowedSchemes = {'https', 'http', 'tel', 'geo', 'mailto'};

/// Schemes that address a remote host and therefore must have one.
const _hostSchemes = {'https', 'http'};

abstract final class SafeLink {
  /// Validates a raw string into a launchable [Uri].
  static LinkResult validate(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return const LinkResult.rejected(LinkRejection.empty);

    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException {
      return const LinkResult.rejected(LinkRejection.malformed);
    }

    // A bare "example.com" parses with an empty scheme. Treat it as https
    // rather than refusing something a restaurant owner will plausibly type.
    if (uri.scheme.isEmpty) {
      try {
        uri = Uri.parse('https://$trimmed');
      } on FormatException {
        return const LinkResult.rejected(LinkRejection.malformed);
      }
    }

    final scheme = uri.scheme.toLowerCase();
    if (!_allowedSchemes.contains(scheme)) {
      return const LinkResult.rejected(LinkRejection.disallowedScheme);
    }

    if (_hostSchemes.contains(scheme)) {
      if (uri.host.isEmpty) {
        return const LinkResult.rejected(LinkRejection.missingHost);
      }
      // https://user:pass@evil.example is a classic way to make a hostile
      // host look like a familiar one in a truncated UI.
      if (uri.userInfo.isNotEmpty) {
        return const LinkResult.rejected(LinkRejection.embeddedCredentials);
      }
      // Upgrade rather than refuse: plenty of legitimate restaurant sites are
      // still recorded as http, and the platform will redirect anyway.
      if (scheme == 'http') uri = uri.replace(scheme: 'https');
    }

    return LinkResult.ok(uri);
  }

  /// Validates and opens [raw]. Returns null on success, or the reason it was
  /// refused so the caller can tell the user something specific.
  ///
  /// [launcher] exists so tests can assert what would have been launched
  /// without needing a platform.
  static Future<LinkRejection?> open(
    String? raw, {
    Future<bool> Function(Uri uri, {LaunchMode mode})? launcher,
  }) async {
    final result = validate(raw);
    final uri = result.uri;
    if (uri == null) return result.rejection;

    final launch = launcher ?? _defaultLauncher;
    final opened = await launch(uri, mode: LaunchMode.externalApplication);
    // A device with no dialler or no browser is a missing-app case, not a
    // malformed link, so it reports as a launch failure rather than a
    // validation one.
    return opened ? null : LinkRejection.malformed;
  }

  static Future<bool> _defaultLauncher(Uri uri, {required LaunchMode mode}) =>
      launchUrl(uri, mode: mode);
}
