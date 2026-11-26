/// Common Geoapify place category and condition keys.
///
/// The Places API accepts arbitrary category and condition strings so callers
/// are not restricted if Geoapify adds new taxonomy keys. These constants are
/// provided for convenience.
library;

/// Common Geoapify Places API category keys.
abstract final class PlaceCategories {
  /// Accommodation (hotels, hostels, apartments, etc.).
  static const String accommodation = 'accommodation';

  /// Hotels (`accommodation.hotel`).
  static const String accommodationHotel = 'accommodation.hotel';

  /// Catering & dining (`catering`).
  static const String catering = 'catering';

  /// Restaurants (`catering.restaurant`).
  static const String cateringRestaurant = 'catering.restaurant';

  /// Cafes (`catering.cafe`).
  static const String cateringCafe = 'catering.cafe';

  /// Fast food (`catering.fast_food`).
  static const String cateringFastFood = 'catering.fast_food';

  /// Commercial & retail (`commercial`).
  static const String commercial = 'commercial';

  /// Supermarkets (`commercial.supermarket`).
  static const String commercialSupermarket = 'commercial.supermarket';

  /// Pharmacies (`healthcare.pharmacy`).
  static const String healthcarePharmacy = 'healthcare.pharmacy';

  /// Hospitals (`healthcare.hospital`).
  static const String healthcareHospital = 'healthcare.hospital';

  /// Leisure & parks (`leisure`).
  static const String leisure = 'leisure';

  /// Parks (`leisure.park`).
  static const String leisurePark = 'leisure.park';

  /// Tourism (`tourism`).
  static const String tourism = 'tourism';

  /// Attractions (`tourism.attraction`).
  static const String tourismAttraction = 'tourism.attraction';

  /// Public transport (`public_transport`).
  static const String publicTransport = 'public_transport';

  /// Fuel stations (`service.vehicle.fuel`).
  static const String serviceVehicleFuel = 'service.vehicle.fuel';

  /// Parking (`parking`).
  static const String parking = 'parking';
}

/// Common Geoapify Places API condition keys.
abstract final class PlaceConditions {
  /// Places with internet access (`internet_access`).
  static const String internetAccess = 'internet_access';

  /// Places with free internet access (`internet_access.free`).
  static const String internetAccessFree = 'internet_access.free';

  /// Wheelchair-accessible places (`wheelchair`).
  static const String wheelchair = 'wheelchair';

  /// Fully wheelchair-accessible places (`wheelchair.yes`).
  static const String wheelchairYes = 'wheelchair.yes';

  /// Limited wheelchair accessibility (`wheelchair.limited`).
  static const String wheelchairLimited = 'wheelchair.limited';

  /// Dogs allowed (`dogs`).
  static const String dogs = 'dogs';

  /// Vegetarian options (`vegetarian`).
  static const String vegetarian = 'vegetarian';

  /// Vegan options (`vegan`).
  static const String vegan = 'vegan';

  /// Halal options (`halal`).
  static const String halal = 'halal';

  /// No entry fee (`no_fee`).
  static const String noFee = 'no_fee';

  /// Named places only (`named`).
  static const String named = 'named';
}
