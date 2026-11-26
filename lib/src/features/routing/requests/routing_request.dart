/// Request model for the Geoapify Routing API (`GET /v1/routing`).
library;

import '../../../core/exceptions/geoapify_exception.dart';
import '../../../core/http/request_builder.dart';
import '../../../shared/enums/distance_units.dart';
import '../../../shared/enums/route_type.dart';
import '../../../shared/enums/traffic_model.dart';
import '../../../shared/enums/travel_mode.dart';
import '../../../shared/models/avoid_rule.dart';
import '../../../shared/models/geo_point.dart';
import '../models/routing_enums.dart';

/// Request parameters for route calculation (`GET /v1/routing`).
final class RoutingRequest {
  /// Creates a [RoutingRequest].
  RoutingRequest({
    required List<GeoPoint> waypoints,
    required this.mode,
    this.intermediateWaypointMode,
    this.optimizeStops,
    this.type,
    this.units,
    this.lang,
    List<AvoidRule>? avoid,
    Set<RouteDetail>? details,
    this.traffic,
    this.maxSpeed,
    this.format = RoutingFormat.geojson,
  }) : waypoints = List.unmodifiable(waypoints),
       avoid = avoid != null ? List.unmodifiable(avoid) : null,
       details = details != null ? Set.unmodifiable(details) : null;

  /// Ordered route waypoints (`2` to `1000` points).
  ///
  /// Serialized as pipe-delimited `latitude,longitude` pairs (`lat,lon|lat,lon`).
  final List<GeoPoint> waypoints;

  /// Travel mode used to calculate speeds and road access rules.
  final TravelMode mode;

  /// How intermediate waypoints affect route legs.
  final IntermediateWaypointMode? intermediateWaypointMode;

  /// Whether to optimize the order of intermediate stops while keeping the
  /// first and last waypoints fixed.
  final bool? optimizeStops;

  /// Route optimization objective (`balanced`, `short`, or `less_maneuvers`).
  final RouteType? type;

  /// Distance unit system (`metric` or `imperial`).
  final DistanceUnits? units;

  /// Language code for turn-by-turn instructions.
  final String? lang;

  /// Road features, locations, polygons, or countries to avoid.
  final List<AvoidRule>? avoid;

  /// Additional detail datasets to include in the response.
  final Set<RouteDetail>? details;

  /// Traffic model (`free_flow` or `approximated`).
  final TrafficModel? traffic;

  /// Maximum speed (`10-252` km/h for metric or `6.5-155` mph for imperial).
  final double? maxSpeed;

  /// Response format (`geojson` default or `json`).
  final RoutingFormat format;

  /// Validates request parameters against the Routing OpenAPI specification.
  void validate() {
    if (waypoints.length < 2) {
      throw GeoapifyValidationException(
        'Routing requires at least 2 waypoints, got ${waypoints.length}.',
      );
    }
    if (waypoints.length > 1000) {
      throw GeoapifyValidationException(
        'Routing supports at most 1000 waypoints, got ${waypoints.length}.',
      );
    }
    if (maxSpeed != null &&
        (!maxSpeed!.isFinite || maxSpeed! < 6.5 || maxSpeed! > 252.0)) {
      throw GeoapifyValidationException(
        'maxSpeed must be between 6.5 and 252, got $maxSpeed.',
      );
    }
  }

  /// Builds query parameters for `GET /v1/routing`.
  Map<String, List<String>> toQueryParameters() {
    validate();
    final avoidStrings = avoid
        ?.expand((rule) => rule.toQueryValues())
        .toList(growable: false);

    final builder = QueryParametersBuilder()
      ..addJoined(
        'waypoints',
        waypoints.map((p) => p.toLatLonString()),
        separator: '|',
      )
      ..add('mode', mode.value)
      ..add('intermediate_waypoint_mode', intermediateWaypointMode?.value)
      ..addBool('optimize_stops', optimizeStops)
      ..add('type', type?.value)
      ..add('units', units?.value)
      ..add('lang', lang?.trim().isNotEmpty == true ? lang!.trim() : null)
      ..addJoined('avoid', avoidStrings, separator: '|')
      ..addJoined('details', details?.map((d) => d.value))
      ..add('traffic', traffic?.value)
      ..addNum('max_speed', maxSpeed)
      ..add('format', format.value);
    return builder.build();
  }
}
