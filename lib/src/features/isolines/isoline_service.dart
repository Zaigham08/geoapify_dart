/// Service for the Geoapify Isoline API (`GET /v1/isoline`).
library;

import '../../core/http/geoapify_http_client.dart';
import '../../shared/enums/distance_units.dart';
import '../../shared/enums/route_type.dart';
import '../../shared/enums/traffic_model.dart';
import '../../shared/enums/travel_mode.dart';
import '../../shared/models/avoid_rule.dart';
import '../../shared/models/geo_point.dart';
import 'models/isoline_models.dart';

/// Client service for the Geoapify Isoline API (`/v1/isoline`).
final class IsolineService {
  /// Creates an [IsolineService] backed by the shared HTTP transport.
  const IsolineService(this._httpClient);

  final GeoapifyHttpClient _httpClient;

  /// Calculates time-based isochrones or distance-based isodistances from
  /// [location].
  Future<IsolineResponse> calculate({
    required GeoPoint location,
    required IsolineType type,
    required TravelMode mode,
    required List<num> ranges,
    DistanceUnits? units,
    List<AvoidRule>? avoid,
    RouteType? routeType,
    TrafficModel? traffic,
    double? maxSpeed,
    List<String>? details,
  }) {
    return execute(
      IsolineRequest.calculate(
        location: location,
        type: type,
        mode: mode,
        ranges: ranges,
        units: units,
        avoid: avoid,
        routeType: routeType,
        traffic: traffic,
        maxSpeed: maxSpeed,
        details: details,
      ),
    );
  }

  /// Retrieves a previously generated isoline by its 32-character hexadecimal
  /// [id].
  Future<IsolineResponse> getById(String id) {
    return execute(IsolineRequest.byId(id: id));
  }

  /// Executes an [IsolineRequest].
  Future<IsolineResponse> execute(IsolineRequest request) async {
    final json = await _httpClient.getJson(
      '/v1/isoline',
      queryParameters: request.toQueryParameters(),
    );
    return IsolineResponse.fromJson(json);
  }
}
