# geoapify_dart

A type-safe, community-maintained pure Dart SDK for [Geoapify](https://www.geoapify.com/) geocoding, routing, places, route matrix, isolines, and map tile URLs. Works seamlessly in both Flutter applications and standalone Dart programs.

> **Community-Maintained Notice:** `geoapify_dart` is an independent, community-maintained open-source SDK. It is not an official Geoapify product and is not endorsed by Geoapify.
>
> **Scope Notice:** This package handles Geoapify REST API communication, request validation, and typed response parsing. It does **not** render interactive maps or include Flutter UI widgets. You can pair `GeoapifyMapTiles` URL templates with mapping packages such as [`flutter_map`](https://pub.dev/packages/flutter_map).

## Features

- **Pure Dart:** No Flutter SDK dependency, platform channels, or native Android/iOS code.
- **Coordinate Safety:** Explicit `GeoPoint` serialization (`lat,lon`, `lon,lat`, and GeoJSON `[lon, lat]`) tailored to each endpoint's specification.
- **Injectable HTTP Transport:** Built on `package:http` with configurable timeouts, `x-api-key` header or `apiKey` query-parameter authentication, optional opt-in retries, and predictable client lifecycle management.
- **Typed Error Hierarchy:** Distinguishes validation errors, authentication failures (401/403), bad requests (400), rate limits (429 with `Retry-After`), server errors (5xx), timeouts, network errors, and malformed JSON responses.
- **Null-Safe International Models:** Gracefully handles missing or omitted international address fields, empty collections, unreachable matrix cells, and extra response properties.

## Supported APIs & Feature Coverage

### Implemented (v1.0.0)

| Service / Helper | Endpoint(s) | Capabilities |
| --- | --- | --- |
| `GeoapifyClient.geocoding` | `GET /v1/geocode/search`<br>`GET /v1/geocode/autocomplete`<br>`GET /v1/geocode/reverse` | Free-form & structured forward geocoding, address autocomplete, reverse geocoding, filters, biases, language, limit, country codes, GeoJSON & JSON parsing |
| `GeoapifyClient.routing` | `GET /v1/routing` | Multi-waypoint routing, all 17 `TravelMode` profiles, intermediate waypoint modes, stop optimization, avoidance rules, extra details (`elevation`, `admin_areas`, `polyline5`/`6`, etc.), GeoJSON & JSON parsing |
| `GeoapifyClient.places` | `GET /v2/places`<br>`POST /v2/places` | Hierarchical categories & conditions, circle/rect/geometry/place/country/polygon/polyline filters, proximity/circle/rect biases, pagination (`limit`/`offset`), automatic `POST` for complex geometry filters |
| `GeoapifyClient.routeMatrix` | `POST /v1/routematrix` | Multi-source to multi-target time & distance matrices, `1,000`-cell validation, avoidance rules, nullable unreachable pairs |
| `GeoapifyClient.isolines` | `GET /v1/isoline` | Time-based isochrones & distance-based isodistances, up to 10 range values, avoidance rules, population detail dataset, retrieval by geometry ID |
| `GeoapifyMapTiles` | `maps.geoapify.com/v1/tile/...`<br>`maps.geoapify.com/v1/styles/...` | XYZ raster PNG templates (`1x`, `@2x`, `@3x`), vector `.pbf` templates, MapLibre `style.json` URLs, all 19 documented map styles, attribution strings |

### Planned / Not Yet Implemented

The following Geoapify APIs are **not** included in v1.0.0 and are candidates for future releases:

- Batch Geocoding & Batch API
- Map Matching
- Route Planner
- Timezone API (standalone endpoint)
- IP Geolocation
- Elevation
- Postcode & Boundaries
- Place Details & Place Info
- Static Maps & Marker Icons
- Geometry & Geometry Operations

## Installation

Add `geoapify_dart` to your Dart or Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  geoapify_dart: ^1.0.0
```

Or install via the CLI:

```bash
# Standalone Dart
dart pub add geoapify_dart

# Flutter
flutter pub add geoapify_dart
```

## API Key Setup

1. Create an account and API key in the [Geoapify MyProjects Dashboard](https://myprojects.geoapify.com/).
2. Store your key in an environment variable or secure runtime configuration—never commit API keys to source control.
3. Usage of Geoapify APIs is subject to Geoapify's plans, credit quotas, terms of service, and attribution requirements.

## Initialization

```dart
import 'package:geoapify_dart/geoapify_dart.dart';

final geoapify = GeoapifyClient(
  apiKey: apiKey,
);
```

To target Geoapify's EU infrastructure:

```dart
final geoapify = GeoapifyClient.withConfig(
  GeoapifyConfig.eu(apiKey: apiKey),
);
```

## Usage Examples

### Forward Geocoding

```dart
final response = await geoapify.geocoding.search(
  text: 'Gulberg, Lahore, Pakistan',
  limit: 5,
  countryCodes: ['pk'],
);

for (final result in response.results) {
  print('${result.formatted} -> ${result.location}');
}
```

Structured address geocoding (do not combine with `text`):

```dart
final structured = await geoapify.geocoding.search(
  housenumber: '200',
  street: 'Larkin Street',
  city: 'San Francisco',
  state: 'California',
  country: 'United States',
);
```

### Address Autocomplete

```dart
final suggestions = await geoapify.geocoding.autocomplete(
  text: 'Gulberg, Lahore',
  limit: 5,
  biases: [
    GeocodingProximityBias(
      location: GeoPoint(latitude: 31.5204, longitude: 74.3587),
    ),
  ],
);

for (final item in suggestions.results) {
  print(item.formatted);
}
```

### Reverse Geocoding

```dart
final address = await geoapify.geocoding.reverse(
  location: GeoPoint(latitude: 31.5204, longitude: 74.3587),
);

print(address.firstOrNull?.formatted);
```

### Routing

```dart
final routingResponse = await geoapify.routing.calculate(
  waypoints: [
    GeoPoint(latitude: 31.5204, longitude: 74.3587),
    GeoPoint(latitude: 31.4504, longitude: 73.1350),
  ],
  mode: TravelMode.drive,
  units: DistanceUnits.metric,
  avoid: [AvoidFeatureRule(feature: AvoidFeature.tolls)],
  details: {RouteDetail.instructionDetails},
);

final route = routingResponse.primaryRoute;
if (route != null) {
  print('Distance: ${route.distance} m, Duration: ${route.time} s');
  for (final leg in route.legs) {
    for (final step in leg.steps) {
      print(step.instruction?.text);
    }
  }
}
```

### Places Search

```dart
final center = GeoPoint(latitude: 31.5204, longitude: 74.3587);

// GET /v2/places search with circle filter and proximity bias
final placesResponse = await geoapify.places.search(
  categories: [PlaceCategories.cateringRestaurant],
  conditions: [PlaceConditions.wheelchairYes],
  filter: CircleFilter(center: center, radiusMeters: 3000),
  bias: ProximityBias(location: center),
  limit: 20,
  offset: 0,
);

for (final place in placesResponse.places) {
  print('${place.name}: ${place.formatted}');
}
```

Polygon and polyline filters automatically use `POST /v2/places`:

```dart
final corridorPlaces = await geoapify.places.search(
  categories: ['service.vehicle.fuel'],
  filter: PolylineFilter.lineString(
    coordinates: [
      GeoPoint(latitude: 31.5204, longitude: 74.3587),
      GeoPoint(latitude: 31.4504, longitude: 73.1350),
    ],
    bufferMeters: 1000,
  ),
);
```

### Route Matrix

```dart
final matrix = await geoapify.routeMatrix.calculate(
  mode: TravelMode.drive,
  sources: [
    GeoPoint(latitude: 31.5204, longitude: 74.3587),
  ],
  targets: [
    GeoPoint(latitude: 31.4697, longitude: 74.2728),
    GeoPoint(latitude: 31.4504, longitude: 73.1350),
  ],
);

final cell = matrix.cellAt(0, 1);
if (cell != null && cell.isReachable) {
  print('Distance: ${cell.distance} m, Time: ${cell.time} s');
} else {
  print('Target is unreachable.');
}
```

### Isolines (Isochrones & Isodistances)

```dart
final isolines = await geoapify.isolines.calculate(
  location: GeoPoint(latitude: 31.5204, longitude: 74.3587),
  type: IsolineType.time,
  mode: TravelMode.drive,
  ranges: [600, 1200], // 10 and 20 minutes in seconds
  details: ['population'],
);

final isolineId = isolines.id;
if (isolineId != null) {
  // Retrieve previously generated isoline by ID
  final cached = await geoapify.isolines.getById(isolineId);
  print('Features: ${cached.features.length}');
}
```

### Map Tiles Integration with `flutter_map`

`geoapify_dart` does not depend on `flutter_map` or render map widgets, but `GeoapifyMapTiles` generates compatible XYZ tile templates and attribution strings:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:latlong2/latlong.dart';

class GeoapifyMapExample extends StatelessWidget {
  const GeoapifyMapExample({super.key, required this.apiKey});

  final String apiKey;

  @override
  Widget build(BuildContext context) {
    final tileUrl = GeoapifyMapTiles.rasterUrlTemplate(
      apiKey: apiKey,
      style: GeoapifyMapStyle.osmBright,
      scale: 2, // Retina @2x tiles
    );

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(31.5204, 74.3587),
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.example.app',
          retinaMode: true,
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(GeoapifyMapTiles.attributionText),
          ],
        ),
      ],
    );
  }
}
```

Always display the required **Geoapify**, **OpenMapTiles**, and **OpenStreetMap** attribution visibly on your map.

## Error Handling

All SDK errors extend the sealed `GeoapifyException` class:

```dart
try {
  final result = await geoapify.geocoding.search(text: 'Lahore');
  print(result.results.length);
} on GeoapifyValidationException catch (e) {
  // Invalid client-side parameters (caught before making an HTTP request)
  print('Invalid input: ${e.message}');
} on GeoapifyUnauthorizedException catch (e) {
  // HTTP 401: invalid or missing API key
  print('Auth error (${e.statusCode}): ${e.message}');
} on GeoapifyRateLimitException catch (e) {
  // HTTP 429: quota or rate limit exceeded
  print('Rate limited. Retry after: ${e.retryAfter}');
} on GeoapifyBadRequestException catch (e) {
  // HTTP 400: server rejected parameters
  print('Bad request: ${e.message}');
} on GeoapifyTimeoutException catch (e) {
  print('Timed out after ${e.timeout}');
} on GeoapifyNetworkException catch (e) {
  print('Network failure: ${e.message}');
} on GeoapifyException catch (e) {
  print('Geoapify error: $e');
}
```

## Client Lifecycle Management

`GeoapifyClient` shares a single `http.Client` across all services:

- If you do not pass `httpClient`, `GeoapifyClient` creates one internally and closes it when you call `await geoapify.close()`.
- If you pass your own `httpClient` (for example, a shared `http.Client` or a `MockClient` in tests), `await geoapify.close()` marks the `GeoapifyClient` as closed while leaving your `httpClient` open for you to manage.
- Automatic retries are **disabled by default** (`RetryPolicy.none`) to avoid unexpected API credit usage. You can opt in via `RetryPolicy(maxRetries: 2)`.

## Security Considerations

- By default, REST API requests authenticate using the `x-api-key` header (`ApiKeyAuthMethod.header`) rather than placing the key in the URL query string.
- Error messages and `GeoapifyConfig.toString()` redact API keys automatically.
- Browser and mobile apps that embed an API key (especially in XYZ tile URLs) expose that key to end users. Restrict your Geoapify API key by allowed domain/IP/referrer in the Geoapify dashboard or route requests through your own backend proxy in production.
- Geoapify API usage is governed by Geoapify's plans, quotas, terms of service, and attribution rules.

## Official Documentation

- [Geoapify API Documentation](https://apidocs.geoapify.com/docs)
- [Geoapify OpenAPI Specifications](https://github.com/geoapify/geoapify-openapi-specs)

## Supported Platforms

Because `geoapify_dart` is a pure Dart package depending only on `package:http`, it works on:

- Dart VM (CLI tools, backend servers)
- Flutter (Android, iOS, Web, macOS, Windows, Linux)

## Roadmap

- Batch Geocoding & Batch API
- Timezone, IP Geolocation, and Elevation services
- Postcode, Boundaries, and Place Details services
- Static Maps & Map Marker URL helpers
- Map Matching, Route Planner, and Geometry Operations

## Contributing

Contributions are welcome:

1. Fork the repository and create a feature branch.
2. Add tests under `test/` using `MockClient` (never commit real API keys).
3. Ensure formatting, static analysis, and tests pass:
   ```bash
   dart format --output=none --set-exit-if-changed .
   dart analyze
   dart test
   ```
4. Open a pull request describing your changes and referencing the relevant Geoapify OpenAPI specification.

## License

MIT License — see the `LICENSE` file in the package root.
