// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// d:spatch Rust SDK — Flutter bindings via flutter_rust_bridge.
///
/// This barrel file re-exports all generated types so consumers only need:
/// ```dart
/// import 'package:dspatch_sdk/dspatch_sdk.dart';
/// ```
library;

// FRB entrypoint (RustLib.init)
export 'src/generated/frb_generated.dart' show RustLib;

// SDK handle + bridge types
export 'src/generated/bridge/api.dart' show RustSdk, BridgePackageLogEntry;

// SDK enums
export 'src/generated/sdk.dart' show DatabaseReadyState;

// SDK event bus
export 'src/generated/server/event_bus.dart';

// Domain enums
export 'src/generated/domain/enums/agent_state.dart';
export 'src/generated/domain/enums/auth_mode.dart';
export 'src/generated/domain/enums/inquiry_priority.dart';
export 'src/generated/domain/enums/inquiry_status.dart';
export 'src/generated/domain/enums/log_level.dart';
export 'src/generated/domain/enums/log_source.dart';
export 'src/generated/domain/enums/platform_type.dart';
export 'src/generated/domain/enums/source_type.dart';
export 'src/generated/domain/enums/token_scope.dart';

// Domain models
export 'src/generated/domain/models/agent_activity.dart';
export 'src/generated/domain/models/agent_file.dart';
export 'src/generated/domain/models/agent_log.dart';
export 'src/generated/domain/models/agent_message.dart';
export 'src/generated/domain/models/agent_provider.dart';
export 'src/generated/domain/models/agent_template.dart';
export 'src/generated/domain/models/agent_usage.dart';
export 'src/generated/domain/models/api_key.dart';
export 'src/generated/domain/models/auth_state.dart';
export 'src/generated/domain/models/auth_tokens.dart';
export 'src/generated/domain/models/backup_codes_data.dart';
export 'src/generated/domain/models/create_agent_provider_request.dart';
export 'src/generated/domain/models/create_agent_template_request.dart';
export 'src/generated/domain/models/create_workspace_request.dart';
export 'src/generated/domain/models/device.dart';
export 'src/generated/domain/models/device_registration_request.dart';
export 'src/generated/domain/models/docker_status.dart';
export 'src/generated/domain/models/file_entry.dart';
export 'src/generated/domain/models/inquiry_with_workspace.dart';
export 'src/generated/domain/models/totp_setup_data.dart';
export 'src/generated/domain/models/update_agent_provider_request.dart';
export 'src/generated/domain/models/update_agent_template_request.dart';
export 'src/generated/domain/models/workspace.dart';
export 'src/generated/domain/models/workspace_agent.dart';
export 'src/generated/domain/models/workspace_inquiry.dart';
export 'src/generated/domain/models/workspace_run.dart';
export 'src/generated/domain/models/workspace_template.dart';

// Domain services (types exposed via API)
export 'src/generated/domain/services/docker.dart';

// Docker models
export 'src/generated/docker/models.dart';

// Hub models
export 'src/generated/hub/models.dart';

// Workspace config
export 'src/generated/workspace_config/config.dart';
export 'src/generated/workspace_config/validation.dart';
