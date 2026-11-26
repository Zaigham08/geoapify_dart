/// Typed exception hierarchy for Geoapify API and client errors.
library;

/// Base class for all errors thrown by the `geoapify_dart` SDK.
sealed class GeoapifyException implements Exception {
  /// Creates a [GeoapifyException].
  const GeoapifyException(
    this.message, {
    this.statusCode,
    this.error,
    this.details,
    this.cause,
  });

  /// Human-readable description of the error.
  final String message;

  /// HTTP status code associated with the error, if available.
  final int? statusCode;

  /// Standard error title returned by the Geoapify gateway, if available.
  final String? error;

  /// Additional structured details from the error response, if available.
  final Map<String, Object?>? details;

  /// Underlying exception that caused this failure, if any.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType');
    if (statusCode != null) {
      buffer.write(' ($statusCode');
      if (error != null && error!.isNotEmpty) {
        buffer.write(' $error');
      }
      buffer.write(')');
    }
    buffer.write(': $message');
    return buffer.toString();
  }
}

/// Thrown when request parameters fail client-side validation before an HTTP
/// call is made.
final class GeoapifyValidationException extends GeoapifyException {
  /// Creates a [GeoapifyValidationException].
  const GeoapifyValidationException(
    super.message, {
    super.details,
    super.cause,
  });
}

/// Thrown when the Geoapify API returns HTTP 400 (Bad Request).
final class GeoapifyBadRequestException extends GeoapifyException {
  /// Creates a [GeoapifyBadRequestException].
  const GeoapifyBadRequestException(
    super.message, {
    super.statusCode = 400,
    super.error,
    super.details,
    super.cause,
  });
}

/// Thrown when the Geoapify API returns HTTP 401 (Unauthorized) due to a
/// missing or invalid API key.
final class GeoapifyUnauthorizedException extends GeoapifyException {
  /// Creates a [GeoapifyUnauthorizedException].
  const GeoapifyUnauthorizedException(
    super.message, {
    super.statusCode = 401,
    super.error,
    super.details,
    super.cause,
  });
}

/// Thrown when the Geoapify API returns HTTP 403 (Forbidden).
final class GeoapifyForbiddenException extends GeoapifyException {
  /// Creates a [GeoapifyForbiddenException].
  const GeoapifyForbiddenException(
    super.message, {
    super.statusCode = 403,
    super.error,
    super.details,
    super.cause,
  });
}

/// Thrown when the Geoapify API returns HTTP 429 (Too Many Requests) because
/// a rate limit or quota has been exceeded.
final class GeoapifyRateLimitException extends GeoapifyException {
  /// Creates a [GeoapifyRateLimitException].
  const GeoapifyRateLimitException(
    super.message, {
    super.statusCode = 429,
    super.error,
    super.details,
    super.cause,
    this.retryAfter,
  });

  /// Suggested wait duration parsed from the `Retry-After` header, if present.
  final Duration? retryAfter;
}

/// Thrown when the Geoapify API returns a 5xx server or gateway error.
final class GeoapifyServerException extends GeoapifyException {
  /// Creates a [GeoapifyServerException].
  const GeoapifyServerException(
    super.message, {
    required int statusCode,
    super.error,
    super.details,
    super.cause,
  }) : super(statusCode: statusCode);
}

/// Thrown for other non-success HTTP status codes returned by the API.
final class GeoapifyApiException extends GeoapifyException {
  /// Creates a [GeoapifyApiException].
  const GeoapifyApiException(
    super.message, {
    required int statusCode,
    super.error,
    super.details,
    super.cause,
  }) : super(statusCode: statusCode);
}

/// Thrown when a request cannot be completed due to a network or socket error.
final class GeoapifyNetworkException extends GeoapifyException {
  /// Creates a [GeoapifyNetworkException].
  const GeoapifyNetworkException(super.message, {super.cause});
}

/// Thrown when an HTTP request exceeds the configured timeout duration.
final class GeoapifyTimeoutException extends GeoapifyException {
  /// Creates a [GeoapifyTimeoutException].
  const GeoapifyTimeoutException(
    super.message, {
    required this.timeout,
    super.cause,
  });

  /// Timeout duration that was exceeded.
  final Duration timeout;
}

/// Thrown when a response body is malformed JSON or does not match the expected
/// JSON object structure.
final class GeoapifyResponseFormatException extends GeoapifyException {
  /// Creates a [GeoapifyResponseFormatException].
  const GeoapifyResponseFormatException(
    super.message, {
    super.statusCode,
    super.details,
    super.cause,
  });
}
