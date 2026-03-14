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
      SECRET: hunter2
  helper:
    template: dspatch://agent/test/helper
    peers:
      - main
''';

const _invalidYaml = '{{{not valid yaml';

const _incompleteYaml = 'name: incomplete\n';

const _emptyYaml = '';

const _agentsOnlyYaml = '''
agents:
  main:
    template: dspatch://agent/test/echo
''';

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
    test('parse valid YAML returns config with name, agents, and details',
        () async {
      final result =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      expect(result['name'], equals('parse-test'));
      expect(result['agents'], isA<Map>());
      final agents = result['agents'] as Map;
      expect(agents, contains('main'));
      expect(agents, contains('helper'));

      // Verify agent details are parsed, not just keys.
      final mainAgent = agents['main'] as Map;
      expect(mainAgent['template'], equals('dspatch://agent/test/echo'));

      final helperAgent = agents['helper'] as Map;
      expect(helperAgent['template'], equals('dspatch://agent/test/helper'));
    });

    test('parse invalid YAML throws EngineException', () async {
      expect(
        () => harness.client.parseWorkspaceConfig(yaml: _invalidYaml),
        throwsA(isA<EngineException>()),
      );
    });

    test('parse empty YAML throws EngineException', () async {
      expect(
        () => harness.client.parseWorkspaceConfig(yaml: _emptyYaml),
        throwsA(isA<EngineException>()),
      );
    });

    test('validate valid config returns zero errors', () async {
      // Using raw sendCommand because the typed validateWorkspaceConfig()
      // wraps params under a `config` key, but the Rust command expects
      // `yaml: String` at the top level.
      final result = await harness.client
          .sendCommand('validate_workspace_config', {'yaml': _validYaml});

      final errors = (result['errors'] as List<dynamic>?) ?? [];
      expect(errors, isEmpty);
    });

    test('validate incomplete config (no agents) returns errors or rejects',
        () async {
      // _incompleteYaml has a name but no agents. Depending on the engine's
      // serde config, missing `agents` may cause a parse-time rejection
      // (EngineException) or pass parsing and produce validation errors.
      // We assert one specific outcome: a VALIDATION_ERROR exception,
      // because the engine's serde schema requires the agents field.
      expect(
        () => harness.client
            .sendCommand('validate_workspace_config', {'yaml': _incompleteYaml}),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            contains('VALIDATION_ERROR'),
          ),
        ),
      );
    });

    test('validate YAML with only agents (no name) fails', () async {
      expect(
        () => harness.client
            .sendCommand('validate_workspace_config', {'yaml': _agentsOnlyYaml}),
        throwsA(isA<EngineException>()),
      );
    });

    test('encode config to YAML returns non-empty string', () async {
      final parsed =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      // Using raw sendCommand because the typed encodeWorkspaceYaml()
      // wraps params under a `config` key, but the Rust command uses
      // #[serde(flatten)] and expects flat params at the top level.
      final encoded = await harness.client.sendCommand(
        'encode_workspace_yaml',
        parsed,
      );

      expect(encoded['yaml'], isA<String>());
      expect((encoded['yaml'] as String), isNotEmpty);
    });

    test('round-trip: parse -> encode -> parse preserves full config',
        () async {
      final first =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      // Encode using raw sendCommand (see comment in encode test above).
      final encoded = await harness.client.sendCommand(
        'encode_workspace_yaml',
        first,
      );
      final reEncodedYaml = encoded['yaml'] as String;

      final second =
          await harness.client.parseWorkspaceConfig(yaml: reEncodedYaml);

      // Workspace name survives round-trip.
      expect(second['name'], equals(first['name']));

      // Agent keys survive round-trip.
      final firstAgents = first['agents'] as Map;
      final secondAgents = second['agents'] as Map;
      expect(secondAgents.keys, unorderedEquals(firstAgents.keys));

      // Agent templates survive round-trip.
      for (final key in firstAgents.keys) {
        final firstAgent = firstAgents[key] as Map;
        final secondAgent = secondAgents[key] as Map;
        expect(secondAgent['template'], equals(firstAgent['template']),
            reason: 'template for agent "$key" should survive round-trip');
      }
    });

    test('round-trip preserves agent env vars', () async {
      final first =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      final encoded = await harness.client.sendCommand(
        'encode_workspace_yaml',
        first,
      );
      final reEncodedYaml = encoded['yaml'] as String;

      final second =
          await harness.client.parseWorkspaceConfig(yaml: reEncodedYaml);

      final firstMain = (first['agents'] as Map)['main'] as Map;
      final secondMain = (second['agents'] as Map)['main'] as Map;

      // Env vars on the main agent should survive round-trip.
      expect(secondMain['env'], isNotNull,
          reason: 'env map should survive round-trip');
      final firstEnv = firstMain['env'] as Map;
      final secondEnv = secondMain['env'] as Map;
      expect(secondEnv['API_KEY'], equals(firstEnv['API_KEY']));
      expect(secondEnv['SECRET'], equals(firstEnv['SECRET']));
    });

    test('round-trip preserves peer references', () async {
      final first =
          await harness.client.parseWorkspaceConfig(yaml: _validYaml);

      final encoded = await harness.client.sendCommand(
        'encode_workspace_yaml',
        first,
      );
      final reEncodedYaml = encoded['yaml'] as String;

      final second =
          await harness.client.parseWorkspaceConfig(yaml: reEncodedYaml);

      final firstHelper = (first['agents'] as Map)['helper'] as Map;
      final secondHelper = (second['agents'] as Map)['helper'] as Map;

      // Peer list on the helper agent should survive round-trip.
      expect(secondHelper['peers'], isNotNull,
          reason: 'peers list should survive round-trip');
      expect(secondHelper['peers'], equals(firstHelper['peers']));
    });
  });
}
