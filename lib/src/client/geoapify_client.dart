/// Main entry point client composing Geoapify API services.
library;

import 'package:http/http.dart' as http;

import '../config/geoapify_config.dart';
import '../core/http/geoapify_http_client.dart';
import '../features/geocoding/geocoding_service.dart';
import '../features/isolines/isoline_service.dart';
import '../features/places/places_service.dart';
import '../features/route_matrix/route_matrix_service.dart';
import '../features/routing/routing_service.dart';

/// Main client for Geoapify geocoding, routing, places, route matrix, and
/// isoline APIs.
///
/// Shares a single HTTP transport across all services. Call [close] when the
/// client is no longer needed.
final class GeoapifyClient {
  /// Creates a [GeoapifyClient] with the given [apiKey] and optional settings.
  ///
  /// Provide [httpClient] to reuse an existing `http.Client` or inject a mock
  /// client in tests. When [httpClient] is provided by the caller, [close]
  /// does not close it.
  factory GeoapifyClient({
    required String apiKey,
    Uri? baseUrl,
    Duration timeout = const Duration(seconds: 30),
    ApiKeyAuthMethod authMethod = ApiKeyAuthMethod.header,
    RetryPolicy retryPolicy = RetryPolicy.none,
    http.Client? httpClient,
    Map<String, String> defaultHeaders = const {},
  }) {
    return GeoapifyClient.withConfig(
      GeoapifyConfig(
        apiKey: apiKey,
        baseUrl: baseUrl,
        timeout: timeout,
        authMethod: authMethod,
        retryPolicy: retryPolicy,
        defaultHeaders: defaultHeaders,
      ),
      httpClient: httpClient,
    );
  }

  /// Creates a [GeoapifyClient] from an explicit [GeoapifyConfig].
  GeoapifyClient.withConfig(this.config, {http.Client? httpClient})
    : _httpClient = GeoapifyHttpClient(config: config, httpClient: httpClient) {
    geocoding = GeocodingService(_httpClient);
    routing = RoutingService(_httpClient);
    places = PlacesService(_httpClient);
    routeMatrix = RouteMatrixService(_httpClient);
    isolines = IsolineService(_httpClient);
  }

  /// Client configuration.
  final GeoapifyConfig config;

  final GeoapifyHttpClient _httpClient;

  /// Forward geocoding, reverse geocoding, and address autocomplete service.
  late final GeocodingService geocoding;

  /// Turn-by-turn route calculation service.
  late final RoutingService routing;

  /// Points-of-interest and places search service.
  late final PlacesService places;

  /// Source-to-target travel time and distance matrix service.
  late final RouteMatrixService routeMatrix;

  /// Time-based isochrone and distance-based isodistance service.
  late final IsolineService isolines;

  /// Whether [close] has been called on this client.
  bool get isClosed => _httpClient.isClosed;

  /// Closes the underlying HTTP client if it was created internally by this
  /// [GeoapifyClient].
  Future<void> close() => _httpClient.close();
}
