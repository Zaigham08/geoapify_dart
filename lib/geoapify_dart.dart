/// A type-safe, community-maintained Dart client for Geoapify geocoding,
/// routing, places, route matrix, isoline, and map tile APIs.
library;

// Client & Configuration
export 'src/client/geoapify_client.dart';
export 'src/config/geoapify_config.dart';

// Exceptions
export 'src/core/exceptions/geoapify_exception.dart';

// Geocoding
export 'src/features/geocoding/geocoding_service.dart';
export 'src/features/geocoding/models/geocoding_enums.dart';
export 'src/features/geocoding/models/geocoding_filter_bias.dart';
export 'src/features/geocoding/requests/geocoding_requests.dart';
export 'src/features/geocoding/responses/geocoding_response.dart';

// Isolines
export 'src/features/isolines/isoline_service.dart';
export 'src/features/isolines/models/isoline_models.dart';

// Map Tiles
export 'src/features/map_tiles/geoapify_map_tiles.dart';

// Places
export 'src/features/places/models/places_constants.dart';
export 'src/features/places/models/places_filter_bias.dart';
export 'src/features/places/places_service.dart';
export 'src/features/places/requests/places_search_request.dart';
export 'src/features/places/responses/places_response.dart';

// Route Matrix
export 'src/features/route_matrix/models/route_matrix_models.dart';
export 'src/features/route_matrix/route_matrix_service.dart';

// Routing
export 'src/features/routing/models/routing_enums.dart';
export 'src/features/routing/requests/routing_request.dart';
export 'src/features/routing/responses/routing_response.dart';
export 'src/features/routing/routing_service.dart';

// Shared Models & Enums
export 'src/shared/enums/distance_units.dart';
export 'src/shared/enums/route_type.dart';
export 'src/shared/enums/traffic_model.dart';
export 'src/shared/enums/travel_mode.dart';
export 'src/shared/models/avoid_rule.dart';
export 'src/shared/models/datasource_info.dart';
export 'src/shared/models/geo_bounding_box.dart';
export 'src/shared/models/geo_json_geometry.dart';
export 'src/shared/models/geo_point.dart';
export 'src/shared/models/timezone_info.dart';
