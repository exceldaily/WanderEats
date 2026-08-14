import 'package:flutter/material.dart';

/// Which map the user is looking at.
///
/// One control instead of a wall of filter chips: a lens changes *what the map
/// is about*, while filters narrow whatever the lens returned. Keeping them
/// separate is what stops the map screen becoming a settings panel.
enum MapLens {
  /// Everything in view, ranked by recommendations. The signed-out and
  /// default state.
  everything,

  /// Only places recommended by Tasters the user follows.
  following,

  /// The user's saved places.
  saved,

  /// Where the user has already eaten.
  visited,

  /// Well regarded but under-discovered.
  hiddenGems;

  String get label => switch (this) {
    MapLens.everything => 'Everything',
    MapLens.following => 'Following',
    MapLens.saved => 'Saved',
    MapLens.visited => 'Visited',
    MapLens.hiddenGems => 'Hidden gems',
  };

  String get description => switch (this) {
    MapLens.everything => 'Every place worth eating around here',
    MapLens.following => 'Only what people you follow recommend',
    MapLens.saved => 'Places you saved for later',
    MapLens.visited => 'Where you have already eaten',
    MapLens.hiddenGems => 'Highly rated, barely discovered',
  };

  IconData get icon => switch (this) {
    MapLens.everything => Icons.public,
    MapLens.following => Icons.people_alt_outlined,
    MapLens.saved => Icons.bookmark_outline,
    MapLens.visited => Icons.check_circle_outline,
    MapLens.hiddenGems => Icons.auto_awesome_outlined,
  };

  /// Lenses that describe the viewer's own relationship to a place are
  /// meaningless signed out, and the RPCs behind them key off auth.uid().
  bool get requiresAccount => this != MapLens.everything;

  /// What to say when this lens legitimately has nothing to show. Written per
  /// lens because "no results" is a different problem in each case, and the
  /// fix is different too.
  String get emptyTitle => switch (this) {
    MapLens.everything => 'Nothing here yet',
    MapLens.following => 'Your trusted map starts here',
    MapLens.saved => 'Nothing saved in this area',
    MapLens.visited => 'You have not eaten here yet',
    MapLens.hiddenGems => 'No hidden gems in view',
  };

  String get emptyMessage => switch (this) {
    MapLens.everything =>
      'Pan somewhere else, or zoom out to find places nearby.',
    MapLens.following =>
      'Follow Tasters whose taste you trust and their favourite places will '
          'appear on this map.',
    MapLens.saved =>
      'Save places from the map or BiteSwipe and they will collect here.',
    MapLens.visited =>
      'Mark places visited after you eat, and this becomes your own food map.',
    MapLens.hiddenGems =>
      'Try a wider area. Gems need a few recommendations before they surface.',
  };
}
