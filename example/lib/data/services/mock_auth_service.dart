import 'dart:convert';
import '../../domain/models/plugin_session_context.dart';

/// Service generating realistic JWT tokens and mock session envelopes.
class MockAuthService {
  const MockAuthService();

  /// Generates a standard 3-part Base64URL-encoded dummy JWT.
  String generateMockJwt({
    String userId = 'USR-9921',
    String userName = 'Jane Doe',
    String role = 'CHIEF_ACCOUNTANT',
    String companyId = 'COMP-001',
    String finYear = '2025-2026',
    String branchId = 'BR-CHICAGO',
    int validitySeconds = 3600,
  }) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final payload = {
      'sub': userId,
      'name': userName,
      'role': role,
      'companyId': companyId,
      'finYear': finYear,
      'branchId': branchId,
      'iss': 'accounts-erp-host',
      'aud': 'imprest-cash-plugin',
      'iat': nowSeconds,
      'exp': nowSeconds + validitySeconds,
    };

    final base64Header = _base64UrlEncode(jsonEncode(header));
    final base64Payload = _base64UrlEncode(jsonEncode(payload));
    // Fixed deterministic mock signature segment (RFC 7519 compliant structure)
    const mockSignature = 'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    return '$base64Header.$base64Payload.$mockSignature';
  }

  /// Constructs a full [PluginSessionContext] bootstrap envelope.
  PluginSessionContext getMockSessionContext({
    String companyId = 'COMP-001',
    String companyName = 'Acme Global Trading Ltd',
    String finYear = '2025-2026',
    String branchId = 'BR-CHICAGO',
    String currency = 'USD',
    String userId = 'USR-9921',
    String userName = 'Jane Doe',
    String role = 'CHIEF_ACCOUNTANT',
  }) {
    final jwt = generateMockJwt(
      userId: userId,
      userName: userName,
      role: role,
      companyId: companyId,
      finYear: finYear,
      branchId: branchId,
    );

    return PluginSessionContext(
      auth: AuthContext(
        token: jwt,
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
      context: FiscalContext(
        companyId: companyId,
        companyName: companyName,
        finYear: finYear,
        branchId: branchId,
        currency: currency,
      ),
      user: UserContext(
        id: userId,
        name: userName,
        role: role,
      ),
    );
  }

  static String _base64UrlEncode(String input) {
    return base64Url.encode(utf8.encode(input)).replaceAll('=', '');
  }
}
