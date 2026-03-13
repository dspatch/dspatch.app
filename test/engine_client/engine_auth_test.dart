import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/engine_auth.dart';

void main() {
  group('AuthResult', () {
    test('parses anonymous auth response', () {
      final json = {
        'session_token': 'abc123',
        'auth_mode': 'anonymous',
      };

      final result = AuthResult.fromJson(json);
      expect(result.sessionToken, 'abc123');
      expect(result.authMode, 'anonymous');
    });

    test('parses connected auth response', () {
      final json = {
        'session_token': 'xyz789',
        'auth_mode': 'connected',
      };

      final result = AuthResult.fromJson(json);
      expect(result.sessionToken, 'xyz789');
      expect(result.authMode, 'connected');
    });
  });

  group('EngineAuth', () {
    test('authenticateAnonymous fails gracefully when engine is down', () async {
      final auth = EngineAuth(host: '127.0.0.1', port: 1);
      expect(
        () => auth.authenticateAnonymous(),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
