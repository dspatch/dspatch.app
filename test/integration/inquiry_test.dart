// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  late TestHarness harness;

  setUpAll(() async {
    harness = TestHarness.fromEnv();
    await harness.setUp();
  });

  tearDownAll(() async {
    await harness.tearDown();
  });

  group('Inquiry response', () {
    test('respond to non-existent inquiry returns NOT_FOUND', () async {
      expect(
        () => harness.client.respondToInquiry(
          inquiryId: 'nonexistent-inquiry-id',
          response: 'yes',
        ),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            contains('NOT_FOUND'),
          ),
        ),
      );
    });

    test('respond with choice_index to non-existent returns NOT_FOUND',
        () async {
      expect(
        () => harness.client.respondToInquiry(
          inquiryId: 'nonexistent',
          response: '',
          choiceIndex: 0,
        ),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            contains('NOT_FOUND'),
          ),
        ),
      );
    });

    // TODO: Add happy-path tests when we have a way to seed pending inquiries
    // (requires Docker + running agent or a test-only seed command)
  });
}
