import 'package:flutter_test/flutter_test.dart';
import 'package:dak/core/security/pinned_http_client.dart';

void main() {
  group('PinnedHttpClient Tests', () {
    test('PinnedHttpClient can be instantiated without throwing', () {
      final client = PinnedHttpClient();
      expect(client, isNotNull);
      client.close();
    });
  });
}
