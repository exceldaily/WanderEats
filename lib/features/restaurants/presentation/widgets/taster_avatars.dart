import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../domain/restaurant.dart';

/// Overlapping avatar row of recommending Tasters, tap-through to profiles.
class TasterAvatars extends StatelessWidget {
  const TasterAvatars({super.key, required this.tasters, this.size = 32});

  final List<RecommendingTaster> tasters;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: size + 4,
      child: Stack(
        children: [
          for (var i = 0; i < tasters.length && i < 6; i++)
            Positioned(
              left: i * (size * 0.7),
              child: Tooltip(
                message: tasters[i].displayName,
                child: InkWell(
                  onTap: () => context.pushNamed(
                    Routes.taster,
                    pathParameters: {'id': tasters[i].id},
                  ),
                  customBorder: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surfaceContainerLow,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: size / 2,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage: tasters[i].avatarUrl == null
                          ? null
                          : CachedNetworkImageProvider(tasters[i].avatarUrl!),
                      child: tasters[i].avatarUrl == null
                          ? Text(
                              tasters[i].displayName.characters.first
                                  .toUpperCase(),
                              style: TextStyle(fontSize: size * 0.4),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
