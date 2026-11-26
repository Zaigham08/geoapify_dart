import 'dart:io';

import 'package:geoapify_dart/geoapify_dart.dart';

/// Demonstrates searching points of interest using GET and POST Places queries.
///
/// Run with:
/// `GEOAPIFY_API_KEY=your_api_key dart run example/places_example.dart`
Future<void> main() async {
  final apiKey = Platform.environment['GEOAPIFY_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('Set GEOAPIFY_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final client = GeoapifyClient(apiKey: apiKey);

  try {
    final center = GeoPoint(latitude: 31.5204, longitude: 74.3587);

    // 1. Standard GET search within a 3 km circle
    final nearbyRestaurants = await client.places.search(
      categories: [PlaceCategories.cateringRestaurant],
      filter: CircleFilter(center: center, radiusMeters: 3000),
      bias: ProximityBias(location: center),
      limit: 10,
      offset: 0,
    );

    print('Found ${nearbyRestaurants.places.length} restaurants:');
    for (final place in nearbyRestaurants.places) {
      print(' - ${place.name ?? place.formatted} (${place.distance} m)');
    }

    // 2. Structured POST search inside a custom polygon
    final polygonPlaces = await client.places.search(
      categories: [PlaceCategories.cateringCafe],
      filter: PolygonFilter.polygon(
        rings: [
          [
            GeoPoint(latitude: 31.50, longitude: 74.33),
            GeoPoint(latitude: 31.50, longitude: 74.37),
            GeoPoint(latitude: 31.54, longitude: 74.37),
            GeoPoint(latitude: 31.54, longitude: 74.33),
            GeoPoint(latitude: 31.50, longitude: 74.33),
          ],
        ],
      ),
      limit: 5,
    );

    print('\nCafes inside polygon: ${polygonPlaces.places.length}');
  } on GeoapifyException catch (error) {
    stderr.writeln('Geoapify places error: $error');
    exitCode = 1;
  } finally {
    await client.close();
  }
}
