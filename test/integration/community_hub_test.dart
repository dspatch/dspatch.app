// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/models/commands/commands.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

/// Sends a raw hub command and returns the response data as a map.
Future<Map<String, dynamic>> _hubRaw(
  TestHarness harness,
  String method, [
  Map<String, dynamic>? params,
]) async {
  final response = await harness.client.send(
    RawEngineCommand(method: method, params: params),
  );
  return response.data;
}

/// Runs a hub API test, skipping if the backend or hub API is unavailable.
Future<void> hubTest(
  TestHarness harness,
  Future<void> Function() body,
) async {
  if (!await harness.isBackendAvailable()) {
    markTestSkipped('Backend not available at localhost:3000');
    return;
  }
  try {
    await body();
  } on EngineException catch (e) {
    if (e.code == 'API_ERROR') {
      markTestSkipped('Hub API not available: ${e.message}');
      return;
    }
    rethrow;
  }
}

void main() {
  late TestHarness harness;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Community Hub browsing (requires localhost:3000)', () {
    test('browse agents returns paginated list', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_browse_agents',
          {'per_page': 5},
        );

        expect(result, contains('items'));
        expect(result['items'], isA<List>());
        if (result.containsKey('cursor')) {
          expect(result['cursor'], anyOf(isNull, isA<String>()));
        }
      });
    });

    test('browse agents with search filter', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_browse_agents',
          {'search': 'test', 'per_page': 5},
        );

        expect(result, contains('items'));
        expect(result['items'], isA<List>());
      });
    });

    test('browse agents with category filter', () async {
      await hubTest(harness, () async {
        // First get a valid category, then filter by it.
        final categories = await _hubRaw(
          harness,
          'hub_agent_categories',
        );
        expect(categories, contains('categories'));
        final categoryList = categories['categories'] as List;

        if (categoryList.isNotEmpty) {
          final firstCategory = categoryList.first as Map<String, dynamic>;
          final categorySlug = firstCategory['slug'] as String? ??
              firstCategory['name'] as String;

          final result = await _hubRaw(
            harness,
            'hub_browse_agents',
            {'category': categorySlug, 'per_page': 5},
          );

          expect(result, contains('items'));
          expect(result['items'], isA<List>());
        }
      });
    });

    test('browse agents pagination workflow', () async {
      await hubTest(harness, () async {
        // Fetch page 1 with a small page size.
        final page1 = await _hubRaw(
          harness,
          'hub_browse_agents',
          {'per_page': 1},
        );

        expect(page1, contains('items'));
        final items1 = page1['items'] as List;

        // If there is a cursor, fetch page 2 and verify it returns results.
        if (page1['cursor'] != null) {
          final page2 = await _hubRaw(
            harness,
            'hub_browse_agents',
            {'per_page': 1, 'cursor': page1['cursor'] as String},
          );

          expect(page2, contains('items'));
          final items2 = page2['items'] as List;

          // Page 2 should be different from page 1 (if items exist).
          if (items1.isNotEmpty && items2.isNotEmpty) {
            expect(items2.first, isNot(equals(items1.first)));
          }
        }
      });
    });

    test('browse workspaces returns paginated list', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_browse_workspaces',
          {'per_page': 5},
        );

        expect(result, contains('items'));
        expect(result['items'], isA<List>());
        if (result.containsKey('cursor')) {
          expect(result['cursor'], anyOf(isNull, isA<String>()));
        }
      });
    });

    test('get agent categories', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_agent_categories',
        );

        expect(result, contains('categories'));
        expect(result['categories'], isA<List>());
      });
    });

    test('get workspace categories', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_workspace_categories',
        );

        expect(result, contains('categories'));
        expect(result['categories'], isA<List>());
      });
    });

    test('resolve non-existent agent returns error', () async {
      await hubTest(harness, () async {
        expect(
          () => harness.client.send(
            RawEngineCommand(
              method: 'hub_resolve_agent',
              params: {'agent_id': 'nonexistent/agent-slug-xyz'},
            ),
          ),
          throwsA(
            isA<EngineException>().having(
              (e) => e.code,
              'code',
              isNotEmpty,
            ),
          ),
        );
      });
    });

    test('resolve non-existent workspace returns error', () async {
      await hubTest(harness, () async {
        expect(
          () => harness.client.send(
            RawEngineCommand(
              method: 'hub_resolve_workspace_details',
              params: {'slug': 'nonexistent/workspace-slug-xyz'},
            ),
          ),
          throwsA(
            isA<EngineException>().having(
              (e) => e.code,
              'code',
              isNotEmpty,
            ),
          ),
        );
      });
    });

    test('popular tags returns tag list', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_popular_tags',
        );

        expect(result, contains('tags'));
        expect(result['tags'], isA<List>());
      });
    });

    test('search tags returns results', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_search_tags',
          {'query': 'test'},
        );

        expect(result, contains('tags'));
        expect(result['tags'], isA<List>());
      });
    });

    test('search with nonsense query returns empty items', () async {
      await hubTest(harness, () async {
        final result = await _hubRaw(
          harness,
          'hub_browse_agents',
          {
            'search':
                'zzz-no-match-guaranteed-${DateTime.now().millisecondsSinceEpoch}',
            'per_page': 5,
          },
        );

        expect(result, contains('items'));
        expect(result['items'], isA<List>());
        expect((result['items'] as List), isEmpty);
      });
    });
  });
}
