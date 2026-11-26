/// Typed response models for the Geoapify Places API.
library;

import '../../../core/serialization/json_utils.dart';
import '../../../shared/models/datasource_info.dart';
import '../../../shared/models/geo_bounding_box.dart';
import '../../../shared/models/geo_json_geometry.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/models/timezone_info.dart';

/// Response returned by `GET` or `POST /v2/places`.
final class PlacesResponse {
  /// Creates a [PlacesResponse].
  const PlacesResponse({this.places = const []});

  /// Parses a GeoJSON FeatureCollection from the Places API.
  factory PlacesResponse.fromJson(Map<String, Object?> json) {
    final rawFeatures = readList(json, 'features') ?? const [];
    final places = <PlaceResult>[];
    for (final item in rawFeatures) {
      if (item is Map) {
        places.add(PlaceResult.fromGeoJsonFeature(asJsonMap(item)));
      }
    }
    return PlacesResponse(places: List.unmodifiable(places));
  }

  /// Matching places returned in this response page.
  final List<PlaceResult> places;

  /// Whether [places] contains no entries.
  bool get isEmpty => places.isEmpty;

  /// Whether [places] contains at least one entry.
  bool get isNotEmpty => places.isNotEmpty;
}

/// A single place / point of interest returned by the Places API.
final class PlaceResult {
  /// Creates a [PlaceResult].
  const PlaceResult({
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
    this.street,
    this.housenumber,
    this.placeId,
    this.distance,
    this.categories = const [],
    this.details = const [],
    this.datasource,
    this.timezone,
    this.website,
    this.openingHours,
    this.openingHoursCovid19,
    this.brand,
    this.operatorName,
    this.branch,
    this.network,
    this.owner,
    this.description,
    this.contact = const {},
    this.facilities = const {},
    this.catering = const {},
    this.accommodation = const {},
    this.paymentOptions = const {},
    this.wikiAndMedia = const {},
    this.otherNames = const {},
    this.additionalProperties = const {},
  });

  /// Parses a GeoJSON `Feature` item into a [PlaceResult].
  factory PlaceResult.fromGeoJsonFeature(Map<String, Object?> feature) {
    final props = readMap(feature, 'properties') ?? const {};
    final geomMap = readMap(feature, 'geometry');
    final geometry = geomMap != null ? GeoJsonGeometry.fromJson(geomMap) : null;
    final rawBbox = readList(feature, 'bbox');
    final bbox = rawBbox != null
        ? GeoBoundingBox.fromGeoJsonBbox(rawBbox)
        : null;

    final lat = readDouble(props, 'lat');
    final lon = readDouble(props, 'lon');
    GeoPoint? location;
    if (lat != null && lon != null) {
      location = GeoPoint(latitude: lat, longitude: lon);
    } else if (geometry is GeoPointGeometry) {
      location = geometry.coordinates;
    }

    final dsMap = readMap(props, 'datasource');
    final tzMap = readMap(props, 'timezone');

    return PlaceResult(
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
      street: readString(props, 'street') ?? readString(props, 'road'),
      housenumber:
          readString(props, 'housenumber') ?? readString(props, 'house_number'),
      placeId: readString(props, 'place_id'),
      distance: readDouble(props, 'distance'),
      categories: readStringList(props, 'categories'),
      details: readStringList(props, 'details'),
      datasource: dsMap != null ? DatasourceInfo.fromJson(dsMap) : null,
      timezone: tzMap != null ? TimezoneInfo.fromJson(tzMap) : null,
      website: readString(props, 'website'),
      openingHours: readString(props, 'opening_hours'),
      openingHoursCovid19: readString(props, 'opening_hours_covid19'),
      brand: readString(props, 'brand'),
      operatorName: readString(props, 'operator'),
      branch: readString(props, 'branch'),
      network: readString(props, 'network'),
      owner: readString(props, 'owner'),
      description: readString(props, 'description'),
      contact: Map.unmodifiable(readMap(props, 'contact') ?? const {}),
      facilities: Map.unmodifiable(readMap(props, 'facilities') ?? const {}),
      catering: Map.unmodifiable(readMap(props, 'catering') ?? const {}),
      accommodation: Map.unmodifiable(
        readMap(props, 'accommodation') ?? const {},
      ),
      paymentOptions: _readBoolMap(props, 'payment_options'),
      wikiAndMedia: Map.unmodifiable(
        readMap(props, 'wiki_and_media') ?? const {},
      ),
      otherNames: readStringMap(props, 'other_names'),
      additionalProperties: extractAdditionalProperties(props, _knownKeys),
    );
  }

  static Map<String, bool> _readBoolMap(Map<String, Object?> json, String key) {
    final map = readMap(json, key);
    if (map == null) {
      return const {};
    }
    final result = <String, bool>{};
    for (final entry in map.entries) {
      if (entry.value is bool) {
        result[entry.key] = entry.value as bool;
      }
    }
    return Map.unmodifiable(result);
  }

  static const Set<String> _knownKeys = {
    'lat',
    'lon',
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
    'street',
    'road',
    'housenumber',
    'house_number',
    'place_id',
    'distance',
    'categories',
    'details',
    'datasource',
    'timezone',
    'website',
    'opening_hours',
    'opening_hours_covid19',
    'brand',
    'operator',
    'branch',
    'network',
    'owner',
    'description',
    'contact',
    'facilities',
    'catering',
    'accommodation',
    'payment_options',
    'wiki_and_media',
    'other_names',
  };

  /// Coordinate of the place.
  final GeoPoint? location;

  /// Parsed GeoJSON geometry.
  final GeoJsonGeometry? geometry;

  /// Bounding box, if provided.
  final GeoBoundingBox? bbox;

  /// Place name.
  final String? name;

  /// Formatted full address.
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

  /// Region name.
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

  /// District name.
  final String? district;

  /// Suburb name.
  final String? suburb;

  /// Neighbourhood name.
  final String? neighbourhood;

  /// Street or road name.
  final String? street;

  /// House number.
  final String? housenumber;

  /// Geoapify place identifier.
  final String? placeId;

  /// Distance in meters from the search origin or bias point, if provided.
  final double? distance;

  /// Category keys assigned to this place.
  final List<String> categories;

  /// Detail group keys present on this place.
  final List<String> details;

  /// Data source attribution and raw source tags.
  final DatasourceInfo? datasource;

  /// Timezone metadata, if available.
  final TimezoneInfo? timezone;

  /// Place website URL.
  final String? website;

  /// Opening hours specification string.
  final String? openingHours;

  /// COVID-19 opening hours string, if available.
  final String? openingHoursCovid19;

  /// Brand name.
  final String? brand;

  /// Operator name.
  final String? operatorName;

  /// Branch name.
  final String? branch;

  /// Network name.
  final String? network;

  /// Owner name.
  final String? owner;

  /// Description text.
  final String? description;

  /// Contact details (phone, email, fax, social links, etc.).
  final Map<String, Object?> contact;

  /// Facilities metadata (wheelchair, internet_access, smoking, etc.).
  final Map<String, Object?> facilities;

  /// Catering metadata (cuisine, diet options, etc.).
  final Map<String, Object?> catering;

  /// Accommodation metadata (stars, rooms, etc.).
  final Map<String, Object?> accommodation;

  /// Accepted payment methods.
  final Map<String, bool> paymentOptions;

  /// Wikipedia / Wikidata / media references.
  final Map<String, Object?> wikiAndMedia;

  /// Alternative/localized names.
  final Map<String, String> otherNames;

  /// Category-specific or unmodeled properties preserved from the response.
  final Map<String, Object?> additionalProperties;
}
