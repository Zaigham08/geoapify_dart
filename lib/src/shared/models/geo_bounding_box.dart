/// Geographic bounding box model.
library;

import 'geo_point.dart';

/// An axis-aligned geographic bounding box defined by [southWest] and
/// [northEast] corners.
final class GeoBoundingBox {
  /// Creates a [GeoBoundingBox] from [southWest] and [northEast] corners.
  const GeoBoundingBox({required this.southWest, required this.northEast});

  /// Parses a GeoJSON `bbox` array `[minLon, minLat, maxLon, maxLat]`
  /// (or 6-element 3D bbox `[minLon, minLat, minEle, maxLon, maxLat, maxEle]`).
  factory GeoBoundingBox.fromGeoJsonBbox(List<Object?> bbox) {
    if (bbox.length == 4) {
      final lon1 = bbox[0];
      final lat1 = bbox[1];
      final lon2 = bbox[2];
      final lat2 = bbox[3];
      if (lon1 is num && lat1 is num && lon2 is num && lat2 is num) {
        return GeoBoundingBox(
          southWest: GeoPoint(
            latitude: lat1.toDouble(),
            longitude: lon1.toDouble(),
          ),
          northEast: GeoPoint(
            latitude: lat2.toDouble(),
            longitude: lon2.toDouble(),
          ),
        );
      }
    } else if (bbox.length == 6) {
      final lon1 = bbox[0];
      final lat1 = bbox[1];
      final lon2 = bbox[3];
      final lat2 = bbox[4];
      if (lon1 is num && lat1 is num && lon2 is num && lat2 is num) {
        return GeoBoundingBox(
          southWest: GeoPoint(
            latitude: lat1.toDouble(),
            longitude: lon1.toDouble(),
          ),
          northEast: GeoPoint(
            latitude: lat2.toDouble(),
            longitude: lon2.toDouble(),
          ),
        );
      }
    }
    throw const FormatException(
      'GeoJSON bbox must contain 4 or 6 numeric values.',
    );
  }

  /// Parses a Geoapify properties `bbox` object `{lon1, lat1, lon2, lat2}`.
  factory GeoBoundingBox.fromLonLatJson(Map<String, Object?> json) {
    final lon1 = json['lon1'];
    final lat1 = json['lat1'];
    final lon2 = json['lon2'];
    final lat2 = json['lat2'];
    if (lon1 is! num || lat1 is! num || lon2 is! num || lat2 is! num) {
      throw const FormatException(
        'Bounding box JSON must contain numeric lon1, lat1, lon2, and lat2.',
      );
    }
    return GeoBoundingBox(
      southWest: GeoPoint(
        latitude: lat1.toDouble(),
        longitude: lon1.toDouble(),
      ),
      northEast: GeoPoint(
        latitude: lat2.toDouble(),
        longitude: lon2.toDouble(),
      ),
    );
  }

  /// South-west corner (`lon1`, `lat1`).
  final GeoPoint southWest;

  /// North-east corner (`lon2`, `lat2`).
  final GeoPoint northEast;

  /// Serializes as `"lon1,lat1,lon2,lat2"` for Geoapify `rect:` filters and
  /// biases.
  String toLon1Lat1Lon2Lat2String() {
    return '${southWest.longitude},${southWest.latitude},'
        '${northEast.longitude},${northEast.latitude}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GeoBoundingBox &&
        other.southWest == southWest &&
        other.northEast == northEast;
  }

  @override
  int get hashCode => Object.hash(southWest, northEast);

  @override
  String toString() {
    return 'GeoBoundingBox(southWest: $southWest, northEast: $northEast)';
  }
}
