/// Request and response models for the Geoapify Route Matrix API.
library;

import '../../../core/exceptions/geoapify_exception.dart';
import '../../../core/serialization/json_utils.dart';
import '../../../shared/enums/distance_units.dart';
import '../../../shared/enums/route_type.dart';
import '../../../shared/enums/traffic_model.dart';
import '../../../shared/enums/travel_mode.dart';
import '../../../shared/models/avoid_rule.dart';
import '../../../shared/models/geo_point.dart';

/// Request body model for `POST /v1/routematrix`.
///
/// Each source and target is serialized in GeoJSON `[longitude, latitude]`
/// order per the Route Matrix OpenAPI specification.
final class RouteMatrixRequest {
  /// Creates a [RouteMatrixRequest].
  RouteMatrixRequest({
    required this.mode,
    required List<GeoPoint> sources,
    required List<GeoPoint> targets,
    List<AvoidRule>? avoid,
    this.traffic,
    this.type,
    this.maxSpeed,
    this.units,
  }) : sources = List.unmodifiable(sources),
       targets = List.unmodifiable(targets),
       avoid = avoid != null ? List.unmodifiable(avoid) : null;

  /// Maximum number of matrix cells allowed for a regular API call.
  static const int maxMatrixCells = 1000;

  /// Travel mode used for the matrix calculation.
  ///
  /// Public transit modes ([TravelMode.transit], [TravelMode.approximatedTransit])
  /// are not supported by the Route Matrix API.
  final TravelMode mode;

  /// Origin locations (`1` to `1000`).
  final List<GeoPoint> sources;

  /// Destination locations (`1` to `1000`).
  final List<GeoPoint> targets;

  /// Road features, locations, polygons, or countries to avoid (up to 100).
  final List<AvoidRule>? avoid;

  /// Traffic model (`free_flow` or `approximated`).
  final TrafficModel? traffic;

  /// Route optimization objective (`balanced`, `short`, or `less_maneuvers`).
  final RouteType? type;

  /// Maximum speed (`10-252` km/h metric or `6.5-155` mph imperial).
  final double? maxSpeed;

  /// Unit system for distances (`metric` or `imperial`).
  final DistanceUnits? units;

  /// Validates request constraints against the Route Matrix OpenAPI spec.
  void validate() {
    if (mode.isTransit) {
      throw GeoapifyValidationException(
        'TravelMode.${mode.name} is not supported by the Route Matrix API.',
      );
    }
    if (sources.isEmpty || sources.length > maxMatrixCells) {
      throw GeoapifyValidationException(
        'Route Matrix requires between 1 and $maxMatrixCells sources, got ${sources.length}.',
      );
    }
    if (targets.isEmpty || targets.length > maxMatrixCells) {
      throw GeoapifyValidationException(
        'Route Matrix requires between 1 and $maxMatrixCells targets, got ${targets.length}.',
      );
    }
    final cellCount = sources.length * targets.length;
    if (cellCount > maxMatrixCells) {
      throw GeoapifyValidationException(
        'Route Matrix size ($cellCount cells) exceeds the maximum of $maxMatrixCells cells for a regular API call.',
      );
    }
    if (avoid != null && avoid!.length > 100) {
      throw GeoapifyValidationException(
        'Route Matrix supports at most 100 avoid rules, got ${avoid!.length}.',
      );
    }
    if (maxSpeed != null &&
        (!maxSpeed!.isFinite || maxSpeed! < 6.5 || maxSpeed! > 252.0)) {
      throw GeoapifyValidationException(
        'maxSpeed must be between 6.5 and 252, got $maxSpeed.',
      );
    }
  }

  /// Serializes this request into the JSON body for `POST /v1/routematrix`.
  Map<String, Object?> toJson() {
    validate();
    return {
      'mode': mode.value,
      'sources': sources
          .map((point) => {'location': point.toGeoJsonPosition()})
          .toList(growable: false),
      'targets': targets
          .map((point) => {'location': point.toGeoJsonPosition()})
          .toList(growable: false),
      if (avoid != null && avoid!.isNotEmpty)
        'avoid': avoid!
            .map((rule) => rule.toMatrixJson())
            .toList(growable: false),
      if (traffic != null) 'traffic': traffic!.value,
      if (type != null) 'type': type!.value,
      if (maxSpeed != null) 'max_speed': maxSpeed,
      if (units != null) 'units': units!.value,
    };
  }
}

/// Response returned by `POST /v1/routematrix`.
final class RouteMatrixResponse {
  /// Creates a [RouteMatrixResponse].
  const RouteMatrixResponse({
    this.sources = const [],
    this.targets = const [],
    this.sourcesToTargets = const [],
    this.units,
    this.distanceUnits,
    this.mode,
    this.type,
    this.maxSpeed,
    this.avoid = const [],
    this.traffic,
  });

  /// Parses a [RouteMatrixResponse] from JSON.
  factory RouteMatrixResponse.fromJson(Map<String, Object?> json) {
    final sources = _parseLocations(readList(json, 'sources'));
    final targets = _parseLocations(readList(json, 'targets'));

    final matrix = <List<RouteMatrixCell>>[];
    final rawRows = readList(json, 'sources_to_targets');
    if (rawRows != null) {
      for (final row in rawRows) {
        if (row is List) {
          final cells = <RouteMatrixCell>[];
          for (final cell in row) {
            if (cell is Map) {
              cells.add(RouteMatrixCell.fromJson(asJsonMap(cell)));
            }
          }
          matrix.add(List.unmodifiable(cells));
        }
      }
    }

    final avoidRules = <AvoidRule>[];
    final rawAvoid = readList(json, 'avoid');
    if (rawAvoid != null) {
      for (final item in rawAvoid) {
        if (item is Map) {
          avoidRules.add(AvoidRule.fromJson(asJsonMap(item)));
        }
      }
    }

    return RouteMatrixResponse(
      sources: sources,
      targets: targets,
      sourcesToTargets: List.unmodifiable(matrix),
      units: DistanceUnits.tryParse(readString(json, 'units')),
      distanceUnits: readString(json, 'distance_units'),
      mode: TravelMode.tryParse(readString(json, 'mode')),
      type: RouteType.tryParse(readString(json, 'type')),
      maxSpeed: readDouble(json, 'max_speed'),
      avoid: List.unmodifiable(avoidRules),
      traffic: TrafficModel.tryParse(readString(json, 'traffic')),
    );
  }

  /// Resolved source locations (with original and road-snapped coordinates).
  final List<RouteMatrixLocation> sources;

  /// Resolved target locations.
  final List<RouteMatrixLocation> targets;

  /// Matrix cells indexed by `[sourceIndex][targetIndex]`.
  final List<List<RouteMatrixCell>> sourcesToTargets;

  /// Unit system for matrix distances.
  final DistanceUnits? units;

  /// Distance unit label (`meters` or `miles`).
  final String? distanceUnits;

  /// Travel mode used.
  final TravelMode? mode;

  /// Route optimization objective used.
  final RouteType? type;

  /// Maximum speed constraint applied.
  final double? maxSpeed;

  /// Avoidance rules applied.
  final List<AvoidRule> avoid;

  /// Traffic model applied.
  final TrafficModel? traffic;

  /// Returns the matrix cell for [sourceIndex] and [targetIndex], or `null`
  /// if out of bounds.
  RouteMatrixCell? cellAt(int sourceIndex, int targetIndex) {
    if (sourceIndex < 0 || sourceIndex >= sourcesToTargets.length) {
      return null;
    }
    final row = sourcesToTargets[sourceIndex];
    if (targetIndex < 0 || targetIndex >= row.length) {
      return null;
    }
    return row[targetIndex];
  }

  static List<RouteMatrixLocation> _parseLocations(List<Object?>? rawList) {
    if (rawList == null) {
      return const [];
    }
    final result = <RouteMatrixLocation>[];
    for (final item in rawList) {
      if (item is Map) {
        result.add(RouteMatrixLocation.fromJson(asJsonMap(item)));
      }
    }
    return List.unmodifiable(result);
  }
}

/// A source or target location returned in a [RouteMatrixResponse].
final class RouteMatrixLocation {
  /// Creates a [RouteMatrixLocation].
  const RouteMatrixLocation({
    required this.originalLocation,
    this.snappedLocation,
  });

  /// Parses a [RouteMatrixLocation] from JSON (`[longitude, latitude]` order).
  factory RouteMatrixLocation.fromJson(Map<String, Object?> json) {
    final originalRaw = readList(json, 'original_location');
    if (originalRaw == null) {
      throw const FormatException(
        'RouteMatrixLocation is missing "original_location".',
      );
    }
    final snappedRaw = readList(json, 'location');
    return RouteMatrixLocation(
      originalLocation: GeoPoint.fromGeoJsonPosition(originalRaw),
      snappedLocation: snappedRaw != null
          ? GeoPoint.fromGeoJsonPosition(snappedRaw)
          : null,
    );
  }

  /// Input location supplied in the request.
  final GeoPoint originalLocation;

  /// Nearest road-network location snapped by the router, if available.
  final GeoPoint? snappedLocation;
}

/// Travel distance and time for a single source-target pair.
///
/// [distance] and [time] are `null` when no route is available between the
/// source and target.
final class RouteMatrixCell {
  /// Creates a [RouteMatrixCell].
  const RouteMatrixCell({
    required this.sourceIndex,
    required this.targetIndex,
    this.distance,
    this.time,
  });

  /// Parses a [RouteMatrixCell] from JSON.
  factory RouteMatrixCell.fromJson(Map<String, Object?> json) {
    return RouteMatrixCell(
      sourceIndex: readInt(json, 'source_index') ?? 0,
      targetIndex: readInt(json, 'target_index') ?? 0,
      distance: readDouble(json, 'distance'),
      time: readDouble(json, 'time'),
    );
  }

  /// 0-based index into [RouteMatrixResponse.sources].
  final int sourceIndex;

  /// 0-based index into [RouteMatrixResponse.targets].
  final int targetIndex;

  /// Travel distance in response units, or `null` if unreachable.
  final double? distance;

  /// Travel time in seconds, or `null` if unreachable.
  final double? time;

  /// Whether a valid route was found between this source and target.
  bool get isReachable => distance != null && time != null;
}
