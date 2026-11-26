/// Typed response models for the Geoapify Routing API.
library;

import '../../../core/serialization/json_utils.dart';
import '../../../shared/enums/distance_units.dart';
import '../../../shared/enums/traffic_model.dart';
import '../../../shared/enums/travel_mode.dart';
import '../../../shared/models/avoid_rule.dart';
import '../../../shared/models/geo_bounding_box.dart';
import '../../../shared/models/geo_json_geometry.dart';
import '../../../shared/models/geo_point.dart';
import '../models/routing_enums.dart';

/// Response returned by `GET /v1/routing`.
///
/// Supports both `format=geojson` and `format=json` responses.
final class RoutingResponse {
  /// Creates a [RoutingResponse].
  const RoutingResponse({this.routes = const [], this.options, this.bbox});

  /// Parses a [RoutingResponse] from either GeoJSON or plain JSON format.
  factory RoutingResponse.fromJson(Map<String, Object?> json) {
    final routes = <RouteResult>[];

    final rawFeatures = readList(json, 'features');
    if (rawFeatures != null) {
      for (final item in rawFeatures) {
        if (item is Map) {
          routes.add(RouteResult.fromGeoJsonFeature(asJsonMap(item)));
        }
      }
    } else {
      final rawResults = readList(json, 'results');
      if (rawResults != null) {
        for (final item in rawResults) {
          if (item is Map) {
            routes.add(RouteResult.fromPlainJson(asJsonMap(item)));
          }
        }
      }
    }

    final optionsMap = readMap(json, 'properties');
    final rawBbox = readList(json, 'bbox');

    return RoutingResponse(
      routes: List.unmodifiable(routes),
      options: optionsMap != null
          ? RoutingResponseOptions.fromJson(optionsMap)
          : null,
      bbox: rawBbox != null ? GeoBoundingBox.fromGeoJsonBbox(rawBbox) : null,
    );
  }

  /// Calculated route(s). Usually contains one primary route.
  final List<RouteResult> routes;

  /// Echoed routing options from the response `properties` object.
  final RoutingResponseOptions? options;

  /// Bounding box covering the returned routes, if present.
  final GeoBoundingBox? bbox;

  /// Returns the first route, or `null` if [routes] is empty.
  RouteResult? get primaryRoute => routes.isNotEmpty ? routes.first : null;
}

/// Echoed request options returned on the top-level routing response.
final class RoutingResponseOptions {
  /// Creates a [RoutingResponseOptions].
  const RoutingResponseOptions({
    this.mode,
    this.units,
    this.waypoints = const [],
    this.avoid = const [],
    this.details = const [],
    this.traffic,
    this.intermediateWaypointMode,
  });

  /// Parses a [RoutingResponseOptions] from JSON.
  factory RoutingResponseOptions.fromJson(Map<String, Object?> json) {
    return RoutingResponseOptions(
      mode: TravelMode.tryParse(readString(json, 'mode')),
      units: DistanceUnits.tryParse(readString(json, 'units')),
      waypoints: _parseWaypoints(readList(json, 'waypoints')),
      avoid: _parseAvoidList(readList(json, 'avoid')),
      details: readStringList(json, 'details')
          .map(RouteDetail.tryParse)
          .whereType<RouteDetail>()
          .toList(growable: false),
      traffic: TrafficModel.tryParse(readString(json, 'traffic')),
      intermediateWaypointMode: IntermediateWaypointMode.tryParse(
        readString(json, 'intermediate_waypoint_mode'),
      ),
    );
  }

  /// Travel mode used.
  final TravelMode? mode;

  /// Distance units used.
  final DistanceUnits? units;

  /// Waypoints used for the route.
  final List<RouteWaypoint> waypoints;

  /// Avoidance rules applied.
  final List<AvoidRule> avoid;

  /// Detail datasets included.
  final List<RouteDetail> details;

  /// Traffic model applied.
  final TrafficModel? traffic;

  /// Intermediate waypoint mode applied.
  final IntermediateWaypointMode? intermediateWaypointMode;
}

/// A calculated route with legs, steps, geometry, and summary metrics.
final class RouteResult {
  /// Creates a [RouteResult].
  const RouteResult({
    this.mode,
    this.units,
    this.distanceUnits,
    this.distance,
    this.time,
    this.maxSpeed,
    this.waypoints = const [],
    this.legs = const [],
    this.geometry = const [],
    this.rawGeometry,
    this.polyline5,
    this.polyline6,
    this.countryCodes = const [],
    this.adminAreas = const [],
    this.adminAreaCrossings = const [],
    this.toll,
    this.ferry,
    this.traffic,
    this.intermediateWaypointMode,
    this.avoid = const [],
    this.details = const [],
    this.bbox,
  });

  /// Parses a GeoJSON `RoutingFeature` into a [RouteResult].
  factory RouteResult.fromGeoJsonFeature(Map<String, Object?> feature) {
    final props = readMap(feature, 'properties') ?? const {};
    final geomMap = readMap(feature, 'geometry');
    final parsedGeometry = geomMap != null
        ? GeoJsonGeometry.fromJson(geomMap)
        : null;

    final lines = switch (parsedGeometry) {
      GeoMultiLineStringGeometry(:final coordinates) => coordinates,
      GeoLineStringGeometry(:final coordinates) => [coordinates],
      _ => const <List<GeoPoint>>[],
    };

    final rawBbox = readList(feature, 'bbox');
    return _fromProperties(
      props,
      geometryLines: lines,
      rawGeometry: parsedGeometry,
      bbox: rawBbox != null ? GeoBoundingBox.fromGeoJsonBbox(rawBbox) : null,
    );
  }

  /// Parses a `RoutingJsonResult` (`format=json`) into a [RouteResult].
  factory RouteResult.fromPlainJson(Map<String, Object?> json) {
    final rawGeometry = readList(json, 'geometry');
    final lines = <List<GeoPoint>>[];
    if (rawGeometry != null) {
      for (final rawLeg in rawGeometry) {
        if (rawLeg is List) {
          final legPoints = <GeoPoint>[];
          for (final point in rawLeg) {
            if (point is Map) {
              legPoints.add(GeoPoint.fromLatLonJson(asJsonMap(point)));
            }
          }
          lines.add(List.unmodifiable(legPoints));
        }
      }
    }
    return _fromProperties(
      json,
      geometryLines: List.unmodifiable(lines),
      rawGeometry: GeoMultiLineStringGeometry(coordinates: lines),
    );
  }

  static RouteResult _fromProperties(
    Map<String, Object?> props, {
    required List<List<GeoPoint>> geometryLines,
    GeoJsonGeometry? rawGeometry,
    GeoBoundingBox? bbox,
  }) {
    final legs = <RouteLeg>[];
    final rawLegs = readList(props, 'legs');
    if (rawLegs != null) {
      for (final item in rawLegs) {
        if (item is Map) {
          legs.add(RouteLeg.fromJson(asJsonMap(item)));
        }
      }
    }

    final adminAreas = <RouteAdminArea>[];
    final rawAdminAreas = readList(props, 'admin_areas');
    if (rawAdminAreas != null) {
      for (final item in rawAdminAreas) {
        if (item is Map) {
          adminAreas.add(RouteAdminArea.fromJson(asJsonMap(item)));
        }
      }
    }

    final crossings = <RouteAdminAreaCrossing>[];
    final rawCrossings = readList(props, 'admin_area_crossings');
    if (rawCrossings != null) {
      for (final item in rawCrossings) {
        if (item is Map) {
          crossings.add(RouteAdminAreaCrossing.fromJson(asJsonMap(item)));
        }
      }
    }

    return RouteResult(
      mode: TravelMode.tryParse(readString(props, 'mode')),
      units: DistanceUnits.tryParse(readString(props, 'units')),
      distanceUnits: readString(props, 'distance_units'),
      distance: readDouble(props, 'distance'),
      time: readDouble(props, 'time'),
      maxSpeed: readDouble(props, 'max_speed'),
      waypoints: _parseWaypoints(readList(props, 'waypoints')),
      legs: List.unmodifiable(legs),
      geometry: geometryLines,
      rawGeometry: rawGeometry,
      polyline5: readString(props, 'polyline5'),
      polyline6: readString(props, 'polyline6'),
      countryCodes: readStringList(props, 'country_code'),
      adminAreas: List.unmodifiable(adminAreas),
      adminAreaCrossings: List.unmodifiable(crossings),
      toll: readBool(props, 'toll'),
      ferry: readBool(props, 'ferry'),
      traffic: TrafficModel.tryParse(readString(props, 'traffic')),
      intermediateWaypointMode: IntermediateWaypointMode.tryParse(
        readString(props, 'intermediate_waypoint_mode'),
      ),
      avoid: _parseAvoidList(readList(props, 'avoid')),
      details: readStringList(props, 'details')
          .map(RouteDetail.tryParse)
          .whereType<RouteDetail>()
          .toList(growable: false),
      bbox: bbox,
    );
  }

  /// Travel mode used to calculate this route.
  final TravelMode? mode;

  /// Unit system for distance values.
  final DistanceUnits? units;

  /// Explicit unit string (for example `meters` or `miles`).
  final String? distanceUnits;

  /// Total route distance in [distanceUnits].
  final double? distance;

  /// Total estimated travel time in seconds.
  final double? time;

  /// Maximum speed constraint applied, if any.
  final double? maxSpeed;

  /// Snapped or input waypoints for this route.
  final List<RouteWaypoint> waypoints;

  /// Route legs between stopover waypoints.
  final List<RouteLeg> legs;

  /// Route geometry coordinates organized by line segment (typically one list
  /// of points per leg).
  final List<List<GeoPoint>> geometry;

  /// Underlying GeoJSON geometry model.
  final GeoJsonGeometry? rawGeometry;

  /// Precision-5 encoded route polyline when `RouteDetail.polyline5` is
  /// requested.
  final String? polyline5;

  /// Precision-6 encoded route polyline when `RouteDetail.polyline6` is
  /// requested.
  final String? polyline6;

  /// Countries crossed along the route.
  final List<String> countryCodes;

  /// Administrative areas crossed when `RouteDetail.adminAreas` is requested.
  final List<RouteAdminArea> adminAreas;

  /// Crossings between administrative areas.
  final List<RouteAdminAreaCrossing> adminAreaCrossings;

  /// Whether the route uses toll roads.
  final bool? toll;

  /// Whether the route uses ferries.
  final bool? ferry;

  /// Traffic model applied.
  final TrafficModel? traffic;

  /// Intermediate waypoint mode applied.
  final IntermediateWaypointMode? intermediateWaypointMode;

  /// Avoidance rules applied.
  final List<AvoidRule> avoid;

  /// Detail datasets included.
  final List<RouteDetail> details;

  /// Route bounding box, if provided.
  final GeoBoundingBox? bbox;
}

/// Snapped or input waypoint on a calculated route.
final class RouteWaypoint {
  /// Creates a [RouteWaypoint].
  const RouteWaypoint({
    required this.location,
    this.originalIndex,
    this.address,
  });

  /// Parses either a `SnappedRouteWaypoint` (`{location: [lon, lat]}`) or an
  /// `InputRouteWaypoint` (`{lat, lon}`).
  factory RouteWaypoint.fromJson(Map<String, Object?> json) {
    final locationList = readList(json, 'location');
    if (locationList != null) {
      return RouteWaypoint(
        location: GeoPoint.fromGeoJsonPosition(locationList),
        originalIndex: readInt(json, 'original_index'),
        address: readString(json, 'address'),
      );
    }
    return RouteWaypoint(
      location: GeoPoint.fromLatLonJson(json),
      originalIndex: readInt(json, 'original_index'),
      address: readString(json, 'address'),
    );
  }

  /// Waypoint coordinate.
  final GeoPoint location;

  /// Original 0-based index in the input waypoints list, if provided.
  final int? originalIndex;

  /// Optional address string.
  final String? address;
}

/// A leg of a route between two stopover waypoints.
final class RouteLeg {
  /// Creates a [RouteLeg].
  const RouteLeg({
    this.time,
    this.distance,
    this.steps = const [],
    this.polyline5,
    this.polyline6,
    this.countryCodes = const [],
    this.elevation = const [],
    this.elevationRange = const [],
    this.agencyName,
    this.agencyId,
    this.agencyUrl,
    this.routeId,
    this.routeShortName,
    this.routeLongName,
    this.tripId,
  });

  /// Parses a [RouteLeg] from JSON.
  factory RouteLeg.fromJson(Map<String, Object?> json) {
    final steps = <RouteStep>[];
    final rawSteps = readList(json, 'steps');
    if (rawSteps != null) {
      for (final item in rawSteps) {
        if (item is Map) {
          steps.add(RouteStep.fromJson(asJsonMap(item)));
        }
      }
    }

    final elevation = <double>[];
    final rawElevation = readList(json, 'elevation');
    if (rawElevation != null) {
      for (final value in rawElevation) {
        if (value is num && value.isFinite) {
          elevation.add(value.toDouble());
        }
      }
    }

    final elevationRange = <List<double>>[];
    final rawRanges = readList(json, 'elevation_range');
    if (rawRanges != null) {
      for (final pair in rawRanges) {
        if (pair is List && pair.length >= 2) {
          final a = pair[0];
          final b = pair[1];
          if (a is num && b is num) {
            elevationRange.add(List.unmodifiable([a.toDouble(), b.toDouble()]));
          }
        }
      }
    }

    return RouteLeg(
      time: readDouble(json, 'time'),
      distance: readDouble(json, 'distance'),
      steps: List.unmodifiable(steps),
      polyline5: readString(json, 'polyline5'),
      polyline6: readString(json, 'polyline6'),
      countryCodes: readStringList(json, 'country_code'),
      elevation: List.unmodifiable(elevation),
      elevationRange: List.unmodifiable(elevationRange),
      agencyName: readString(json, 'agency_name'),
      agencyId: readString(json, 'agency_id'),
      agencyUrl: readString(json, 'agency_url'),
      routeId: readString(json, 'route_id'),
      routeShortName: readString(json, 'route_short_name'),
      routeLongName: readString(json, 'route_long_name'),
      tripId: readString(json, 'trip_id'),
    );
  }

  /// Estimated travel time for this leg in seconds.
  final double? time;

  /// Distance of this leg in the response unit system.
  final double? distance;

  /// Navigation steps within this leg.
  final List<RouteStep> steps;

  /// Precision-5 encoded geometry for this leg.
  final String? polyline5;

  /// Precision-6 encoded geometry for this leg.
  final String? polyline6;

  /// Country codes traversed in this leg.
  final List<String> countryCodes;

  /// Elevation profile values along this leg.
  final List<double> elevation;

  /// `[distance, elevation]` pairs when `RouteDetail.elevation` is requested.
  final List<List<double>> elevationRange;

  /// Public transit agency name (transit modes only).
  final String? agencyName;

  /// Public transit agency ID (transit modes only).
  final String? agencyId;

  /// Public transit agency URL (transit modes only).
  final String? agencyUrl;

  /// Public transit route ID (transit modes only).
  final String? routeId;

  /// Public transit short route name (transit modes only).
  final String? routeShortName;

  /// Public transit long route name (transit modes only).
  final String? routeLongName;

  /// Public transit trip ID (transit modes only).
  final String? tripId;
}

/// A single navigation step within a [RouteLeg].
final class RouteStep {
  /// Creates a [RouteStep].
  const RouteStep({
    this.fromIndex,
    this.toIndex,
    this.time,
    this.distance,
    this.instruction,
    this.toll,
    this.ferry,
    this.bridge,
    this.tunnel,
    this.elevation,
    this.elevationGain,
    this.maxElevation,
    this.minElevation,
    this.adminAreaIndices = const [],
    this.speed,
    this.speedLimit,
    this.truckLimit,
    this.surface,
    this.laneCount,
    this.roadClass,
    this.name,
    this.roundabout,
    this.rightside,
    this.traversability,
    this.fromStopId,
    this.fromStopName,
    this.toStopId,
    this.toStopName,
  });

  /// Parses a [RouteStep] from JSON.
  factory RouteStep.fromJson(Map<String, Object?> json) {
    final instructionMap = readMap(json, 'instruction');
    final adminAreaRaw = readList(json, 'admin_area');
    final adminAreaIndices = <int>[];
    if (adminAreaRaw != null) {
      for (final item in adminAreaRaw) {
        if (item is int) {
          adminAreaIndices.add(item);
        }
      }
    }

    return RouteStep(
      fromIndex: readInt(json, 'from_index'),
      toIndex: readInt(json, 'to_index'),
      time: readDouble(json, 'time'),
      distance: readDouble(json, 'distance'),
      instruction: instructionMap != null
          ? RouteInstruction.fromJson(instructionMap)
          : null,
      toll: readBool(json, 'toll'),
      ferry: readBool(json, 'ferry'),
      bridge: readBool(json, 'bridge'),
      tunnel: readBool(json, 'tunnel'),
      elevation: readDouble(json, 'elevation'),
      elevationGain: readDouble(json, 'elevation_gain'),
      maxElevation: readDouble(json, 'max_elevation'),
      minElevation: readDouble(json, 'min_elevation'),
      adminAreaIndices: List.unmodifiable(adminAreaIndices),
      speed: readDouble(json, 'speed'),
      speedLimit: readDouble(json, 'speed_limit'),
      truckLimit: readDouble(json, 'truck_limit'),
      surface: readString(json, 'surface'),
      laneCount: readDouble(json, 'lane_count'),
      roadClass: readString(json, 'road_class'),
      name: readString(json, 'name'),
      roundabout: readBool(json, 'roundabout'),
      rightside: readBool(json, 'rightside'),
      traversability: readString(json, 'traversability'),
      fromStopId: readString(json, 'from_stop_id'),
      fromStopName: readString(json, 'from_stop_name'),
      toStopId: readString(json, 'to_stop_id'),
      toStopName: readString(json, 'to_stop_name'),
    );
  }

  /// Start vertex index in the leg geometry.
  final int? fromIndex;

  /// End vertex index in the leg geometry.
  final int? toIndex;

  /// Step duration in seconds.
  final double? time;

  /// Step distance in response units.
  final double? distance;

  /// Turn-by-turn instruction for this step, if present.
  final RouteInstruction? instruction;

  /// Whether this step is on a toll road.
  final bool? toll;

  /// Whether this step is a ferry crossing.
  final bool? ferry;

  /// Whether this step crosses a bridge.
  final bool? bridge;

  /// Whether this step passes through a tunnel.
  final bool? tunnel;

  /// Step elevation value.
  final double? elevation;

  /// Elevation gain across this step.
  final double? elevationGain;

  /// Maximum elevation in this step.
  final double? maxElevation;

  /// Minimum elevation in this step.
  final double? minElevation;

  /// Indices into [RouteResult.adminAreas].
  final List<int> adminAreaIndices;

  /// Estimated speed on this step.
  final double? speed;

  /// Posted speed limit on this step.
  final double? speedLimit;

  /// Truck speed limit on this step.
  final double? truckLimit;

  /// Road surface type.
  final String? surface;

  /// Number of lanes.
  final double? laneCount;

  /// Road classification.
  final String? roadClass;

  /// Road or path name.
  final String? name;

  /// Whether the step traverses a roundabout.
  final bool? roundabout;

  /// Whether traffic keeps to the right.
  final bool? rightside;

  /// Traversability classification.
  final String? traversability;

  /// Departure transit stop ID.
  final String? fromStopId;

  /// Departure transit stop name.
  final String? fromStopName;

  /// Arrival transit stop ID.
  final String? toStopId;

  /// Arrival transit stop name.
  final String? toStopName;
}

/// Turn-by-turn instruction attached to a [RouteStep].
final class RouteInstruction {
  /// Creates a [RouteInstruction].
  const RouteInstruction({
    this.text,
    this.type,
    this.transitionInstruction,
    this.preTransitionInstruction,
    this.postTransitionInstruction,
    this.containsNextInstruction,
    this.streets = const [],
    this.exitNumber = const [],
    this.exitRoadName = const [],
    this.exitTowards = const [],
    this.roundaboutExit,
  });

  /// Parses a [RouteInstruction] from JSON.
  factory RouteInstruction.fromJson(Map<String, Object?> json) {
    return RouteInstruction(
      text: readString(json, 'text'),
      type: readString(json, 'type'),
      transitionInstruction: readString(json, 'transition_instruction'),
      preTransitionInstruction: readString(json, 'pre_transition_instruction'),
      postTransitionInstruction: readString(
        json,
        'post_transition_instruction',
      ),
      containsNextInstruction: readBool(json, 'contains_next_instruction'),
      streets: readStringList(json, 'streets'),
      exitNumber: readStringList(json, 'exit_number'),
      exitRoadName: readStringList(json, 'exit_road_name'),
      exitTowards: readStringList(json, 'exit_towards'),
      roundaboutExit: readDouble(json, 'roundabout_exit'),
    );
  }

  /// Human-readable navigation instruction.
  final String? text;

  /// Maneuver type identifier (present with `RouteDetail.instructionDetails`).
  final String? type;

  /// Verbal transition instruction.
  final String? transitionInstruction;

  /// Verbal pre-transition instruction.
  final String? preTransitionInstruction;

  /// Verbal post-transition instruction.
  final String? postTransitionInstruction;

  /// Whether this instruction previews the subsequent maneuver.
  final bool? containsNextInstruction;

  /// Street names referenced by the maneuver.
  final List<String> streets;

  /// Highway exit numbers.
  final List<String> exitNumber;

  /// Highway exit road names.
  final List<String> exitRoadName;

  /// Highway exit destination signs.
  final List<String> exitTowards;

  /// Roundabout exit ordinal, if applicable.
  final double? roundaboutExit;
}

/// Administrative area metadata along a route.
final class RouteAdminArea {
  /// Creates a [RouteAdminArea].
  const RouteAdminArea({
    this.countryCode,
    this.countryText,
    this.stateCode,
    this.stateText,
  });

  /// Parses a [RouteAdminArea] from JSON.
  factory RouteAdminArea.fromJson(Map<String, Object?> json) {
    return RouteAdminArea(
      countryCode: readString(json, 'country_code'),
      countryText: readString(json, 'country_text'),
      stateCode: readString(json, 'state_code'),
      stateText: readString(json, 'state_text'),
    );
  }

  /// ISO country code.
  final String? countryCode;

  /// Country name.
  final String? countryText;

  /// State or province code.
  final String? stateCode;

  /// State or province name.
  final String? stateText;
}

/// Border crossing between two administrative areas along a route.
final class RouteAdminAreaCrossing {
  /// Creates a [RouteAdminAreaCrossing].
  const RouteAdminAreaCrossing({
    this.fromAdminIndex,
    this.toAdminIndex,
    this.beginShapeIndex,
    this.endShapeIndex,
  });

  /// Parses a [RouteAdminAreaCrossing] from JSON.
  factory RouteAdminAreaCrossing.fromJson(Map<String, Object?> json) {
    return RouteAdminAreaCrossing(
      fromAdminIndex: readInt(json, 'from_admin_index'),
      toAdminIndex: readInt(json, 'to_admin_index'),
      beginShapeIndex: readInt(json, 'begin_shape_index'),
      endShapeIndex: readInt(json, 'end_shape_index'),
    );
  }

  /// Index of the exited area in [RouteResult.adminAreas].
  final int? fromAdminIndex;

  /// Index of the entered area in [RouteResult.adminAreas].
  final int? toAdminIndex;

  /// Start shape index of the crossing.
  final int? beginShapeIndex;

  /// End shape index of the crossing.
  final int? endShapeIndex;
}

List<RouteWaypoint> _parseWaypoints(List<Object?>? rawList) {
  if (rawList == null) {
    return const [];
  }
  final waypoints = <RouteWaypoint>[];
  for (final item in rawList) {
    if (item is Map) {
      waypoints.add(RouteWaypoint.fromJson(asJsonMap(item)));
    }
  }
  return List.unmodifiable(waypoints);
}

List<AvoidRule> _parseAvoidList(List<Object?>? rawList) {
  if (rawList == null) {
    return const [];
  }
  final rules = <AvoidRule>[];
  for (final item in rawList) {
    if (item is Map) {
      rules.add(AvoidRule.fromJson(asJsonMap(item)));
    }
  }
  return List.unmodifiable(rules);
}
