## 1.0.1

- Added `example/geoapify_dart_example.dart` for `pub.dev` example tab detection.

## 1.0.0

- Initial release of `geoapify_dart`.
- Implemented `GeoapifyClient` with shared HTTP transport, configurable timeouts, `x-api-key` header and `apiKey` query-parameter authentication, optional `RetryPolicy`, and typed `GeoapifyException` error mapping.
- Added `GeocodingService` supporting forward geocoding (free-form and structured), address autocomplete, and reverse geocoding.
- Added `RoutingService` supporting multi-waypoint routes, all documented `TravelMode` profiles, avoidance rules, optional route details, and GeoJSON/JSON response parsing.
- Added `PlacesService` supporting category/condition search, typed spatial filters and biases, pagination, and both `GET` and structured `POST` requests.
- Added `RouteMatrixService` supporting multi-source/target time and distance matrices, `1,000`-cell validation, and nullable unreachable pairs.
- Added `IsolineService` supporting time-based isochrones, distance-based isodistances, multiple ranges, avoidance rules, and retrieval by geometry ID.
- Added `GeoapifyMapTiles` URL-template and attribution helpers for raster tiles, vector tiles, and MapLibre style JSON URLs.
