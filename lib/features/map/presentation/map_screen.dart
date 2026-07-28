import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/configuration/env.dart';
import '../../../core/widgets/wb_states.dart';

/// Map home. Milestone 4 wires GoogleMap, bounds queries, clustering and the
/// restaurant preview sheet. Until a Maps key is provided, a friendly
/// fallback explains what is missing rather than rendering a broken map.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Env.hasMapsKey
            ? const _MapView()
            : const WbEmptyState(
                icon: Icons.map_outlined,
                title: 'Map needs a Google Maps API key',
                message:
                    'Add GOOGLE_MAPS_API_KEY to dart_defines/dev.json and rebuild. Everything else in the app works without it. See SETUP.md.',
              ),
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView();

  @override
  Widget build(BuildContext context) {
    // Replaced with the full GoogleMap experience in Milestone 4.
    return const Center(child: CircularProgressIndicator());
  }
}
