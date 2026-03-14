// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for agent interaction and instance lifecycle.
///
/// Bug fixes:
/// - `interrupt_instance`: adds missing `agent_key`
/// - `stop_instance`: adds missing `agent_key`
/// - `cleanup_stale_instances`: adds missing `workspace_id`
library;

import 'command.dart';

class SendAgentInput extends VoidEngineCommand {
  SendAgentInput({
    required this.runId,
    required this.instanceId,
    required this.text,
  });
  final String runId;
  final String instanceId;
  final String text;

  @override
  String get method => 'send_user_input_to_agent';

  @override
  Map<String, dynamic> get params => {
        'run_id': runId,
        'instance_id': instanceId,
        'text': text,
      };
}

class RespondToInquiry extends VoidEngineCommand {
  RespondToInquiry({
    required this.inquiryId,
    required this.response,
    this.choiceIndex,
  });
  final String inquiryId;
  final String response;
  final int? choiceIndex;

  @override
  String get method => 'respond_to_inquiry';

  @override
  Map<String, dynamic> get params => {
        'inquiry_id': inquiryId,
        'response': response,
        if (choiceIndex != null) 'choice_index': choiceIndex,
      };
}

class StartRootInstance extends VoidEngineCommand {
  StartRootInstance({required this.runId, required this.agentKey});
  final String runId;
  final String agentKey;

  @override
  String get method => 'start_root_instance';

  @override
  Map<String, dynamic> get params => {
        'run_id': runId,
        'agent_key': agentKey,
      };
}

class StartSubInstance extends VoidEngineCommand {
  StartSubInstance({
    required this.runId,
    required this.agentKey,
    required this.parentInstanceId,
  });
  final String runId;
  final String agentKey;
  final String parentInstanceId;

  @override
  String get method => 'start_sub_instance';

  @override
  Map<String, dynamic> get params => {
        'run_id': runId,
        'agent_key': agentKey,
        'parent_instance_id': parentInstanceId,
      };
}

/// Bug fix: adds missing `agent_key` parameter.
class StopInstance extends VoidEngineCommand {
  StopInstance({
    required this.runId,
    required this.agentKey,
    required this.instanceId,
  });
  final String runId;
  final String agentKey;
  final String instanceId;

  @override
  String get method => 'stop_instance';

  @override
  Map<String, dynamic> get params => {
        'run_id': runId,
        'agent_key': agentKey,
        'instance_id': instanceId,
      };
}

/// Bug fix: adds missing `agent_key` parameter.
class InterruptInstance extends VoidEngineCommand {
  InterruptInstance({
    required this.runId,
    required this.agentKey,
    required this.instanceId,
  });
  final String runId;
  final String agentKey;
  final String instanceId;

  @override
  String get method => 'interrupt_instance';

  @override
  Map<String, dynamic> get params => {
        'run_id': runId,
        'agent_key': agentKey,
        'instance_id': instanceId,
      };
}

/// Bug fix: adds missing `workspace_id` parameter.
class CleanupStaleInstances extends VoidEngineCommand {
  CleanupStaleInstances({
    required this.workspaceId,
    required this.runId,
  });
  final String workspaceId;
  final String runId;

  @override
  String get method => 'cleanup_stale_instances';

  @override
  Map<String, dynamic> get params => {
        'workspace_id': workspaceId,
        'run_id': runId,
      };
}

class PackageInspectorEntries extends VoidEngineCommand {
  PackageInspectorEntries({required this.runId});
  final String runId;

  @override
  String get method => 'package_inspector_entries';

  @override
  Map<String, dynamic> get params => {'run_id': runId};
}
