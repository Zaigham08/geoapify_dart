/// Service for the Geoapify Route Matrix API (`POST /v1/routematrix`).
library;

import '../../core/http/geoapify_http_client.dart';
import '../../shared/enums/distance_units.dart';
import '../../shared/enums/route_type.dart';
import '../../shared/enums/traffic_model.dart';
import '../../shared/enums/travel_mode.dart';
import '../../shared/models/avoid_rule.dart';
import '../../shared/models/geo_point.dart';
import 'models/route_matrix_models.dart';

/// Client service for the Geoapify Route Matrix API (`/v1/routematrix`).
final class RouteMatrixService {
  /// Creates a [RouteMatrixService] backed by the shared HTTP transport.
  const RouteMatrixService(this._httpClient);

  final GeoapifyHttpClient _httpClient;

  /// Calculates travel distances and durations between every location in
  /// [sources] and every location in [targets].
  Future<RouteMatrixResponse> calculate({
    required TravelMode mode,
    required List<GeoPoint> sources,
    required List<GeoPoint> targets,
    List<AvoidRule>? avoid,
    TrafficModel? traffic,
    RouteType? type,
    double? maxSpeed,
    DistanceUnits? units,
  }) {
    return calculateWithRequest(
      RouteMatrixRequest(
        mode: mode,
        sources: sources,
        targets: targets,
        avoid: avoid,
        traffic: traffic,
        type: type,
        maxSpeed: maxSpeed,
        units: units,
      ),
    );
  }

  /// Executes a Route Matrix calculation using a [RouteMatrixRequest].
  Future<RouteMatrixResponse> calculateWithRequest(
    RouteMatrixRequest request,
  ) async {
    final json = await _httpClient.postJson(
      '/v1/routematrix',
      body: request.toJson(),
    );
    return RouteMatrixResponse.fromJson(json);
  }
}
