import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/theme/wb_tokens.dart';
import '../data/billing_service.dart';
import '../data/entitlement_service.dart';

/// The WanderBites Premium paywall.
///
/// Renders the "default" RevenueCat offering (Monthly + Annual). This screen
/// is only ever reached from an [EntitlementDenial.premiumRequired] gate or
/// the settings row - never from an age-restriction path; buying premium
/// cannot and must not be offered as a way around an age gate.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

final _offeringProvider = FutureProvider.autoDispose<Offering?>((ref) {
  return ref.watch(billingServiceProvider).currentOffering();
});

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;
  Package? _selected;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final offering = ref.watch(_offeringProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('WanderBites Premium')),
      body: isPremium
          ? const _AlreadyPremium()
          : !BillingService.isAvailable
          ? const _Unavailable()
          : offering.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _LoadFailed(
                message: e is BillingException
                    ? e.message
                    : 'Plans could not be loaded. Try again in a moment.',
                onRetry: () => ref.invalidate(_offeringProvider),
              ),
              data: (offering) {
                final packages = offering?.availablePackages ?? const [];
                if (packages.isEmpty) {
                  return _LoadFailed(
                    message: 'No plans are available right now.',
                    onRetry: () => ref.invalidate(_offeringProvider),
                  );
                }
                return _plans(context, packages);
              },
            ),
    );
  }

  Widget _plans(BuildContext context, List<Package> packages) {
    // Annual leads: it is the best value and the store sorts are unreliable.
    final sorted = [...packages]
      ..sort(
        (a, b) => a.packageType == PackageType.annual
            ? -1
            : b.packageType == PackageType.annual
            ? 1
            : 0,
      );
    _selected ??= sorted.first;

    return ListView(
      padding: const EdgeInsets.all(WbSpacing.md),
      children: [
        const _Pitch(),
        const SizedBox(height: WbSpacing.lg),
        for (final package in sorted) ...[
          _PlanCard(
            package: package,
            selected: package == _selected,
            onTap: _busy ? null : () => setState(() => _selected = package),
          ),
          const SizedBox(height: WbSpacing.sm),
        ],
        const SizedBox(height: WbSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: WbColors.ember,
            minimumSize: const Size.fromHeight(kWbMinTouchTarget + 4),
          ),
          onPressed: _busy || _selected == null
              ? null
              : () => _run(() => ref
                    .read(billingServiceProvider)
                    .purchase(_selected!)),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(_ctaLabel(_selected)),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(() => ref.read(billingServiceProvider).restore()),
          child: const Text('Restore purchases'),
        ),
        const SizedBox(height: WbSpacing.sm),
        Text(
          'Subscriptions renew automatically until cancelled in your store '
          'account settings. The free week applies to new subscribers only.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _ctaLabel(Package? package) {
    final intro = package?.storeProduct.introductoryPrice;
    // Intro offer configured in App Store Connect: free first week.
    if (intro != null && intro.price == 0) return 'Start free week';
    return 'Subscribe';
  }

  Future<void> _run(Future<PurchaseOutcome> Function() action) async {
    setState(() => _busy = true);
    try {
      final outcome = await action();
      if (!mounted) return;
      switch (outcome) {
        case PurchaseOutcome.granted:
          unawaited(Navigator.of(context).maybePop());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome to WanderBites Premium!')),
          );
        case PurchaseOutcome.pendingServerSync:
          // They paid; the webhook is still in flight. Reassure, never alarm.
          unawaited(Navigator.of(context).maybePop());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Purchase received - Premium unlocks in a moment.',
              ),
            ),
          );
        case PurchaseOutcome.cancelled:
          break; // Their choice; no message.
      }
    } on BillingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Pitch extends ConsumerWidget {
  const _Pitch();

  static const _features = [
    (Icons.chat_bubble_outline, 'Message other Tasters (18+)'),
    (Icons.groups_outlined, 'Create Taste Groups'),
    (Icons.map_outlined, 'Plan multi-stop food trips'),
    (Icons.auto_awesome_outlined, 'Custom banner photos and profile styles'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A confirmed minor may still subscribe for the other features, but
    // messaging must not be part of what is being sold to them.
    final age = ref.watch(ageStatusProvider).value;
    final isConfirmedMinor = (age?.confirmed ?? false) && !(age?.adult ?? true);
    final features = isConfirmedMinor
        ? _features.where((f) => f.$1 != Icons.chat_bubble_outline)
        : _features;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Taste more, together.',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: WbSpacing.md),
        for (final (icon, label) in features)
          Padding(
            padding: const EdgeInsets.only(bottom: WbSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 20, color: WbColors.voyageLight),
                const SizedBox(width: WbSpacing.sm),
                Expanded(child: Text(label)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WbRadius.card),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(WbRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(WbSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAnnual ? 'Annual' : 'Monthly',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (isAnnual) ...[
                          const SizedBox(width: WbSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WbSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: WbColors.emberSoft,
                              borderRadius: BorderRadius.circular(
                                WbRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'Best value',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: WbColors.ember,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.priceString} / ${isAnnual ? 'year' : 'month'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlreadyPremium extends StatelessWidget {
  const _AlreadyPremium();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 56, color: WbColors.voyageLight),
            const SizedBox(height: WbSpacing.md),
            Text(
              'You have WanderBites Premium',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WbSpacing.sm),
            Text(
              'Manage or cancel any time from your store account settings.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.xl),
        child: Text(
          'Subscriptions are not available on this device yet.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WbSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: WbSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
