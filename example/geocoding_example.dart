import 'dart:io';

import 'package:geoapify_dart/geoapify_dart.dart';

/// Demonstrates forward geocoding, address autocomplete, and reverse geocoding.
///
/// Run with:
/// `GEOAPIFY_API_KEY=your_api_key dart run example/geocoding_example.dart`
Future<void> main() async {
  final apiKey = Platform.environment['GEOAPIFY_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('Set GEOAPIFY_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final client = GeoapifyClient(apiKey: apiKey);

  try {
    // 1. Forward geocoding (free-form query)
    final forward = await client.geocoding.search(
      text: 'Gulberg, Lahore, Pakistan',
      limit: 3,
      lang: 'en',
    );
    print('Forward results: ${forward.results.length}');
    for (final result in forward.results) {
      print(' - ${result.formatted} (${result.location})');
    }

    // 2. Address autocomplete with country bias
    final suggestions = await client.geocoding.autocomplete(
      text: 'Gulberg, Lah',
      limit: 5,
      biases: [
        GeocodingCountryBias(countryCodes: ['pk']),
      ],
    );
    print('\nAutocomplete suggestions: ${suggestions.results.length}');
    for (final suggestion in suggestions.results) {
      print(' - ${suggestion.formatted}');
    }

    // 3. Reverse geocoding
    final reverse = await client.geocoding.reverse(
      location: GeoPoint(latitude: 31.5204, longitude: 74.3587),
    );
    final nearest = reverse.firstOrNull;
    print('\nNearest address: ${nearest?.formatted ?? 'None found'}');
  } on GeoapifyException catch (error) {
    stderr.writeln('Geoapify API error: $error');
    exitCode = 1;
  } finally {
    await client.close();
  }
}
