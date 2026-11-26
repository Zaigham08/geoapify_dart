/// Distance unit systems supported by Geoapify routing, matrix, and isolines.
library;

/// Unit system for distance values and speed limits.
enum DistanceUnits {
  /// Metric units (meters and km/h).
  metric('metric'),

  /// Imperial units (miles and mph).
  imperial('imperial');

  const DistanceUnits(this.value);

  /// Wire value expected by Geoapify APIs.
  final String value;

  /// Parses [DistanceUnits] from its wire string, returning `null` if unknown.
  static DistanceUnits? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final unit in values) {
      if (unit.value == value) {
        return unit;
      }
    }
    return null;
  }
}
