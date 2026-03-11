// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::pin::Pin;

use futures::Stream;

/// A boxed, pinned, Send stream — used as the Rust equivalent of Dart's `Stream<T>`.
pub type WatchStream<T> = Pin<Box<dyn Stream<Item = T> + Send>>;

pub mod agent_data;
pub mod agent_provider;
pub mod agent_template;
pub mod api_client;
pub mod api_key;
pub mod auth;
pub mod connectivity;
pub mod device;
pub mod docker;
pub mod file_browser;
pub mod inquiry;
pub mod notification;
pub mod preference;
pub mod sync;
pub mod workspace;
pub mod workspace_template;

pub use agent_data::AgentDataService;
pub use agent_provider::AgentProviderService;
pub use agent_template::AgentTemplateService;
pub use api_client::ApiClient;
pub use api_key::ApiKeyService;
pub use auth::AuthService;
pub use connectivity::ConnectivityService;
pub use device::DeviceService;
pub use docker::{ContainerSummary, DockerService};
pub use file_browser::FileBrowserService;
pub use inquiry::InquiryService;
pub use notification::NotificationService;
pub use preference::PreferenceService;
pub use sync::{SyncService, SyncState};
pub use workspace::WorkspaceService;
pub use workspace_template::WorkspaceTemplateService;
