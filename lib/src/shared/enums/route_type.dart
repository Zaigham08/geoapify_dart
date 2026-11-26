/// Route optimization preferences supported by Routing, Matrix, and Isolines.
library;

/// Route optimization objective (`type` in Routing/Matrix, `route_type` in
/// Isolines).
enum RouteType {
  /// Balances travel time and distance (`balanced`).
  balanced('balanced'),

  /// Prioritizes shortest distance (`short`).
  short('short'),

  /// Penalizes turns and maneuvers (`less_maneuvers`).
  lessManeuvers('less_maneuvers');

  const RouteType(this.value);

  /// Wire value expected by Geoapify APIs.
  final String value;

  /// Parses a [RouteType] from its wire string, returning `null` if unknown.
  static RouteType? tryParse(String? value) {
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
