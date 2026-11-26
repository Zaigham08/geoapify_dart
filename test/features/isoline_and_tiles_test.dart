import 'dart:convert';

import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('IsolineService', () {
    test(
      'calculates isolines with repeated avoid params and parses MultiPolygon',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'type': 'FeatureCollection',
              'properties': {'id': '768fc88900268ab0ec5aa67fbfa09cc2'},
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'id': '768fc88900268ab0ec5aa67fbfa09cc2',
                    'lat': 36.9743711,
                    'lon': -76.4166222,
                    'mode': 'drive',
                    'type': 'time',
                    'range': 900,
                    'details': {
                      'population': {'value': 42500, 'attribution': 'WorldPop'},
                    },
                  },
                  'geometry': {
                    'type': 'MultiPolygon',
                    'coordinates': [
                      [
                        [
                          [-76.44, 36.97],
                          [-76.42, 36.95],
                          [-76.39, 36.97],
                          [-76.44, 36.97],
                        ],
                      ],
                    ],
                  },
                },
              ],
            }),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.isolines.calculate(
          location: GeoPoint(latitude: 36.9743711, longitude: -76.4166222),
          type: IsolineType.time,
          mode: TravelMode.drive,
          ranges: [900, 1800],
          units: DistanceUnits.metric,
          avoid: [
            AvoidFeatureRule(feature: AvoidFeature.tolls),
            AvoidFeatureRule(feature: AvoidFeature.ferries),
          ],
          routeType: RouteType.balanced,
          traffic: TrafficModel.approximated,
          maxSpeed: 90,
          details: ['population'],
        );

        expect(captured.method, 'GET');
        expect(captured.url.path, '/v1/isoline');
        expect(captured.url.queryParameters['lat'], '36.9743711');
        expect(captured.url.queryParameters['lon'], '-76.4166222');
        expect(captured.url.queryParameters['range'], '900,1800');
        expect(captured.url.queryParameters['type'], 'time');
        expect(captured.url.queryParameters['mode'], 'drive');
        expect(captured.url.queryParametersAll['avoid'], ['tolls', 'ferries']);
        expect(captured.url.queryParameters['details'], 'population');

        expect(response.id, '768fc88900268ab0ec5aa67fbfa09cc2');
        expect(response.features, hasLength(1));
        final feature = response.features.single;
        expect(feature.geometry, isA<GeoMultiPolygonGeometry>());
        expect(feature.properties.range, 900);
        expect(feature.properties.population?.value, 42500);
        expect(feature.properties.population?.attribution, 'WorldPop');
      },
    );

    test('retrieves isoline by ID and validates parameters', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'type': 'FeatureCollection',
            'properties': {'id': '768fc88900268ab0ec5aa67fbfa09cc2'},
            'features': <Object>[],
          }),
          200,
        );
      });

      final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
      final response = await client.isolines.getById(
        '768fc88900268ab0ec5aa67fbfa09cc2',
      );
      expect(
        captured.url.queryParameters['id'],
        '768fc88900268ab0ec5aa67fbfa09cc2',
      );
      expect(response.features, isEmpty);

      await expectLater(
        () => client.isolines.getById('not-a-valid-id'),
        throwsA(isA<GeoapifyValidationException>()),
      );
      await expectLater(
        () => client.isolines.calculate(
          location: GeoPoint(latitude: 10, longitude: 10),
          type: IsolineType.distance,
          mode: TravelMode.transit,
          ranges: [1000],
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );
      await expectLater(
        () => client.isolines.calculate(
          location: GeoPoint(latitude: 10, longitude: 10),
          type: IsolineType.time,
          mode: TravelMode.drive,
          ranges: List.generate(11, (i) => (i + 1) * 60),
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );
    });
  });

  group('GeoapifyMapTiles', () {
    test('builds raster, retina, vector, and style.json URLs', () {
      expect(
        GeoapifyMapTiles.rasterUrlTemplate(
          apiKey: 'my-key',
          style: GeoapifyMapStyle.osmBright,
        ),
        'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=my-key',
      );

      expect(
        GeoapifyMapTiles.rasterUrlTemplate(
          apiKey: 'my-key',
          style: GeoapifyMapStyle.darkMatter,
          scale: 2,
          useEuEndpoint: true,
        ),
        'https://api-eu.geoapify.com/v1/tile/dark-matter/{z}/{x}/{y}@2x.png?apiKey=my-key',
      );

      expect(
        GeoapifyMapTiles.vectorUrlTemplate(
          apiKey: 'my-key',
          style: GeoapifyMapStyle.positron,
        ),
        'https://maps.geoapify.com/v1/tile/positron/{z}/{x}/{y}.pbf?apiKey=my-key',
      );

      expect(
        GeoapifyMapTiles.styleJsonUrl(
          apiKey: 'my-key',
          style: GeoapifyMapStyle.osmLiberty,
          attribution: MapStyleAttribution.mandatory,
        ),
        'https://maps.geoapify.com/v1/styles/osm-liberty/style.json?attribution=mandatory&apiKey=my-key',
      );

      expect(GeoapifyMapTiles.attributionText, contains('Geoapify'));
      expect(GeoapifyMapTiles.attributionText, contains('OpenMapTiles'));
      expect(GeoapifyMapTiles.attributionText, contains('OpenStreetMap'));

      expect(
        () => GeoapifyMapTiles.rasterUrlTemplate(apiKey: ''),
        throwsArgumentError,
      );
      expect(
        () => GeoapifyMapTiles.rasterUrlTemplate(apiKey: 'k', scale: 4),
        throwsArgumentError,
      );
    });
  });
}
