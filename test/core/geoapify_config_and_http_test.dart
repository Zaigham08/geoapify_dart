import 'dart:async';
import 'dart:convert';

import 'package:geoapify_dart/geoapify_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('GeoapifyConfig', () {
    test('rejects empty API key and non-positive timeout', () {
      expect(() => GeoapifyConfig(apiKey: ''), throwsArgumentError);
      expect(() => GeoapifyConfig(apiKey: '   '), throwsArgumentError);
      expect(
        () => GeoapifyConfig(apiKey: 'secret', timeout: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => GeoapifyConfig(
          apiKey: 'secret',
          baseUrl: Uri.parse('ftp://api.geoapify.com'),
        ),
        throwsArgumentError,
      );
    });

    test('masks API key in toString and supports EU endpoint', () {
      final config = GeoapifyConfig.eu(apiKey: 'super-secret-key-123');
      expect(config.baseUrl.toString(), 'https://api-eu.geoapify.com');
      expect(config.toString(), isNot(contains('super-secret-key-123')));
      expect(config.toString(), contains('apiKey: ***'));
    });
  });

  group('GeoapifyClient HTTP transport and auth', () {
    test('uses x-api-key header by default and sends custom headers', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'type': 'FeatureCollection', 'features': <Object>[]}),
          200,
        );
      });

      final client = GeoapifyClient(
        apiKey: 'test-key-xyz',
        defaultHeaders: {'x-custom-app': 'geo-app'},
        httpClient: mock,
      );

      await client.geocoding.search(text: 'Lahore');

      expect(captured.method, 'GET');
      expect(captured.url.host, 'api.geoapify.com');
      expect(captured.url.path, '/v1/geocode/search');
      expect(captured.url.queryParameters['apiKey'], isNull);
      expect(captured.headers['x-api-key'], 'test-key-xyz');
      expect(captured.headers['x-custom-app'], 'geo-app');
      expect(captured.headers['accept'], 'application/json');
    });

    test('supports query-parameter API key authentication', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'type': 'FeatureCollection', 'features': <Object>[]}),
          200,
        );
      });

      final client = GeoapifyClient(
        apiKey: 'query-secret-key',
        authMethod: ApiKeyAuthMethod.queryParameter,
        httpClient: mock,
      );

      await client.geocoding.search(text: 'Berlin');

      expect(captured.headers['x-api-key'], isNull);
      expect(captured.url.queryParameters['apiKey'], 'query-secret-key');
    });

    test('maps 400, 401, 403, 429, and 500 error responses properly', () async {
      Future<void> expectStatus(
        int statusCode,
        Map<String, Object?> body,
        Matcher matcher, {
        Map<String, String> headers = const {},
      }) async {
        final mock = MockClient((_) async {
          return http.Response(jsonEncode(body), statusCode, headers: headers);
        });
        final client = GeoapifyClient(apiKey: 'k', httpClient: mock);
        await expectLater(
          () => client.geocoding.search(text: 'x'),
          throwsA(matcher),
        );
      }

      await expectStatus(
        400,
        {'statusCode': 400, 'error': 'Bad Request', 'message': 'Invalid param'},
        isA<GeoapifyBadRequestException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.error, 'error', 'Bad Request')
            .having((e) => e.message, 'message', 'Invalid param'),
      );

      await expectStatus(
        401,
        {
          'statusCode': 401,
          'error': 'Unauthorized',
          'message': 'Invalid apiKey',
        },
        isA<GeoapifyUnauthorizedException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid apiKey'),
      );

      await expectStatus(
        403,
        {'statusCode': 403, 'error': 'Forbidden', 'message': 'Access denied'},
        isA<GeoapifyForbiddenException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        ),
      );

      await expectStatus(
        429,
        {
          'statusCode': 429,
          'error': 'Too Many Requests',
          'message': 'Quota exceeded',
        },
        isA<GeoapifyRateLimitException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 12),
            ),
        headers: {'Retry-After': '12'},
      );

      await expectStatus(
        500,
        {
          'statusCode': 500,
          'error': 'Internal Server Error',
          'message': 'Gateway error',
        },
        isA<GeoapifyServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        ),
      );
    });

    test('redacts API key from network exceptions and error details', () async {
      const secret = 'secret-abc-999';
      final mock = MockClient((request) async {
        throw http.ClientException(
          'Connection reset for https://api.geoapify.com/v1/geocode/search?apiKey=$secret',
          request.url,
        );
      });
      final client = GeoapifyClient(
        apiKey: secret,
        authMethod: ApiKeyAuthMethod.queryParameter,
        httpClient: mock,
      );

      await expectLater(
        () => client.geocoding.search(text: 'London'),
        throwsA(
          isA<GeoapifyNetworkException>().having(
            (e) => e.message,
            'message',
            allOf(contains('***'), isNot(contains(secret))),
          ),
        ),
      );
    });

    test('throws GeoapifyTimeoutException when request times out', () async {
      final mock = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('{}', 200);
      });
      final client = GeoapifyClient(
        apiKey: 'k',
        timeout: const Duration(milliseconds: 15),
        httpClient: mock,
      );

      await expectLater(
        () => client.geocoding.search(text: 'Paris'),
        throwsA(isA<GeoapifyTimeoutException>()),
      );
    });

    test(
      'throws GeoapifyResponseFormatException on invalid or empty JSON',
      () async {
        final malformedMock = MockClient(
          (_) async => http.Response('<html>', 200),
        );
        final malformedClient = GeoapifyClient(
          apiKey: 'k',
          httpClient: malformedMock,
        );
        await expectLater(
          () => malformedClient.geocoding.search(text: 'Paris'),
          throwsA(isA<GeoapifyResponseFormatException>()),
        );

        final emptyMock = MockClient((_) async => http.Response('  ', 200));
        final emptyClient = GeoapifyClient(apiKey: 'k', httpClient: emptyMock);
        await expectLater(
          () => emptyClient.geocoding.search(text: 'Paris'),
          throwsA(isA<GeoapifyResponseFormatException>()),
        );
      },
    );

    test(
      'does not retry by default and retries only retryable errors when enabled',
      () async {
        var attempts = 0;
        final defaultMock = MockClient((_) async {
          attempts++;
          return http.Response(
            jsonEncode({
              'statusCode': 500,
              'error': 'Error',
              'message': 'Fail',
            }),
            500,
          );
        });
        final defaultClient = GeoapifyClient(
          apiKey: 'k',
          httpClient: defaultMock,
        );
        await expectLater(
          () => defaultClient.geocoding.search(text: 'Test'),
          throwsA(isA<GeoapifyServerException>()),
        );
        expect(attempts, 1);

        var retryAttempts = 0;
        final retryMock = MockClient((_) async {
          retryAttempts++;
          if (retryAttempts < 3) {
            return http.Response(
              jsonEncode({
                'statusCode': 503,
                'error': 'Busy',
                'message': 'Retry',
              }),
              503,
            );
          }
          return http.Response(
            jsonEncode({'type': 'FeatureCollection', 'features': <Object>[]}),
            200,
          );
        });
        final retryClient = GeoapifyClient(
          apiKey: 'k',
          retryPolicy: const RetryPolicy(
            maxRetries: 2,
            initialDelay: Duration(milliseconds: 1),
            maxDelay: Duration(milliseconds: 5),
          ),
          httpClient: retryMock,
        );
        final response = await retryClient.geocoding.search(text: 'Test');
        expect(response.results, isEmpty);
        expect(retryAttempts, 3);

        var badReqAttempts = 0;
        final badReqMock = MockClient((_) async {
          badReqAttempts++;
          return http.Response(
            jsonEncode({'statusCode': 400, 'error': 'Bad', 'message': 'Nope'}),
            400,
          );
        });
        final badReqClient = GeoapifyClient(
          apiKey: 'k',
          retryPolicy: const RetryPolicy(
            maxRetries: 3,
            initialDelay: Duration(milliseconds: 1),
          ),
          httpClient: badReqMock,
        );
        await expectLater(
          () => badReqClient.geocoding.search(text: 'Test'),
          throwsA(isA<GeoapifyBadRequestException>()),
        );
        expect(badReqAttempts, 1);
      },
    );

    test(
      'lifecycle close() respects caller-owned vs internally-owned clients',
      () async {
        final spy = _SpyHttpClient();
        final externalClient = GeoapifyClient(apiKey: 'k', httpClient: spy);
        await externalClient.close();
        expect(externalClient.isClosed, isTrue);
        expect(spy.closed, isFalse);

        await expectLater(
          () => externalClient.geocoding.search(text: 'Lahore'),
          throwsStateError,
        );

        final ownedClient = GeoapifyClient(apiKey: 'k');
        await ownedClient.close();
        expect(ownedClient.isClosed, isTrue);
      },
    );
  });
}

final class _SpyHttpClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }

  @override
  void close() {
    closed = true;
  }
}
