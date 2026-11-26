/// Request models for the Geoapify Geocoding APIs.
library;

import '../../../core/exceptions/geoapify_exception.dart';
import '../../../core/http/request_builder.dart';
import '../../../shared/models/geo_point.dart';
import '../models/geocoding_enums.dart';
import '../models/geocoding_filter_bias.dart';

/// Request parameters for forward geocoding (`GET /v1/geocode/search`).
///
/// Provide either free-form [text] OR one or more structured address fields
/// ([name], [housenumber], [street], [postcode], [city], [state], [country]),
/// never both.
final class ForwardGeocodingRequest {
  /// Creates a [ForwardGeocodingRequest].
  ForwardGeocodingRequest({
    this.text,
    this.name,
    this.housenumber,
    this.street,
    this.postcode,
    this.city,
    this.state,
    this.country,
    this.type,
    this.lang,
    this.limit,
    List<String>? countryCodes,
    List<GeocodingFilter>? filters,
    List<GeocodingBias>? biases,
    this.format = GeocodingFormat.geojson,
  }) : countryCodes = countryCodes != null
           ? List.unmodifiable(countryCodes)
           : null,
       filters = filters != null ? List.unmodifiable(filters) : null,
       biases = biases != null ? List.unmodifiable(biases) : null;

  /// Free-form address query. Do not combine with structured fields.
  final String? text;

  /// Place or amenity name (structured input).
  final String? name;

  /// House number (structured input).
  final String? housenumber;

  /// Street name (structured input).
  final String? street;

  /// Postal or ZIP code (structured input).
  final String? postcode;

  /// City name (structured input).
  final String? city;

  /// State or region name (structured input).
  final String? state;

  /// Country name (structured input).
  final String? country;

  /// Requested target location type.
  final GeocodingLocationType? type;

  /// ISO 639-1 language code for results (for example `en` or `de`).
  final String? lang;

  /// Maximum number of results (`1` to `100`).
  final int? limit;

  /// Optional ISO 3166-1 alpha-2 country code filters (up to 10).
  final List<String>? countryCodes;

  /// Hard spatial or administrative filters.
  final List<GeocodingFilter>? filters;

  /// Ranking biases.
  final List<GeocodingBias>? biases;

  /// Response format (`geojson` default or `json`).
  final GeocodingFormat format;

  /// Validates parameters against the Forward Geocoding OpenAPI spec.
  void validate() {
    final hasText = text != null && text!.trim().isNotEmpty;
    final hasStructured = [
      name,
      housenumber,
      street,
      postcode,
      city,
      state,
      country,
    ].any((value) => value != null && value.trim().isNotEmpty);

    if (!hasText && !hasStructured) {
      throw const GeoapifyValidationException(
        'Forward geocoding requires either "text" or at least one structured address field.',
      );
    }
    if (hasText && hasStructured) {
      throw const GeoapifyValidationException(
        'Do not combine free-form "text" with structured address parameters.',
      );
    }
    if (type == GeocodingLocationType.building) {
      throw const GeoapifyValidationException(
        'GeocodingLocationType.building is only supported by reverse geocoding.',
      );
    }
    _validateLimit(limit);
    _validateCountryCodes(countryCodes);
  }

  /// Builds query parameters for `GET /v1/geocode/search`.
  Map<String, List<String>> toQueryParameters() {
    validate();
    final builder = QueryParametersBuilder()
      ..add('text', _trimOrNull(text))
      ..add('name', _trimOrNull(name))
      ..add('housenumber', _trimOrNull(housenumber))
      ..add('street', _trimOrNull(street))
      ..add('postcode', _trimOrNull(postcode))
      ..add('city', _trimOrNull(city))
      ..add('state', _trimOrNull(state))
      ..add('country', _trimOrNull(country))
      ..add('type', type?.value)
      ..add('lang', _trimOrNull(lang))
      ..addInt('limit', limit)
      ..addJoined(
        'countrycodes',
        countryCodes?.map((c) => c.trim().toLowerCase()),
      )
      ..addJoined(
        'filter',
        filters?.map((f) => f.toQueryString()),
        separator: '|',
      )
      ..addJoined('bias', biases?.map((b) => b.toQueryString()), separator: '|')
      ..add('format', format.value);
    return builder.build();
  }
}

/// Request parameters for address autocomplete (`GET /v1/geocode/autocomplete`).
final class AutocompleteRequest {
  /// Creates an [AutocompleteRequest].
  AutocompleteRequest({
    required this.text,
    this.type,
    this.lang,
    this.limit,
    List<String>? countryCodes,
    List<GeocodingFilter>? filters,
    List<GeocodingBias>? biases,
    this.format = GeocodingFormat.geojson,
  }) : countryCodes = countryCodes != null
           ? List.unmodifiable(countryCodes)
           : null,
       filters = filters != null ? List.unmodifiable(filters) : null,
       biases = biases != null ? List.unmodifiable(biases) : null;

  /// Partial address or place name query.
  final String text;

  /// Requested target location type.
  final GeocodingLocationType? type;

  /// ISO 639-1 language code for results.
  final String? lang;

  /// Maximum number of suggestions (`1` to `100`).
  final int? limit;

  /// Optional ISO 3166-1 alpha-2 country code filters (up to 10).
  final List<String>? countryCodes;

  /// Hard spatial or administrative filters.
  final List<GeocodingFilter>? filters;

  /// Ranking biases.
  final List<GeocodingBias>? biases;

  /// Response format (`geojson` default or `json`).
  final GeocodingFormat format;

  /// Validates parameters against the Address Autocomplete OpenAPI spec.
  void validate() {
    if (text.trim().isEmpty) {
      throw const GeoapifyValidationException(
        'Autocomplete "text" must not be empty.',
      );
    }
    if (type == GeocodingLocationType.building) {
      throw const GeoapifyValidationException(
        'GeocodingLocationType.building is only supported by reverse geocoding.',
      );
    }
    _validateLimit(limit);
    _validateCountryCodes(countryCodes);
  }

  /// Builds query parameters for `GET /v1/geocode/autocomplete`.
  Map<String, List<String>> toQueryParameters() {
    validate();
    final builder = QueryParametersBuilder()
      ..add('text', text.trim())
      ..add('type', type?.value)
      ..add('lang', _trimOrNull(lang))
      ..addInt('limit', limit)
      ..addJoined(
        'countrycodes',
        countryCodes?.map((c) => c.trim().toLowerCase()),
      )
      ..addJoined(
        'filter',
        filters?.map((f) => f.toQueryString()),
        separator: '|',
      )
      ..addJoined('bias', biases?.map((b) => b.toQueryString()), separator: '|')
      ..add('format', format.value);
    return builder.build();
  }
}

/// Request parameters for reverse geocoding (`GET /v1/geocode/reverse`).
final class ReverseGeocodingRequest {
  /// Creates a [ReverseGeocodingRequest].
  ReverseGeocodingRequest({
    required this.location,
    this.type,
    this.lang,
    this.limit,
    List<String>? countryCodes,
    this.format = GeocodingFormat.geojson,
  }) : countryCodes = countryCodes != null
           ? List.unmodifiable(countryCodes)
           : null;

  /// Target geographic coordinate (`lat` and `lon` query parameters).
  final GeoPoint location;

  /// Requested result type (`country`, `state`, `city`, `postcode`, `street`,
  /// `amenity`, `locality`, or `building`).
  final GeocodingLocationType? type;

  /// ISO 639-1 language code for results.
  final String? lang;

  /// Maximum number of results (`1` to `100`).
  final int? limit;

  /// Optional ISO 3166-1 alpha-2 country code filters (up to 10).
  final List<String>? countryCodes;

  /// Response format (`geojson` default or `json`).
  final GeocodingFormat format;

  /// Validates parameters against the Reverse Geocoding OpenAPI spec.
  void validate() {
    _validateLimit(limit);
    _validateCountryCodes(countryCodes);
  }

  /// Builds query parameters for `GET /v1/geocode/reverse`.
  Map<String, List<String>> toQueryParameters() {
    validate();
    final builder = QueryParametersBuilder()
      ..addNum('lat', location.latitude)
      ..addNum('lon', location.longitude)
      ..add('type', type?.value)
      ..add('lang', _trimOrNull(lang))
      ..addInt('limit', limit)
      ..addJoined(
        'countrycodes',
        countryCodes?.map((c) => c.trim().toLowerCase()),
      )
      ..add('format', format.value);
    return builder.build();
  }
}

String? _trimOrNull(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void _validateLimit(int? limit) {
  if (limit != null && (limit < 1 || limit > 100)) {
    throw GeoapifyValidationException(
      'Geocoding limit must be between 1 and 100, got $limit.',
    );
  }
}

void _validateCountryCodes(List<String>? countryCodes) {
  if (countryCodes == null) {
    return;
  }
  if (countryCodes.length > 10) {
    throw GeoapifyValidationException(
      'At most 10 country codes are allowed, got ${countryCodes.length}.',
    );
  }
  for (final code in countryCodes) {
    final normalized = code.trim().toLowerCase();
    if (!RegExp(r'^[a-z]{2}$').hasMatch(normalized)) {
      throw GeoapifyValidationException(
        'Invalid ISO 3166-1 alpha-2 country code: "$code".',
      );
    }
  }
}
