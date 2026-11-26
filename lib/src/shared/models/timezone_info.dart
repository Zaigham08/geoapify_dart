/// Timezone metadata returned by Geocoding and Places APIs.
library;

import '../../core/serialization/json_utils.dart';

/// Timezone metadata (`TimezoneOutput`) embedded in Geoapify location results.
final class TimezoneInfo {
  /// Creates a [TimezoneInfo].
  const TimezoneInfo({
    this.name,
    this.nameAlt,
    this.countryCodes = const [],
    this.offsetStd,
    this.offsetDst,
    this.offsetStdSeconds,
    this.offsetDstSeconds,
    this.abbreviationStd,
    this.abbreviationDst,
  });

  /// Parses a [TimezoneInfo] from JSON.
  factory TimezoneInfo.fromJson(Map<String, Object?> json) {
    return TimezoneInfo(
      name: readString(json, 'name'),
      nameAlt: readString(json, 'name_alt'),
      countryCodes: readStringList(json, 'country_codes'),
      offsetStd: readString(json, 'offset_STD'),
      offsetDst: readString(json, 'offset_DST'),
      offsetStdSeconds: readDouble(json, 'offset_STD_seconds'),
      offsetDstSeconds: readDouble(json, 'offset_DST_seconds'),
      abbreviationStd: readString(json, 'abbreviation_STD'),
      abbreviationDst: readString(json, 'abbreviation_DST'),
    );
  }

  /// IANA timezone identifier (for example `America/Los_Angeles`).
  final String? name;

  /// Alternative timezone identifier, if provided.
  final String? nameAlt;

  /// Associated ISO country codes.
  final List<String> countryCodes;

  /// Standard UTC offset string (for example `-08:00`).
  final String? offsetStd;

  /// Daylight saving time UTC offset string (for example `-07:00`).
  final String? offsetDst;

  /// Standard UTC offset in seconds.
  final double? offsetStdSeconds;

  /// Daylight saving time UTC offset in seconds.
  final double? offsetDstSeconds;

  /// Standard time abbreviation (for example `PST`).
  final String? abbreviationStd;

  /// Daylight saving time abbreviation (for example `PDT`).
  final String? abbreviationDst;
}
