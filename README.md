<div align="center">
  <br />
  <img src="https://dspatch.dev/fulllogo.png" alt="d:spatch" width="400" />
  <br /><br />
  <strong>Autonomous AI × Engineering</strong>
  <br /><br />
  <a href="https://dspatch.dev/"><img src="https://img.shields.io/badge/Website-c4f042?style=for-the-badge" alt="Website" /></a>
  &nbsp;
  <a href="https://dspatch.dev/docs"><img src="https://img.shields.io/badge/Docs-c4f042?style=for-the-badge" alt="Docs" /></a>
  &nbsp;
  <a href="https://dspatch.dev/"><img src="https://img.shields.io/badge/Early_Access-c4f042?style=for-the-badge" alt="Early Access" /></a>
  <br /><br />
  <sub>Open-source cross-platform app for the d:spatch agent orchestration platform.<br />End-to-end encrypted · Zero cloud dependency.</sub>
  <br /><br />

  <img src="https://img.shields.io/badge/Rust-1a1a2e?style=for-the-badge&logo=rust&logoColor=white" alt="Rust" />
  &nbsp;
  <img src="https://img.shields.io/badge/Flutter-1a1a2e?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  &nbsp;
  <img src="https://img.shields.io/badge/Docker-1a1a2e?style=for-the-badge&logo=docker&logoColor=white" alt="Docker" />
  &nbsp;
  <img src="https://img.shields.io/badge/Python_SDK-1a1a2e?style=for-the-badge&logo=python&logoColor=white" alt="Python SDK" />
  <br /><br />
</div>

> **Early Access** — d:spatch is under active development and **not yet stable**. Core features like workspace management, agent orchestration, Docker isolation, real-time monitoring, and the CLI are functional enough enough to explore, experiment, and get a feel for what it's building toward — but not all features are complete, and the experience will be polished going forward. Additional capabilities (multi-device networking, scheduling) are rolling out in upcoming releases. Expect rough edges — that said, we'd love for you to try it out, break things, and share your feedback!

---

<!-- TODO: Replace with actual screenshot of the workspace view showing agent hierarchy + timeline -->
<!-- Ideal size: 1200x750, showing a running workspace with agents in the sidebar and the timeline/logs in the main panel -->
<!-- ![d:spatch workspace view](docs/screenshots/workspace.png) -->

## What is d:spatch?

d:spatch is a cross-platform app that lets you build your own secure network of trusted devices and deploy, monitor, and control AI agents on any of them — from any of them. All device-to-device communication is end-to-end encrypted with the Signal protocol.

Define shared workspaces with multi-level agent teams, endless hierarchies, and arbitrary horizontal cross-communication. Every agent runs in an isolated Docker container with Docker-in-Docker and full root access. Easily integrate any model, agent, or framework using the [Agent SDK](https://github.com/dspatch/sdk.python). d:spatch manages everything else: logging, monitoring, lifecycle, checkpointing, inter-agent communication, and recovery.

No cloud required. No API keys leave your network.

### Secure Device Network

- **Trusted devices** — Link your machines into a private, encrypted mesh. Deploy agents to any device and manage them from any other <img src="https://img.shields.io/badge/coming_soon-grey" alt="Coming soon" height="16" />
- **E2E encryption** — All device-to-device communication uses the Signal protocol. Your data never touches a third-party server <img src="https://img.shields.io/badge/coming_soon-grey" alt="Coming soon" height="16" />
- **Agent & LLM exposure** — Expose any agent or LLM endpoint across your devices over E2E encrypted relays. No port forwarding, no cloud — just your hardware, accessible from anywhere <img src="https://img.shields.io/badge/coming_soon-grey" alt="Coming soon" height="16" />
- **Cross-platform** — Windows and macOS today. Linux, iOS, Android coming soon

### Agent Workspaces

- **Multi-level teams** — Define shared workspaces with endless agent hierarchies — supervisor/worker trees of any depth. Supervisors orchestrate, delegate, and escalate while workers execute
- **Cross-communication** — Agents talk to each other freely across the hierarchy via the IAC protocol — one-to-one, group chats, and interrupts. No rigid tree constraints
- **Inquiry system** — Agents escalate decisions up the hierarchy with structured context and suggestions. Unresolved inquiries bubble up as push notifications to your devices
- **Scheduling & delegation** — Schedule recurring jobs and delegate tasks to specific agents or teams, all tracked on a shared timeline <img src="https://img.shields.io/badge/coming_soon-grey" alt="Coming soon" height="16" />

### Execution & Isolation

- **Docker sandbox** — Every agent runs in an isolated container with Docker-in-Docker and full root access. Agents install, build, and run freely — your host stays sealed
- **Agent SDK** — Easily integrate any model, any agent framework, any stack. d:spatch manages the rest: logging, monitoring, lifecycle, checkpointing, inter-agent communication, and recovery. See the [Python SDK](https://github.com/dspatch/sdk.python)
- **CLI** — Everything the app can do, headless. Automate deployments, integrate into CI/CD pipelines, or run d:spatch on machines without a display

### Monitoring & Control

- **Real-time observability** — Live logs, messages, events, file browsing, and per-agent token usage in one dashboard
- **File browser** — Inspect what your agents are building. View files and contents of any workspace in real time

### Community Hub

- **Browse & install** — Discover agents and workspaces shared by the community, with ratings and reviews
- **Share your work** — Publish your own agent integrations and workspace templates for others to use
- **Build your own agents** — The [Agent SDK](https://github.com/dspatch/sdk.python) makes it easy to wrap any model or framework into a d:spatch agent. Follow the [integration guide](https://dspatch.dev/docs) to get started

> For the full feature list see [dspatch.dev](https://dspatch.dev/#features).

---

## Getting Started

See the full [Getting Started guide](https://dspatch.dev/docs/latest/getting-started) for detailed setup instructions.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running on your machine

### Download

Pre-built binaries for Windows and macOS are available on the [Releases](../../releases) page. More platforms coming soon.

---

## Development

The d:spatch platform consists of two main components:

- **Flutter App** — The cross-platform GUI, a thin wrapper around the Rust SDK via [flutter_rust_bridge](https://github.com/aspect-build/rules_swc)
- **Rust SDK & CLI** (`packages/dspatch-sdk/`) — The core library and standalone CLI binary, written entirely in Rust

### CLI (Rust)

The CLI is a standalone Rust binary. To build and run:

```bash
cd packages/dspatch-sdk
cargo build --release
# Binary is at target/release/dspatch-cli
```

To run directly during development:

```bash
cargo run --bin dspatch-cli -- <command>
```

### Flutter App

Requires [Flutter](https://docs.flutter.dev/get-started/install) (3.11+) and [Rust](https://rustup.rs/) toolchain.

```bash
git clone https://github.com/dspatch/dspatch.app.git
cd dspatch.app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

> **Note:** The Flutter app depends on the Rust SDK via flutter_rust_bridge. The Rust code is compiled automatically as part of the Flutter build process.

---

## Community

### Build & Share Agents

The easiest way to get involved is by building and sharing agent integrations on the Community Hub:

1. **Read the guide** — [Getting Started](https://dspatch.dev/docs/latest/getting-started) and the [Agent SDK docs](https://dspatch.dev/docs/latest/agent-sdk) walk you through creating your first agent
2. **Use the Python SDK** — [`pip install dspatch-sdk`](https://github.com/dspatch/sdk.python) to get started
3. **Publish to the Hub** — Share your agent with the community directly from the app

### Report Issues & Request Features

Found a bug? Have an idea? We want to hear it:

- **Bug reports** — [Open a bug report](../../issues/new?template=bug_report.md)
- **Feature requests** — [Request a feature](../../issues/new?template=feature_request.md)
- **Agent ideas** — [Suggest an agent integration](../../issues/new?template=agent_integration.md)
- **Questions & discussion** — [Start a discussion](../../discussions)

---

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE).

### Commercial Licensing

If you or your organization would like to use d:spatch under terms other than the AGPL-3.0 (e.g., for proprietary or commercial use), commercial licenses are available. Contact **oakisnotree** for details.

## Trademark Notice

**d:spatch** is a trademark of Osman Alperen Çinar-Koraş (oakisnotree). This license grants rights to the source code only — it does not grant permission to use the d:spatch name, logo, or branding in derivative works or products without prior written consent.

---

<div align="center">
  <sub>Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). All rights reserved.</sub>
</div>
