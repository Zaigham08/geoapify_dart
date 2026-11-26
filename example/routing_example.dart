import 'dart:io';

import 'package:geoapify_dart/geoapify_dart.dart';

/// Demonstrates calculating a driving route with turn-by-turn instructions.
///
/// Run with:
/// `GEOAPIFY_API_KEY=your_api_key dart run example/routing_example.dart`
Future<void> main() async {
  final apiKey = Platform.environment['GEOAPIFY_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('Set GEOAPIFY_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final client = GeoapifyClient(apiKey: apiKey);

  try {
    final response = await client.routing.calculate(
      waypoints: [
        GeoPoint(latitude: 31.5204, longitude: 74.3587), // Lahore
        GeoPoint(latitude: 31.4504, longitude: 73.1350), // Faisalabad
      ],
      mode: TravelMode.drive,
      units: DistanceUnits.metric,
      avoid: [AvoidFeatureRule(feature: AvoidFeature.tolls, importance: 0.5)],
      details: {RouteDetail.instructionDetails},
    );

    final route = response.primaryRoute;
    if (route == null) {
      print('No route returned.');
      return;
    }

    print('Distance: ${route.distance} ${route.distanceUnits ?? 'meters'}');
    print('Estimated time: ${route.time} seconds');
    print('Legs: ${route.legs.length}');

    for (final leg in route.legs) {
      for (final step in leg.steps) {
        final instruction = step.instruction?.text;
        if (instruction != null) {
          print(' - $instruction (${step.distance} m)');
        }
      }
    }
  } on GeoapifyException catch (error) {
    stderr.writeln('Geoapify routing error: $error');
    exitCode = 1;
  } finally {
    await client.close();
  }
}
