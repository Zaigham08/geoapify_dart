/// Enums for the Geoapify Geocoding API.
library;

/// Requested target location granularity for geocoding queries.
enum GeocodingLocationType {
  /// Country level (`country`).
  country('country'),

  /// State or province level (`state`).
  state('state'),

  /// City or town level (`city`).
  city('city'),

  /// Postal code / ZIP code (`postcode`).
  postcode('postcode'),

  /// Street level (`street`).
  street('street'),

  /// Amenity or point of interest (`amenity`).
  amenity('amenity'),

  /// Locality (`locality`).
  locality('locality'),

  /// Building level (`building`, supported for reverse geocoding).
  building('building');

  const GeocodingLocationType(this.value);

  /// Wire value expected by Geoapify Geocoding APIs.
  final String value;
}

/// Classification of a geocoded result returned by Geoapify.
enum GeocodingResultType {
  /// Unclassified result (`unknown`).
  unknown('unknown'),

  /// Named amenity match (`amenity_name`).
  amenityName('amenity_name'),

  /// Amenity or POI (`amenity`).
  amenity('amenity'),

  /// Building or house number (`building`).
  building('building'),

  /// Street (`street`).
  street('street'),

  /// Postal code (`postcode`).
  postcode('postcode'),

  /// Suburb (`suburb`).
  suburb('suburb'),

  /// City district (`district`).
  district('district'),

  /// City (`city`).
  city('city'),

  /// County (`county`).
  county('county'),

  /// State or province (`state`).
  state('state'),

  /// Country (`country`).
  country('country');

  const GeocodingResultType(this.value);

  /// Wire value returned by Geoapify APIs.
  final String value;

  /// Parses a [GeocodingResultType] from its wire string.
  static GeocodingResultType? tryParse(String? value) {
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

/// Match quality classification in [GeocodingRank].
enum GeocodingMatchType {
  /// Full match (`full_match`).
  fullMatch('full_match'),

  /// Partial/inner part match (`inner_part`).
  innerPart('inner_part'),

  /// Matched at building level (`match_by_building`).
  matchByBuilding('match_by_building'),

  /// Matched at street level (`match_by_street`).
  matchByStreet('match_by_street'),

  /// Matched at postcode level (`match_by_postcode`).
  matchByPostcode('match_by_postcode'),

  /// Matched at city or district level (`match_by_city_or_disrict`).
  matchByCityOrDistrict('match_by_city_or_disrict'),

  /// Matched at country or state level (`match_by_country_or_state`).
  matchByCountryOrState('match_by_country_or_state');

  const GeocodingMatchType(this.value);

  /// Wire value returned by Geoapify APIs.
  final String value;

  /// Parses a [GeocodingMatchType] from its wire string.
  static GeocodingMatchType? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    if (value == 'match_by_city_or_district') {
      return matchByCityOrDistrict;
    }
    for (final item in values) {
      if (item.value == value) {
        return item;
      }
    }
    return null;
  }
}

/// Response serialization format for Geocoding requests.
enum GeocodingFormat {
  /// GeoJSON FeatureCollection (`geojson`, default).
  geojson('geojson'),

  /// Plain JSON object with a `results` array (`json`).
  json('json');

  const GeocodingFormat(this.value);

  /// Wire value expected by Geoapify Geocoding APIs.
  final String value;
}
