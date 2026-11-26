/// Request model for the Geoapify Places API (`GET` and `POST /v2/places`).
library;

import '../../../core/exceptions/geoapify_exception.dart';
import '../../../core/http/request_builder.dart';
import '../models/places_filter_bias.dart';

/// Request parameters for searching places (`GET /v2/places` or
/// `POST /v2/places`).
final class PlacesSearchRequest {
  /// Creates a [PlacesSearchRequest].
  PlacesSearchRequest({
    required List<String> categories,
    List<String>? conditions,
    this.filter,
    this.bias,
    this.limit,
    this.offset,
    this.lang,
    this.name,
  }) : categories = List.unmodifiable(categories),
       conditions = conditions != null ? List.unmodifiable(conditions) : null;

  /// One or more hierarchical place category keys (1 to 100).
  final List<String> categories;

  /// Optional hierarchical place attribute conditions (1 to 100).
  final List<String>? conditions;

  /// Spatial or administrative hard filter.
  final PlacesFilter? filter;

  /// Ranking preference bias.
  final PlacesBias? bias;

  /// Maximum number of places per page (`1` to `500`, API default `20`).
  final int? limit;

  /// Zero-based pagination offset (`>= 0`, API default `0`).
  final int? offset;

  /// ISO 639-1 language code for place names and addresses.
  final String? lang;

  /// Optional place-name filter.
  final String? name;

  /// Whether this request requires `POST /v2/places` (for example when using
  /// [PolygonFilter] or [PolylineFilter]).
  bool get requiresPost => filter != null && !filter!.supportsGet;

  /// Validates common parameters against the Places API OpenAPI spec.
  void validate() {
    if (categories.isEmpty || categories.length > 100) {
      throw GeoapifyValidationException(
        'Places search requires between 1 and 100 categories, got ${categories.length}.',
      );
    }
    for (final category in categories) {
      if (category.trim().length < 3) {
        throw GeoapifyValidationException(
          'Invalid category key "$category": must be at least 3 characters.',
        );
      }
    }
    if (conditions != null) {
      if (conditions!.isEmpty || conditions!.length > 100) {
        throw const GeoapifyValidationException(
          'Conditions must contain between 1 and 100 items when provided.',
        );
      }
      for (final condition in conditions!) {
        if (condition.trim().length < 3) {
          throw GeoapifyValidationException(
            'Invalid condition key "$condition": must be at least 3 characters.',
          );
        }
      }
    }
    if (filter == null && bias == null) {
      throw const GeoapifyValidationException(
        'Places search requires at least one of "filter" or "bias".',
      );
    }
    if (limit != null && (limit! < 1 || limit! > 500)) {
      throw GeoapifyValidationException(
        'Places limit must be between 1 and 500, got $limit.',
      );
    }
    if (offset != null && offset! < 0) {
      throw GeoapifyValidationException(
        'Places offset must be >= 0, got $offset.',
      );
    }
    if (name != null && name!.trim().isEmpty) {
      throw const GeoapifyValidationException(
        'Places name filter must not be blank when provided.',
      );
    }
  }

  /// Builds query parameters for `GET /v2/places`.
  ///
  /// Throws [GeoapifyValidationException] if [filter] requires POST.
  Map<String, List<String>> toQueryParameters() {
    validate();
    final activeFilter = filter;
    if (activeFilter != null && !activeFilter.supportsGet) {
      throw GeoapifyValidationException(
        '${activeFilter.runtimeType} requires POST /v2/places and cannot be used with GET.',
      );
    }

    final builder = QueryParametersBuilder()
      ..addJoined('categories', categories.map((c) => c.trim()))
      ..addJoined('conditions', conditions?.map((c) => c.trim()))
      ..add('filter', activeFilter?.toGetFilterString())
      ..add('bias', bias?.toGetBiasString())
      ..addInt('limit', limit)
      ..addInt('offset', offset)
      ..add('lang', lang?.trim().isNotEmpty == true ? lang!.trim() : null)
      ..add('name', name?.trim().isNotEmpty == true ? name!.trim() : null);
    return builder.build();
  }

  /// Builds the JSON request body for `POST /v2/places`.
  ///
  /// Throws [GeoapifyValidationException] if [filter] is GET-only (such as
  /// [CompositePlacesFilter]).
  Map<String, Object?> toPostBody() {
    validate();
    final activeFilter = filter;
    if (activeFilter != null && !activeFilter.supportsPost) {
      throw GeoapifyValidationException(
        '${activeFilter.runtimeType} is only supported by GET /v2/places.',
      );
    }

    return {
      'categories': categories.map((c) => c.trim()).toList(growable: false),
      if (conditions != null)
        'conditions': conditions!.map((c) => c.trim()).toList(growable: false),
      if (activeFilter != null) 'filter': activeFilter.toPostJson(),
      if (bias != null) 'bias': bias!.toPostJson(),
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (lang != null && lang!.trim().isNotEmpty) 'lang': lang!.trim(),
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
    };
  }
}
