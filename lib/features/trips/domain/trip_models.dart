class FoodTrip {
  const FoodTrip({
    required this.id,
    required this.name,
    this.destination,
    this.startsOn,
    this.notes,
    this.stopCount = 0,
  });

  factory FoodTrip.fromRow(Map<String, dynamic> row) => FoodTrip(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    destination: row['destination'] as String?,
    startsOn: row['starts_on'] == null
        ? null
        : DateTime.tryParse(row['starts_on'] as String),
    notes: row['notes'] as String?,
    stopCount: ((row['food_trip_stops'] as List?)?.length) ??
        (row['stop_count'] as num?)?.toInt() ??
        0,
  );

  final String id;
  final String name;
  final String? destination;
  final DateTime? startsOn;
  final String? notes;
  final int stopCount;
}

class TripStop {
  const TripStop({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.coverPhotoUrl,
    this.note,
    this.position = 0,
  });

  factory TripStop.fromRow(Map<String, dynamic> row) {
    final r = (row['restaurants'] as Map?)?.cast<String, dynamic>() ?? const {};
    return TripStop(
      id: row['id'] as String,
      restaurantId: r['id'] as String? ?? '',
      restaurantName: r['name'] as String? ?? '',
      coverPhotoUrl: r['cover_photo_url'] as String?,
      note: row['note'] as String?,
      position: (row['position'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? coverPhotoUrl;
  final String? note;
  final int position;
}
