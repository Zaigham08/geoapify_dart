import 'dart:convert';

import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('GeocodingService', () {
    test(
      'forward search encodes parameters and parses GeoJSON response',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'name': 'Gulberg',
                    'country': 'Pakistan',
                    'country_code': 'pk',
                    'state': 'Punjab',
                    'city': 'Lahore',
                    'lat': 31.5102,
                    'lon': 74.3441,
                    'result_type': 'suburb',
                    'formatted': 'Gulberg, Lahore, Pakistan',
                    'address_line1': 'Gulberg',
                    'address_line2': 'Lahore, Pakistan',
                    'place_id': '51abc',
                    'rank': {
                      'confidence': 0.95,
                      'match_type': 'match_by_city_or_disrict',
                    },
                    'timezone': {
                      'name': 'Asia/Karachi',
                      'offset_STD': '+05:00',
                      'offset_DST': '+05:00',
                      'offset_STD_seconds': 18000,
                      'offset_DST_seconds': 18000,
                    },
                    'custom_extra': 'preserved',
                  },
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [74.3441, 31.5102],
                  },
                  'bbox': [74.32, 31.49, 74.36, 31.53],
                },
              ],
              'query': {
                'text': 'Gulberg, Lahore, Pakistan',
                'parsed': {'city': 'Lahore', 'country': 'Pakistan'},
              },
            }),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.geocoding.search(
          text: 'Gulberg, Lahore, Pakistan',
          type: GeocodingLocationType.locality,
          lang: 'en',
          limit: 5,
          countryCodes: ['PK'],
          filters: [
            GeocodingCircleFilter(
              center: GeoPoint(latitude: 31.5204, longitude: 74.3587),
              radiusMeters: 10000,
            ),
            GeocodingCountryFilter(countryCodes: ['pk']),
          ],
          biases: [
            GeocodingProximityBias(
              location: GeoPoint(latitude: 31.5204, longitude: 74.3587),
            ),
          ],
        );

        expect(captured.method, 'GET');
        expect(captured.url.path, '/v1/geocode/search');
        expect(captured.url.queryParameters, {
          'text': 'Gulberg, Lahore, Pakistan',
          'type': 'locality',
          'lang': 'en',
          'limit': '5',
          'countrycodes': 'pk',
          'filter': 'circle:74.3587,31.5204,10000.0|countrycode:pk',
          'bias': 'proximity:74.3587,31.5204',
          'format': 'geojson',
        });

        expect(response.results, hasLength(1));
        final top = response.firstOrNull!;
        expect(top.city, 'Lahore');
        expect(top.countryCode, 'pk');
        expect(top.location, GeoPoint(latitude: 31.5102, longitude: 74.3441));
        expect(top.resultType, GeocodingResultType.suburb);
        expect(top.rank?.matchType, GeocodingMatchType.matchByCityOrDistrict);
        expect(top.timezone?.name, 'Asia/Karachi');
        expect(
          top.bbox?.southWest,
          GeoPoint(latitude: 31.49, longitude: 74.32),
        );
        expect(top.additionalProperties['custom_extra'], 'preserved');
        expect(response.query?.parsed?.city, 'Lahore');
      },
    );

    test(
      'supports structured forward geocoding and JSON format response',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'city': 'Berlin',
                  'country': 'Germany',
                  'lat': 52.52,
                  'lon': 13.405,
                },
              ],
            }),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.geocoding.search(
          street: 'Friedrichstrasse',
          city: 'Berlin',
          country: 'Germany',
          format: GeocodingFormat.json,
        );

        expect(captured.url.queryParameters['street'], 'Friedrichstrasse');
        expect(captured.url.queryParameters['city'], 'Berlin');
        expect(captured.url.queryParameters['format'], 'json');
        expect(response.results.single.city, 'Berlin');
        expect(response.results.single.street, isNull);
      },
    );

    test('validates forward search inputs before HTTP call', () async {
      var called = false;
      final mock = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final client = GeoapifyClient(apiKey: 'k', httpClient: mock);

      await expectLater(
        () => client.geocoding.search(),
        throwsA(isA<GeoapifyValidationException>()),
      );
      await expectLater(
        () => client.geocoding.search(text: 'Berlin', city: 'Berlin'),
        throwsA(isA<GeoapifyValidationException>()),
      );
      await expectLater(
        () => client.geocoding.search(
          text: 'Berlin',
          type: GeocodingLocationType.building,
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );
      await expectLater(
        () => client.geocoding.search(text: 'Berlin', limit: 101),
        throwsA(isA<GeoapifyValidationException>()),
      );
      expect(called, isFalse);
    });

    test(
      'autocomplete sends /v1/geocode/autocomplete and handles empty results',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'type': 'FeatureCollection', 'features': <Object>[]}),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.geocoding.autocomplete(
          text: 'Gulberg, Lah',
          limit: 5,
        );

        expect(captured.url.path, '/v1/geocode/autocomplete');
        expect(captured.url.queryParameters['text'], 'Gulberg, Lah');
        expect(response.isEmpty, isTrue);
        expect(response.firstOrNull, isNull);
      },
    );

    test(
      'reverse geocoding sends lat/lon query params and supports building type',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'type': 'FeatureCollection',
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'housenumber': '24',
                    'street': 'Clark Street',
                    'city': 'Boston',
                    'lat': 42.3653541,
                    'lon': -71.0526773,
                    'distance': 0,
                    'result_type': 'building',
                  },
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [-71.0526773, 42.3653541],
                  },
                },
              ],
            }),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.geocoding.reverse(
          location: GeoPoint(latitude: 42.365344, longitude: -71.052655),
          type: GeocodingLocationType.building,
          countryCodes: ['us'],
        );

        expect(captured.url.path, '/v1/geocode/reverse');
        expect(captured.url.queryParameters['lat'], '42.365344');
        expect(captured.url.queryParameters['lon'], '-71.052655');
        expect(captured.url.queryParameters['type'], 'building');
        expect(captured.url.queryParameters['countrycodes'], 'us');

        expect(response.results.single.housenumber, '24');
        expect(
          response.results.single.resultType,
          GeocodingResultType.building,
        );
      },
    );
  });
}
