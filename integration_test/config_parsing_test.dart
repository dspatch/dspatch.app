// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

const _validYaml = '''
name: parse-test
agents:
  main:
    template: dspatch://agent/test/echo
    env:
      API_KEY: test
  helper:
    template: dspatch://agent/test/helper
    peers:
      - main
''';

const _invalidYaml = '{{{not valid yaml';

const _incompleteYaml = 'name: incomplete\n';

void main() {
  late TestHarness harness;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Config parsing', () {
    test('parse valid YAML returns config with name and agents', () async {
      final result =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      expect(result['name'], equals('parse-test'));
      expect(result['agents'], isA<Map>());
      final agents = result['agents'] as Map;
      expect(agents, contains('main'));
      expect(agents, contains('helper'));
    });

    test('parse invalid YAML returns error', () async {
      expect(
        () => harness.client.parseWorkspaceConfig(yaml: _invalidYaml),
        throwsA(isA<EngineException>()),
      );
    });

    test('validate valid config succeeds', () async {
      final result = await harness.client
          .sendCommand('validate_workspace_config', {'yaml': _validYaml});

      final errors = (result['errors'] as List<dynamic>?) ?? [];
      expect(errors, isEmpty);
    });

    test('validate incomplete config returns errors', () async {
      final result = await harness.client
          .sendCommand('validate_workspace_config', {'yaml': _incompleteYaml});

      final errors = (result['errors'] as List<dynamic>?) ?? [];
      expect(errors, isNotEmpty);
    });

    test('encode config to YAML returns string', () async {
      final parsed =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      final encoded =
          await harness.client.encodeWorkspaceYaml(config: parsed);

      expect(encoded['yaml'], isA<String>());
      expect((encoded['yaml'] as String), isNotEmpty);
    });

    test('round-trip: parse → encode → parse → names match', () async {
      final first =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      final encoded =
          await harness.client.encodeWorkspaceYaml(config: first);
      final reEncoded = encoded['yaml'] as String;

      final second =
          await harness.client.parseWorkspaceConfig(yaml: reEncoded);

      expect(second['name'], equals(first['name']));
    });
  });
}
