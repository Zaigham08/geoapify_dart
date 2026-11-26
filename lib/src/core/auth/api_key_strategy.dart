/// API key authentication strategies for Geoapify requests.
library;

import '../../config/geoapify_config.dart';

/// Applies Geoapify API key credentials to outgoing HTTP requests.
sealed class ApiKeyStrategy {
  const ApiKeyStrategy();

  /// Creates the [ApiKeyStrategy] corresponding to [method].
  factory ApiKeyStrategy.fromMethod(ApiKeyAuthMethod method) {
    return switch (method) {
      ApiKeyAuthMethod.header => const HeaderApiKeyStrategy(),
      ApiKeyAuthMethod.queryParameter => const QueryParamApiKeyStrategy(),
    };
  }

  /// Applies authentication to [headers] or [queryParameters].
  void apply({
    required String apiKey,
    required Map<String, String> headers,
    required Map<String, List<String>> queryParameters,
  });
}

/// Sends the API key in the `x-api-key` request header.
final class HeaderApiKeyStrategy extends ApiKeyStrategy {
  /// Creates a header-based API key authentication strategy.
  const HeaderApiKeyStrategy();

  /// HTTP header name recognized by Geoapify APIs.
  static const String headerName = 'x-api-key';

  @override
  void apply({
    required String apiKey,
    required Map<String, String> headers,
    required Map<String, List<String>> queryParameters,
  }) {
    headers[headerName] = apiKey;
  }
}

/// Sends the API key in the `apiKey` query parameter.
final class QueryParamApiKeyStrategy extends ApiKeyStrategy {
  /// Creates a query-parameter-based API key authentication strategy.
  const QueryParamApiKeyStrategy();

  /// Query parameter name recognized by Geoapify APIs.
  static const String queryParameterName = 'apiKey';

  @override
  void apply({
    required String apiKey,
    required Map<String, String> headers,
    required Map<String, List<String>> queryParameters,
  }) {
    queryParameters[queryParameterName] = [apiKey];
  }
}

/// Redacts occurrences of [apiKey] and `apiKey=` query values from [text]
/// so credentials are never leaked in exceptions or logs.
String redactApiKey(String text, {String? apiKey}) {
  var sanitized = text.replaceAllMapped(
    RegExp(r'([?&]apiKey=)[^&\s]+', caseSensitive: false),
    (match) => '${match.group(1)}***',
  );
  if (apiKey != null && apiKey.isNotEmpty) {
    sanitized = sanitized.replaceAll(apiKey, '***');
    final encoded = Uri.encodeQueryComponent(apiKey);
    if (encoded != apiKey) {
      sanitized = sanitized.replaceAll(encoded, '***');
    }
  }
  return sanitized;
}
