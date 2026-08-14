/// What a pin is, visually, in priority order.
///
/// A restaurant can be several of these at once (saved *and* recommended by
/// someone you follow). The map shows exactly one treatment per pin, and this
/// order decides which: selection beats trust, trust beats your own bookkeeping,
/// bookkeeping beats generic signal.
enum WbMarkerKind {
  selected,
  followedTaster,
  saved,
  visited,
  trending,
  hiddenGem,
  standard;

  /// Lower sorts first, and survives longer when the map thins pins out at
  /// wide zoom. Mirrors the declaration order above.
  int get priority => index;
}

/// The visual inputs for one pin. Kept free of any map SDK type so the painter
/// and the cache can be unit-tested, and so a different renderer can reuse it.
class WbMarkerSpec {
  const WbMarkerSpec({
    required this.kind,
    this.recCount = 0,
    this.clusterCount = 0,
  });

  final WbMarkerKind kind;

  /// Shown as a small count badge on trusted pins ("3 people you follow").
  final int recCount;

  /// When > 1 this spec paints a cluster bubble rather than a single pin.
  final int clusterCount;

  bool get isCluster => clusterCount > 1;

  /// Stable identity for the bitmap cache. Two pins that look identical must
  /// produce the same key, or the map re-rasterises the same image hundreds of
  /// times per pan.
  String get cacheKey => isCluster
      ? 'c:${_clusterBucket(clusterCount)}:${kind.name}'
      : 'p:${kind.name}:${recCount.clamp(0, 9)}';

  /// Clusters bucket their label so 41 and 44 share one bitmap. Exact counts
  /// are still drawn from the bucket's representative, which is why the bucket
  /// is the count itself below 10.
  static int _clusterBucket(int n) {
    if (n < 10) return n;
    if (n < 100) return (n ~/ 10) * 10;
    return 100;
  }
}
