# WanderBites Map Architecture

How the map is built, why it is built this way, and what it would take to
change providers.

---

## The decision that shapes everything: we stayed on Google Maps

The Map 2.0 brief asked for a keyless/open architecture, defaulting to MapLibre
plus self-hosted vector tiles. We audited that and did not migrate. The reason
is worth stating plainly, because it inverts the usual assumption:

**Google's Maps SDK for Android and iOS renders dynamic maps at no charge.**
Google bills the Maps JavaScript API, Static Maps, Street View, and the various
data APIs (Places, Directions, Geocoding). Native mobile map rendering is not
metered. WanderBites is a mobile app, so the basemap is already free.

The Places API *is* metered, and WanderBites uses it to import restaurants in
areas with no coverage. That cost is unaffected by the rendering provider:
switching to MapLibre would not remove a single Places call.

Meanwhile MapLibre would have added real cost and risk:

| | Google Maps (current) | MapLibre + PMTiles |
|---|---|---|
| Basemap rendering | free on mobile SDKs | free (client library) |
| Tile hosting | included | self-hosted; a planet extract is 100 GB+ |
| Keyless | no (native key, unbilled) | yes, if self-hosted |
| Migration cost | none | rewrite of every map surface |
| Risk while in App Review | none | high |

The genuinely free keyless tile sources (OpenFreeMap, Protomaps' public demo)
carry no SLA, and the brief itself forbids leaning on community infrastructure
in production. Self-hosting on object storage is cheap for one region and not
cheap for the world.

**So the premium feel was built where it actually comes from: the basemap
style, the markers, the clustering, and the interaction design.** None of that
was vendor-specific work, and all of it survives a future migration.

### What we did instead, to keep the door open

The map feature is now layered so the SDK touches exactly one file:

```
domain/          map_bounds.dart, map_clustering.dart, map_marker_style.dart
                 ↑ pure Dart. No Flutter map types. Unit-testable.
data/            map_style_service.dart
presentation/    marker_painter.dart      (Flutter Canvas only)
                 map_marker_layer.dart    ← the ONLY google_maps_flutter binding
                 map_screen.dart          (widget; owns the camera)
```

Swapping to MapLibre means rewriting `map_marker_layer.dart` and the
`GoogleMap` widget call, and supplying a MapLibre-flavoured style. Clustering,
priority rules, bounds maths, pin artwork, and every test come across
untouched.

---

## Basemap

`assets/map/wanderbites_light.json` and `wanderbites_dark.json`, applied via
`GoogleMap(style:)` and selected by `Theme.of(context).brightness`.

Both styles do three things:

1. **Kill generic POI clutter.** `poi` is switched off wholesale, then parks and
   attractions are switched back on. Banks, shops, offices, and transit noise
   disappear, so the only commercial thing on the map is a WanderBites pin.
2. **Warm the palette to the brand.** Light uses the app's cream
   (`#FAF6F0`) for land with muted blue-grey water; dark uses the app's
   charcoal (`#121614`), a genuine dark basemap rather than dark chrome over a
   bright map.
3. **Reweight the labels.** Localities and neighbourhoods stay legible, local
   road labels are dropped, and arterial labels are simplified.

`MapStyleService` caches each style after first read and **returns null on
failure**. Null means "use the provider default", so a missing or malformed
asset degrades to a plain map instead of a blank screen.

---

## Markers

Pins are **drawn on canvas at runtime**, not shipped as images
(`marker_painter.dart`). One code path covers every state and every device
pixel ratio, colours come from `WbColors` so the map cannot drift from the
design system, and adding a state costs a switch arm rather than eight PNG
exports at multiple densities.

The shape is deliberately not a teardrop: a rounded plate on a short stem,
which reads as WanderBites at a glance and leaves a flat face for the count
badge.

### States and priority

`WbMarkerKind` is ordered, and the order *is* the priority:

```
selected > followedTaster > saved > visited > trending > hiddenGem > standard
```

A restaurant is often several of these at once. The map draws exactly one
treatment, highest priority wins: selection beats trust, trust beats your own
bookkeeping, bookkeeping beats generic signal.

Colour is never the only signal. Every pin carries a glyph, and every marker
carries a semantic label for screen readers
(`"Somtum Der · Recommended by someone you follow"`).

### Bitmap caching

Rasterising is the expensive part, so every bitmap is cached by
`WbMarkerSpec.cacheKey`. Two pins that look identical share one bitmap. Cluster
labels bucket above 10 (41 and 44 share an image), which keeps the cache small
during a pan through a dense city.

---

## Clustering

Previously **nonexistent** — the map drew up to 200 overlapping pins in a dense
city. `WbClusterer` groups them.

- **Grid over screen space, not degrees.** Cells are sized in pixels
  (88 by default, roughly two pin widths) and projected through Web Mercator,
  so cell size stays constant as you zoom and longitude cells do not collapse
  near the poles.
- **Not a quadtree, on purpose.** At the query cap of a few hundred markers a
  single pass over a hash map beats building a tree, and it is far easier to
  reason about.
- **Off above zoom 16.** At street level the user is choosing between specific
  places; a bubble would hide the answer.
- **Important pins are promoted out of their cluster.** If a group contains
  something the user cares about (selected, followed-Taster, saved, visited),
  that one pin is drawn individually and the remainder cluster. A saved
  restaurant never disappears into a grey bubble.

Tapping a cluster flies the camera into its bounds rather than opening a list:
the map is the interface. Members sharing one coordinate (a food hall) would
produce a zero-area bounds, which throws on Android, so the box is nudged open
by a small epsilon.

---

## Query pipeline

Unchanged in this milestone and still sound:

```
camera idle → getVisibleRegion() → MapViewController.onCameraIdle(bounds)
            → 700 ms debounce → restaurants_in_bounds RPC (cap 200)
            → paint → maybe import from Google Places → re-read
```

`restaurants_in_bounds` is SECURITY INVOKER, so restaurant RLS applies and
signed-out browsing works without a special path.

### Known gaps, deliberately not yet addressed

These came out of the audit and are the next work, not oversights:

- **Filters are client-side.** `MapFilters` (`maxPrice`, `savedOnly`,
  `minRecs`) is applied over the already-capped 200 rows, so a filtered view
  can be empty because the server truncated by `rec_count` before the filter
  ran. Filters belong in the RPC.
- **No antimeridian handling in the query.** `WbBounds.split()` exists and is
  tested, but the controller still passes raw bounds. A viewport straddling
  ±180° currently returns nothing.
- **No request cancellation.** A fast pan can let an older in-flight query
  write stale markers over a newer result. The marker build is already
  generation-guarded; the data query is not.
- **The "Search this area" button is decorative.** `boundsDirty` renders it,
  but the 700 ms debounce fires the same query anyway.
- **Sticky empty-result fast path.** Once a query returns zero results, every
  later camera idle bypasses the debounce entirely.

---

## Data available for future layers

The backend audit found substantial unused material:

| Layer | Source |
|---|---|
| Taste Pulse | `restaurant_conversion_events` (already indexed by restaurant + time, counts signed-out traffic) |
| Following lens | `follows` + `recommendations`, or `taste_deck`'s existing trust-first ranking with its `reason` / `via_taster_id` |
| Taster map | `taster_places(uid)` — needs a bounds parameter |
| Tasters Nearby | `suggested_tasters(uid, area_lat, area_lng)` — already spatial, hardcoded 50 km |
| Saved / Visited | `restaurant_saves`, `restaurant_visits` |
| Trending | `trending_restaurants(city_slug)` — city-scoped, would need rewriting for bounds |

Spatial coverage today is two GIST indexes: `restaurants.location` and
`cities.center`. A partial index matching the hot predicate
(`where deleted_at is null and status = 'active'`) is the obvious next
optimisation.

---

## Attribution

Google's own attribution is rendered by the SDK and must not be covered or
removed. If the map ever moves to OpenStreetMap-derived tiles, OSM attribution
becomes mandatory and visible in both themes — see `MAP_ATTRIBUTION.md` when
that migration happens.

---

## Testing

`test/map_domain_test.dart` covers the pure layer: bounds maths including the
antimeridian split, cache-key identity and collision, priority ordering,
clustering behaviour at street vs city zoom, promotion of important pins, and
centroid placement.

The painter and the SDK binding are not unit-tested — they produce pixels and
platform objects respectively. They are exercised by the release build and on
device.
