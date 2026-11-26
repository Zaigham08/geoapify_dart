/// Travel modes supported across Geoapify routing, matrix, and isoline APIs.
library;

/// Transportation profile used for routing, route matrix, and isoline
/// calculations.
enum TravelMode {
  /// Walking pedestrian profile.
  walk('walk'),

  /// Hiking trails and pedestrian paths.
  hike('hike'),

  /// Low-power scooter/moped profile.
  scooter('scooter'),

  /// Motorcycle profile.
  motorcycle('motorcycle'),

  /// Standard passenger car (`drive`).
  drive('drive'),

  /// Light commercial vehicle (`light_truck`).
  lightTruck('light_truck'),

  /// Standard bicycle profile.
  bicycle('bicycle'),

  /// Mountain bike profile (`mountain_bike`).
  mountainBike('mountain_bike'),

  /// Road/racing bicycle profile (`road_bike`).
  roadBike('road_bike'),

  /// Bus vehicle profile.
  bus('bus'),

  /// Medium truck profile (`medium_truck`).
  mediumTruck('medium_truck'),

  /// Standard truck profile.
  truck('truck'),

  /// Truck carrying dangerous goods (`truck_dangerous_goods`).
  truckDangerousGoods('truck_dangerous_goods'),

  /// Heavy truck profile (`heavy_truck`).
  heavyTruck('heavy_truck'),

  /// Long combination truck (`long_truck`).
  longTruck('long_truck'),

  /// Public transit timetable routing.
  transit('transit'),

  /// Approximated public transit routing (`approximated_transit`).
  approximatedTransit('approximated_transit');

  const TravelMode(this.value);

  /// Wire value expected by Geoapify APIs.
  final String value;

  /// Whether this mode represents public transit routing.
  bool get isTransit => this == transit || this == approximatedTransit;

  /// Parses a [TravelMode] from its wire string, returning `null` if unknown.
  static TravelMode? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final mode in values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return null;
  }
}
