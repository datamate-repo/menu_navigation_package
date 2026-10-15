import 'package:flutter_test/flutter_test.dart';
import 'package:example/domain/models/plugin_session_context.dart';

void main() {
  group('PluginSessionContext Model Tests', () {
    test('serializes to valid JSON matching the protocol specification', () {
      const session = PluginSessionContext(
        auth: AuthContext(
          token: 'mock.jwt.token',
          tokenType: 'Bearer',
          expiresIn: 3600,
        ),
        context: FiscalContext(
          companyId: 'COMP-001',
          companyName: 'Acme Global',
          finYear: '2025-2026',
          branchId: 'BR-CHICAGO',
          currency: 'USD',
        ),
        user: UserContext(
          id: 'USR-1',
          name: 'Jane Doe',
          role: 'ADMIN',
        ),
      );

      final json = session.toJson();

      // Validate structure
      expect(json.containsKey('auth'), isTrue);
      expect(json.containsKey('context'), isTrue);
      expect(json.containsKey('user'), isTrue);

      // Validate nested auth
      final auth = json['auth'] as Map<String, dynamic>;
      expect(auth['token'], equals('mock.jwt.token'));
      expect(auth['tokenType'], equals('Bearer'));
      expect(auth['expiresIn'], equals(3600));

      // Validate nested context
      final context = json['context'] as Map<String, dynamic>;
      expect(context['companyId'], equals('COMP-001'));
      expect(context['companyName'], equals('Acme Global'));
      expect(context['finYear'], equals('2025-2026'));
      expect(context['currency'], equals('USD'));

      // Validate nested user
      final user = json['user'] as Map<String, dynamic>;
      expect(user['id'], equals('USR-1'));
      expect(user['name'], equals('Jane Doe'));
      expect(user['role'], equals('ADMIN'));
    });
  });
}
