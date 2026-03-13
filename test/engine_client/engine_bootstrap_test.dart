import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/engine_bootstrap.dart';

void main() {
  group('EngineBootstrapConfig', () {
    test('default config uses port 9847', () {
      final config = EngineBootstrapConfig();
      expect(config.port, 9847);
      expect(config.host, '127.0.0.1');
    });

    test('engineExternal reads from const', () {
      // The const is set at compile time via --dart-define.
      // In tests, it defaults to false.
      final config = EngineBootstrapConfig();
      expect(config.engineExternal, isFalse);
    });

    test('custom config overrides defaults', () {
      final config = EngineBootstrapConfig(
        host: '192.168.1.1',
        port: 8080,
        engineExternal: true,
      );
      expect(config.host, '192.168.1.1');
      expect(config.port, 8080);
      expect(config.engineExternal, isTrue);
    });
  });

  group('EngineBootstrap', () {
    test('bootstrap fails gracefully when engine is unreachable', () async {
      final config = EngineBootstrapConfig(
        port: 1, // Nothing listening here.
        engineExternal: true,
      );
      final bootstrap = EngineBootstrap(config);

      expect(
        () => bootstrap.initialize(),
        throwsA(anything), // EngineStartException or similar
      );
    });
  });
}
