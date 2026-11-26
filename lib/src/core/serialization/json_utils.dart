/// Safe JSON parsing helpers for Geoapify response models.
library;

/// Reads a [String] value for [key] from [json], returning `null` if absent or
/// not a [String].
String? readString(Map<String, Object?> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

/// Reads a [double] value for [key] from [json], accepting any finite [num].
double? readDouble(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num && value.isFinite) {
    return value.toDouble();
  }
  return null;
}

/// Reads an [int] value for [key] from [json], converting integral [num] values.
int? readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite) {
    return value.toInt();
  }
  return null;
}

/// Reads a [bool] value for [key] from [json].
bool? readBool(Map<String, Object?> json, String key) {
  final value = json[key];
  return value is bool ? value : null;
}

/// Reads a JSON object map for [key] from [json], returning `null` if absent or
/// not a [Map].
Map<String, Object?>? readMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

/// Converts a dynamic [Map] into a typed `Map<String, Object?>`.
Map<String, Object?> asJsonMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  throw FormatException('Expected JSON object, got ${value.runtimeType}.');
}

/// Reads a [List] of objects for [key] from [json].
List<Object?>? readList(Map<String, Object?> json, String key) {
  final value = json[key];
  return value is List<Object?> ? value : null;
}

/// Reads a list of strings for [key] from [json], ignoring non-string entries.
List<String> readStringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    return const [];
  }
  return value.whereType<String>().toList(growable: false);
}

/// Reads a map of string values for [key] from [json].
Map<String, String> readStringMap(Map<String, Object?> json, String key) {
  final map = readMap(json, key);
  if (map == null) {
    return const {};
  }
  final result = <String, String>{};
  for (final entry in map.entries) {
    final val = entry.value;
    if (val is String) {
      result[entry.key] = val;
    }
  }
  return Map.unmodifiable(result);
}

/// Extracts all entries from [json] whose keys are not in [knownKeys].
Map<String, Object?> extractAdditionalProperties(
  Map<String, Object?> json,
  Set<String> knownKeys,
) {
  final extras = <String, Object?>{};
  for (final entry in json.entries) {
    if (!knownKeys.contains(entry.key)) {
      extras[entry.key] = entry.value;
    }
  }
  return Map.unmodifiable(extras);
}
