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
use crate::services::{
    LocalAgentDataService, LocalAgentProviderService, LocalAgentTemplateService,
    LocalApiKeyService, LocalFileBrowserService, LocalInquiryService, LocalPreferenceService,
    LocalWorkspaceService, LocalWorkspaceTemplateService,
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
}

impl ServiceRegistry {
    /// Creates all services from the given database.
    ///
    /// DAOs are constructed internally — callers only need the `Database`
    /// and a `data_dir` path (used by `LocalAgentTemplateService` to
    /// locate template files on disk).
    pub fn new(db: Arc<Database>, data_dir: PathBuf) -> Self {
        let workspace_dao = Arc::new(WorkspaceDao::new(db.clone()));
        let agent_provider_dao = Arc::new(AgentProviderDao::new(db.clone()));
        let agent_template_dao = Arc::new(AgentTemplateDao::new(db.clone()));
        let workspace_template_dao = Arc::new(WorkspaceTemplateDao::new(db.clone()));
        let api_key_dao = Arc::new(ApiKeyDao::new(db.clone()));
        let preference_dao = Arc::new(PreferenceDao::new(db.clone()));

        // WorkspaceBridge is None — the engine wires it separately when
        // the agent-facing server starts (post-auth). Commands that need
        // the bridge (launch, stop) will fail gracefully until then.
        let bridge = Arc::new(TokioMutex::new(None));

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

        Self {
            workspaces: Arc::new(LocalWorkspaceService::new(
                workspace_dao.clone(),
                bridge,
            )),
            agent_providers: Arc::new(LocalAgentProviderService::new(agent_provider_dao)),
            agent_templates: Arc::new(LocalAgentTemplateService::new(
                agent_template_dao,
                data_dir,
            )),
            workspace_templates: Arc::new(LocalWorkspaceTemplateService::new(
                workspace_template_dao,
            )),
            api_keys: Arc::new(LocalApiKeyService::new(api_key_dao)),
            preferences: Arc::new(LocalPreferenceService::new(preference_dao)),
            inquiries: Arc::new(LocalInquiryService::new(workspace_dao.clone())),
            agent_data: Arc::new(LocalAgentDataService::new(workspace_dao)),
            crypto,
            file_browser,
            docker,
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
}
