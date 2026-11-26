import 'dart:io';

import 'package:geoapify_dart/geoapify_dart.dart';

/// Demonstrates calculating a multi-origin, multi-destination route matrix.
///
/// Run with:
/// `GEOAPIFY_API_KEY=your_api_key dart run example/route_matrix_example.dart`
Future<void> main() async {
  final apiKey = Platform.environment['GEOAPIFY_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('Set GEOAPIFY_API_KEY before running this example.');
    exitCode = 1;
    return;
  }

  final client = GeoapifyClient(apiKey: apiKey);

  try {
    final matrix = await client.routeMatrix.calculate(
      mode: TravelMode.drive,
      sources: [
        GeoPoint(latitude: 31.5204, longitude: 74.3587),
        GeoPoint(latitude: 31.5497, longitude: 74.3436),
      ],
      targets: [
        GeoPoint(latitude: 31.4697, longitude: 74.2728),
        GeoPoint(latitude: 31.4504, longitude: 73.1350),
      ],
      units: DistanceUnits.metric,
    );

    for (var s = 0; s < matrix.sources.length; s++) {
      for (var t = 0; t < matrix.targets.length; t++) {
        final cell = matrix.cellAt(s, t);
        if (cell == null || !cell.isReachable) {
          print('Source $s -> Target $t: unreachable');
        } else {
          print(
            'Source $s -> Target $t: '
            '${cell.distance} ${matrix.distanceUnits ?? 'meters'}, '
            '${cell.time} s',
          );
        }
      }
    }
  } on GeoapifyException catch (error) {
    stderr.writeln('Geoapify route matrix error: $error');
    exitCode = 1;
  } finally {
    await client.close();
  }
}
