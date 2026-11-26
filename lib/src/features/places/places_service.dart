/// Service for the Geoapify Places API (`GET` and `POST /v2/places`).
library;

import '../../core/http/geoapify_http_client.dart';
import 'models/places_filter_bias.dart';
import 'requests/places_search_request.dart';
import 'responses/places_response.dart';

/// Client service for the Geoapify Places API (`/v2/places`).
final class PlacesService {
  /// Creates a [PlacesService] backed by the shared HTTP transport.
  const PlacesService(this._httpClient);

  final GeoapifyHttpClient _httpClient;

  /// Searches for places matching [categories] and at least one [filter] or
  /// [bias].
  ///
  /// Uses `GET /v2/places` by default, or automatically switches to
  /// `POST /v2/places` when [usePost] is `true` or when [filter] is a
  /// POST-only filter such as [PolygonFilter] or [PolylineFilter].
  Future<PlacesResponse> search({
    required List<String> categories,
    List<String>? conditions,
    PlacesFilter? filter,
    PlacesBias? bias,
    int? limit,
    int? offset,
    String? lang,
    String? name,
    bool usePost = false,
  }) {
    final request = PlacesSearchRequest(
      categories: categories,
      conditions: conditions,
      filter: filter,
      bias: bias,
      limit: limit,
      offset: offset,
      lang: lang,
      name: name,
    );
    if (usePost || request.requiresPost) {
      return searchPost(request);
    }
    return searchGet(request);
  }

  /// Executes a Places search using `GET /v2/places`.
  Future<PlacesResponse> searchGet(PlacesSearchRequest request) async {
    final json = await _httpClient.getJson(
      '/v2/places',
      queryParameters: request.toQueryParameters(),
    );
    return PlacesResponse.fromJson(json);
  }

  /// Executes a structured Places search using `POST /v2/places`.
  Future<PlacesResponse> searchPost(PlacesSearchRequest request) async {
    final json = await _httpClient.postJson(
      '/v2/places',
      body: request.toPostBody(),
    );
    return PlacesResponse.fromJson(json);
  }
}
