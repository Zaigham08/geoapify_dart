/// Enums for the Geoapify Routing API.
library;

/// Treatment of intermediate waypoints along a multi-stop route.
enum IntermediateWaypointMode {
  /// Splits the route into independent legs (`stopover`, default).
  stopover('stopover'),

  /// Splits into legs while preserving incoming travel direction
  /// (`through_stop`).
  throughStop('through_stop'),

  /// Treats intermediate waypoints as via points without creating a new leg
  /// (`pass_through`).
  passThrough('pass_through');

  const IntermediateWaypointMode(this.value);

  /// Wire value expected by the Routing API.
  final String value;

  /// Parses an [IntermediateWaypointMode] from its wire string.
  static IntermediateWaypointMode? tryParse(String? value) {
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

/// Optional extra detail datasets requested via `details` on the Routing API.
enum RouteDetail {
  /// Adds detailed maneuver metadata to instructions (`instruction_details`).
  instructionDetails('instruction_details'),

  /// Adds road attributes such as surface, speed limit, and road class
  /// (`route_details`). Increases API credit cost.
  routeDetails('route_details'),

  /// Adds elevation profile data (`elevation`). Increases API credit cost.
  elevation('elevation'),

  /// Adds country/state metadata and border crossings (`admin_areas`).
  adminAreas('admin_areas'),

  /// Adds precision-5 encoded polylines (`polyline5`).
  polyline5('polyline5'),

  /// Adds precision-6 encoded polylines (`polyline6`).
  polyline6('polyline6');

  const RouteDetail(this.value);

  /// Wire value expected by the Routing API.
  final String value;

  /// Parses a [RouteDetail] from its wire string.
  static RouteDetail? tryParse(String? value) {
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

/// Response serialization format for Routing requests.
enum RoutingFormat {
  /// GeoJSON FeatureCollection (`geojson`, default).
  geojson('geojson'),

  /// Plain JSON response with `{lon, lat}` geometry arrays (`json`).
  json('json');

  const RoutingFormat(this.value);

  /// Wire value expected by the Routing API.
  final String value;
}
