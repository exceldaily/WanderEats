import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/configuration/env.dart';
import '../../features/restaurants/data/places_repository.dart';

/// Restaurant photo loader that understands both storage URLs and external
/// provider photo references.
///
/// Provider photos are proxied through our own edge function (so the provider
/// key stays server-side), and that function requires auth — so requests to it
/// need the Supabase headers attached. Centralizing that here keeps every call
/// site a plain widget.
class WbPhoto extends StatelessWidget {
  const WbPhoto({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.semanticLabel,
  });

  /// Either an ordinary URL or a provider photo reference ("places/X/photos/Y").
  final String? source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? semanticLabel;

  bool get _isProxied {
    final url = resolvePhotoUrl(source);
    return url != null && url.startsWith('${Env.supabaseUrl}/functions/');
  }

  @override
  Widget build(BuildContext context) {
    final url = resolvePhotoUrl(source);
    if (url == null) return _placeholder(context);

    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ??
        Env.supabasePublishableKey;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        httpHeaders: _isProxied
            ? {
                'Authorization': 'Bearer $token',
                'apikey': Env.supabasePublishableKey,
              }
            : null,
        // Photos ease in instead of popping; honors reduced motion.
        fadeInDuration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 220),
        placeholder: (_, _) => _placeholder(context),
        errorWidget: (_, _, _) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    width: width,
    height: height,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.restaurant,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
