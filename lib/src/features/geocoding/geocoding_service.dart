/// Service for Geoapify Forward Geocoding, Reverse Geocoding, and Address
/// Autocomplete APIs.
library;

import '../../core/http/geoapify_http_client.dart';
import '../../shared/models/geo_point.dart';
import 'models/geocoding_enums.dart';
import 'models/geocoding_filter_bias.dart';
import 'requests/geocoding_requests.dart';
import 'responses/geocoding_response.dart';

/// Client service for Geoapify Geocoding APIs (`/v1/geocode/*`).
final class GeocodingService {
  /// Creates a [GeocodingService] backed by the shared HTTP transport.
  const GeocodingService(this._httpClient);

  final GeoapifyHttpClient _httpClient;

  /// Searches for geographic coordinates and address details matching a
  /// free-form [text] query or structured address fields (`GET /v1/geocode/search`).
  ///
  /// Do not combine [text] with structured fields ([name], [housenumber],
  /// [street], [postcode], [city], [state], [country]).
  Future<GeocodingResponse> search({
    String? text,
    String? name,
    String? housenumber,
    String? street,
    String? postcode,
    String? city,
    String? state,
    String? country,
    GeocodingLocationType? type,
    String? lang,
    int? limit,
    List<String>? countryCodes,
    List<GeocodingFilter>? filters,
    List<GeocodingBias>? biases,
    GeocodingFormat format = GeocodingFormat.geojson,
  }) {
    return searchWithRequest(
      ForwardGeocodingRequest(
        text: text,
        name: name,
        housenumber: housenumber,
        street: street,
        postcode: postcode,
        city: city,
        state: state,
        country: country,
        type: type,
        lang: lang,
        limit: limit,
        countryCodes: countryCodes,
        filters: filters,
        biases: biases,
        format: format,
      ),
    );
  }

  /// Executes a forward geocoding search using a [ForwardGeocodingRequest].
  Future<GeocodingResponse> searchWithRequest(
    ForwardGeocodingRequest request,
  ) async {
    final json = await _httpClient.getJson(
      '/v1/geocode/search',
      queryParameters: request.toQueryParameters(),
    );
    return GeocodingResponse.fromJson(json);
  }

  /// Returns address and place suggestions for partial [text]
  /// (`GET /v1/geocode/autocomplete`).
  Future<GeocodingResponse> autocomplete({
    required String text,
    GeocodingLocationType? type,
    String? lang,
    int? limit,
    List<String>? countryCodes,
    List<GeocodingFilter>? filters,
    List<GeocodingBias>? biases,
    GeocodingFormat format = GeocodingFormat.geojson,
  }) {
    return autocompleteWithRequest(
      AutocompleteRequest(
        text: text,
        type: type,
        lang: lang,
        limit: limit,
        countryCodes: countryCodes,
        filters: filters,
        biases: biases,
        format: format,
      ),
    );
  }

  /// Executes an autocomplete request using an [AutocompleteRequest].
  Future<GeocodingResponse> autocompleteWithRequest(
    AutocompleteRequest request,
  ) async {
    final json = await _httpClient.getJson(
      '/v1/geocode/autocomplete',
      queryParameters: request.toQueryParameters(),
    );
    return GeocodingResponse.fromJson(json);
  }

  /// Resolves the nearest address or place for [location]
  /// (`GET /v1/geocode/reverse`).
  Future<GeocodingResponse> reverse({
    required GeoPoint location,
    GeocodingLocationType? type,
    String? lang,
    int? limit,
    List<String>? countryCodes,
    GeocodingFormat format = GeocodingFormat.geojson,
  }) {
    return reverseWithRequest(
      ReverseGeocodingRequest(
        location: location,
        type: type,
        lang: lang,
        limit: limit,
        countryCodes: countryCodes,
        format: format,
      ),
    );
  }

  /// Executes a reverse geocoding lookup using a [ReverseGeocodingRequest].
  Future<GeocodingResponse> reverseWithRequest(
    ReverseGeocodingRequest request,
  ) async {
    final json = await _httpClient.getJson(
      '/v1/geocode/reverse',
      queryParameters: request.toQueryParameters(),
    );
    return GeocodingResponse.fromJson(json);
  }
}
