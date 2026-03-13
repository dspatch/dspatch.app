import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/protocol/server_frame.dart';

void main() {
  group('ServerFrame.fromJson', () {
    test('parses result frame', () {
      final json = '{"type":"result","id":"cmd_1","data":{"run_id":"xyz"}}';
      final frame = ServerFrame.fromJson(jsonDecode(json));

      expect(frame, isA<ResultFrame>());
      final result = frame as ResultFrame;
      expect(result.id, 'cmd_1');
      expect(result.data['run_id'], 'xyz');
    });

    test('parses error frame with id', () {
      final json =
          '{"type":"error","id":"cmd_1","code":"NOT_FOUND","message":"Workspace not found"}';
      final frame = ServerFrame.fromJson(jsonDecode(json));

      expect(frame, isA<ErrorFrame>());
      final error = frame as ErrorFrame;
      expect(error.id, 'cmd_1');
      expect(error.code, 'NOT_FOUND');
      expect(error.message, 'Workspace not found');
    });

    test('parses error frame without id', () {
      final json =
          '{"type":"error","code":"INVALID_FRAME","message":"bad json"}';
      final frame = ServerFrame.fromJson(jsonDecode(json));

      expect(frame, isA<ErrorFrame>());
      final error = frame as ErrorFrame;
      expect(error.id, isNull);
    });

    test('parses invalidate frame', () {
      final json =
          '{"type":"invalidate","tables":["agent_messages","workspace_runs"]}';
      final frame = ServerFrame.fromJson(jsonDecode(json));

      expect(frame, isA<InvalidateFrame>());
      final inv = frame as InvalidateFrame;
      expect(inv.tables, ['agent_messages', 'workspace_runs']);
    });

    test('parses event frame', () {
      final json =
          '{"type":"event","name":"welcome","data":{"protocol_version":1}}';
      final frame = ServerFrame.fromJson(jsonDecode(json));

      expect(frame, isA<EventFrame>());
      final event = frame as EventFrame;
      expect(event.name, 'welcome');
      expect(event.data['protocol_version'], 1);
    });

    test('throws on unknown type', () {
      final json = '{"type":"unknown"}';
      expect(
        () => ServerFrame.fromJson(jsonDecode(json)),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
