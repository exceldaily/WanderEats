/// Count + noun for UI text, with the noun agreeing with the count.
///
/// `countOf(1, 'rec')` -> "1 rec", `countOf(3, 'rec')` -> "3 recs".
/// Irregular plurals pass the plural form explicitly:
/// `countOf(n, 'city', 'cities')`.
///
/// Exists because "1 recommendations" was showing on the map preview card,
/// restaurant details and search results, and each of those had built the
/// string by hand.
String countOf(int count, String singular, [String? plural]) =>
    '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';

/// Same, for counts that arrive from Postgres as `num?` inside a dynamic map.
String countOfDynamic(Object? count, String singular, [String? plural]) =>
    countOf((count as num?)?.toInt() ?? 0, singular, plural);
