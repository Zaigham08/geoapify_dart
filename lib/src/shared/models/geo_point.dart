/// Geographic coordinate model with explicit serialization formats.
library;

/// An immutable WGS 84 geographic coordinate pair ([latitude], [longitude]).
///
/// Geoapify APIs use different coordinate orderings across endpoints:
/// - Routing waypoints and reverse geocoding/isoline query parameters use
///   `latitude,longitude` or `lat`/`lon` parameters.
/// - GeoJSON geometries, Route Matrix locations, and Geocoding/Places
///   `filter`/`bias` strings use `longitude,latitude` order.
///
/// Use the explicit conversion methods on [GeoPoint] rather than manually
/// formatting coordinates.
final class GeoPoint {
  /// Creates a validated [GeoPoint].
  ///
  /// Throws an [ArgumentError] if [latitude] is outside `[-90, 90]`,
  /// [longitude] is outside `[-180, 180]`, or either coordinate is non-finite.
  GeoPoint({required this.latitude, required this.longitude}) {
    validate(latitude: latitude, longitude: longitude);
  }

  /// Creates a `const` [GeoPoint] without runtime validation.
  ///
  /// Prefer the default [GeoPoint] constructor unless a compile-time constant
  /// is required for known-valid coordinates.
  const GeoPoint.unchecked({required this.latitude, required this.longitude});

  /// Parses a GeoJSON position `[longitude, latitude, ...]`.
  ///
  /// Throws a [FormatException] if [position] has fewer than 2 numeric values,
  /// or an [ArgumentError] if the coordinates are out of range.
  factory GeoPoint.fromGeoJsonPosition(List<Object?> position) {
    if (position.length < 2) {
      throw FormatException(
        'GeoJSON position must have at least 2 elements, got ${position.length}.',
      );
    }
    final rawLon = position[0];
    final rawLat = position[1];
    if (rawLon is! num || rawLat is! num) {
      throw const FormatException(
        'GeoJSON position coordinates must be numeric [longitude, latitude].',
      );
    }
    return GeoPoint(latitude: rawLat.toDouble(), longitude: rawLon.toDouble());
  }

  /// Parses a JSON object containing `lat` and `lon` keys.
  ///
  /// Throws a [FormatException] if `lat` or `lon` is missing or non-numeric.
  factory GeoPoint.fromLatLonJson(Map<String, Object?> json) {
    final rawLat = json['lat'];
    final rawLon = json['lon'];
    if (rawLat is! num || rawLon is! num) {
      throw const FormatException(
        'Coordinate JSON object must contain numeric "lat" and "lon" fields.',
      );
    }
    return GeoPoint(latitude: rawLat.toDouble(), longitude: rawLon.toDouble());
  }

  /// Latitude in decimal degrees (`-90.0` to `90.0`).
  final double latitude;

  /// Longitude in decimal degrees (`-180.0` to `180.0`).
  final double longitude;

  /// Validates that [latitude] and [longitude] are finite and within WGS 84
  /// bounds.
  static void validate({required double latitude, required double longitude}) {
    if (!latitude.isFinite || latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Latitude must be a finite number between -90.0 and 90.0.',
      );
    }
    if (!longitude.isFinite || longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Longitude must be a finite number between -180.0 and 180.0.',
      );
    }
  }

  /// Serializes as `"latitude,longitude"` (used by Routing `waypoints` and
  /// `avoid` location/polygon query rules).
  String toLatLonString() => '$latitude,$longitude';

  /// Serializes as `"longitude,latitude"` (used by Geocoding and Places
  /// `filter`/`bias` strings).
  String toLonLatString() => '$longitude,$latitude';

  /// Serializes as a GeoJSON position `[longitude, latitude]`.
  List<double> toGeoJsonPosition() => [longitude, latitude];

  /// Serializes as `{"lat": latitude, "lon": longitude}`.
  Map<String, double> toLatLonJson() => {'lat': latitude, 'lon': longitude};

  /// Serializes as separate `lat` and `lon` query parameters.
  Map<String, String> toLatLonQueryParameters() => {
    'lat': '$latitude',
    'lon': '$longitude',
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GeoPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint(latitude: $latitude, longitude: $longitude)';
}
