import 'dart:convert';

import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('RouteMatrixService', () {
    test(
      'sends POST /v1/routematrix with [lon, lat] coordinates and parses cells',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'mode': 'drive',
              'units': 'metric',
              'distance_units': 'meters',
              'sources': [
                {
                  'original_location': [74.3587, 31.5204],
                  'location': [74.3588, 31.5205],
                },
                {
                  'original_location': [74.3000, 31.5000],
                },
              ],
              'targets': [
                {
                  'original_location': [73.1350, 31.4504],
                  'location': [73.1351, 31.4503],
                },
              ],
              'sources_to_targets': [
                [
                  {
                    'source_index': 0,
                    'target_index': 0,
                    'distance': 152340,
                    'time': 7320,
                  },
                ],
                [
                  {
                    'source_index': 1,
                    'target_index': 0,
                    'distance': null,
                    'time': null,
                  },
                ],
              ],
            }),
            200,
          );
        });

        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        final response = await client.routeMatrix.calculate(
          mode: TravelMode.drive,
          sources: [
            GeoPoint(latitude: 31.5204, longitude: 74.3587),
            GeoPoint(latitude: 31.5000, longitude: 74.3000),
          ],
          targets: [GeoPoint(latitude: 31.4504, longitude: 73.1350)],
          avoid: [AvoidFeatureRule(feature: AvoidFeature.tolls)],
          traffic: TrafficModel.freeFlow,
          type: RouteType.short,
          units: DistanceUnits.metric,
          maxSpeed: 100,
        );

        expect(captured.method, 'POST');
        expect(captured.url.path, '/v1/routematrix');
        final body = jsonDecode(captured.body) as Map<String, Object?>;
        expect(body['mode'], 'drive');
        expect(body['type'], 'short');
        expect(body['max_speed'], 100);
        expect(
          ((body['sources'] as List<Object?>).first
              as Map<String, Object?>)['location'],
          [74.3587, 31.5204],
        );
        expect(
          ((body['targets'] as List<Object?>).first
              as Map<String, Object?>)['location'],
          [73.1350, 31.4504],
        );

        expect(response.sources, hasLength(2));
        expect(
          response.sources.first.snappedLocation,
          GeoPoint(latitude: 31.5205, longitude: 74.3588),
        );
        expect(response.sources[1].snappedLocation, isNull);

        final reachable = response.cellAt(0, 0)!;
        expect(reachable.isReachable, isTrue);
        expect(reachable.distance, 152340);
        expect(reachable.time, 7320);

        final unreachable = response.cellAt(1, 0)!;
        expect(unreachable.isReachable, isFalse);
        expect(unreachable.distance, isNull);
        expect(unreachable.time, isNull);
        expect(response.cellAt(9, 9), isNull);
      },
    );

    test('enforces 1000-cell limit and rejects transit modes', () async {
      final client = GeoapifyClient(
        apiKey: 'k',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      final p = GeoPoint(latitude: 31.5, longitude: 74.3);
      await expectLater(
        () => client.routeMatrix.calculate(
          mode: TravelMode.transit,
          sources: [p],
          targets: [p],
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );

      await expectLater(
        () => client.routeMatrix.calculate(
          mode: TravelMode.drive,
          sources: List.filled(40, p),
          targets: List.filled(30, p),
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );
    });
  });
}
