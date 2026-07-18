import 'dart:async';

import 'package:beautyhub/data/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('a hung request fails with TimeoutException instead of spinning',
      () async {
    final hangingClient = MockClient((request) => Completer<http.Response>()
        .future); // never completes, like a dead server that still accepts
    final api = ApiClient(
      httpClient: hangingClient,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(api.get('/salons'), throwsA(isA<TimeoutException>()));
  });

  test('responses inside the deadline pass through', () async {
    final client = MockClient((request) async => http.Response('[]', 200));
    final api = ApiClient(
      httpClient: client,
      timeout: const Duration(milliseconds: 50),
    );

    expect(await api.get('/salons'), isEmpty);
  });
}
