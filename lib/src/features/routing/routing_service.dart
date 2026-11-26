/// Service for the Geoapify Routing API (`GET /v1/routing`).
library;

import '../../core/http/geoapify_http_client.dart';
import '../../shared/enums/distance_units.dart';
import '../../shared/enums/route_type.dart';
import '../../shared/enums/traffic_model.dart';
import '../../shared/enums/travel_mode.dart';
import '../../shared/models/avoid_rule.dart';
import '../../shared/models/geo_point.dart';
import 'models/routing_enums.dart';
import 'requests/routing_request.dart';
import 'responses/routing_response.dart';

/// Client service for the Geoapify Routing API (`/v1/routing`).
final class RoutingService {
  /// Creates a [RoutingService] backed by the shared HTTP transport.
  const RoutingService(this._httpClient);

  final GeoapifyHttpClient _httpClient;

  /// Calculates a route between two or more [waypoints] using [mode].
  Future<RoutingResponse> calculate({
    required List<GeoPoint> waypoints,
    required TravelMode mode,
    IntermediateWaypointMode? intermediateWaypointMode,
    bool? optimizeStops,
    RouteType? type,
    DistanceUnits? units,
    String? lang,
    List<AvoidRule>? avoid,
    Set<RouteDetail>? details,
    TrafficModel? traffic,
    double? maxSpeed,
    RoutingFormat format = RoutingFormat.geojson,
  }) {
    return calculateWithRequest(
      RoutingRequest(
        waypoints: waypoints,
        mode: mode,
        intermediateWaypointMode: intermediateWaypointMode,
        optimizeStops: optimizeStops,
        type: type,
        units: units,
        lang: lang,
        avoid: avoid,
        details: details,
        traffic: traffic,
        maxSpeed: maxSpeed,
        format: format,
      ),
    );
  }

  /// Executes a route calculation using a [RoutingRequest].
  Future<RoutingResponse> calculateWithRequest(RoutingRequest request) async {
    final json = await _httpClient.getJson(
      '/v1/routing',
      queryParameters: request.toQueryParameters(),
    );
    return RoutingResponse.fromJson(json);
  }
}
