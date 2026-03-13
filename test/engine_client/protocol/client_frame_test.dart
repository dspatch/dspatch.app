import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/protocol/client_frame.dart';

void main() {
  group('ClientFrame', () {
    test('command serializes to JSON with correct shape', () {
      final frame = ClientFrame.command(
        id: 'cmd_1',
        method: 'launch_workspace',
        params: {'workspace_id': 'abc'},
      );

      final json = jsonDecode(jsonEncode(frame.toJson()));
      expect(json['id'], 'cmd_1');
      expect(json['type'], 'command');
      expect(json['method'], 'launch_workspace');
      expect(json['params']['workspace_id'], 'abc');
    });

    test('command with empty params serializes correctly', () {
      final frame = ClientFrame.command(
        id: 'cmd_2',
        method: 'list_workspaces',
        params: {},
      );

      final json = jsonDecode(jsonEncode(frame.toJson()));
      expect(json['params'], isEmpty);
    });
  });
}
