import 'dart:io';

import 'package:geoapify_dart/geoapify_dart.dart';

/// Primary example for `geoapify_dart` demonstrating geocoding, routing,
/// places search, and map tile URL generation.
///
/// Run with:
/// `GEOAPIFY_API_KEY=your_api_key dart run example/geoapify_dart_example.dart`
Future<void> main() async {
  final apiKey = Platform.environment['GEOAPIFY_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('Set GEOAPIFY_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final geoapify = GeoapifyClient(apiKey: apiKey);

  try {
    // Forward geocoding
    final locations = await geoapify.geocoding.search(
      text: 'Gulberg, Lahore, Pakistan',
      limit: 1,
    );
    final origin =
        locations.firstOrNull?.location ??
        GeoPoint(latitude: 31.5204, longitude: 74.3587);
    print('Geocoded origin: $origin');

    // Routing
    final destination = GeoPoint(latitude: 31.4504, longitude: 73.1350);
    final route = await geoapify.routing.calculate(
      waypoints: [origin, destination],
      mode: TravelMode.drive,
    );
    print(
      'Route: ${route.primaryRoute?.distance} m in '
      '${route.primaryRoute?.time} s',
    );

    // Places search
    final places = await geoapify.places.search(
      categories: [PlaceCategories.cateringRestaurant],
      filter: CircleFilter(center: origin, radiusMeters: 3000),
      limit: 5,
    );
    print('Nearby restaurants: ${places.places.length}');

    // Map tiles URL template (for use with flutter_map)
    final tileUrl = GeoapifyMapTiles.rasterUrlTemplate(
      apiKey: apiKey,
      style: GeoapifyMapStyle.osmBright,
    );
    print('Tile URL template ready (${tileUrl.split('?').first})');
  } on GeoapifyException catch (error) {
    stderr.writeln('Geoapify API error: $error');
    exitCode = 1;
  } finally {
    await geoapify.close();
  }
}
