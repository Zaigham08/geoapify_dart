import 'dart:convert';

import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('PlacesService', () {
    test(
      'GET /v2/places serializes filters, bias, pagination, and parses places',
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
                    'name': 'Haveli Restaurant',
                    'country': 'Pakistan',
                    'country_code': 'pk',
                    'city': 'Lahore',
                    'lat': 31.5882,
                    'lon': 74.3095,
                    'categories': ['catering', 'catering.restaurant'],
                    'place_id': 'place-123',
                    'distance': 412,
                    'contact': {'phone': '+92-42-1234567'},
                    'payment_options': {'cash': true, 'credit_cards': false},
                    'extra_field': 42,
                  },
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [74.3095, 31.5882],
                  },
                },
              ],
            }),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.places.search(
          categories: [
            PlaceCategories.cateringRestaurant,
            PlaceCategories.cateringCafe,
          ],
          conditions: [PlaceConditions.wheelchairYes],
          filter: CompositePlacesFilter(
            filters: [
              CircleFilter(
                center: GeoPoint(latitude: 31.5204, longitude: 74.3587),
                radiusMeters: 3000,
              ),
              CountryCodeFilter(countryCodes: ['PK']),
            ],
          ),
          bias: ProximityBias(
            location: GeoPoint(latitude: 31.5204, longitude: 74.3587),
          ),
          limit: 25,
          offset: 50,
          lang: 'en',
          name: 'Haveli',
        );

        expect(captured.method, 'GET');
        expect(captured.url.path, '/v2/places');
        expect(
          captured.url.queryParameters['categories'],
          'catering.restaurant,catering.cafe',
        );
        expect(captured.url.queryParameters['conditions'], 'wheelchair.yes');
        expect(
          captured.url.queryParameters['filter'],
          'circle:74.3587,31.5204,3000.0|countrycode:pk',
        );
        expect(
          captured.url.queryParameters['bias'],
          'proximity:74.3587,31.5204',
        );
        expect(captured.url.queryParameters['limit'], '25');
        expect(captured.url.queryParameters['offset'], '50');
        expect(captured.url.queryParameters['name'], 'Haveli');

        expect(response.places, hasLength(1));
        final place = response.places.single;
        expect(place.name, 'Haveli Restaurant');
        expect(place.location, GeoPoint(latitude: 31.5882, longitude: 74.3095));
        expect(place.contact['phone'], '+92-42-1234567');
        expect(place.paymentOptions['cash'], isTrue);
        expect(place.additionalProperties['extra_field'], 42);
      },
    );

    test(
      'POST /v2/places automatically used for PolygonFilter and PolylineFilter',
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
        await client.places.search(
          categories: ['commercial.supermarket'],
          filter: PolygonFilter.polygon(
            rings: [
              [
                GeoPoint(latitude: 31.50, longitude: 74.30),
                GeoPoint(latitude: 31.50, longitude: 74.40),
                GeoPoint(latitude: 31.60, longitude: 74.40),
                GeoPoint(latitude: 31.50, longitude: 74.30),
              ],
            ],
            bufferMeters: 250,
          ),
          bias: ProximityBias(
            location: GeoPoint(latitude: 31.55, longitude: 74.35),
          ),
        );

        expect(captured.method, 'POST');
        expect(captured.url.path, '/v2/places');
        final decoded = jsonDecode(captured.body) as Map<String, Object?>;
        expect(decoded['categories'], ['commercial.supermarket']);
        final filterMap = decoded['filter'] as Map<String, Object?>;
        expect(filterMap['type'], 'polygon');
        expect(filterMap['buffer'], 250);
        final geom = filterMap['geometry'] as Map<String, Object?>;
        expect(geom['type'], 'Polygon');
        final rings = geom['coordinates'] as List<Object?>;
        final firstRing = rings.first as List<Object?>;
        // Verify GeoJSON [lon, lat] ordering!
        expect(firstRing.first, [74.30, 31.50]);

        await client.places.search(
          categories: ['catering.cafe'],
          filter: PolylineFilter.encoded(
            geometry: '_p~iF~ps|U_ulLnnqC',
            encoding: PolylineEncoding.polyline5,
            bufferMeters: 500,
          ),
        );
        expect(captured.method, 'POST');
        final polyBody = jsonDecode(captured.body) as Map<String, Object?>;
        expect(
          (polyBody['filter'] as Map<String, Object?>)['encoding'],
          'polyline5',
        );
      },
    );

    test(
      'validates categories, filter/bias presence, and GET/POST compatibility',
      () async {
        final client = GeoapifyClient(
          apiKey: 'k',
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );

        await expectLater(
          () => client.places.search(categories: []),
          throwsA(isA<GeoapifyValidationException>()),
        );
        await expectLater(
          () => client.places.search(categories: ['catering.restaurant']),
          throwsA(isA<GeoapifyValidationException>()),
        );
        await expectLater(
          () => client.places.searchGet(
            PlacesSearchRequest(
              categories: ['catering.restaurant'],
              filter: PolylineFilter.lineString(
                coordinates: [
                  GeoPoint(latitude: 10, longitude: 10),
                  GeoPoint(latitude: 11, longitude: 11),
                ],
              ),
            ),
          ),
          throwsA(isA<GeoapifyValidationException>()),
        );
        await expectLater(
          () => client.places.searchPost(
            PlacesSearchRequest(
              categories: ['catering.restaurant'],
              filter: CompositePlacesFilter(
                filters: [
                  CountryCodeFilter(countryCodes: ['us']),
                ],
              ),
            ),
          ),
          throwsA(isA<GeoapifyValidationException>()),
        );
      },
    );
  });
}
