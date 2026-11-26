import 'dart:convert';

import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('RoutingService', () {
    test(
      'serializes waypoints in lat,lon order and parses GeoJSON response',
      () async {
        late http.Request captured;
        final mock = MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'type': 'FeatureCollection',
              'properties': {
                'mode': 'drive',
                'units': 'metric',
                'waypoints': [
                  {'lat': 31.5204, 'lon': 74.3587},
                  {'lat': 31.4504, 'lon': 73.1350},
                ],
              },
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'mode': 'drive',
                    'units': 'metric',
                    'distance': 152340,
                    'distance_units': 'meters',
                    'time': 7320.5,
                    'toll': true,
                    'ferry': false,
                    'polyline6': 'abc_poly6',
                    'country_code': ['pk'],
                    'waypoints': [
                      {
                        'location': [74.3587, 31.5204],
                        'original_index': 0,
                      },
                      {
                        'location': [73.1350, 31.4504],
                        'original_index': 1,
                      },
                    ],
                    'legs': [
                      {
                        'distance': 152340,
                        'time': 7320.5,
                        'polyline6': 'leg_poly6',
                        'steps': [
                          {
                            'from_index': 0,
                            'to_index': 1,
                            'distance': 430,
                            'time': 42.1,
                            'toll': false,
                            'instruction': {
                              'text': 'Drive west on Main Boulevard.',
                              'type': 'StartAt',
                              'streets': ['Main Boulevard'],
                            },
                          },
                          {
                            'from_index': 1,
                            'to_index': 2,
                            'distance': 1200,
                            'time': 60,
                          },
                        ],
                      },
                    ],
                  },
                  'geometry': {
                    'type': 'MultiLineString',
                    'coordinates': [
                      [
                        [74.3587, 31.5204],
                        [74.0, 31.5],
                        [73.1350, 31.4504],
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
        final response = await client.routing.calculate(
          waypoints: [
            GeoPoint(latitude: 31.5204, longitude: 74.3587),
            GeoPoint(latitude: 31.4504, longitude: 73.1350),
          ],
          mode: TravelMode.drive,
          intermediateWaypointMode: IntermediateWaypointMode.throughStop,
          optimizeStops: true,
          type: RouteType.balanced,
          units: DistanceUnits.metric,
          lang: 'en',
          avoid: [
            AvoidFeatureRule(feature: AvoidFeature.tolls, importance: 0.8),
            AvoidFeatureRule(feature: AvoidFeature.ferries),
          ],
          details: {RouteDetail.instructionDetails, RouteDetail.polyline6},
          traffic: TrafficModel.approximated,
          maxSpeed: 110,
        );

        expect(captured.method, 'GET');
        expect(captured.url.path, '/v1/routing');
        expect(
          captured.url.queryParameters['waypoints'],
          '31.5204,74.3587|31.4504,73.135',
        );
        expect(captured.url.queryParameters['mode'], 'drive');
        expect(
          captured.url.queryParameters['intermediate_waypoint_mode'],
          'through_stop',
        );
        expect(captured.url.queryParameters['optimize_stops'], 'true');
        expect(captured.url.queryParameters['avoid'], 'tolls:0.8|ferries');
        expect(
          captured.url.queryParameters['details'],
          'instruction_details,polyline6',
        );
        expect(captured.url.queryParameters['traffic'], 'approximated');
        expect(captured.url.queryParameters['max_speed'], '110.0');

        final route = response.primaryRoute!;
        expect(route.distance, 152340);
        expect(route.time, 7320.5);
        expect(route.toll, isTrue);
        expect(route.polyline6, 'abc_poly6');
        expect(
          route.geometry.single.first,
          GeoPoint(latitude: 31.5204, longitude: 74.3587),
        );
        expect(route.legs.single.steps, hasLength(2));
        expect(
          route.legs.single.steps.first.instruction?.text,
          'Drive west on Main Boulevard.',
        );
        expect(route.legs.single.steps[1].instruction, isNull);
      },
    );

    test('parses plain JSON format response (format=json)', () async {
      final mock = MockClient((request) async {
        expect(request.url.queryParameters['format'], 'json');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'mode': 'walk',
                'units': 'metric',
                'distance': 850,
                'time': 610,
                'waypoints': [
                  {
                    'location': [-122.4, 37.78],
                    'original_index': 0,
                  },
                  {
                    'location': [-122.41, 37.79],
                    'original_index': 1,
                  },
                ],
                'legs': [
                  {'distance': 850, 'time': 610, 'steps': <Object>[]},
                ],
                'geometry': [
                  [
                    {'lon': -122.4, 'lat': 37.78},
                    {'lon': -122.41, 'lat': 37.79},
                  ],
                ],
              },
            ],
          }),
          200,
        );
      });

      final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
      final response = await client.routing.calculate(
        waypoints: [
          GeoPoint(latitude: 37.78, longitude: -122.4),
          GeoPoint(latitude: 37.79, longitude: -122.41),
        ],
        mode: TravelMode.walk,
        format: RoutingFormat.json,
      );

      final route = response.primaryRoute!;
      expect(route.mode, TravelMode.walk);
      expect(
        route.geometry.single.first,
        GeoPoint(latitude: 37.78, longitude: -122.4),
      );
    });

    test('validates waypoint count and maxSpeed', () async {
      final client = GeoapifyClient(
        apiKey: 'k',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      await expectLater(
        () => client.routing.calculate(
          waypoints: [GeoPoint(latitude: 10, longitude: 10)],
          mode: TravelMode.drive,
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );

      await expectLater(
        () => client.routing.calculate(
          waypoints: [
            GeoPoint(latitude: 10, longitude: 10),
            GeoPoint(latitude: 11, longitude: 11),
          ],
          mode: TravelMode.drive,
          maxSpeed: 5,
        ),
        throwsA(isA<GeoapifyValidationException>()),
      );
    });
  });
}
