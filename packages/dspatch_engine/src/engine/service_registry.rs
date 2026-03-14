// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Centralized access to all initialized service instances.
//!
//! Created once after the database is opened and migrations are complete.
//! Passed to the command dispatcher (via `Arc`) so every command can access
//! the service it needs without re-initialization.

use std::path::PathBuf;
use std::sync::Arc;

use tokio::sync::Mutex as TokioMutex;

use crate::crypto::AesGcmCrypto;
use crate::crypto::KeyringSecretStore;
use crate::db::Database;
use crate::db::dao::agent_provider_dao::AgentProviderDao;
use crate::db::dao::agent_template_dao::AgentTemplateDao;
use crate::db::dao::api_key_dao::ApiKeyDao;
use crate::db::dao::preference_dao::PreferenceDao;
use crate::db::dao::workspace_dao::WorkspaceDao;
use crate::db::dao::workspace_template_dao::WorkspaceTemplateDao;
use crate::docker::DockerClient;
use crate::domain::services::{AgentProviderService, ApiKeyService, DockerService};
use crate::hub::HubApiClient;
use crate::server::agent_server::EmbeddedAgentServer;
use crate::server::workspace_bridge::WorkspaceBridge;
use crate::services::{
    LocalAgentDataService, LocalAgentProviderService, LocalAgentTemplateService,
    LocalApiKeyService, LocalDockerService, LocalFileBrowserService, LocalInquiryService,
    LocalPreferenceService, LocalWorkspaceService, LocalWorkspaceTemplateService,
};

/// Holds `Arc`-wrapped instances of all local services.
///
/// Constructed once at engine startup. Shared with the command dispatcher
/// via `Arc<ServiceRegistry>`.
pub struct ServiceRegistry {
    workspaces: Arc<LocalWorkspaceService>,
    agent_providers: Arc<LocalAgentProviderService>,
    agent_templates: Arc<LocalAgentTemplateService>,
    workspace_templates: Arc<LocalWorkspaceTemplateService>,
    api_keys: Arc<LocalApiKeyService>,
    preferences: Arc<LocalPreferenceService>,
    inquiries: Arc<LocalInquiryService>,
    agent_data: Arc<LocalAgentDataService>,
    crypto: Arc<AesGcmCrypto>,
    file_browser: Arc<LocalFileBrowserService>,
    docker: Arc<DockerClient>,
    hub_client: Option<Arc<HubApiClient>>,
}

impl ServiceRegistry {
    /// Creates all services from the given database, wiring the workspace
    /// bridge immediately so that launch/stop commands work from startup.
    ///
    /// `hub_client` is optional — when provided, hub commands are dispatched
    /// to the backend API; otherwise they return `API_ERROR`.
    pub fn new(
        db: Arc<Database>,
        data_dir: PathBuf,
        hub_client: Option<Arc<HubApiClient>>,
    ) -> Self {
        let workspace_dao = Arc::new(WorkspaceDao::new(db.clone()));
        let agent_provider_dao = Arc::new(AgentProviderDao::new(db.clone()));
        let agent_template_dao = Arc::new(AgentTemplateDao::new(db.clone()));
        let workspace_template_dao = Arc::new(WorkspaceTemplateDao::new(db.clone()));
        let api_key_dao = Arc::new(ApiKeyDao::new(db.clone()));
        let preference_dao = Arc::new(PreferenceDao::new(db.clone()));

        // Crypto: uses the platform keyring for master key storage.
        let secret_store: Arc<dyn crate::db::key_manager::SecretStore> =
            Arc::new(KeyringSecretStore::new("dspatch"));
        let crypto = Arc::new(AesGcmCrypto::new(secret_store));

        // File browser: default root is the data_dir (overridden per-workspace at usage site).
        let file_browser = Arc::new(LocalFileBrowserService::new(
            data_dir.to_string_lossy().to_string(),
        ));

        // Docker: uses the default platform Docker CLI.
        let docker = Arc::new(DockerClient::for_platform());

        // Agent-facing server (created but not started — the bridge starts it on demand).
        let agent_server = Arc::new(TokioMutex::new(EmbeddedAgentServer::new(
            Arc::clone(&workspace_dao),
            Arc::clone(&docker),
        )));

        // Docker service for status detection (assets_dir only needed for image builds).
        let docker_service: Arc<dyn DockerService> = Arc::new(LocalDockerService::new(
            DockerClient::for_platform(),
            data_dir.to_string_lossy().to_string(),
        ));

        // Wire the workspace bridge so launch/stop commands work immediately.
        let agent_providers = Arc::new(LocalAgentProviderService::new(agent_provider_dao));
        let api_keys = Arc::new(LocalApiKeyService::new(api_key_dao));

        let ws_bridge = WorkspaceBridge::new(
            agent_server,
            Arc::clone(&workspace_dao),
            Arc::clone(&agent_providers) as Arc<dyn AgentProviderService>,
            Arc::clone(&api_keys) as Arc<dyn ApiKeyService>,
            Arc::clone(&crypto),
            Arc::clone(&docker),
            docker_service,
            Arc::clone(&preference_dao),
        );
        let bridge = Arc::new(TokioMutex::new(Some(ws_bridge)));

        Self {
            workspaces: Arc::new(LocalWorkspaceService::new(
                workspace_dao.clone(),
                bridge,
            )),
            agent_providers,
            agent_templates: Arc::new(LocalAgentTemplateService::new(
                agent_template_dao,
                data_dir,
            )),
            workspace_templates: Arc::new(LocalWorkspaceTemplateService::new(
                workspace_template_dao,
            )),
            api_keys,
            preferences: Arc::new(LocalPreferenceService::new(preference_dao)),
            inquiries: Arc::new(LocalInquiryService::new(workspace_dao.clone())),
            agent_data: Arc::new(LocalAgentDataService::new(workspace_dao)),
            crypto,
            file_browser,
            docker,
            hub_client,
        }
    }

    pub fn workspaces(&self) -> &Arc<LocalWorkspaceService> {
        &self.workspaces
    }

    pub fn agent_providers(&self) -> &Arc<LocalAgentProviderService> {
        &self.agent_providers
    }

    pub fn agent_templates(&self) -> &Arc<LocalAgentTemplateService> {
        &self.agent_templates
    }

    pub fn workspace_templates(&self) -> &Arc<LocalWorkspaceTemplateService> {
        &self.workspace_templates
    }

    pub fn api_keys(&self) -> &Arc<LocalApiKeyService> {
        &self.api_keys
    }

    pub fn preferences(&self) -> &Arc<LocalPreferenceService> {
        &self.preferences
    }

    pub fn inquiries(&self) -> &Arc<LocalInquiryService> {
        &self.inquiries
    }

    pub fn agent_data(&self) -> &Arc<LocalAgentDataService> {
        &self.agent_data
    }

    pub fn crypto(&self) -> &Arc<AesGcmCrypto> {
        &self.crypto
    }

    pub fn file_browser(&self) -> &Arc<LocalFileBrowserService> {
        &self.file_browser
    }

    pub fn docker(&self) -> &Arc<DockerClient> {
        &self.docker
    }

    pub fn hub_client(&self) -> Option<&Arc<HubApiClient>> {
        self.hub_client.as_ref()
    }
}
