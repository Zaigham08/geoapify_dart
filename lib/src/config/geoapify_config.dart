/// Configuration options for [GeoapifyClient].
library;

/// Supported Geoapify API key authentication mechanisms.
enum ApiKeyAuthMethod {
  /// Sends the API key in the `x-api-key` HTTP request header.
  ///
  /// Recommended for server-to-server and non-browser clients because it
  /// keeps the API key out of request URLs and server access logs.
  header,

  /// Sends the API key as the `apiKey` query parameter.
  ///
  /// Useful when working with environments or proxies that strip custom
  /// request headers.
  queryParameter,
}

/// Optional retry policy for transient network, timeout, and 5xx/429 errors.
///
/// Retries are disabled by default ([RetryPolicy.none]) to prevent unexpected
/// Geoapify API credit consumption.
final class RetryPolicy {
  /// Creates a retry policy.
  ///
  /// [maxRetries] must be `0` or greater. [initialDelay] and [maxDelay] must
  /// not be negative.
  const RetryPolicy({
    this.maxRetries = 0,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
    this.retryOnRateLimit = true,
  }) : assert(maxRetries >= 0, 'maxRetries must be >= 0'),
       assert(backoffMultiplier >= 1.0, 'backoffMultiplier must be >= 1.0');

  /// Disabled retry policy (default).
  static const RetryPolicy none = RetryPolicy(maxRetries: 0);

  /// Maximum number of retry attempts after the initial request.
  final int maxRetries;

  /// Base delay before the first retry attempt when no `Retry-After` header
  /// is provided.
  final Duration initialDelay;

  /// Upper bound for backoff and `Retry-After` delays.
  final Duration maxDelay;

  /// Exponential multiplier applied between successive retries.
  final double backoffMultiplier;

  /// Whether HTTP 429 rate-limit responses should be retried when
  /// [maxRetries] is greater than `0`.
  final bool retryOnRateLimit;

  /// Whether retries are enabled.
  bool get isEnabled => maxRetries > 0;

  /// Computes the delay for the given 1-based [attempt], preferring
  /// [retryAfter] if provided, clamped to [maxDelay].
  Duration delayForAttempt(int attempt, {Duration? retryAfter}) {
    if (retryAfter != null && retryAfter > Duration.zero) {
      return retryAfter <= maxDelay ? retryAfter : maxDelay;
    }
    var factor = 1.0;
    for (var i = 1; i < attempt; i++) {
      factor *= backoffMultiplier;
    }
    final computed = Duration(
      milliseconds: (initialDelay.inMilliseconds * factor).round(),
    );
    if (computed < Duration.zero) {
      return Duration.zero;
    }
    return computed <= maxDelay ? computed : maxDelay;
  }
}

/// Immutable configuration for [GeoapifyClient] and its HTTP transport.
final class GeoapifyConfig {
  /// Creates a [GeoapifyConfig] instance.
  ///
  /// Throws an [ArgumentError] if [apiKey] is empty or [timeout] is not
  /// positive.
  GeoapifyConfig({
    required this.apiKey,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.authMethod = ApiKeyAuthMethod.header,
    this.retryPolicy = RetryPolicy.none,
    Map<String, String> defaultHeaders = const {},
  }) : baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl),
       defaultHeaders = Map.unmodifiable(defaultHeaders) {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'API key must not be empty.');
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Timeout must be greater than zero.',
      );
    }
  }

  /// Creates a configuration targeting the EU Geoapify API endpoint
  /// (`https://api-eu.geoapify.com`).
  factory GeoapifyConfig.eu({
    required String apiKey,
    Duration timeout = const Duration(seconds: 30),
    ApiKeyAuthMethod authMethod = ApiKeyAuthMethod.header,
    RetryPolicy retryPolicy = RetryPolicy.none,
    Map<String, String> defaultHeaders = const {},
  }) {
    return GeoapifyConfig(
      apiKey: apiKey,
      baseUrl: euBaseUrl,
      timeout: timeout,
      authMethod: authMethod,
      retryPolicy: retryPolicy,
      defaultHeaders: defaultHeaders,
    );
  }

  /// Default Geoapify REST API host.
  static final Uri defaultBaseUrl = Uri.parse('https://api.geoapify.com');

  /// EU Geoapify REST API host.
  static final Uri euBaseUrl = Uri.parse('https://api-eu.geoapify.com');

  /// Geoapify API key used to authenticate requests.
  final String apiKey;

  /// Base host URI for API requests (for example `https://api.geoapify.com`).
  final Uri baseUrl;

  /// Per-request timeout applied to HTTP calls.
  final Duration timeout;

  /// Authentication method used when sending API requests.
  final ApiKeyAuthMethod authMethod;

  /// Retry policy for transient failures (disabled by default).
  final RetryPolicy retryPolicy;

  /// Additional default headers included on every request.
  final Map<String, String> defaultHeaders;

  static Uri _normalizeBaseUrl(Uri uri) {
    if (!uri.hasScheme || !uri.hasAuthority) {
      throw ArgumentError.value(
        uri,
        'baseUrl',
        'baseUrl must be an absolute HTTP or HTTPS URI.',
      );
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw ArgumentError.value(
        uri,
        'baseUrl',
        'baseUrl scheme must be http or https.',
      );
    }
    return uri;
  }

  @override
  String toString() {
    return 'GeoapifyConfig('
        'baseUrl: $baseUrl, '
        'timeout: $timeout, '
        'authMethod: $authMethod, '
        'apiKey: ***)';
  }
}
