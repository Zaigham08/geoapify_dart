/// Shared HTTP transport for Geoapify services.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/geoapify_config.dart';
import '../auth/api_key_strategy.dart';
import '../exceptions/geoapify_exception.dart';
import '../serialization/json_utils.dart';
import 'request_builder.dart';

/// Shared HTTP client wrapper handling Geoapify authentication, URI building,
/// timeouts, JSON decoding, error mapping, and optional retries.
final class GeoapifyHttpClient {
  /// Creates a [GeoapifyHttpClient].
  ///
  /// When [httpClient] is omitted, an internal `http.Client` is created and
  /// closed when [close] is called. When [httpClient] is provided by the
  /// caller, [close] leaves it open so the caller retains ownership.
  GeoapifyHttpClient({
    required GeoapifyConfig config,
    http.Client? httpClient,
    ApiKeyStrategy? apiKeyStrategy,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _apiKeyStrategy =
           apiKeyStrategy ?? ApiKeyStrategy.fromMethod(config.authMethod);

  final GeoapifyConfig _config;
  final http.Client _httpClient;
  final bool _ownsClient;
  final ApiKeyStrategy _apiKeyStrategy;
  bool _isClosed = false;

  /// Whether [close] has already been called.
  bool get isClosed => _isClosed;

  /// Sends a GET request to [path] and returns the decoded JSON object.
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, List<String>>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _sendJson(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Sends a POST request with a JSON-encoded [body] to [path] and returns the
  /// decoded JSON object.
  Future<Map<String, Object?>> postJson(
    String path, {
    required Object body,
    Map<String, List<String>>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _sendJson(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Map<String, Object?>> _sendJson({
    required String method,
    required String path,
    Object? body,
    Map<String, List<String>>? queryParameters,
    Map<String, String>? headers,
  }) async {
    if (_isClosed) {
      throw StateError(
        'Cannot execute $method $path after GeoapifyClient has been closed.',
      );
    }

    final mergedHeaders = <String, String>{
      'accept': 'application/json',
      ..._config.defaultHeaders,
      ...?headers,
    };
    final mergedQuery = <String, List<String>>{
      if (queryParameters != null)
        for (final entry in queryParameters.entries)
          entry.key: List.of(entry.value),
    };

    _apiKeyStrategy.apply(
      apiKey: _config.apiKey,
      headers: mergedHeaders,
      queryParameters: mergedQuery,
    );

    String? encodedBody;
    if (body != null) {
      mergedHeaders.putIfAbsent(
        'content-type',
        () => 'application/json; charset=utf-8',
      );
      encodedBody = jsonEncode(body);
    }

    final uri = buildGeoapifyUri(
      baseUrl: _config.baseUrl,
      path: path,
      queryParameters: mergedQuery,
    );

    final retryPolicy = _config.retryPolicy;
    var attempt = 0;

    while (true) {
      try {
        final response = await _executeOnce(
          method: method,
          uri: uri,
          headers: mergedHeaders,
          encodedBody: encodedBody,
        );
        return _handleResponse(response);
      } on GeoapifyException catch (error) {
        attempt++;
        if (!retryPolicy.isEnabled ||
            attempt > retryPolicy.maxRetries ||
            !_isRetryableException(error, retryPolicy)) {
          rethrow;
        }
        final retryAfter = error is GeoapifyRateLimitException
            ? error.retryAfter
            : null;
        final delay = retryPolicy.delayForAttempt(
          attempt,
          retryAfter: retryAfter,
        );
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }
    }
  }

  Future<http.Response> _executeOnce({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? encodedBody,
  }) async {
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encodedBody != null) {
        request.body = encodedBody;
      }

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_config.timeout);
      return await http.Response.fromStream(
        streamedResponse,
      ).timeout(_config.timeout);
    } on TimeoutException catch (error) {
      throw GeoapifyTimeoutException(
        'Request timed out after ${_config.timeout.inMilliseconds} ms.',
        timeout: _config.timeout,
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw GeoapifyNetworkException(
        redactApiKey(
          'Network error while calling Geoapify API: ${error.message}',
          apiKey: _config.apiKey,
        ),
        cause: error,
      );
    } on Exception catch (error) {
      throw GeoapifyNetworkException(
        redactApiKey(
          'Unexpected transport error: $error',
          apiKey: _config.apiKey,
        ),
        cause: error,
      );
    }
  }

  Map<String, Object?> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return _decodeJsonObject(response.body, statusCode: statusCode);
    }

    throw _mapHttpError(response);
  }

  Map<String, Object?> _decodeJsonObject(
    String rawBody, {
    required int statusCode,
  }) {
    if (rawBody.trim().isEmpty) {
      throw GeoapifyResponseFormatException(
        'Geoapify API returned an empty response body.',
        statusCode: statusCode,
      );
    }

    try {
      final decoded = jsonDecode(rawBody);
      return asJsonMap(decoded);
    } on FormatException catch (error) {
      throw GeoapifyResponseFormatException(
        'Failed to decode JSON response from Geoapify API: ${error.message}',
        statusCode: statusCode,
        cause: error,
      );
    }
  }

  GeoapifyException _mapHttpError(http.Response response) {
    final statusCode = response.statusCode;
    Map<String, Object?>? bodyMap;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          bodyMap = asJsonMap(decoded);
        }
      } on FormatException {
        // Non-JSON error body (for example proxy HTML page); fall back below.
      }
    }

    final gatewayError = bodyMap != null ? readString(bodyMap, 'error') : null;
    final rawMessage = bodyMap != null
        ? (readString(bodyMap, 'message') ??
              readString(bodyMap, 'error_description'))
        : null;
    final message = redactApiKey(
      rawMessage ??
          (response.reasonPhrase?.isNotEmpty == true
              ? response.reasonPhrase!
              : 'Geoapify API request failed with HTTP $statusCode.'),
      apiKey: _config.apiKey,
    );

    final sanitizedDetails = bodyMap != null ? _sanitizeMap(bodyMap) : null;

    if (statusCode == 400) {
      return GeoapifyBadRequestException(
        message,
        error: gatewayError,
        details: sanitizedDetails,
      );
    }
    if (statusCode == 401) {
      return GeoapifyUnauthorizedException(
        message,
        error: gatewayError,
        details: sanitizedDetails,
      );
    }
    if (statusCode == 403) {
      return GeoapifyForbiddenException(
        message,
        error: gatewayError,
        details: sanitizedDetails,
      );
    }
    if (statusCode == 429) {
      return GeoapifyRateLimitException(
        message,
        error: gatewayError,
        details: sanitizedDetails,
        retryAfter: _parseRetryAfter(response.headers),
      );
    }
    if (statusCode >= 500) {
      return GeoapifyServerException(
        message,
        statusCode: statusCode,
        error: gatewayError,
        details: sanitizedDetails,
      );
    }
    return GeoapifyApiException(
      message,
      statusCode: statusCode,
      error: gatewayError,
      details: sanitizedDetails,
    );
  }

  Map<String, Object?> _sanitizeMap(Map<String, Object?> source) {
    final result = <String, Object?>{};
    for (final entry in source.entries) {
      final value = entry.value;
      if (value is String) {
        result[entry.key] = redactApiKey(value, apiKey: _config.apiKey);
      } else {
        result[entry.key] = value;
      }
    }
    return Map.unmodifiable(result);
  }

  Duration? _parseRetryAfter(Map<String, String> headers) {
    String? rawValue;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'retry-after') {
        rawValue = entry.value.trim();
        break;
      }
    }
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    final seconds = int.tryParse(rawValue);
    if (seconds != null) {
      return seconds >= 0 ? Duration(seconds: seconds) : Duration.zero;
    }
    return null;
  }

  bool _isRetryableException(GeoapifyException error, RetryPolicy policy) {
    return switch (error) {
      GeoapifyNetworkException() => true,
      GeoapifyTimeoutException() => true,
      GeoapifyServerException() => true,
      GeoapifyRateLimitException() => policy.retryOnRateLimit,
      _ => false,
    };
  }

  /// Releases HTTP client resources if owned by this instance.
  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}
