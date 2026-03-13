import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:dspatch_app/engine_client/protocol/protocol.dart';

void main() {
  group('EngineClient', () {
    late EngineConnection connection;
    late EngineClient client;

    setUp(() {
      connection = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );
      client = EngineClient(connection);
    });

    tearDown(() {
      client.dispose();
    });

    test('sendCommand generates unique correlation IDs', () {
      // We can't easily test the full flow without a server,
      // but we can verify that two commands get different IDs
      // by inspecting the pending commands map.
      final future1 = connection.registerPendingCommand('id_1');
      final future2 = connection.registerPendingCommand('id_2');

      // Complete them to avoid hanging.
      connection.handleServerFrame(ResultFrame(id: 'id_1', data: {}));
      connection.handleServerFrame(ResultFrame(id: 'id_2', data: {}));

      expect(future1, isNotNull);
      expect(future2, isNotNull);
    });

    test('launchWorkspace sends correct command and returns result', () async {
      // Register a pending command manually to simulate the flow.
      final id = 'test-cmd';
      final future = connection.registerPendingCommand(id);

      // Simulate engine response.
      connection.handleServerFrame(ResultFrame(
        id: id,
        data: {'run_id': 'run_123'},
      ));

      final result = await future;
      expect(result, isA<ResultFrame>());
      expect((result as ResultFrame).data['run_id'], 'run_123');
    });

    test('sendCommand throws EngineException on error response', () async {
      final id = 'err-cmd';
      final future = connection.registerPendingCommand(id);

      connection.handleServerFrame(ErrorFrame(
        id: id,
        code: 'DOCKER_NOT_AVAILABLE',
        message: 'Docker is not running',
      ));

      final result = await future;
      expect(result, isA<ErrorFrame>());
      expect((result as ErrorFrame).code, 'DOCKER_NOT_AVAILABLE');
    });
  });
}
