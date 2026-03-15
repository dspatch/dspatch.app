// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Concrete local service implementations.
//!
//! Each struct wraps a DAO and/or other dependencies and exposes methods
//! matching the corresponding trait in [`crate::domain::services`].
//! Trait impls will be added later when the SDK facade wires everything up.

pub mod agent_data;
pub mod agent_provider;
pub mod agent_template;
pub mod api_key;

pub mod connectivity;
pub mod device;
pub mod docker;
pub mod file_browser;
pub mod inquiry;
pub mod preference;
pub mod sync;
pub mod workspace;
pub mod workspace_template;

pub use agent_data::LocalAgentDataService;
pub use agent_provider::LocalAgentProviderService;
pub use agent_template::LocalAgentTemplateService;
pub use api_key::LocalApiKeyService;

pub use connectivity::LocalConnectivityService;
pub use device::LocalDeviceService;
pub use docker::LocalDockerService;
pub use file_browser::LocalFileBrowserService;
pub use inquiry::LocalInquiryService;
pub use preference::LocalPreferenceService;
pub use sync::LocalSyncService;
pub use workspace::LocalWorkspaceService;
pub use workspace_template::LocalWorkspaceTemplateService;
