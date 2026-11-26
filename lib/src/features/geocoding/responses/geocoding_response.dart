/// Typed response models for Geoapify Geocoding APIs.
library;

import '../../../core/serialization/json_utils.dart';
import '../../../shared/models/datasource_info.dart';
import '../../../shared/models/geo_bounding_box.dart';
import '../../../shared/models/geo_json_geometry.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/models/timezone_info.dart';
import '../models/geocoding_enums.dart';

/// Response returned by Forward Geocoding, Reverse Geocoding, and Address
/// Autocomplete APIs.
///
/// Supports both `format=geojson` (`features` array) and `format=json`
/// (`results` array).
final class GeocodingResponse {
  /// Creates a [GeocodingResponse].
  const GeocodingResponse({this.results = const [], this.query});

  /// Parses a [GeocodingResponse] from either GeoJSON or JSON response format.
  factory GeocodingResponse.fromJson(Map<String, Object?> json) {
    final results = <GeocodingResult>[];

    final rawFeatures = readList(json, 'features');
    if (rawFeatures != null) {
      for (final item in rawFeatures) {
        if (item is Map) {
          results.add(GeocodingResult.fromGeoJsonFeature(asJsonMap(item)));
        }
      }
    } else {
      final rawResults = readList(json, 'results');
      if (rawResults != null) {
        for (final item in rawResults) {
          if (item is Map) {
            results.add(GeocodingResult.fromPropertiesJson(asJsonMap(item)));
          }
        }
      }
    }

    final queryMap = readMap(json, 'query');
    return GeocodingResponse(
      results: List.unmodifiable(results),
      query: queryMap != null ? GeocodingQueryInfo.fromJson(queryMap) : null,
    );
  }

  /// Ordered list of matching geocoding results.
  final List<GeocodingResult> results;

  /// Echoed/parsed query metadata returned by Geoapify, if present.
  final GeocodingQueryInfo? query;

  /// Returns the top result, or `null` if [results] is empty.
  GeocodingResult? get firstOrNull => results.isNotEmpty ? results.first : null;

  /// Whether [results] contains no entries.
  bool get isEmpty => results.isEmpty;

  /// Whether [results] contains at least one entry.
  bool get isNotEmpty => results.isNotEmpty;
}

/// A single geocoded location or address candidate.
final class GeocodingResult {
  /// Creates a [GeocodingResult].
  const GeocodingResult({
    this.location,
    this.geometry,
    this.bbox,
    this.name,
    this.formatted,
    this.addressLine1,
    this.addressLine2,
    this.continent,
    this.country,
    this.countryCode,
    this.region,
    this.state,
    this.stateCode,
    this.county,
    this.city,
    this.postcode,
    this.district,
    this.suburb,
    this.neighbourhood,
    this.town,
    this.village,
    this.municipality,
    this.street,
    this.housenumber,
    this.plusCode,
    this.plusCodeShort,
    this.resultType,
    this.category,
    this.categories = const [],
    this.placeId,
    this.distance,
    this.population,
    this.timezone,
    this.datasource,
    this.rank,
    this.postcodes = const [],
    this.otherNames = const {},
    this.additionalProperties = const {},
  });

  /// Parses a GeoJSON `Feature` item into a [GeocodingResult].
  factory GeocodingResult.fromGeoJsonFeature(Map<String, Object?> feature) {
    final properties = readMap(feature, 'properties') ?? const {};
    final geometryMap = readMap(feature, 'geometry');
    final geometry = geometryMap != null
        ? GeoJsonGeometry.fromJson(geometryMap)
        : null;
    final featureBbox = readList(feature, 'bbox');
    final bbox = featureBbox != null
        ? GeoBoundingBox.fromGeoJsonBbox(featureBbox)
        : null;

    return GeocodingResult.fromPropertiesJson(
      properties,
      geometry: geometry,
      fallbackBbox: bbox,
    );
  }

  /// Parses `GeocodingProperties` JSON (from `format=json` or a GeoJSON
  /// feature's `properties`).
  factory GeocodingResult.fromPropertiesJson(
    Map<String, Object?> props, {
    GeoJsonGeometry? geometry,
    GeoBoundingBox? fallbackBbox,
  }) {
    final lat = readDouble(props, 'lat');
    final lon = readDouble(props, 'lon');
    GeoPoint? location;
    if (lat != null && lon != null) {
      location = GeoPoint(latitude: lat, longitude: lon);
    } else if (geometry is GeoPointGeometry) {
      location = geometry.coordinates;
    }

    final bboxMap = readMap(props, 'bbox');
    final bbox = bboxMap != null
        ? GeoBoundingBox.fromLonLatJson(bboxMap)
        : fallbackBbox;

    final tzMap = readMap(props, 'timezone');
    final dsMap = readMap(props, 'datasource');
    final rankMap = readMap(props, 'rank');

    return GeocodingResult(
      location: location,
      geometry: geometry,
      bbox: bbox,
      name: readString(props, 'name'),
      formatted: readString(props, 'formatted'),
      addressLine1: readString(props, 'address_line1'),
      addressLine2: readString(props, 'address_line2'),
      continent: readString(props, 'continent'),
      country: readString(props, 'country'),
      countryCode: readString(props, 'country_code'),
      region: readString(props, 'region'),
      state: readString(props, 'state'),
      stateCode: readString(props, 'state_code'),
      county: readString(props, 'county'),
      city: readString(props, 'city'),
      postcode:
          readString(props, 'postcode') ?? readString(props, 'postal_code'),
      district: readString(props, 'district'),
      suburb: readString(props, 'suburb'),
      neighbourhood: readString(props, 'neighbourhood'),
      town: readString(props, 'town'),
      village: readString(props, 'village'),
      municipality: readString(props, 'municipality'),
      street: readString(props, 'street') ?? readString(props, 'road'),
      housenumber:
          readString(props, 'housenumber') ?? readString(props, 'house_number'),
      plusCode: readString(props, 'plus_code'),
      plusCodeShort: readString(props, 'plus_code_short'),
      resultType: GeocodingResultType.tryParse(
        readString(props, 'result_type'),
      ),
      category: readString(props, 'category'),
      categories: readStringList(props, 'categories'),
      placeId: readString(props, 'place_id'),
      distance: readDouble(props, 'distance'),
      population: readDouble(props, 'population'),
      timezone: tzMap != null ? TimezoneInfo.fromJson(tzMap) : null,
      datasource: dsMap != null ? DatasourceInfo.fromJson(dsMap) : null,
      rank: rankMap != null ? GeocodingRank.fromJson(rankMap) : null,
      postcodes: readStringList(props, 'postcodes'),
      otherNames: readStringMap(props, 'other_names'),
      additionalProperties: extractAdditionalProperties(props, _knownKeys),
    );
  }

  static const Set<String> _knownKeys = {
    'lat',
    'lon',
    'bbox',
    'name',
    'formatted',
    'address_line1',
    'address_line2',
    'continent',
    'country',
    'country_code',
    'region',
    'state',
    'state_code',
    'county',
    'city',
    'postcode',
    'postal_code',
    'district',
    'suburb',
    'neighbourhood',
    'town',
    'village',
    'municipality',
    'street',
    'road',
    'housenumber',
    'house_number',
    'plus_code',
    'plus_code_short',
    'result_type',
    'category',
    'categories',
    'place_id',
    'distance',
    'population',
    'timezone',
    'datasource',
    'rank',
    'postcodes',
    'other_names',
  };

  /// Coordinate of the result, if available.
  final GeoPoint? location;

  /// Parsed GeoJSON geometry when `format=geojson` is used.
  final GeoJsonGeometry? geometry;

  /// Bounding box of the location, if provided.
  final GeoBoundingBox? bbox;

  /// Place or amenity name.
  final String? name;

  /// Full formatted address string.
  final String? formatted;

  /// Primary address line.
  final String? addressLine1;

  /// Secondary address line.
  final String? addressLine2;

  /// Continent name.
  final String? continent;

  /// Country name.
  final String? country;

  /// Lowercase ISO 3166-1 alpha-2 country code.
  final String? countryCode;

  /// Geographic region name.
  final String? region;

  /// State or province name.
  final String? state;

  /// State or province code.
  final String? stateCode;

  /// County name.
  final String? county;

  /// City name.
  final String? city;

  /// Postal or ZIP code.
  final String? postcode;

  /// City district.
  final String? district;

  /// Suburb name.
  final String? suburb;

  /// Neighbourhood name.
  final String? neighbourhood;

  /// Town name (when distinct from [city]).
  final String? town;

  /// Village name.
  final String? village;

  /// Municipality name.
  final String? municipality;

  /// Street or road name.
  final String? street;

  /// House number.
  final String? housenumber;

  /// Open Location Code (Plus Code).
  final String? plusCode;

  /// Short Plus Code.
  final String? plusCodeShort;

  /// Classified result type.
  final GeocodingResultType? resultType;

  /// Primary category key, if available.
  final String? category;

  /// Category keys associated with the result.
  final List<String> categories;

  /// Geoapify place identifier.
  final String? placeId;

  /// Distance in meters (for reverse geocoding or proximity-biased searches).
  final double? distance;

  /// Population count, when available.
  final double? population;

  /// Timezone metadata.
  final TimezoneInfo? timezone;

  /// Data source attribution metadata.
  final DatasourceInfo? datasource;

  /// Match confidence and ranking scores.
  final GeocodingRank? rank;

  /// Additional postcodes associated with the area.
  final List<String> postcodes;

  /// Localized or alternative names keyed by tag.
  final Map<String, String> otherNames;

  /// Additional response properties not explicitly modeled on [GeocodingResult].
  final Map<String, Object?> additionalProperties;
}

/// Confidence and ranking scores (`GeocodingRank`).
final class GeocodingRank {
  /// Creates a [GeocodingRank].
  const GeocodingRank({
    this.confidence,
    this.confidenceCityLevel,
    this.confidenceStreetLevel,
    this.confidenceBuildingLevel,
    this.matchType,
    this.importance,
    this.popularity,
  });

  /// Parses a [GeocodingRank] from JSON.
  factory GeocodingRank.fromJson(Map<String, Object?> json) {
    return GeocodingRank(
      confidence: readDouble(json, 'confidence'),
      confidenceCityLevel: readDouble(json, 'confidence_city_level'),
      confidenceStreetLevel: readDouble(json, 'confidence_street_level'),
      confidenceBuildingLevel: readDouble(json, 'confidence_building_level'),
      matchType: GeocodingMatchType.tryParse(readString(json, 'match_type')),
      importance: readDouble(json, 'importance'),
      popularity: readDouble(json, 'popularity'),
    );
  }

  /// Overall confidence score (`0.0` to `1.0`).
  final double? confidence;

  /// City-level confidence score.
  final double? confidenceCityLevel;

  /// Street-level confidence score.
  final double? confidenceStreetLevel;

  /// Building-level confidence score.
  final double? confidenceBuildingLevel;

  /// Match granularity classification.
  final GeocodingMatchType? matchType;

  /// Administrative/place importance score.
  final double? importance;

  /// Popularity score.
  final double? popularity;
}

/// Echoed query metadata returned by Geocoding APIs.
final class GeocodingQueryInfo {
  /// Creates a [GeocodingQueryInfo].
  const GeocodingQueryInfo({
    this.text,
    this.location,
    this.plusCode,
    this.postcode,
    this.city,
    this.state,
    this.country,
    this.housenumber,
    this.street,
    this.parsed,
  });

  /// Parses a [GeocodingQueryInfo] from JSON.
  factory GeocodingQueryInfo.fromJson(Map<String, Object?> json) {
    final lat = readDouble(json, 'lat');
    final lon = readDouble(json, 'lon');
    final parsedMap = readMap(json, 'parsed');
    return GeocodingQueryInfo(
      text: readString(json, 'text'),
      location: lat != null && lon != null
          ? GeoPoint(latitude: lat, longitude: lon)
          : null,
      plusCode: readString(json, 'plus_code'),
      postcode: readString(json, 'postcode'),
      city: readString(json, 'city'),
      state: readString(json, 'state'),
      country: readString(json, 'country'),
      housenumber: readString(json, 'housenumber'),
      street: readString(json, 'street'),
      parsed: parsedMap != null
          ? GeocodingParsedAddress.fromJson(parsedMap)
          : null,
    );
  }

  /// Input query text.
  final String? text;

  /// Reverse-geocoding query coordinate or parsed Plus Code location.
  final GeoPoint? location;

  /// Plus code in query.
  final String? plusCode;

  /// Postcode in query.
  final String? postcode;

  /// City in query.
  final String? city;

  /// State in query.
  final String? state;

  /// Country in query.
  final String? country;

  /// House number in query.
  final String? housenumber;

  /// Street in query.
  final String? street;

  /// Parsed structured components extracted from [text].
  final GeocodingParsedAddress? parsed;
}

/// Structured address components parsed from a free-form query.
final class GeocodingParsedAddress {
  /// Creates a [GeocodingParsedAddress].
  const GeocodingParsedAddress({
    this.poBox,
    this.unit,
    this.house,
    this.housenumber,
    this.street,
    this.suburb,
    this.postcode,
    this.district,
    this.city,
    this.county,
    this.state,
    this.region,
    this.country,
    this.expectedType,
  });

  /// Parses a [GeocodingParsedAddress] from JSON.
  factory GeocodingParsedAddress.fromJson(Map<String, Object?> json) {
    return GeocodingParsedAddress(
      poBox: readString(json, 'po_box'),
      unit: readString(json, 'unit'),
      house: readString(json, 'house'),
      housenumber: readString(json, 'housenumber'),
      street: readString(json, 'street'),
      suburb: readString(json, 'suburb'),
      postcode: readString(json, 'postcode'),
      district: readString(json, 'district'),
      city: readString(json, 'city'),
      county: readString(json, 'county'),
      state: readString(json, 'state'),
      region: readString(json, 'region'),
      country: readString(json, 'country'),
      expectedType: GeocodingResultType.tryParse(
        readString(json, 'expected_type'),
      ),
    );
  }

  /// Post office box.
  final String? poBox;

  /// Unit or apartment identifier.
  final String? unit;

  /// House or building name.
  final String? house;

  /// House number.
  final String? housenumber;

  /// Street name.
  final String? street;

  /// Suburb name.
  final String? suburb;

  /// Postal code.
  final String? postcode;

  /// District name.
  final String? district;

  /// City name.
  final String? city;

  /// County name.
  final String? county;

  /// State or province name.
  final String? state;

  /// Region name.
  final String? region;

  /// Country name.
  final String? country;

  /// Expected result type inferred from the query.
  final GeocodingResultType? expectedType;
}
