/// URL-template and attribution helpers for Geoapify Map Tiles.
library;

/// Supported Geoapify map style identifiers (`MapStyleId` in the Map Tiles
/// OpenAPI specification).
enum GeoapifyMapStyle {
  /// Standard OpenStreetMap Carto style (`osm-carto`).
  osmCarto('osm-carto'),

  /// Carto style (`carto`).
  carto('carto'),

  /// Dark Matter dark map style (`dark-matter`).
  darkMatter('dark-matter'),

  /// Klokantech Basic style (`klokantech-basic`).
  klokantechBasic('klokantech-basic'),

  /// Clean, bright OpenStreetMap style (`osm-bright`).
  osmBright('osm-bright'),

  /// High-contrast black and white Toner style (`toner`).
  toner('toner'),

  /// Greyscale Toner style (`toner-grey`).
  tonerGrey('toner-grey'),

  /// OSM Liberty style (`osm-liberty`).
  osmLiberty('osm-liberty'),

  /// MapTiler 3D style (`maptiler-3d`).
  maptiler3d('maptiler-3d'),

  /// Light, minimalist Positron style (`positron`).
  positron('positron'),

  /// Dark Matter brown variant (`dark-matter-brown`).
  darkMatterBrown('dark-matter-brown'),

  /// Dark Matter dark-grey variant (`dark-matter-dark-grey`).
  darkMatterDarkGrey('dark-matter-dark-grey'),

  /// Dark Matter dark-purple variant (`dark-matter-dark-purple`).
  darkMatterDarkPurple('dark-matter-dark-purple'),

  /// Dark Matter purple-roads variant (`dark-matter-purple-roads`).
  darkMatterPurpleRoads('dark-matter-purple-roads'),

  /// Dark Matter yellow-roads variant (`dark-matter-yellow-roads`).
  darkMatterYellowRoads('dark-matter-yellow-roads'),

  /// Desaturated grey variant of OSM Bright (`osm-bright-grey`).
  osmBrightGrey('osm-bright-grey'),

  /// Smooth aesthetic variant of OSM Bright (`osm-bright-smooth`).
  osmBrightSmooth('osm-bright-smooth'),

  /// Blue-accented Positron variant (`positron-blue`).
  positronBlue('positron-blue'),

  /// Red-accented Positron variant (`positron-red`).
  positronRed('positron-red');

  const GeoapifyMapStyle(this.id);

  /// Style identifier used in Geoapify Map Tiles URLs.
  final String id;
}

/// Attribution parameter options for MapLibre `style.json` URLs.
enum MapStyleAttribution {
  /// Includes Geoapify branding and required data-provider attribution
  /// (`default`).
  defaultAttribution('default'),

  /// Includes only required data-provider attribution (`mandatory`).
  mandatory('mandatory'),

  /// Omits attribution metadata from style resources (`none`).
  none('none');

  const MapStyleAttribution(this.value);

  /// Wire value for the `attribution` query parameter.
  final String value;
}

/// Lightweight URL-template and attribution helper for Geoapify Map Tiles.
///
/// Use [rasterUrlTemplate] with Flutter or Dart mapping libraries such as
/// `flutter_map` that consume XYZ raster tile URLs.
///
/// Geoapify map tiles are subject to Geoapify, OpenMapTiles, and
/// OpenStreetMap attribution requirements. Display [attributionText] or
/// [attributionHtml] visibly on maps powered by these tiles.
abstract final class GeoapifyMapTiles {
  /// Default map tile host (`https://maps.geoapify.com`).
  static const String defaultHost = 'https://maps.geoapify.com';

  /// EU map tile host (`https://api-eu.geoapify.com`).
  static const String euHost = 'https://api-eu.geoapify.com';

  /// Plain-text attribution string covering Geoapify, OpenMapTiles, and
  /// OpenStreetMap contributors.
  static const String attributionText =
      'Powered by Geoapify | © OpenMapTiles © OpenStreetMap contributors';

  /// HTML attribution string from Geoapify's Map Tiles documentation.
  static const String attributionHtml =
      'Powered by <a href="https://www.geoapify.com/" target="_blank">Geoapify</a> | '
      '<a href="https://openmaptiles.org/" rel="nofollow" target="_blank">© OpenMapTiles</a> '
      '<a href="https://www.openstreetmap.org/copyright" rel="nofollow" target="_blank">© OpenStreetMap</a> contributors';

  /// Generates an XYZ PNG raster tile URL template compatible with `flutter_map`
  /// and standard Slippy Map tile renderers.
  ///
  /// [scale] may be `1` (standard 256px tiles), `2` (`@2x` retina tiles), or
  /// `3` (`@3x` high-DPI tiles). Throws an [ArgumentError] if [apiKey] is empty
  /// or [scale] is not `1`, `2`, or `3`.
  static String rasterUrlTemplate({
    required String apiKey,
    GeoapifyMapStyle style = GeoapifyMapStyle.osmBright,
    int scale = 1,
    bool useEuEndpoint = false,
  }) {
    final key = _validateApiKey(apiKey);
    if (scale < 1 || scale > 3) {
      throw ArgumentError.value(
        scale,
        'scale',
        'Raster tile scale must be 1, 2, or 3.',
      );
    }
    final host = useEuEndpoint ? euHost : defaultHost;
    final scaleSuffix = scale == 1 ? '' : '@${scale}x';
    final encodedKey = Uri.encodeQueryComponent(key);
    return '$host/v1/tile/${style.id}/{z}/{x}/{y}$scaleSuffix.png?apiKey=$encodedKey';
  }

  /// Generates an XYZ vector tile URL template (`.pbf`).
  ///
  /// Throws an [ArgumentError] if [apiKey] is empty.
  static String vectorUrlTemplate({
    required String apiKey,
    GeoapifyMapStyle style = GeoapifyMapStyle.osmBright,
    bool useEuEndpoint = false,
  }) {
    final key = _validateApiKey(apiKey);
    final host = useEuEndpoint ? euHost : defaultHost;
    final encodedKey = Uri.encodeQueryComponent(key);
    return '$host/v1/tile/${style.id}/{z}/{x}/{y}.pbf?apiKey=$encodedKey';
  }

  /// Generates a MapLibre `style.json` URL for [style].
  ///
  /// Throws an [ArgumentError] if [apiKey] is empty.
  static String styleJsonUrl({
    required String apiKey,
    GeoapifyMapStyle style = GeoapifyMapStyle.osmBright,
    MapStyleAttribution attribution = MapStyleAttribution.defaultAttribution,
    bool useEuEndpoint = false,
  }) {
    final key = _validateApiKey(apiKey);
    final host = useEuEndpoint ? euHost : defaultHost;
    final base = Uri.parse('$host/v1/styles/${style.id}/style.json');
    return base
        .replace(
          queryParameters: {
            if (attribution != MapStyleAttribution.defaultAttribution)
              'attribution': attribution.value,
            'apiKey': key,
          },
        )
        .toString();
  }

  static String _validateApiKey(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'API key must not be empty.');
    }
    return trimmed;
  }
}
