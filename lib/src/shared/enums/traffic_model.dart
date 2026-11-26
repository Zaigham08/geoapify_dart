/// Traffic models supported by Geoapify Routing, Matrix, and Isoline APIs.
library;

/// Traffic estimation model for motorized travel modes.
enum TrafficModel {
  /// Assumes uncongested roads (`free_flow`).
  freeFlow('free_flow'),

  /// Accounts for typical congestion where supported (`approximated`).
  approximated('approximated');

  const TrafficModel(this.value);

  /// Wire value expected by Geoapify APIs.
  final String value;

  /// Parses a [TrafficModel] from its wire string, returning `null` if unknown.
  static TrafficModel? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final item in values) {
      if (item.value == value) {
        return item;
      }
    }
    return null;
  }
}
