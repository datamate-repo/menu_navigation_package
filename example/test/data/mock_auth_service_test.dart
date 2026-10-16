import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/data/services/mock_auth_service.dart';

void main() {
  const service = MockAuthService();

  group('MockAuthService Tests', () {
    test('generates valid 3-part Base64URL-encoded JWT', () {
      final jwt = service.generateMockJwt(
        userId: 'USR-888',
        userName: 'Alice Smith',
        role: 'AUDITOR',
        companyId: 'COMP-NY',
        finYear: '2025-2026',
      );

      final parts = jwt.split('.');
      expect(parts.length, equals(3), reason: 'JWT must have header.payload.signature');

      // Decode Header
      final headerJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[0])));
      final header = jsonDecode(headerJson) as Map<String, dynamic>;
      expect(header['alg'], equals('HS256'));
      expect(header['typ'], equals('JWT'));

      // Decode Payload
      final payloadJson = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      expect(payload['sub'], equals('USR-888'));
      expect(payload['name'], equals('Alice Smith'));
      expect(payload['role'], equals('AUDITOR'));
      expect(payload['companyId'], equals('COMP-NY'));
      expect(payload['finYear'], equals('2025-2026'));
      expect(payload['aud'], equals('imprest-cash-plugin'));
      expect(payload['iss'], equals('accounts-erp-host'));
      expect(payload.containsKey('exp'), isTrue);
      expect(payload.containsKey('iat'), isTrue);
    });

    test('generates full session context with consistent credentials', () {
      final session = service.getMockSessionContext(
        companyId: 'COMP-777',
        finYear: '2026-2027',
      );

      expect(session.context.companyId, equals('COMP-777'));
      expect(session.context.finYear, equals('2026-2027'));
      expect(session.auth.token.isNotEmpty, isTrue);
      expect(session.auth.tokenType, equals('Bearer'));
    });
  });
}
