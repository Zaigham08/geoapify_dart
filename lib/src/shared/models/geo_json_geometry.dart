/// Strongly typed GeoJSON geometry models with longitude/latitude parsing.
library;

import '../../core/serialization/json_utils.dart';
import 'geo_point.dart';

/// Base class for parsed GeoJSON geometries.
sealed class GeoJsonGeometry {
  const GeoJsonGeometry({required this.type});

  /// GeoJSON geometry type discriminator (for example `Point` or `Polygon`).
  final String type;

  /// Parses a GeoJSON geometry object, converting GeoJSON `[lon, lat]`
  /// positions into [GeoPoint] instances.
  factory GeoJsonGeometry.fromJson(Map<String, Object?> json) {
    final type = readString(json, 'type');
    if (type == null || type.isEmpty) {
      throw const FormatException('GeoJSON geometry is missing "type".');
    }

    switch (type) {
      case 'Point':
        final coords = readList(json, 'coordinates');
        if (coords == null) {
          throw const FormatException('Point geometry missing "coordinates".');
        }
        return GeoPointGeometry(
          coordinates: GeoPoint.fromGeoJsonPosition(coords),
        );

      case 'MultiPoint':
        final coords = readList(json, 'coordinates');
        if (coords == null) {
          throw const FormatException(
            'MultiPoint geometry missing "coordinates".',
          );
        }
        return GeoMultiPointGeometry(coordinates: _parsePositionList(coords));

      case 'LineString':
        final coords = readList(json, 'coordinates');
        if (coords == null) {
          throw const FormatException(
            'LineString geometry missing "coordinates".',
          );
        }
        return GeoLineStringGeometry(coordinates: _parsePositionList(coords));

      case 'MultiLineString':
        final coords = readList(json, 'coordinates');
        if (coords == null) {
          throw const FormatException(
            'MultiLineString geometry missing "coordinates".',
          );
        }
        return GeoMultiLineStringGeometry(coordinates: _parseLineList(coords));

      case 'Polygon':
        final coords = readList(json, 'coordinates');
        if (coords == null) {
          throw const FormatException(
            'Polygon geometry missing "coordinates".',
          );
        }
        return GeoPolygonGeometry(rings: _parseLineList(coords));

      case 'MultiPolygon':
        final coords = readList(json, 'coordinates');
        if (coords == null) {
          throw const FormatException(
            'MultiPolygon geometry missing "coordinates".',
          );
        }
        return GeoMultiPolygonGeometry(polygons: _parsePolygonList(coords));

      case 'GeometryCollection':
        final rawGeometries = readList(json, 'geometries') ?? const [];
        final parsed = <GeoJsonGeometry>[];
        for (final item in rawGeometries) {
          if (item is Map) {
            parsed.add(GeoJsonGeometry.fromJson(asJsonMap(item)));
          }
        }
        return GeoGeometryCollection(geometries: parsed);

      default:
        return UnknownGeoJsonGeometry(type: type, raw: Map.unmodifiable(json));
    }
  }

  /// Serializes this geometry back into a GeoJSON-compatible map.
  Map<String, Object?> toJson();

  static List<GeoPoint> _parsePositionList(List<Object?> rawList) {
    final points = <GeoPoint>[];
    for (final item in rawList) {
      if (item is! List<Object?>) {
        throw const FormatException('Expected coordinate position array.');
      }
      points.add(GeoPoint.fromGeoJsonPosition(item));
    }
    return List.unmodifiable(points);
  }

  static List<List<GeoPoint>> _parseLineList(List<Object?> rawLines) {
    final lines = <List<GeoPoint>>[];
    for (final line in rawLines) {
      if (line is! List<Object?>) {
        throw const FormatException('Expected list of coordinate positions.');
      }
      lines.add(_parsePositionList(line));
    }
    return List.unmodifiable(lines);
  }

  static List<List<List<GeoPoint>>> _parsePolygonList(
    List<Object?> rawPolygons,
  ) {
    final polygons = <List<List<GeoPoint>>>[];
    for (final polygon in rawPolygons) {
      if (polygon is! List<Object?>) {
        throw const FormatException('Expected polygon ring array.');
      }
      polygons.add(_parseLineList(polygon));
    }
    return List.unmodifiable(polygons);
  }
}

/// GeoJSON `Point` geometry.
final class GeoPointGeometry extends GeoJsonGeometry {
  /// Creates a [GeoPointGeometry].
  const GeoPointGeometry({required this.coordinates}) : super(type: 'Point');

  /// Point coordinate.
  final GeoPoint coordinates;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'coordinates': coordinates.toGeoJsonPosition(),
  };
}

/// GeoJSON `MultiPoint` geometry.
final class GeoMultiPointGeometry extends GeoJsonGeometry {
  /// Creates a [GeoMultiPointGeometry].
  const GeoMultiPointGeometry({required this.coordinates})
    : super(type: 'MultiPoint');

  /// List of points.
  final List<GeoPoint> coordinates;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'coordinates': coordinates.map((p) => p.toGeoJsonPosition()).toList(),
  };
}

/// GeoJSON `LineString` geometry.
final class GeoLineStringGeometry extends GeoJsonGeometry {
  /// Creates a [GeoLineStringGeometry].
  const GeoLineStringGeometry({required this.coordinates})
    : super(type: 'LineString');

  /// Ordered vertices of the line.
  final List<GeoPoint> coordinates;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'coordinates': coordinates.map((p) => p.toGeoJsonPosition()).toList(),
  };
}

/// GeoJSON `MultiLineString` geometry.
final class GeoMultiLineStringGeometry extends GeoJsonGeometry {
  /// Creates a [GeoMultiLineStringGeometry].
  const GeoMultiLineStringGeometry({required this.coordinates})
    : super(type: 'MultiLineString');

  /// Ordered line segments.
  final List<List<GeoPoint>> coordinates;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'coordinates': coordinates
        .map((line) => line.map((p) => p.toGeoJsonPosition()).toList())
        .toList(),
  };
}

/// GeoJSON `Polygon` geometry.
final class GeoPolygonGeometry extends GeoJsonGeometry {
  /// Creates a [GeoPolygonGeometry].
  const GeoPolygonGeometry({required this.rings}) : super(type: 'Polygon');

  /// Linear rings, where the first ring is the exterior boundary and any
  /// subsequent rings are interior holes.
  final List<List<GeoPoint>> rings;

  /// Exterior boundary ring, or `null` if [rings] is empty.
  List<GeoPoint>? get outerRing => rings.isNotEmpty ? rings.first : null;

  /// Interior hole rings.
  List<List<GeoPoint>> get holes =>
      rings.length > 1 ? rings.sublist(1) : const [];

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'coordinates': rings
        .map((ring) => ring.map((p) => p.toGeoJsonPosition()).toList())
        .toList(),
  };
}

/// GeoJSON `MultiPolygon` geometry.
final class GeoMultiPolygonGeometry extends GeoJsonGeometry {
  /// Creates a [GeoMultiPolygonGeometry].
  const GeoMultiPolygonGeometry({required this.polygons})
    : super(type: 'MultiPolygon');

  /// List of polygons, each represented as a list of linear rings.
  final List<List<List<GeoPoint>>> polygons;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'coordinates': polygons
        .map(
          (rings) => rings
              .map((ring) => ring.map((p) => p.toGeoJsonPosition()).toList())
              .toList(),
        )
        .toList(),
  };
}

/// GeoJSON `GeometryCollection`.
final class GeoGeometryCollection extends GeoJsonGeometry {
  /// Creates a [GeoGeometryCollection].
  const GeoGeometryCollection({required this.geometries})
    : super(type: 'GeometryCollection');

  /// Member geometries.
  final List<GeoJsonGeometry> geometries;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'geometries': geometries.map((g) => g.toJson()).toList(),
  };
}

/// Fallback representation for an unrecognized GeoJSON geometry type.
final class UnknownGeoJsonGeometry extends GeoJsonGeometry {
  /// Creates an [UnknownGeoJsonGeometry].
  const UnknownGeoJsonGeometry({required super.type, required this.raw});

  /// Unmodified GeoJSON map.
  final Map<String, Object?> raw;

  @override
  Map<String, Object?> toJson() => raw;
}
