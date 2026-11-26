/// Typed spatial filters and ranking biases for the Geoapify Places API.
library;

import '../../../shared/models/geo_bounding_box.dart';
import '../../../shared/models/geo_point.dart';

/// Polyline encoding precision supported by [EncodedPolylineFilter].
enum PolylineEncoding {
  /// Precision-5 encoded polyline (`polyline5`).
  polyline5('polyline5'),

  /// Precision-6 encoded polyline (`polyline6`).
  polyline6('polyline6');

  const PolylineEncoding(this.value);

  /// Wire value expected by the Places POST API.
  final String value;
}

/// Base class for hard filters on Geoapify Places API searches.
sealed class PlacesFilter {
  const PlacesFilter();

  /// Whether this filter can be serialized in a `GET /v2/places` query string.
  bool get supportsGet => true;

  /// Whether this filter can be serialized in a `POST /v2/places` JSON body.
  bool get supportsPost => true;

  /// Serializes this filter for `GET /v2/places?filter=...`.
  ///
  /// Throws [UnsupportedError] for POST-only filters such as [PolygonFilter]
  /// and [PolylineFilter].
  String toGetFilterString();

  /// Serializes this filter for `POST /v2/places`.
  ///
  /// Throws [UnsupportedError] for GET-only [CompositePlacesFilter].
  Map<String, Object?> toPostJson();
}

/// Filters places within a circle (`circle:lon,lat,radiusMeters`).
final class CircleFilter extends PlacesFilter {
  /// Creates a [CircleFilter].
  ///
  /// Throws an [ArgumentError] if [radiusMeters] is not positive and finite.
  CircleFilter({required this.center, required this.radiusMeters}) {
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw ArgumentError.value(
        radiusMeters,
        'radiusMeters',
        'radiusMeters must be a positive finite number.',
      );
    }
  }

  /// Circle center coordinate.
  final GeoPoint center;

  /// Search radius in meters.
  final double radiusMeters;

  @override
  String toGetFilterString() =>
      'circle:${center.toLonLatString()},$radiusMeters';

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'circle',
    'lon': center.longitude,
    'lat': center.latitude,
    'radius': radiusMeters,
  };
}

/// Filters places inside a bounding rectangle (`rect:lon1,lat1,lon2,lat2`).
final class RectFilter extends PlacesFilter {
  /// Creates a [RectFilter].
  const RectFilter({required this.southWest, required this.northEast});

  /// Creates a [RectFilter] from a [GeoBoundingBox].
  factory RectFilter.fromBoundingBox(GeoBoundingBox bbox) {
    return RectFilter(southWest: bbox.southWest, northEast: bbox.northEast);
  }

  /// South-west corner (`lon1`, `lat1`).
  final GeoPoint southWest;

  /// North-east corner (`lon2`, `lat2`).
  final GeoPoint northEast;

  @override
  String toGetFilterString() =>
      'rect:${southWest.toLonLatString()},${northEast.toLonLatString()}';

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'rect',
    'lon1': southWest.longitude,
    'lat1': southWest.latitude,
    'lon2': northEast.longitude,
    'lat2': northEast.latitude,
  };
}

/// Filters places inside a previously stored Geoapify geometry ID (for example
/// an isoline ID).
final class GeometryFilter extends PlacesFilter {
  /// Creates a [GeometryFilter].
  ///
  /// Throws an [ArgumentError] if [geometryId] is not a 32-character lowercase
  /// hexadecimal ID.
  GeometryFilter({required String geometryId})
    : geometryId = geometryId.trim().toLowerCase() {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(this.geometryId)) {
      throw ArgumentError.value(
        geometryId,
        'geometryId',
        'geometryId must be a 32-character hexadecimal string.',
      );
    }
  }

  /// 32-character hexadecimal stored geometry identifier.
  final String geometryId;

  @override
  String toGetFilterString() => 'geometry:$geometryId';

  @override
  Map<String, Object?> toPostJson() => {'type': 'geometry', 'id': geometryId};
}

/// Filters places inside a Geoapify place boundary by `place_id`.
final class PlaceFilter extends PlacesFilter {
  /// Creates a [PlaceFilter].
  PlaceFilter({required String placeId}) : placeId = placeId.trim() {
    if (this.placeId.isEmpty) {
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
  String toGetFilterString() => 'place:$placeId';

  @override
  Map<String, Object?> toPostJson() => {'type': 'place', 'id': placeId};
}

/// Filters places to one or more ISO 3166-1 alpha-2 country codes.
final class CountryCodeFilter extends PlacesFilter {
  /// Creates a [CountryCodeFilter].
  CountryCodeFilter({required List<String> countryCodes})
    : countryCodes = _normalizePlaceCountryCodes(countryCodes);

  /// Lowercase ISO 3166-1 alpha-2 country codes (or `auto`/`none`).
  final List<String> countryCodes;

  @override
  String toGetFilterString() => 'countrycode:${countryCodes.join(',')}';

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'countrycode',
    'values': countryCodes,
  };
}

/// Combines multiple GET-compatible filters using AND logic (`filter1|filter2`).
///
/// Supported only for `GET /v2/places`.
final class CompositePlacesFilter extends PlacesFilter {
  /// Creates a [CompositePlacesFilter].
  CompositePlacesFilter({required List<PlacesFilter> filters})
    : filters = List.unmodifiable(filters) {
    if (this.filters.isEmpty) {
      throw ArgumentError.value(
        filters,
        'filters',
        'At least one filter must be provided.',
      );
    }
    for (final filter in this.filters) {
      if (!filter.supportsGet) {
        throw ArgumentError(
          'CompositePlacesFilter only supports GET-compatible filters.',
        );
      }
    }
  }

  /// Member filters combined with `|` (AND).
  final List<PlacesFilter> filters;

  @override
  bool get supportsPost => false;

  @override
  String toGetFilterString() =>
      filters.map((f) => f.toGetFilterString()).join('|');

  @override
  Map<String, Object?> toPostJson() {
    throw UnsupportedError(
      'CompositePlacesFilter is only supported on GET /v2/places.',
    );
  }
}

/// Filters places within a GeoJSON `Polygon` or `MultiPolygon` (`POST /v2/places`
/// only).
final class PolygonFilter extends PlacesFilter {
  /// Filters places within a single GeoJSON `Polygon`.
  ///
  /// Each ring must contain at least 4 positions (closed ring with first and
  /// last positions equal). Coordinates are serialized in GeoJSON
  /// `[longitude, latitude]` order.
  PolygonFilter.polygon({
    required List<List<GeoPoint>> rings,
    this.bufferMeters,
  }) : isMultiPolygon = false,
       polygons = List<List<List<GeoPoint>>>.unmodifiable([
         List<List<GeoPoint>>.unmodifiable(
           rings.map(List<GeoPoint>.unmodifiable),
         ),
       ]) {
    _validateRings(polygons.first);
    _validateBuffer(bufferMeters, allowZero: true);
  }

  /// Filters places within a GeoJSON `MultiPolygon`.
  PolygonFilter.multiPolygon({
    required List<List<List<GeoPoint>>> polygons,
    this.bufferMeters,
  }) : isMultiPolygon = true,
       polygons = List.unmodifiable(
         polygons.map(
           (poly) => List<List<GeoPoint>>.unmodifiable(
             poly.map(List<GeoPoint>.unmodifiable),
           ),
         ),
       ) {
    if (this.polygons.isEmpty) {
      throw ArgumentError.value(
        polygons,
        'polygons',
        'MultiPolygon must contain at least one polygon.',
      );
    }
    for (final poly in this.polygons) {
      _validateRings(poly);
    }
    _validateBuffer(bufferMeters, allowZero: true);
  }

  /// Whether to emit a GeoJSON `MultiPolygon` instead of a `Polygon`.
  final bool isMultiPolygon;

  /// Polygon rings (`polygons[0]` is used for single `Polygon`).
  final List<List<List<GeoPoint>>> polygons;

  /// Optional buffer around the polygon in meters (`0` to `100000`).
  final double? bufferMeters;

  @override
  bool get supportsGet => false;

  @override
  String toGetFilterString() {
    throw UnsupportedError('PolygonFilter requires POST /v2/places.');
  }

  @override
  Map<String, Object?> toPostJson() {
    return {
      'type': 'polygon',
      'geometry': isMultiPolygon
          ? {
              'type': 'MultiPolygon',
              'coordinates': polygons
                  .map(
                    (poly) => poly
                        .map(
                          (ring) =>
                              ring.map((p) => p.toGeoJsonPosition()).toList(),
                        )
                        .toList(),
                  )
                  .toList(),
            }
          : {
              'type': 'Polygon',
              'coordinates': polygons.first
                  .map(
                    (ring) => ring.map((p) => p.toGeoJsonPosition()).toList(),
                  )
                  .toList(),
            },
      if (bufferMeters != null) 'buffer': bufferMeters,
    };
  }

  static void _validateRings(List<List<GeoPoint>> rings) {
    if (rings.isEmpty || rings.length > 100) {
      throw ArgumentError.value(
        rings,
        'rings',
        'Polygon must contain between 1 and 100 rings.',
      );
    }
    for (final ring in rings) {
      if (ring.length < 4) {
        throw ArgumentError.value(
          ring,
          'rings',
          'Each linear ring must contain at least 4 coordinates.',
        );
      }
    }
  }
}

/// Filters places along a route/line or encoded polyline (`POST /v2/places`
/// only).
sealed class PolylineFilter extends PlacesFilter {
  const PolylineFilter({this.bufferMeters});

  /// Filters places along a raw `LineString`.
  factory PolylineFilter.lineString({
    required List<GeoPoint> coordinates,
    double? bufferMeters,
  }) = RawPolylineFilter.lineString;

  /// Filters places along a raw `MultiLineString`.
  factory PolylineFilter.multiLineString({
    required List<List<GeoPoint>> lines,
    double? bufferMeters,
  }) = RawPolylineFilter.multiLineString;

  /// Filters places along an encoded polyline (`polyline5` or `polyline6`).
  factory PolylineFilter.encoded({
    required String geometry,
    required PolylineEncoding encoding,
    double? bufferMeters,
  }) = EncodedPolylineFilter;

  /// Optional buffer around the line in meters (`> 0` and `<= 100000`).
  final double? bufferMeters;

  @override
  bool get supportsGet => false;

  @override
  String toGetFilterString() {
    throw UnsupportedError('PolylineFilter requires POST /v2/places.');
  }
}

/// Raw GeoJSON `LineString` / `MultiLineString` polyline filter.
final class RawPolylineFilter extends PolylineFilter {
  /// Creates a `LineString` filter.
  RawPolylineFilter.lineString({
    required List<GeoPoint> coordinates,
    super.bufferMeters,
  }) : isMultiLineString = false,
       lines = List<List<GeoPoint>>.unmodifiable([
         List<GeoPoint>.unmodifiable(coordinates),
       ]) {
    _validateLine(lines.first);
    _validateBuffer(bufferMeters, allowZero: false);
  }

  /// Creates a `MultiLineString` filter.
  RawPolylineFilter.multiLineString({
    required List<List<GeoPoint>> lines,
    super.bufferMeters,
  }) : isMultiLineString = true,
       lines = List<List<GeoPoint>>.unmodifiable(
         lines.map(List<GeoPoint>.unmodifiable),
       ) {
    if (this.lines.isEmpty) {
      throw ArgumentError.value(
        lines,
        'lines',
        'MultiLineString must contain at least one line.',
      );
    }
    for (final line in this.lines) {
      _validateLine(line);
    }
    _validateBuffer(bufferMeters, allowZero: false);
  }

  /// Whether to emit `MultiLineString` instead of `LineString`.
  final bool isMultiLineString;

  /// Line coordinates.
  final List<List<GeoPoint>> lines;

  @override
  Map<String, Object?> toPostJson() {
    return {
      'type': 'polyline',
      'geometry': isMultiLineString
          ? {
              'type': 'MultiLineString',
              'coordinates': lines
                  .map(
                    (line) => line.map((p) => p.toGeoJsonPosition()).toList(),
                  )
                  .toList(),
            }
          : {
              'type': 'LineString',
              'coordinates': lines.first
                  .map((p) => p.toGeoJsonPosition())
                  .toList(),
            },
      if (bufferMeters != null) 'buffer': bufferMeters,
    };
  }

  static void _validateLine(List<GeoPoint> line) {
    if (line.length < 2 || line.length > 10000) {
      throw ArgumentError.value(
        line,
        'coordinates',
        'Line coordinates must contain between 2 and 10,000 points.',
      );
    }
  }
}

/// Encoded polyline (`polyline5` or `polyline6`) filter.
final class EncodedPolylineFilter extends PolylineFilter {
  /// Creates an [EncodedPolylineFilter].
  EncodedPolylineFilter({
    required this.geometry,
    required this.encoding,
    super.bufferMeters,
  }) {
    if (geometry.isEmpty) {
      throw ArgumentError.value(
        geometry,
        'geometry',
        'Encoded polyline geometry must not be empty.',
      );
    }
    _validateBuffer(bufferMeters, allowZero: false);
  }

  /// Encoded polyline string.
  final String geometry;

  /// Polyline precision encoding.
  final PolylineEncoding encoding;

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'polyline',
    'geometry': geometry,
    'encoding': encoding.value,
    if (bufferMeters != null) 'buffer': bufferMeters,
  };
}

/// Base class for ranking biases on Geoapify Places API searches.
sealed class PlacesBias {
  const PlacesBias();

  /// Serializes this bias for `GET /v2/places?bias=...`.
  String toGetBiasString();

  /// Serializes this bias for `POST /v2/places`.
  Map<String, Object?> toPostJson();
}

/// Prioritizes places nearest to [location] (`proximity:lon,lat`).
final class ProximityBias extends PlacesBias {
  /// Creates a [ProximityBias].
  const ProximityBias({required this.location});

  /// Reference coordinate.
  final GeoPoint location;

  @override
  String toGetBiasString() => 'proximity:${location.toLonLatString()}';

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'proximity',
    'lon': location.longitude,
    'lat': location.latitude,
  };
}

/// Prioritizes places within a circle (`circle:lon,lat,radiusMeters`).
final class CircleBias extends PlacesBias {
  /// Creates a [CircleBias].
  CircleBias({required this.center, required this.radiusMeters}) {
    if (!radiusMeters.isFinite || radiusMeters <= 0) {
      throw ArgumentError.value(
        radiusMeters,
        'radiusMeters',
        'radiusMeters must be a positive finite number.',
      );
    }
  }

  /// Circle center coordinate.
  final GeoPoint center;

  /// Bias radius in meters.
  final double radiusMeters;

  @override
  String toGetBiasString() => 'circle:${center.toLonLatString()},$radiusMeters';

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'circle',
    'lon': center.longitude,
    'lat': center.latitude,
    'radius': radiusMeters,
  };
}

/// Prioritizes places within a rectangle (`rect:lon1,lat1,lon2,lat2`).
final class RectBias extends PlacesBias {
  /// Creates a [RectBias].
  const RectBias({required this.southWest, required this.northEast});

  /// Creates a [RectBias] from a [GeoBoundingBox].
  factory RectBias.fromBoundingBox(GeoBoundingBox bbox) {
    return RectBias(southWest: bbox.southWest, northEast: bbox.northEast);
  }

  /// South-west corner.
  final GeoPoint southWest;

  /// North-east corner.
  final GeoPoint northEast;

  @override
  String toGetBiasString() =>
      'rect:${southWest.toLonLatString()},${northEast.toLonLatString()}';

  @override
  Map<String, Object?> toPostJson() => {
    'type': 'rect',
    'lon1': southWest.longitude,
    'lat1': southWest.latitude,
    'lon2': northEast.longitude,
    'lat2': northEast.latitude,
  };
}

void _validateBuffer(double? bufferMeters, {required bool allowZero}) {
  if (bufferMeters == null) {
    return;
  }
  final validMin = allowZero ? bufferMeters >= 0 : bufferMeters > 0;
  if (!bufferMeters.isFinite || !validMin || bufferMeters > 100000) {
    throw ArgumentError.value(
      bufferMeters,
      'bufferMeters',
      allowZero
          ? 'bufferMeters must be between 0 and 100,000.'
          : 'bufferMeters must be greater than 0 and at most 100,000.',
    );
  }
}

List<String> _normalizePlaceCountryCodes(List<String> codes) {
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
