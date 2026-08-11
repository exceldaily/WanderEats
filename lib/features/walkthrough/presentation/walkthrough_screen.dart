import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';

/// First-run tour. New accounts land here straight from onboarding, so it
/// shows exactly once per sign-up; existing users can replay it from
/// Settings > About. Every exit path leads to the map.
class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.people_alt_outlined,
      title: 'Rate the taster, not the restaurant',
      body:
          'Follow food explorers called Tasters whose taste matches yours. '
          'Their picks build your map, and whether those picks hold up is '
          'what builds their score. No anonymous stars.',
    ),
    (
      icon: Icons.map_outlined,
      title: 'A map, not a directory',
      body:
          'Every pin is a place someone vouched for. Pan to your '
          'neighbourhood or search any city on earth to see where people '
          'actually eat, who recommends it, and why.',
    ),
    (
      icon: Icons.style_outlined,
      title: 'Swipe when you cannot decide',
      body:
          'BiteSwipe deals you a stack of nearby places ranked by the '
          'Tasters you trust. Swipe right to save, left to skip. Saves land '
          'straight on your map.',
    ),
    (
      icon: Icons.travel_explore_outlined,
      title: 'Make it yours',
      body:
          'Recommend the places you love, build lists like playlists, and '
          'mark where you have eaten. Premium adds Taste Groups, messaging '
          'and food trip planning.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  // Replaying the tour from Settings should land back on Settings; only the
  // post-onboarding run (nothing to pop) falls through to the map.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.map);
    }
  }

  void _next() {
    if (_isLast) {
      _leave();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(WbSpacing.sm),
                child: _isLast
                    // Keeps the header height stable without a disabled
                    // empty-label button lingering on the last page.
                    ? const SizedBox(height: 48)
                    : TextButton(
                        onPressed: _leave,
                        child: const Text('Skip'),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WbSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: i.isEven
                                ? WbColors.emberSoft
                                : theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p.icon,
                            size: 56,
                            color: i.isEven
                                ? WbColors.ember
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: WbSpacing.xl),
                        Text(
                          p.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: WbSpacing.md),
                        Text(
                          p.body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(WbRadius.pill),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(WbSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Start exploring' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
