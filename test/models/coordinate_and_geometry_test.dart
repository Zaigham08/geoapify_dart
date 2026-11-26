import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:test/test.dart';

void main() {
  group('GeoPoint coordinate safety and serialization', () {
    test('validates latitude and longitude bounds', () {
      expect(
        GeoPoint(latitude: -90, longitude: -180),
        const GeoPoint.unchecked(latitude: -90, longitude: -180),
      );
      expect(
        GeoPoint(latitude: 90, longitude: 180),
        const GeoPoint.unchecked(latitude: 90, longitude: 180),
      );

      expect(
        () => GeoPoint(latitude: 90.001, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: -90.001, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: 0, longitude: 180.001),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: double.nan, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => GeoPoint(latitude: 0, longitude: double.infinity),
        throwsArgumentError,
      );
    });

    test('serializes explicitly in lat/lon vs lon/lat vs GeoJSON orders', () {
      final point = GeoPoint(latitude: 31.5204, longitude: 74.3587);

      expect(point.toLatLonString(), '31.5204,74.3587');
      expect(point.toLonLatString(), '74.3587,31.5204');
      expect(point.toGeoJsonPosition(), [74.3587, 31.5204]);
      expect(point.toLatLonJson(), {'lat': 31.5204, 'lon': 74.3587});
      expect(point.toLatLonQueryParameters(), {
        'lat': '31.5204',
        'lon': '74.3587',
      });
    });

    test('parses GeoJSON [lon, lat] and {lat, lon} accurately', () {
      final fromGeoJson = GeoPoint.fromGeoJsonPosition([-76.4166, 36.9743, 12]);
      expect(fromGeoJson.latitude, 36.9743);
      expect(fromGeoJson.longitude, -76.4166);

      final fromLatLon = GeoPoint.fromLatLonJson({
        'lat': 36.9743,
        'lon': -76.4166,
      });
      expect(fromLatLon, fromGeoJson);

      expect(
        () => GeoPoint.fromGeoJsonPosition([74.35]),
        throwsFormatException,
      );
      expect(
        () => GeoPoint.fromLatLonJson({'lat': 31.5}),
        throwsFormatException,
      );
    });
  });

  group('GeoBoundingBox and GeoJsonGeometry', () {
    test('parses 4-element, 6-element, and object bounding boxes', () {
      final bbox4 = GeoBoundingBox.fromGeoJsonBbox([-10, 20, 30, 40]);
      expect(bbox4.southWest, GeoPoint(latitude: 20, longitude: -10));
      expect(bbox4.northEast, GeoPoint(latitude: 40, longitude: 30));
      expect(bbox4.toLon1Lat1Lon2Lat2String(), '-10.0,20.0,30.0,40.0');

      final bbox6 = GeoBoundingBox.fromGeoJsonBbox([-10, 20, 0, 30, 40, 100]);
      expect(bbox6, bbox4);

      final bboxObj = GeoBoundingBox.fromLonLatJson({
        'lon1': -10,
        'lat1': 20,
        'lon2': 30,
        'lat2': 40,
      });
      expect(bboxObj, bbox4);
    });

    test('parses all GeoJSON geometry types with [lon, lat] conversion', () {
      final point =
          GeoJsonGeometry.fromJson({
                'type': 'Point',
                'coordinates': [74.3587, 31.5204],
              })
              as GeoPointGeometry;
      expect(
        point.coordinates,
        GeoPoint(latitude: 31.5204, longitude: 74.3587),
      );

      final multiLine =
          GeoJsonGeometry.fromJson({
                'type': 'MultiLineString',
                'coordinates': [
                  [
                    [-123.298, 43.424],
                    [-123.350, 43.261],
                  ],
                ],
              })
              as GeoMultiLineStringGeometry;
      expect(multiLine.coordinates.first.first.latitude, 43.424);
      expect(multiLine.coordinates.first.first.longitude, -123.298);

      final polygon =
          GeoJsonGeometry.fromJson({
                'type': 'Polygon',
                'coordinates': [
                  [
                    [0, 0],
                    [10, 0],
                    [10, 10],
                    [0, 10],
                    [0, 0],
                  ],
                  [
                    [2, 2],
                    [3, 2],
                    [3, 3],
                    [2, 3],
                    [2, 2],
                  ],
                ],
              })
              as GeoPolygonGeometry;
      expect(polygon.outerRing, hasLength(5));
      expect(polygon.holes, hasLength(1));

      final collection =
          GeoJsonGeometry.fromJson({
                'type': 'GeometryCollection',
                'geometries': [
                  {
                    'type': 'Point',
                    'coordinates': [1.0, 2.0],
                  },
                ],
              })
              as GeoGeometryCollection;
      expect(collection.geometries, hasLength(1));

      final unknown = GeoJsonGeometry.fromJson({
        'type': 'CustomShape',
        'coordinates': <Object>[],
      });
      expect(unknown, isA<UnknownGeoJsonGeometry>());
    });
  });

  group('AvoidRule serialization', () {
    test('serializes feature, location, polygon, and country rules', () {
      final tolls = AvoidFeatureRule(
        feature: AvoidFeature.tolls,
        importance: 0.8,
      );
      expect(tolls.toQueryValues(), ['tolls:0.8']);
      expect(tolls.toMatrixJson(), {'type': 'tolls', 'importance': 0.8});

      final loc = AvoidLocationsRule(
        locations: [GeoPoint(latitude: 48.175, longitude: 11.65)],
      );
      expect(loc.toQueryValues(), ['location:48.175,11.65']);
      expect(loc.toMatrixJson(), {
        'type': 'locations',
        'values': [
          {'lat': 48.175, 'lon': 11.65},
        ],
      });

      final poly = AvoidPolygonsRule(
        polygons: [
          [
            GeoPoint(latitude: 48.2, longitude: 11.5),
            GeoPoint(latitude: 48.3, longitude: 11.5),
            GeoPoint(latitude: 48.3, longitude: 11.6),
          ],
        ],
      );
      expect(poly.toQueryValues(), ['polygon:48.2,11.5;48.3,11.5;48.3,11.6']);

      final countries = AvoidCountryCodesRule(countryCodes: ['DE', 'AT']);
      expect(countries.toQueryValues(), ['country_codes:de,at']);
      expect(countries.toMatrixJson(), {
        'type': 'country_codes',
        'values': ['de', 'at'],
      });
    });
  });
}
