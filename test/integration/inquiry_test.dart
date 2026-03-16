// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'package:dspatch_app/engine_client/engine_client.dart';
import 'package:dspatch_app/models/commands/commands.dart';
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
        () => harness.client.send(RespondToInquiry(
          inquiryId: 'nonexistent-inquiry-id',
          response: 'yes',
        )),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            contains('NOT_FOUND'),
          ),
        ),
      );
    });

    test('empty response to non-existent inquiry returns NOT_FOUND', () async {
      expect(
        () => harness.client.send(RespondToInquiry(
          inquiryId: 'nonexistent-inquiry-id',
          response: '',
        )),
        throwsA(
          isA<EngineException>().having(
            (e) => e.code,
            'code',
            contains('NOT_FOUND'),
          ),
        ),
      );
    });

    test('negative choice index to non-existent inquiry returns NOT_FOUND',
        () async {
      expect(
        () => harness.client.send(RespondToInquiry(
          inquiryId: 'nonexistent-inquiry-id',
          response: 'pick',
          choiceIndex: -1,
        )),
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
    // (requires Docker + running agent or a test-only seed command).
    // Scenarios to cover once seeding is available:
    // - Respond to a pending inquiry -> verify it is marked resolved
    // - Respond with a valid choiceIndex -> verify correct choice recorded
    // - Respond to an already-resolved inquiry -> expect CONFLICT or similar
    // - Respond with out-of-bounds choiceIndex -> expect validation error
  });
}
