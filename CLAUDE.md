# d:spatch Engine & App

The d:spatch platform consists of two components:

- **dspatch Engine** — a standalone Rust daemon (desktop) or in-process shared library (mobile) that owns all business logic, persistence, networking, and container orchestration. Exposes a client API over WebSocket.
- **Flutter App** — a thin Dart client (GUI today, CLI in the future) that reads the database directly via Drift (read-only) and sends commands to the engine over WebSocket.

Design doc: `docs/plans/2026-03-13-engine-architecture-design.md`
Implementation plan: `docs/plans/2026-03-13-engine-implementation-plan.md`

## Engine Architecture

The engine is the single authority over all data and logic. Nothing else writes to the database, manages Docker containers, communicates with agents, or handles P2P sync.

**Client API** — fixed port (default 9847). Single WebSocket connection (`ws://127.0.0.1:9847/ws`) carrying JSON commands (client → engine) and events/invalidations (engine → client). Public HTTP endpoints for auth bootstrap (`/auth/*`) and health (`/health`).

**Agent server** — dynamic port, serves Docker containers. Existing WebSocket server with wire protocol. Kept as-is.

**Table invalidation** — when the engine writes to the DB, it sends `{"type": "invalidate", "tables": [...]}` over WS. The Dart Engine Client calls `database.notifyUpdates(...)`, causing Drift to re-run active queries. UI rebuilds automatically.

**Shallow mode** — on devices without Docker (including mobile), the engine starts normally but refuses to create/launch local workspaces. Remote workspaces remain fully accessible.

**Process lifecycle** — Desktop: Flutter spawns engine as detached process, engine survives app close. Mobile: in-process shared library via `dart:ffi` (`start_engine`/`stop_engine`).

See the design doc for full details on multi-device routing, P2P sync, and auth flow.

### Engine crate structure (`packages/dspatch_sdk/`)

The Rust engine crate lives at `packages/dspatch_sdk/`. Key modules:

- **`src/engine/`** — engine daemon core
  - `config.rs` — `EngineConfig` with hardcoded defaults (port 9847, `~/.dspatch/data`, etc.)
  - `startup.rs` — `EngineRuntime` (uptime, shutdown broadcast, optional `ServiceRegistry`), `init_tracing()`, `open_database()`, `wait_for_shutdown_signal()`
  - `service_registry.rs` — `ServiceRegistry` — centralized access to all `Local*Service` instances, created from `Arc<Database>` + `data_dir`
- **`src/client_api/`** — axum HTTP/WebSocket server for client-facing API
  - `health.rs` — `GET /health` (always public, returns JSON status including auth state)
  - `auth.rs` — `POST /auth/anonymous`, `/auth/login`, `/auth/register` (session token issuance)
  - `session.rs` — `SessionStore` (in-memory token → session mapping), `AuthMode`, `Session`
  - `protocol.rs` — `ClientFrame` / `ServerFrame` JSON wire protocol types for WS
  - `commands.rs` — `Command` enum with 50+ variants using `#[serde(tag = "method")]` for typed dispatch
  - `dispatch.rs` — `dispatch_command()` routes `Command` to `ServiceRegistry` methods, returns `serde_json::Value`
  - `error_mapping.rs` — `error_to_code()` / `error_to_frame()` maps `AppError` to wire error codes
  - `ws.rs` — `GET /ws?token=...` WebSocket endpoint with session validation, welcome event, real command dispatch, ping keepalive, table invalidation broadcast, ephemeral event forwarding
  - `server.rs` — `build_router()`, `start_client_api()` with graceful shutdown
  - `invalidation.rs` — `InvalidationBroadcaster` / `InvalidationHandle` — debounced aggregation of `TableChangeTracker` notifications into batched `Vec<String>` for WS clients
  - `ephemeral.rs` — `EphemeralEventEmitter` — broadcast channel for engine lifecycle events (`engine_shutting_down`, `p2p_connected`, etc.)
- **`src/bin/dspatch_engine.rs`** — engine daemon binary entry point (`cargo run --bin dspatch-engine`), wires `InvalidationBroadcaster` from DB tracker
- **`src/db/`** — database layer (schema, migrations, DAOs, shared helpers)
  - `optional_ext.rs` — shared `OptionalExt` trait for `QueryReturnedNoRows` → `Ok(None)`
  - `col.rs` — shared `col()` helper for typed column extraction with error mapping
  - `update_builder.rs` — shared `maybe_set!` / `maybe_set_json!` macros for dynamic UPDATE clauses
  - `schema.rs` — table constants via `include_str!` from `shared/schema/*.sql`
  - `migrations.rs` — incremental migrations (current: v11)
- **`src/util/`** — utilities (`id.rs` for `new_id()` UUID generation, `error.rs`, `result.rs`)
- **`shared/schema/`** — 27 `.sql` files (one per table), shared between Rust and Dart

**Test runner:** `cargo test --lib --tests` (from crate root)

### Engine interaction

**All business logic belongs in the Rust engine, not in the Flutter app.** The engine is shared across all clients — any logic placed in the Flutter layer would be unavailable to other clients. The Flutter app contains ONLY UI/UX code: rendering, navigation, user interaction, and presentation logic.

- **Writes** — send commands to the engine via the Engine Client (`lib/engine_client/`) over WebSocket
- **Reads** — query the SQLite database directly via Drift (read-only mode)
- **Reactivity** — table invalidation events from the engine trigger Drift re-queries

If you find yourself writing business logic (validation, data transformation, orchestration, etc.) in the Flutter app, it likely belongs in the engine instead.

### Layer boundaries

- **features/** — self-contained feature modules. May import from `core/`, `shared/`, `di/`, and packages — but NOT from other features.
- **di/providers.dart** — all global Riverpod providers. Feature-specific controllers use `@riverpod` annotation and live in their feature directory.
- **core/** — pure utilities and extensions. No Flutter widget imports, no feature imports.
- **shared/** — widgets reused across multiple features. If a widget is only used in one feature, it belongs in that feature's `widgets/` directory.

## UI Components

**Always use `dspatch_ui` components.** Never use raw Material widgets when a dspatch_ui equivalent exists.

### Component lookup order

1. **Check if the app already has a widget** built from dspatch_ui components for the required purpose (in the relevant feature's `widgets/` or in `shared/`)
2. **If not, use an existing one or build a new one** from dspatch_ui components
3. **If the needed component is generic** (useful outside this app's domain), add it to `packages/dspatch_ui/` in a generalized form and use it from there

Import: `package:dspatch_ui/dspatch_ui.dart`

Key components: Button, Input, DspatchCard, DspatchTabs, DspatchBadge, EmptyState, Spinner, Alert, DspatchDialog, TerminalLogView, ErrorStateView, CopyButton, Select, Field, Separator, Progress, Sidebar, Breadcrumb, CodeEditor, ConfirmDialog, Sheet, Tooltip, Toggle, ToggleGroup, and more.

Theme constants: `AppColors`, `AppFonts` (DM Sans / DM Mono), `Spacing` (xs/sm/md/lg/xl/xxl), `AppRadius`.

See `packages/dspatch_ui/lib/dspatch_ui.dart` for the full export list.

## State Management (Riverpod)

- **Reactive DB data** — `StreamProvider` backed by Drift `watch` queries on the read-only database. Table invalidation events from the engine trigger re-queries automatically.
- **Engine events** — ephemeral engine lifecycle events (shutdown, P2P connection status) received over WebSocket. Not persisted.
- **Ephemeral UI state** — `StateProvider` for transient state like search queries, filters, selected items. These live in `di/providers.dart`.
- **Feature controllers** — Use `@riverpod` annotation (Riverpod generator) for feature-specific async logic. These live in `features/{name}/` alongside their `.g.dart` files.
- **Provider disposal** — Use `.autoDispose` for all providers tied to specific screens to avoid leaking listeners.

## Error Handling

- **Never show raw errors to the user.** Display a meaningful, human-readable message. Raw error details go into the clipboard-copied content only (for debugging).
- **All error messages must be copyable.** Use `ErrorStateView` (includes SelectableText + CopyButton + optional Retry) for error states. Use `toast()` with `type: ToastType.error` for transient errors.
- **Clipboard content includes raw error** — When the user copies an error, include the full technical details (stack trace, error type) so they can share it for debugging.
- **Retry where possible** — Provide a retry callback in `ErrorStateView.onRetry` for recoverable errors.
- **Wrap engine commands** in try/catch at the controller/screen level. Translate exceptions into user-friendly messages.

## Wire Protocol

**`docs/architecture/PACKAGES.md` is the single source of truth** for the wire protocol.

- **NEVER deviate** from the protocol without presenting the problem and proposed changes first.
- **Wait for explicit approval** before making any protocol changes.
- Any approved deviation MUST be documented in the code with rationale.

## Code Style

### Self-documenting code

- Write code that reads clearly without needing comments for basic logic.
- **Document architectural decisions** inline where relevant — the code serves as living documentation.
- **Document non-obvious bug fixes** — If a fix requires doing something unexpected or specific, add a comment explaining the reasoning and rationale. This prevents unintentional regressions.
- **`// TODO:`** — All unfinished work, known limitations, or planned improvements MUST be marked with a `// TODO:` comment.

### Conventions

- Standard Dart/Flutter naming conventions (lowerCamelCase for variables/functions, UpperCamelCase for types)
- Screens: `*_screen.dart`, widgets: descriptive names in `widgets/` subdirectory
- Controllers: `*_controller.dart` with `@riverpod` annotation
- Copyright header: `// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.`

## Git Rules

- **Commit after each logical unit of work** (usually one step in an implementation plan).
- **Use specific `git add`** — never `git add -A` or `git add .`.
- **NEVER sign commits as Claude** — no `Co-Authored-By` lines, no Claude attribution in commits.
- **Commit messages** — concise, imperative mood, describing what changed and why.
- **NEVER delete git worktrees** — under no circumstances, not even after merging, not even when instructed to. Instead, provide the exact commands for the user to run themselves.

## Design Principles

- **No hacky solutions.** If an existing architecture or design doesn't fit, stop and re-evaluate. Refactor properly to account for the unexpected — don't patch around it.
- **Service boundaries** — Wrap related code/logic in services with distinct boundaries. Use streams or event-driven delegation for loose coupling between services.
- **Testable architecture** — Keep logic separated from UI. Controllers handle business logic; widgets handle presentation.
- **YAGNI** — Don't build for hypothetical futures. Solve the current problem well.
- **Best practices always** — Apply SOLID principles, DRY (but don't over-abstract), and clean architecture patterns thoughtfully.
- **Refactor when needed** — If development reveals a miscalculation or misdesign, re-evaluate the architecture first. Then refactor to properly account for it before continuing.
- **Engine is single writer** — only the engine writes to the database. Clients read via Drift in read-only mode. All mutations go through engine commands.
- **Commands over WebSocket** — all client→engine communication uses the WS command protocol. No direct DB writes, no direct service calls.
- **Table invalidation for reactivity** — clients never poll. The engine pushes invalidation events, Drift re-queries, UI rebuilds.
