/// Typed hard filters and ranking biases for Geoapify Geocoding APIs.
library;

import '../../../shared/models/geo_bounding_box.dart';
import '../../../shared/models/geo_point.dart';

/// Base class for hard spatial or administrative filters on forward geocoding
/// and autocomplete requests.
sealed class GeocodingFilter {
  const GeocodingFilter();

  /// Serializes this filter for the `filter` query parameter.
  String toQueryString();
}

/// Restricts geocoding results to a rectangular bounding box
/// (`rect:lon1,lat1,lon2,lat2`).
final class GeocodingRectFilter extends GeocodingFilter {
  /// Creates a [GeocodingRectFilter].
  GeocodingRectFilter({required this.southWest, required this.northEast});

  /// Creates a [GeocodingRectFilter] from a [GeoBoundingBox].
  factory GeocodingRectFilter.fromBoundingBox(GeoBoundingBox bbox) {
    return GeocodingRectFilter(
      southWest: bbox.southWest,
      northEast: bbox.northEast,
    );
  }

  /// South-west corner of the rectangle.
  final GeoPoint southWest;

  /// North-east corner of the rectangle.
  final GeoPoint northEast;

  @override
  String toQueryString() {
    return 'rect:${southWest.toLonLatString()},${northEast.toLonLatString()}';
  }
}

/// Restricts geocoding results to a circular region
/// (`circle:lon,lat,radiusMeters`).
final class GeocodingCircleFilter extends GeocodingFilter {
  /// Creates a [GeocodingCircleFilter].
  ///
  /// Throws an [ArgumentError] if [radiusMeters] is not positive or finite.
  GeocodingCircleFilter({required this.center, required this.radiusMeters}) {
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw ArgumentError.value(
        radiusMeters,
        'radiusMeters',
        'Radius must be a positive finite number of meters.',
      );
    }
  }

  /// Circle center coordinate.
  final GeoPoint center;

  /// Search radius in meters.
  final double radiusMeters;

  @override
  String toQueryString() => 'circle:${center.toLonLatString()},$radiusMeters';
}

/// Restricts geocoding results to one or more ISO 3166-1 alpha-2 country
/// codes (`countrycode:us,ca`).
final class GeocodingCountryFilter extends GeocodingFilter {
  /// Creates a [GeocodingCountryFilter].
  GeocodingCountryFilter({required List<String> countryCodes})
    : countryCodes = _normalizeCountryCodes(countryCodes);

  /// Lowercase ISO 3166-1 alpha-2 country codes (or `auto`/`none`).
  final List<String> countryCodes;

  @override
  String toQueryString() => 'countrycode:${countryCodes.join(',')}';
}

/// Restricts geocoding results inside a previously returned Geoapify place ID
/// (`place:<placeId>`).
final class GeocodingPlaceFilter extends GeocodingFilter {
  /// Creates a [GeocodingPlaceFilter].
  GeocodingPlaceFilter({required this.placeId}) {
    if (placeId.trim().isEmpty) {
      throw ArgumentError.value(
        placeId,
        'placeId',
        'placeId must not be empty.',
      );
    }
  }

  /// Geoapify place identifier.
  final String placeId;

  @override
  String toQueryString() => 'place:${placeId.trim()}';
}

/// Base class for ranking biases on forward geocoding and autocomplete
/// requests.
sealed class GeocodingBias {
  const GeocodingBias();

  /// Serializes this bias for the `bias` query parameter.
  String toQueryString();
}

/// Prioritizes geocoding results near [location] (`proximity:lon,lat`).
final class GeocodingProximityBias extends GeocodingBias {
  /// Creates a [GeocodingProximityBias].
  const GeocodingProximityBias({required this.location});

  /// Reference coordinate to bias results toward.
  final GeoPoint location;

  @override
  String toQueryString() => 'proximity:${location.toLonLatString()}';
}

/// Prioritizes geocoding results inside a rectangle (`rect:lon1,lat1,lon2,lat2`).
final class GeocodingRectBias extends GeocodingBias {
  /// Creates a [GeocodingRectBias].
  const GeocodingRectBias({required this.southWest, required this.northEast});

  /// Creates a [GeocodingRectBias] from a [GeoBoundingBox].
  factory GeocodingRectBias.fromBoundingBox(GeoBoundingBox bbox) {
    return GeocodingRectBias(
      southWest: bbox.southWest,
      northEast: bbox.northEast,
    );
  }

  /// South-west corner of the rectangle.
  final GeoPoint southWest;

  /// North-east corner of the rectangle.
  final GeoPoint northEast;

  @override
  String toQueryString() {
    return 'rect:${southWest.toLonLatString()},${northEast.toLonLatString()}';
  }
}

/// Prioritizes geocoding results within a circle (`circle:lon,lat,radiusMeters`).
final class GeocodingCircleBias extends GeocodingBias {
  /// Creates a [GeocodingCircleBias].
  GeocodingCircleBias({required this.center, required this.radiusMeters}) {
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw ArgumentError.value(
        radiusMeters,
        'radiusMeters',
        'Radius must be a positive finite number of meters.',
      );
    }
  }

  /// Circle center coordinate.
  final GeoPoint center;

  /// Bias radius in meters.
  final double radiusMeters;

  @override
  String toQueryString() => 'circle:${center.toLonLatString()},$radiusMeters';
}

/// Prioritizes geocoding results in the given countries (`countrycode:...`).
final class GeocodingCountryBias extends GeocodingBias {
  /// Creates a [GeocodingCountryBias].
  GeocodingCountryBias({required List<String> countryCodes})
    : countryCodes = _normalizeCountryCodes(countryCodes);

  /// Lowercase ISO 3166-1 alpha-2 country codes, `auto`, or `none`.
  final List<String> countryCodes;

  @override
  String toQueryString() => 'countrycode:${countryCodes.join(',')}';
}

List<String> _normalizeCountryCodes(List<String> codes) {
  final normalized = codes
      .map((c) => c.trim().toLowerCase())
      .where((c) => c.isNotEmpty)
      .toList(growable: false);
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      codes,
      'countryCodes',
      'At least one country code must be provided.',
    );
  }
  for (final code in normalized) {
    if (code != 'auto' &&
        code != 'none' &&
        !RegExp(r'^[a-z]{2}$').hasMatch(code)) {
      throw ArgumentError.value(
        code,
        'countryCodes',
        'Country codes must be 2-letter ISO 3166-1 alpha-2 codes, "auto", or "none".',
      );
    }
  }
  return List.unmodifiable(normalized);
}
