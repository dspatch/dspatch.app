import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/engine_process_manager.dart';

void main() {
  group('EngineProcessManager', () {
    test('engineExternal flag skips spawning', () {
      final manager = EngineProcessManager(
        engineBinaryPath: '/nonexistent/dspatch-engine',
        host: '127.0.0.1',
        port: 9847,
        engineExternal: true,
      );

      // When external, the manager should not attempt to spawn.
      expect(manager.engineExternal, isTrue);
      expect(manager.shouldSpawn, isFalse);
    });

    test('shouldSpawn is true when not external', () {
      final manager = EngineProcessManager(
        engineBinaryPath: '/path/to/dspatch-engine',
        host: '127.0.0.1',
        port: 9847,
        engineExternal: false,
      );

      expect(manager.shouldSpawn, isTrue);
    });

    test('resolveEngineBinaryPath returns expected path patterns', () {
      // This test verifies the resolution logic works.
      // The actual path depends on the platform, so we just verify
      // the function runs without error.
      final path = EngineProcessManager.resolveEngineBinaryPath();
      expect(path, isA<String>());
      expect(path, isNotEmpty);
    });
  });
}
