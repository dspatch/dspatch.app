import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/engine_connection.dart';
import 'package:dspatch_app/engine_client/protocol/protocol.dart';

void main() {
  group('EngineConnection', () {
    test('initial state is disconnected', () {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      expect(conn.isConnected, isFalse);
      conn.dispose();
    });

    test('completeCommand resolves pending future on ResultFrame', () async {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      // Register a pending command.
      final future = conn.registerPendingCommand('cmd_1');

      // Simulate receiving a result.
      conn.handleServerFrame(ResultFrame(
        id: 'cmd_1',
        data: {'run_id': 'xyz'},
      ));

      final result = await future;
      expect(result, isA<ResultFrame>());
      expect((result as ResultFrame).data['run_id'], 'xyz');

      conn.dispose();
    });

    test('completeCommand resolves pending future on ErrorFrame', () async {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      final future = conn.registerPendingCommand('cmd_2');

      conn.handleServerFrame(ErrorFrame(
        id: 'cmd_2',
        code: 'NOT_FOUND',
        message: 'Workspace not found',
      ));

      final result = await future;
      expect(result, isA<ErrorFrame>());
      expect((result as ErrorFrame).code, 'NOT_FOUND');

      conn.dispose();
    });

    test('invalidation events are emitted on invalidations stream', () async {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      final tables = <List<String>>[];
      final sub = conn.invalidations.listen(tables.add);

      conn.handleServerFrame(
        InvalidateFrame(tables: ['agent_messages', 'workspace_runs']),
      );

      // Allow microtask to propagate.
      await Future.delayed(Duration.zero);

      expect(tables, hasLength(1));
      expect(tables[0], ['agent_messages', 'workspace_runs']);

      await sub.cancel();
      conn.dispose();
    });

    test('ephemeral events are emitted on events stream', () async {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      final events = <EventFrame>[];
      final sub = conn.events.listen(events.add);

      conn.handleServerFrame(
        EventFrame(name: 'engine_shutting_down', data: {}),
      );

      await Future.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events[0].name, 'engine_shutting_down');

      await sub.cancel();
      conn.dispose();
    });

    test('unmatched result frame is dropped without error', () {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      // No pending command registered for 'orphan_id'.
      // Should not throw.
      conn.handleServerFrame(ResultFrame(id: 'orphan_id', data: {}));

      conn.dispose();
    });

    test('dispose completes all pending commands with error', () async {
      final conn = EngineConnection(
        host: '127.0.0.1',
        port: 9847,
        token: 'test-token',
      );

      final future = conn.registerPendingCommand('cmd_3');
      await conn.dispose();

      expect(() => future, throwsA(isA<StateError>()));
    });
  });
}
