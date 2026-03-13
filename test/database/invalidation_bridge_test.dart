import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dspatch_app/database/invalidation_bridge.dart';

void main() {
  group('InvalidationBridge', () {
    test('forwards invalidation events to the database', () {
      final receivedInvalidations = <List<String>>[];
      final controller = StreamController<List<String>>();

      final bridge = InvalidationBridge(
        invalidationStream: controller.stream,
        onInvalidation: (tables) => receivedInvalidations.add(tables),
      );

      bridge.start();

      controller.add(['workspaces']);
      controller.add(['agent_messages', 'workspace_runs']);

      // Use a timer to let the stream events propagate.
      return Future.delayed(const Duration(milliseconds: 50), () {
        expect(receivedInvalidations, hasLength(2));
        expect(receivedInvalidations[0], ['workspaces']);
        expect(receivedInvalidations[1], ['agent_messages', 'workspace_runs']);

        bridge.dispose();
        controller.close();
      });
    });

    test('dispose cancels the subscription', () async {
      final receivedInvalidations = <List<String>>[];
      final controller = StreamController<List<String>>();

      final bridge = InvalidationBridge(
        invalidationStream: controller.stream,
        onInvalidation: (tables) => receivedInvalidations.add(tables),
      );

      bridge.start();
      controller.add(['workspaces']);
      await Future.delayed(const Duration(milliseconds: 50));

      bridge.dispose();

      // Events after dispose should be ignored.
      controller.add(['agent_messages']);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedInvalidations, hasLength(1));

      controller.close();
    });

    test('can be started and disposed multiple times', () {
      final controller = StreamController<List<String>>.broadcast();

      final bridge = InvalidationBridge(
        invalidationStream: controller.stream,
        onInvalidation: (_) {},
      );

      bridge.start();
      bridge.dispose();
      bridge.start();
      bridge.dispose();

      controller.close();
    });
  });
}
