import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/widgets/wb_states.dart';
import '../../premium/data/entitlement_service.dart';
import '../../premium/domain/entitlements.dart';
import '../data/trip_repository.dart';

/// My food trips. Creation is the premium capability; existing trips remain
/// fully editable regardless of subscription state.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(myTripsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Food Trips')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('New trip'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myTripsProvider.future),
        child: trips.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(WbSpacing.md),
            children: [
              for (var i = 0; i < 4; i++)
                const Padding(
                  padding: EdgeInsets.only(bottom: WbSpacing.md),
                  child: WbSkeleton(height: 72),
                ),
            ],
          ),
          error: (e, _) => WbErrorState(
            message: 'Trips could not be loaded.',
            onRetry: () => ref.invalidate(myTripsProvider),
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    WbEmptyState(
                      icon: Icons.map_outlined,
                      title: 'No trips yet',
                      message:
                          'Plan an eating itinerary for your next city: '
                          'ordered stops, notes, zero spreadsheets.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return ListTile(
                      leading: const Icon(Icons.map_outlined),
                      title: Text(
                        t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (t.destination != null) t.destination!,
                          '${t.stopCount} stop${t.stopCount == 1 ? '' : 's'}',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(
                        Routes.trip,
                        pathParameters: {'id': t.id},
                        queryParameters: {'name': t.name},
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final denial = denialFor(ref, PremiumEntitlement.advancedTripPlanning);
    if (denial != null) {
      if (!context.mounted) return;
      if (denial.canBeSolvedByUpgrading) {
        unawaited(context.pushNamed(Routes.premium));
      } else {
        // Say why the button did nothing rather than appearing dead.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (denial) {
              EntitlementDenial.notSignedIn => 'Sign in to plan food trips.',
              _ => 'Trip planning is not available on this account.',
            }),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateTripSheet(),
    );
    ref.invalidate(myTripsProvider);
  }
}

class _CreateTripSheet extends ConsumerStatefulWidget {
  const _CreateTripSheet();

  @override
  ConsumerState<_CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends ConsumerState<_CreateTripSheet> {
  final _name = TextEditingController();
  final _destination = TextEditingController();
  DateTime? _startsOn;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 3) {
      setState(() => _error = 'Name the trip (at least 3 characters).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(tripRepositoryProvider)
          .create(
            name: name,
            destination: _destination.text.trim().isEmpty
                ? null
                : _destination.text.trim(),
            startsOn: _startsOn,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(
        context.pushNamed(
          Routes.trip,
          pathParameters: {'id': id},
          queryParameters: {'name': name},
        ),
      );
    } on TripException catch (e) {
      if (!mounted) return;
      if (e.premiumRequired) {
        Navigator.of(context).pop();
        unawaited(context.pushNamed(Routes.premium));
        return;
      }
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'The trip could not be created. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: WbSpacing.lg,
        right: WbSpacing.lg,
        top: WbSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + WbSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New food trip', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: WbSpacing.md),
          TextField(
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Trip name',
              counterText: '',
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          TextField(
            controller: _destination,
            maxLength: 120,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Destination (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: WbSpacing.sm),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _startsOn ?? now,
                firstDate: now.subtract(const Duration(days: 1)),
                lastDate: DateTime(now.year + 3),
              );
              if (picked != null) setState(() => _startsOn = picked);
            },
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _startsOn == null
                  ? 'Start date (optional)'
                  : MaterialLocalizations.of(context).formatMediumDate(
                      _startsOn!,
                    ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: WbSpacing.xs),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: WbSpacing.md),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create trip'),
          ),
        ],
      ),
    );
  }
}
