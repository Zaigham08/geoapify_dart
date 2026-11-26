/// Datasource attribution metadata returned by Geocoding and Places APIs.
library;

import '../../core/serialization/json_utils.dart';

/// Attribution and licensing metadata (`PublicDatasource` / `PlacesDatasource`).
final class DatasourceInfo {
  /// Creates a [DatasourceInfo].
  const DatasourceInfo({
    this.sourceName,
    this.attribution,
    this.license,
    this.url,
    this.raw,
  });

  /// Parses a [DatasourceInfo] from JSON.
  factory DatasourceInfo.fromJson(Map<String, Object?> json) {
    final rawMap = readMap(json, 'raw');
    return DatasourceInfo(
      sourceName: readString(json, 'sourcename'),
      attribution: readString(json, 'attribution'),
      license: readString(json, 'license'),
      url: readString(json, 'url'),
      raw: rawMap != null ? Map.unmodifiable(rawMap) : null,
    );
  }

  /// Name of the underlying data source (for example `openstreetmap`).
  final String? sourceName;

  /// Required attribution text.
  final String? attribution;

  /// Data license name.
  final String? license;

  /// License or attribution URL.
  final String? url;

  /// Raw source tags when provided by the Places API.
  final Map<String, Object?>? raw;
}
