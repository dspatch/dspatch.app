// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed accessors for Drift-generated data classes.
///
/// Drift stores dates as ISO 8601 strings and JSON as raw strings.
/// These extensions provide parsed, typed access without changing the
/// underlying Drift types or requiring a mapping layer.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../database/engine_database.dart';
import '../../models/enums.dart';
import '../utils/datetime_ext.dart';
import 'agent_state_ext.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

T _safeJsonDecode<T>(String? json, T fallback) {
  if (json == null || json.isEmpty) return fallback;
  try {
    return jsonDecode(json) as T;
  } catch (e) {
    assert(() {
      debugPrint('Failed to decode JSON: $e');
      return true;
    }());
    return fallback;
  }
}

// ── Workspace ──────────────────────────────────────────────────────────────

extension WorkspaceExt on Workspace {
  DateTime get createdAtDate => parseDate(createdAt);
  DateTime get updatedAtDate => parseDate(updatedAt);
}

// ── WorkspaceRun ───────────────────────────────────────────────────────────

extension WorkspaceRunExt on WorkspaceRun {
  DateTime get startedAtDate => parseDate(startedAt);
  DateTime? get stoppedAtDate =>
      stoppedAt != null ? parseDate(stoppedAt!) : null;

  bool get isActive => status == 'starting' || status == 'running';
  bool get isTerminal => status == 'stopped' || status == 'failed';
}

// ── WorkspaceAgent ─────────────────────────────────────────────────────────

extension WorkspaceAgentExt on WorkspaceAgent {
  DateTime get createdAtDate => parseDate(createdAt);
  DateTime get updatedAtDate => parseDate(updatedAt);

  List<String> get chain =>
      _safeJsonDecode<List<dynamic>>(chainJson, []).cast<String>();

  bool get isTerminal => status.isTerminal;
  bool get isWaiting => status.isWaiting;
  bool get isActive => status.isActive;
}

// ── AgentMessage ───────────────────────────────────────────────────────────

extension AgentMessageExt on AgentMessage {
  DateTime get createdAtDate => parseDate(createdAt);
}

// ── AgentLog ───────────────────────────────────────────────────────────────

extension AgentLogExt on AgentLog {
  DateTime get timestampDate => parseDate(timestamp);
}

// ── AgentActivityEvent ─────────────────────────────────────────────────────

extension AgentActivityEventExt on AgentActivityEvent {
  DateTime get timestampDate => parseDate(timestamp);
  Map<String, dynamic>? get data => _safeJsonDecode<Map<String, dynamic>?>(
      dataJson, null);
}

// ── AgentUsageRecord ───────────────────────────────────────────────────────

extension AgentUsageRecordExt on AgentUsageRecord {
  DateTime get timestampDate => parseDate(timestamp);
}

// ── AgentFile ──────────────────────────────────────────────────────────────

extension AgentFileExt on AgentFile {
  DateTime get timestampDate => parseDate(timestamp);
}

// ── WorkspaceInquiry ───────────────────────────────────────────────────────

extension WorkspaceInquiryExt on WorkspaceInquiry {
  DateTime get createdAtDate => parseDate(createdAt);
  DateTime? get respondedAtDate =>
      respondedAt != null ? parseDate(respondedAt!) : null;

  InquiryStatus get statusEnum =>
      InquiryStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => InquiryStatus.pending,
      );
  InquiryPriority get priorityEnum =>
      InquiryPriority.values.firstWhere(
        (e) => e.name == priority,
        orElse: () => InquiryPriority.normal,
      );

  bool get isPending => status == 'pending';
  bool get isResponded => status == 'responded';
  bool get isExpired => status == 'expired';
  bool get isDelivered => status == 'delivered';
  bool get isHighPriority => priority == 'high';

  List<dynamic>? get attachments =>
      _safeJsonDecode<List<dynamic>?>(attachmentsJson, null);
  List<String>? get suggestions =>
      _safeJsonDecode<List<dynamic>?>(suggestionsJson, null)?.cast<String>();
  List<String>? get forwardingChain =>
      _safeJsonDecode<List<dynamic>?>(forwardingChainJson, null)
          ?.cast<String>();
}

// ── AgentProvider ──────────────────────────────────────────────────────────

extension AgentProviderExt on AgentProvider {
  DateTime get createdAtDate => parseDate(createdAt);
  DateTime get updatedAtDate => parseDate(updatedAt);

  SourceType get sourceTypeEnum =>
      SourceType.values.firstWhere(
        (e) => e.name == sourceType,
        orElse: () => SourceType.local,
      );
  bool get isLocal => sourceType == 'local';
  bool get isGit => sourceType == 'git';
  bool get isHub => sourceType == 'hub';

  List<dynamic> get requiredEnv =>
      _safeJsonDecode<List<dynamic>>(requiredEnvJson, []);
  List<dynamic> get requiredMounts =>
      _safeJsonDecode<List<dynamic>>(requiredMountsJson, []);
  List<dynamic> get fields =>
      _safeJsonDecode<List<dynamic>>(fieldsJson, []);
  List<String> get hubTags =>
      _safeJsonDecode<List<dynamic>>(hubTagsJson, []).cast<String>();
}

// ── AgentTemplate ──────────────────────────────────────────────────────────

extension AgentTemplateExt on AgentTemplate {
  DateTime get createdAtDate => parseDate(createdAt);
  DateTime get updatedAtDate => parseDate(updatedAt);
}

// ── WorkspaceTemplate ──────────────────────────────────────────────────────

extension WorkspaceTemplateExt on WorkspaceTemplate {
  DateTime get createdAtDate => parseDate(createdAt);
  DateTime get updatedAtDate => parseDate(updatedAt);
}

// ── ApiKey ──────────────────────────────────────────────────────────────────

extension ApiKeyExt on ApiKey {
  DateTime get createdAtDate => parseDate(createdAt);
}
