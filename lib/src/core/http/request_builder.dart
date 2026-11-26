/// URI and query-parameter builder for Geoapify API requests.
library;

/// Encodes query parameters supporting single values, repeated values,
/// comma-separated lists, and pipe-delimited lists.
final class QueryParametersBuilder {
  final Map<String, List<String>> _params = {};

  /// Adds a single parameter if [value] is non-null.
  void add(String name, String? value) {
    if (value == null) {
      return;
    }
    _params[name] = [value];
  }

  /// Adds an integer parameter if [value] is non-null.
  void addInt(String name, int? value) {
    if (value == null) {
      return;
    }
    _params[name] = [value.toString()];
  }

  /// Adds a numeric parameter if [value] is non-null.
  void addNum(String name, num? value) {
    if (value == null) {
      return;
    }
    _params[name] = [value.toString()];
  }

  /// Adds a boolean parameter if [value] is non-null.
  void addBool(String name, bool? value) {
    if (value == null) {
      return;
    }
    _params[name] = [value ? 'true' : 'false'];
  }

  /// Adds a list joined by [separator] (e.g. `,` or `|`) if non-null and
  /// non-empty.
  void addJoined(
    String name,
    Iterable<String>? values, {
    String separator = ',',
  }) {
    if (values == null) {
      return;
    }
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return;
    }
    _params[name] = [list.join(separator)];
  }

  /// Adds multiple repeated query parameter entries (`name=a&name=b`) if
  /// non-null and non-empty.
  void addRepeated(String name, Iterable<String>? values) {
    if (values == null) {
      return;
    }
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return;
    }
    _params[name] = list;
  }

  /// Returns a mutable copy of the accumulated query parameter map.
  Map<String, List<String>> build() {
    return {
      for (final entry in _params.entries) entry.key: List.of(entry.value),
    };
  }
}

/// Builds an endpoint [Uri] from [baseUrl], a relative [path], and optional
/// multi-value [queryParameters].
Uri buildGeoapifyUri({
  required Uri baseUrl,
  required String path,
  Map<String, List<String>>? queryParameters,
}) {
  final normalizedBasePath = baseUrl.path.endsWith('/')
      ? baseUrl.path.substring(0, baseUrl.path.length - 1)
      : baseUrl.path;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final fullPath = '$normalizedBasePath$normalizedPath';

  final baseQuery = <String, List<String>>{};
  for (final entry in baseUrl.queryParametersAll.entries) {
    baseQuery[entry.key] = List.of(entry.value);
  }
  if (queryParameters != null) {
    for (final entry in queryParameters.entries) {
      if (entry.value.isNotEmpty) {
        baseQuery[entry.key] = List.of(entry.value);
      }
    }
  }

  if (baseQuery.isEmpty) {
    return baseUrl.replace(path: fullPath, query: null);
  }

  // Dart's Uri constructor encodes multi-value lists when passed as
  // Map<String, Object?> where values are String or Iterable<String>.
  final encodedQuery = <String, Object>{
    for (final entry in baseQuery.entries)
      entry.key: entry.value.length == 1 ? entry.value.first : entry.value,
  };
  return baseUrl.replace(path: fullPath, queryParameters: encodedQuery);
}
