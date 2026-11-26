/// Typed avoidance rules for Routing, Route Matrix, and Isoline APIs.
library;

import '../../core/serialization/json_utils.dart';
import 'geo_point.dart';

/// Road features that can be avoided during routing, matrix, or isoline
/// calculations.
enum AvoidFeature {
  /// Avoid toll roads (`tolls`).
  tolls('tolls'),

  /// Avoid ferry crossings (`ferries`).
  ferries('ferries'),

  /// Avoid highways/motorways (`highways`).
  highways('highways'),

  /// Avoid environmental/low-emission green zones (`green_zones`).
  greenZones('green_zones'),

  /// Avoid public transit transfers (`transfers`).
  transfers('transfers');

  const AvoidFeature(this.value);

  /// Wire value expected by Geoapify APIs.
  final String value;
}

/// Base class for Geoapify route avoidance rules.
///
/// Supports serialization to both GET query-parameter rules (for Routing and
/// Isolines) and JSON request objects (for Route Matrix).
sealed class AvoidRule {
  const AvoidRule({this.importance});

  /// Parses an [AvoidRule] from a response JSON `Avoid` object.
  factory AvoidRule.fromJson(Map<String, Object?> json) {
    final type = readString(json, 'type') ?? '';
    final importance = readDouble(json, 'importance');
    final rawValues = readList(json, 'values');

    switch (type) {
      case 'tolls':
        return AvoidFeatureRule(
          feature: AvoidFeature.tolls,
          importance: importance,
        );
      case 'ferries':
        return AvoidFeatureRule(
          feature: AvoidFeature.ferries,
          importance: importance,
        );
      case 'highways':
        return AvoidFeatureRule(
          feature: AvoidFeature.highways,
          importance: importance,
        );
      case 'green_zones':
        return AvoidFeatureRule(
          feature: AvoidFeature.greenZones,
          importance: importance,
        );
      case 'transfers':
        return AvoidFeatureRule(
          feature: AvoidFeature.transfers,
          importance: importance,
        );
      case 'locations':
        final locations = <GeoPoint>[];
        if (rawValues != null) {
          for (final item in rawValues) {
            if (item is Map) {
              locations.add(GeoPoint.fromLatLonJson(asJsonMap(item)));
            }
          }
        }
        return AvoidLocationsRule(locations: locations, importance: importance);
      case 'polygons':
        final polygons = <List<GeoPoint>>[];
        if (rawValues != null) {
          for (final poly in rawValues) {
            if (poly is List) {
              final ring = <GeoPoint>[];
              for (final point in poly) {
                if (point is Map) {
                  ring.add(GeoPoint.fromLatLonJson(asJsonMap(point)));
                }
              }
              polygons.add(ring);
            }
          }
        }
        return AvoidPolygonsRule(polygons: polygons, importance: importance);
      case 'country_codes':
        final codes = rawValues?.whereType<String>().toList() ?? const [];
        return AvoidCountryCodesRule(
          countryCodes: codes,
          importance: importance,
        );
      default:
        return UnknownAvoidRule(
          type: type,
          importance: importance,
          raw: Map.unmodifiable(json),
        );
    }
  }

  /// Optional avoidance penalty weight between `0.0` and `1.0`.
  final double? importance;

  static void _validateImportance(double? importance) {
    if (importance != null &&
        (!importance.isFinite || importance < 0.0 || importance > 1.0)) {
      throw ArgumentError.value(
        importance,
        'importance',
        'Avoidance importance must be between 0.0 and 1.0.',
      );
    }
  }

  /// Serializes this rule to one or more GET query-parameter strings for
  /// Routing (`|`-joined) and Isolines (repeated `avoid` query parameters).
  List<String> toQueryValues();

  /// Serializes this rule as a JSON object for the Route Matrix POST body.
  Map<String, Object?> toMatrixJson();
}

/// Avoids a road or transit feature such as tolls, ferries, or highways.
final class AvoidFeatureRule extends AvoidRule {
  /// Creates an [AvoidFeatureRule].
  AvoidFeatureRule({required this.feature, super.importance}) {
    AvoidRule._validateImportance(importance);
  }

  /// Feature to avoid.
  final AvoidFeature feature;

  @override
  List<String> toQueryValues() {
    if (importance != null) {
      return ['${feature.value}:$importance'];
    }
    return [feature.value];
  }

  @override
  Map<String, Object?> toMatrixJson() => {
    'type': feature.value,
    if (importance != null) 'importance': importance,
  };
}

/// Avoids one or more specific coordinate locations.
final class AvoidLocationsRule extends AvoidRule {
  /// Creates an [AvoidLocationsRule].
  AvoidLocationsRule({required List<GeoPoint> locations, super.importance})
    : locations = List.unmodifiable(locations) {
    AvoidRule._validateImportance(importance);
    if (this.locations.isEmpty) {
      throw ArgumentError.value(
        locations,
        'locations',
        'At least one location must be provided.',
      );
    }
  }

  /// Locations to avoid.
  final List<GeoPoint> locations;

  @override
  List<String> toQueryValues() {
    return locations
        .map((point) => 'location:${point.toLatLonString()}')
        .toList(growable: false);
  }

  @override
  Map<String, Object?> toMatrixJson() => {
    'type': 'locations',
    if (importance != null) 'importance': importance,
    'values': locations.map((point) => point.toLatLonJson()).toList(),
  };
}

/// Avoids one or more polygonal geographic areas.
final class AvoidPolygonsRule extends AvoidRule {
  /// Creates an [AvoidPolygonsRule].
  ///
  /// Each polygon must contain at least 3 vertices.
  AvoidPolygonsRule({required List<List<GeoPoint>> polygons, super.importance})
    : polygons = List.unmodifiable(polygons.map(List<GeoPoint>.unmodifiable)) {
    AvoidRule._validateImportance(importance);
    if (this.polygons.isEmpty) {
      throw ArgumentError.value(
        polygons,
        'polygons',
        'At least one polygon must be provided.',
      );
    }
    for (final polygon in this.polygons) {
      if (polygon.length < 3) {
        throw ArgumentError.value(
          polygon,
          'polygons',
          'Each avoid polygon must contain at least 3 vertices.',
        );
      }
    }
  }

  /// Polygons to avoid, represented as ordered lists of [GeoPoint] vertices.
  final List<List<GeoPoint>> polygons;

  @override
  List<String> toQueryValues() {
    return polygons
        .map(
          (ring) => 'polygon:${ring.map((p) => p.toLatLonString()).join(';')}',
        )
        .toList(growable: false);
  }

  /// Serializes this rule as a JSON object for the Route Matrix POST body.
  @override
  Map<String, Object?> toMatrixJson() => {
    'type': 'polygons',
    if (importance != null) 'importance': importance,
    'values': polygons
        .map((ring) => ring.map(_pointToLatLonJson).toList())
        .toList(),
  };

  static Map<String, double> _pointToLatLonJson(GeoPoint point) =>
      point.toLatLonJson();
}

/// Avoids routing through one or more countries specified by ISO 3166-1
/// alpha-2 country codes.
final class AvoidCountryCodesRule extends AvoidRule {
  /// Creates an [AvoidCountryCodesRule].
  AvoidCountryCodesRule({required List<String> countryCodes, super.importance})
    : countryCodes = List.unmodifiable(
        countryCodes.map((c) => c.trim().toLowerCase()),
      ) {
    AvoidRule._validateImportance(importance);
    if (this.countryCodes.isEmpty) {
      throw ArgumentError.value(
        countryCodes,
        'countryCodes',
        'At least one country code must be provided.',
      );
    }
    for (final code in this.countryCodes) {
      if (!RegExp(r'^[a-z]{2}$').hasMatch(code)) {
        throw ArgumentError.value(
          code,
          'countryCodes',
          'Country codes must be 2-letter ISO 3166-1 alpha-2 codes.',
        );
      }
    }
  }

  /// Lowercase ISO 3166-1 alpha-2 country codes.
  final List<String> countryCodes;

  @override
  List<String> toQueryValues() => ['country_codes:${countryCodes.join(',')}'];

  @override
  Map<String, Object?> toMatrixJson() => {
    'type': 'country_codes',
    if (importance != null) 'importance': importance,
    'values': countryCodes,
  };
}

/// Fallback representation for an unrecognized `Avoid` object returned in a
/// response.
final class UnknownAvoidRule extends AvoidRule {
  /// Creates an [UnknownAvoidRule].
  const UnknownAvoidRule({
    required this.type,
    required this.raw,
    super.importance,
  });

  /// Raw `type` field.
  final String type;

  /// Unmodified JSON object.
  final Map<String, Object?> raw;

  @override
  List<String> toQueryValues() => [type];

  @override
  Map<String, Object?> toMatrixJson() => raw;
}
