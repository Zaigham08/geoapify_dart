/// Request and response models for the Geoapify Isoline API.
library;

import '../../../core/exceptions/geoapify_exception.dart';
import '../../../core/http/request_builder.dart';
import '../../../core/serialization/json_utils.dart';
import '../../../shared/enums/distance_units.dart';
import '../../../shared/enums/route_type.dart';
import '../../../shared/enums/traffic_model.dart';
import '../../../shared/enums/travel_mode.dart';
import '../../../shared/models/avoid_rule.dart';
import '../../../shared/models/geo_bounding_box.dart';
import '../../../shared/models/geo_json_geometry.dart';
import '../../../shared/models/geo_point.dart';

/// Isoline reachability metric.
enum IsolineType {
  /// Travel-time isochrone (ranges in seconds).
  time('time'),

  /// Travel-distance isodistance (ranges in meters or miles depending on units).
  distance('distance');

  const IsolineType(this.value);

  /// Wire value expected by the Isoline API.
  final String value;

  /// Parses an [IsolineType] from its wire string.
  static IsolineType? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final item in values) {
      if (item.value == value) {
        return item;
      }
    }
    return null;
  }
}

/// Request model for `GET /v1/isoline`.
///
/// Use [IsolineRequest.calculate] to compute new isochrones/isodistances, or
/// [IsolineRequest.byId] to retrieve a previously generated isoline by its
/// 32-character hexadecimal ID.
final class IsolineRequest {
  /// Creates a calculation request for `GET /v1/isoline`.
  IsolineRequest.calculate({
    required GeoPoint this.location,
    required IsolineType this.type,
    required TravelMode this.mode,
    required List<num> ranges,
    this.units,
    List<AvoidRule>? avoid,
    this.routeType,
    this.traffic,
    this.maxSpeed,
    List<String>? details,
  }) : ranges = List.unmodifiable(ranges),
       avoid = avoid != null ? List.unmodifiable(avoid) : null,
       details = details != null ? List.unmodifiable(details) : null,
       id = null;

  /// Creates a retrieval request for a previously generated isoline by [id].
  IsolineRequest.byId({required String this.id})
    : location = null,
      type = null,
      mode = null,
      ranges = null,
      units = null,
      avoid = null,
      routeType = null,
      traffic = null,
      maxSpeed = null,
      details = null;

  /// Origin coordinate (required when calculating).
  final GeoPoint? location;

  /// Reachability type (`time` or `distance`, required when calculating).
  final IsolineType? type;

  /// Travel mode (required when calculating).
  final TravelMode? mode;

  /// 1 to 10 reachability limits (seconds for time, meters/miles for distance).
  final List<num>? ranges;

  /// Distance/speed unit system.
  final DistanceUnits? units;

  /// Features, locations, polygons, or countries to avoid.
  final List<AvoidRule>? avoid;

  /// Route optimization objective (`balanced`, `short`, `less_maneuvers`).
  final RouteType? routeType;

  /// Traffic model (`free_flow`, `approximated`).
  final TrafficModel? traffic;

  /// Maximum speed (`10-252` km/h metric or `6.5-155` mph imperial).
  final double? maxSpeed;

  /// Optional extra datasets (for example `['population']`).
  final List<String>? details;

  /// ID of a previously calculated isoline (32-char lowercase hex).
  final String? id;

  /// Validates parameters against the Isoline OpenAPI specification.
  void validate() {
    if (id != null) {
      if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id!.trim())) {
        throw const GeoapifyValidationException(
          'Isoline id must be a 32-character lowercase hexadecimal string.',
        );
      }
      return;
    }

    if (location == null || type == null || mode == null || ranges == null) {
      throw const GeoapifyValidationException(
        'Isoline calculation requires location, type, mode, and ranges.',
      );
    }
    if (ranges!.isEmpty || ranges!.length > 10) {
      throw GeoapifyValidationException(
        'Isoline requires between 1 and 10 range values, got ${ranges!.length}.',
      );
    }
    for (final range in ranges!) {
      if (!range.isFinite || range < 1) {
        throw GeoapifyValidationException(
          'Each isoline range must be >= 1, got $range.',
        );
      }
    }
    if (type == IsolineType.distance && mode!.isTransit) {
      throw GeoapifyValidationException(
        'IsolineType.distance is not supported for TravelMode.${mode!.name}.',
      );
    }
    if (maxSpeed != null &&
        (!maxSpeed!.isFinite || maxSpeed! < 6.5 || maxSpeed! > 252.0)) {
      throw GeoapifyValidationException(
        'maxSpeed must be between 6.5 and 252, got $maxSpeed.',
      );
    }
    if (details != null) {
      for (final detail in details!) {
        final len = detail.trim().length;
        if (len < 5 || len > 100) {
          throw GeoapifyValidationException(
            'Isoline detail "$detail" must be between 5 and 100 characters.',
          );
        }
      }
    }
  }

  /// Builds query parameters for `GET /v1/isoline`.
  Map<String, List<String>> toQueryParameters() {
    validate();
    final builder = QueryParametersBuilder()..add('format', 'geojson');
    if (id != null) {
      builder.add('id', id!.trim());
      return builder.build();
    }

    final avoidValues = avoid
        ?.expand((rule) => rule.toQueryValues())
        .toList(growable: false);

    builder
      ..addNum('lat', location!.latitude)
      ..addNum('lon', location!.longitude)
      ..addJoined('range', ranges!.map((r) => r.toString()))
      ..add('type', type!.value)
      ..add('mode', mode!.value)
      ..add('units', units?.value)
      // Isolines OpenAPI specifies `style: form, explode: true` for `avoid`.
      ..addRepeated('avoid', avoidValues)
      ..add('route_type', routeType?.value)
      ..add('traffic', traffic?.value)
      ..addNum('max_speed', maxSpeed)
      ..addJoined('details', details?.map((d) => d.trim()));

    return builder.build();
  }
}

/// Response returned by `GET /v1/isoline`.
final class IsolineResponse {
  /// Creates an [IsolineResponse].
  const IsolineResponse({this.id, this.features = const [], this.bbox});

  /// Parses an `IsolineFeatureCollection` GeoJSON response.
  factory IsolineResponse.fromJson(Map<String, Object?> json) {
    final collectionProps = readMap(json, 'properties');
    final rawFeatures = readList(json, 'features') ?? const [];
    final features = <IsolineFeature>[];
    for (final item in rawFeatures) {
      if (item is Map) {
        features.add(IsolineFeature.fromJson(asJsonMap(item)));
      }
    }
    final rawBbox = readList(json, 'bbox');
    return IsolineResponse(
      id: collectionProps != null ? readString(collectionProps, 'id') : null,
      features: List.unmodifiable(features),
      bbox: rawBbox != null ? GeoBoundingBox.fromGeoJsonBbox(rawBbox) : null,
    );
  }

  /// Geometry ID that can be passed to [IsolineService.getById] or
  /// [GeometryFilter] in the Places API.
  final String? id;

  /// One isoline polygon/multipolygon feature per requested range value.
  final List<IsolineFeature> features;

  /// Bounding box covering all features, if provided.
  final GeoBoundingBox? bbox;
}

/// A single isoline GeoJSON feature corresponding to one requested range.
final class IsolineFeature {
  /// Creates an [IsolineFeature].
  const IsolineFeature({
    required this.geometry,
    required this.properties,
    this.featureId,
    this.bbox,
  });

  /// Parses an [IsolineFeature] from JSON.
  factory IsolineFeature.fromJson(Map<String, Object?> json) {
    final geomMap = readMap(json, 'geometry');
    if (geomMap == null) {
      throw const FormatException('Isoline feature is missing "geometry".');
    }
    final propsMap = readMap(json, 'properties') ?? const {};
    final rawBbox = readList(json, 'bbox');
    final rawId = json['id'];

    return IsolineFeature(
      geometry: GeoJsonGeometry.fromJson(geomMap),
      properties: IsolineProperties.fromJson(propsMap),
      featureId: rawId?.toString(),
      bbox: rawBbox != null ? GeoBoundingBox.fromGeoJsonBbox(rawBbox) : null,
    );
  }

  /// Reachable area geometry (`GeoPolygonGeometry` or
  /// `GeoMultiPolygonGeometry`).
  final GeoJsonGeometry geometry;

  /// Properties describing the origin, mode, range, and optional details.
  final IsolineProperties properties;

  /// Optional GeoJSON feature ID.
  final String? featureId;

  /// Optional feature bounding box.
  final GeoBoundingBox? bbox;
}

/// Metadata properties for an [IsolineFeature].
final class IsolineProperties {
  /// Creates an [IsolineProperties].
  const IsolineProperties({
    this.id,
    this.origin,
    this.mode,
    this.type,
    this.range,
    this.routeType,
    this.maxSpeed,
    this.units,
    this.traffic,
    this.avoid = const [],
    this.population,
    this.details = const {},
  });

  /// Parses [IsolineProperties] from JSON.
  factory IsolineProperties.fromJson(Map<String, Object?> json) {
    final lat = readDouble(json, 'lat');
    final lon = readDouble(json, 'lon');
    final detailsMap = readMap(json, 'details');
    final popMap = detailsMap != null
        ? readMap(detailsMap, 'population')
        : null;

    final avoidRules = <AvoidRule>[];
    final rawAvoid = readList(json, 'avoid');
    if (rawAvoid != null) {
      for (final item in rawAvoid) {
        if (item is Map) {
          avoidRules.add(AvoidRule.fromJson(asJsonMap(item)));
        }
      }
    }

    return IsolineProperties(
      id: readString(json, 'id'),
      origin: lat != null && lon != null
          ? GeoPoint(latitude: lat, longitude: lon)
          : null,
      mode: TravelMode.tryParse(readString(json, 'mode')),
      type: IsolineType.tryParse(readString(json, 'type')),
      range: readDouble(json, 'range'),
      routeType: RouteType.tryParse(readString(json, 'route_type')),
      maxSpeed: readDouble(json, 'max_speed'),
      units: DistanceUnits.tryParse(readString(json, 'units')),
      traffic: TrafficModel.tryParse(readString(json, 'traffic')),
      avoid: List.unmodifiable(avoidRules),
      population: popMap != null
          ? IsolinePopulationDetail.fromJson(popMap)
          : null,
      details: detailsMap != null ? Map.unmodifiable(detailsMap) : const {},
    );
  }

  /// Geometry ID for this isoline.
  final String? id;

  /// Origin coordinate (`lat`, `lon`).
  final GeoPoint? origin;

  /// Travel mode used.
  final TravelMode? mode;

  /// Isoline type (`time` or `distance`).
  final IsolineType? type;

  /// Range value represented by this feature.
  final double? range;

  /// Route optimization objective used.
  final RouteType? routeType;

  /// Maximum speed constraint applied.
  final double? maxSpeed;

  /// Unit system used.
  final DistanceUnits? units;

  /// Traffic model applied.
  final TrafficModel? traffic;

  /// Avoidance rules applied.
  final List<AvoidRule> avoid;

  /// Estimated population inside the isoline when `details=population` is
  /// requested.
  final IsolinePopulationDetail? population;

  /// Raw `details` map from the response.
  final Map<String, Object?> details;
}

/// Population estimate returned when `details: ['population']` is requested on
/// an isoline.
final class IsolinePopulationDetail {
  /// Creates an [IsolinePopulationDetail].
  const IsolinePopulationDetail({this.value, this.attribution});

  /// Parses an [IsolinePopulationDetail] from JSON.
  factory IsolinePopulationDetail.fromJson(Map<String, Object?> json) {
    return IsolinePopulationDetail(
      value: readDouble(json, 'value'),
      attribution: readString(json, 'attribution'),
    );
  }

  /// Estimated population count.
  final double? value;

  /// Required data attribution string for the population dataset.
  final String? attribution;
}
