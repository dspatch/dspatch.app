// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Central SDK facade that wires all d:spatch services together.
//!
//! Both the Flutter app and the CLI use this struct. It replaces manual
//! Riverpod wiring with plain Rust + `Arc` sharing.
//!
//! ```rust,no_run
//! use dspatch_sdk::sdk::DspatchSdk;
//! use dspatch_sdk::config::DspatchConfig;
//!
//! # async fn example() -> dspatch_sdk::util::result::Result<()> {
//! let sdk = DspatchSdk::new(DspatchConfig::default());
//! sdk.initialize().await?;
//! // ... use sdk.providers(), sdk.workspaces(), etc.
//! sdk.dispose().await?;
//! # Ok(())
//! # }
//! ```

use std::path::PathBuf;
use std::sync::Arc;

use tokio::sync::{broadcast, Mutex as TokioMutex, RwLock};
use tokio::task::JoinHandle;

use crate::api::{ConnectedAuthService, HttpApiClient, TokenStorage};
use crate::config::DspatchConfig;
use crate::crypto::aes_gcm::AesGcmCrypto;
use crate::crypto::secure_storage::KeyringSecretStore;
use crate::db::dao::{
    AgentProviderDao, AgentTemplateDao, ApiKeyDao, PreferenceDao, WorkspaceDao,
    WorkspaceTemplateDao,
};
use crate::db::key_manager::{DatabaseKeyManager, SecretStore};
use crate::db::manager::{DatabaseManager, DatabaseState};
use crate::db::Database;
use crate::docker::{DockerCli, DockerClient};
use crate::domain::services::{AgentProviderService, ApiClient, ApiKeyService, AuthService};
use crate::hub::{HubApiClient, HubVersionChecker};
use crate::server::agent_server::EmbeddedAgentServer;
use crate::server::workspace_bridge::WorkspaceBridge;
use crate::services::{
    LocalAgentDataService, LocalAgentProviderService, LocalAgentTemplateService,
    LocalApiKeyService, LocalConnectivityService, LocalDeviceService, LocalDockerService,
    LocalFileBrowserService, LocalInquiryService,
    LocalPreferenceService, LocalSyncService, LocalWorkspaceService,
    LocalWorkspaceTemplateService,
};
use crate::util::error::AppError;
use crate::util::result::Result;

// ── Default backend URL ────────────────────────────────────────────────

/// Default backend URL — debug builds use localhost, release builds use production.
#[cfg(debug_assertions)]
const DEFAULT_BACKEND_URL: &str = "http://localhost:3000";

#[cfg(not(debug_assertions))]
const DEFAULT_BACKEND_URL: &str = "https://backend.dspatch.dev";

/// Default service name for the keyring secret store.
const KEYRING_SERVICE_NAME: &str = "dspatch";

// ── Database state broadcast ───────────────────────────────────────────

/// Database readiness state sent through the broadcast channel.
#[derive(Debug, Clone)]
pub enum DatabaseReadyState {
    /// Database is open and ready for queries.
    Ready,
    /// Database was closed (e.g. during auth transition).
    Closed,
    /// An anonymous database exists and can be migrated to a per-user
    /// database. The UI should prompt the user and then call
    /// `perform_migration()` or `skip_migration()`.
    MigrationPending,
}

/// Stored when a migration is available but awaiting user decision.
#[derive(Debug, Clone)]
struct PendingMigration {
    anonymous_db_path: PathBuf,
    user_db_path: PathBuf,
    username: String,
}

// ── DB-dependent service bundle ────────────────────────────────────────

/// All services that require an open database. Rebuilt whenever the database
/// changes (e.g. after sign-in switches from anonymous to per-user DB).
struct DbServices {
    providers: Arc<LocalAgentProviderService>,
    templates: Arc<LocalAgentTemplateService>,
    workspace_templates: Arc<LocalWorkspaceTemplateService>,
    api_keys: Arc<LocalApiKeyService>,
    preferences: Arc<LocalPreferenceService>,
    workspaces: Arc<LocalWorkspaceService>,
    inquiries: Arc<LocalInquiryService>,
    agent_data: Arc<LocalAgentDataService>,
    hub_version_checker: Arc<HubVersionChecker>,
}

// ── DspatchSdk ─────────────────────────────────────────────────────────

/// Central facade that wires all d:spatch services together.
///
/// Services are created lazily on first access after the database becomes
/// ready. The auth watcher task monitors authentication state changes and
/// opens the correct database accordingly.
#[allow(dead_code)] // Fields held for Arc ownership / future use
pub struct DspatchSdk {
    config: DspatchConfig,

    // Core services (always present after construction via with_secret_store)
    crypto: Arc<AesGcmCrypto>,
    db_key_manager: Arc<DatabaseKeyManager>,
    token_storage: Arc<TokenStorage>,
    db_manager: Arc<DatabaseManager>,
    api_client: Arc<HttpApiClient>,
    hub_client: Arc<RwLock<HubApiClient>>,
    auth_service: Arc<ConnectedAuthService>,
    docker_client: Arc<DockerClient>,
    docker_service: Arc<LocalDockerService>,
    device_service: Arc<LocalDeviceService>,
    sync_service: Arc<LocalSyncService>,
    connectivity_service: Arc<LocalConnectivityService>,

    // Database + DB-dependent services
    database: Arc<RwLock<Option<Arc<Database>>>>,
    db_services: Arc<RwLock<Option<DbServices>>>,

    // Database state broadcast
    db_state_tx: broadcast::Sender<DatabaseReadyState>,

    // Pending migration (set when MigrationAvailable, cleared by perform/skip)
    pending_migration: Arc<RwLock<Option<PendingMigration>>>,

    // Server (created when DB services are first built; started/stopped separately)
    server: Arc<RwLock<Option<Arc<TokioMutex<EmbeddedAgentServer>>>>>,
    bridge: Arc<TokioMutex<Option<WorkspaceBridge>>>,

    // Background tasks
    auth_watcher: TokioMutex<Option<JoinHandle<()>>>,

    // Initialization guards
    initialized: std::sync::atomic::AtomicBool,
    recovery_spawned: std::sync::atomic::AtomicBool,
}

impl DspatchSdk {
    /// Creates a new SDK instance with default `KeyringSecretStore` and
    /// platform data directory. Call [`initialize`](Self::initialize) to
    /// start services.
    pub fn new(config: DspatchConfig) -> Self {
        let store = Box::new(KeyringSecretStore::new(KEYRING_SERVICE_NAME));
        let data_dir = default_data_dir();
        Self::with_secret_store(config, store, data_dir)
    }

    /// Creates an SDK with an injected secret store (for testing or custom
    /// platforms). Skips the default keyring-backed store.
    pub fn with_secret_store(
        config: DspatchConfig,
        secret_store: Box<dyn SecretStore>,
        data_dir: PathBuf,
    ) -> Self {
        let store_arc: Arc<dyn SecretStore> = Arc::from(secret_store);

        let crypto = Arc::new(AesGcmCrypto::new(Arc::clone(&store_arc)));
        let db_key_manager = Arc::new(DatabaseKeyManager::new(Box::new(
            ArcSecretStoreAdapter(Arc::clone(&store_arc)),
        )));
        let token_storage = Arc::new(TokenStorage::new(Box::new(
            ArcSecretStoreAdapter(Arc::clone(&store_arc)),
        )));

        let backend_url = config
            .backend_url
            .clone()
            .unwrap_or_else(|| DEFAULT_BACKEND_URL.to_string());
        let api_client = Arc::new(HttpApiClient::new(&backend_url));
        let hub_client = Arc::new(RwLock::new(HubApiClient::new(&backend_url, None)));

        let auth_service = Arc::new(ConnectedAuthService::new(
            Arc::clone(&api_client) as Arc<dyn ApiClient>,
            Arc::clone(&token_storage),
        ));

        let db_manager = Arc::new(DatabaseManager::new(
            DatabaseKeyManager::new(Box::new(ArcSecretStoreAdapter(Arc::clone(&store_arc)))),
            data_dir,
        ));

        let assets_dir = config.assets_dir.clone().unwrap_or_else(|| "assets".to_string());
        let docker_client = Arc::new(DockerClient::new(DockerCli::new()));
        let docker_service = Arc::new(LocalDockerService::new(
            DockerClient::new(DockerCli::new()),
            assets_dir,
        ));

        let device_service = Arc::new(LocalDeviceService::new());
        let sync_service = Arc::new(LocalSyncService::new());
        let connectivity_service = Arc::new(LocalConnectivityService::new());

        let (db_state_tx, _) = broadcast::channel(16);

        Self {
            config,
            crypto,
            db_key_manager,
            token_storage,
            db_manager,
            api_client,
            hub_client,
            auth_service,
            docker_client,
            docker_service,
            device_service,
            sync_service,
            connectivity_service,
            database: Arc::new(RwLock::new(None)),
            db_services: Arc::new(RwLock::new(None)),
            db_state_tx,
            pending_migration: Arc::new(RwLock::new(None)),
            server: Arc::new(RwLock::new(None)),
            bridge: Arc::new(TokioMutex::new(None)),
            auth_watcher: TokioMutex::new(None),
            initialized: std::sync::atomic::AtomicBool::new(false),
            recovery_spawned: std::sync::atomic::AtomicBool::new(false),
        }
    }

    // ── Initialization ─────────────────────────────────────────────────

    /// Creates all core services and spawns the auth watcher task.
    ///
    /// After this returns, the auth service will begin initialization and
    /// the database will open asynchronously once auth state is determined.
    ///
    /// Idempotent — calling this multiple times is safe; subsequent calls
    /// return immediately.
    pub async fn initialize(&self) -> Result<()> {
        if self.initialized.swap(true, std::sync::atomic::Ordering::SeqCst) {
            return Ok(());
        }

        let auth = self.auth_service();

        // Subscribe to the auth broadcast BEFORE initializing auth, so we
        // don't miss the initial state emission from auth.initialize().
        let auth_rx = auth.subscribe_auth_state();
        let db_manager = Arc::clone(&self.db_manager);
        let hub_client = Arc::clone(&self.hub_client);
        let database = Arc::clone(&self.database);
        let db_services = Arc::clone(&self.db_services);
        let server = Arc::clone(&self.server);
        let bridge = Arc::clone(&self.bridge);
        let db_state_tx = self.db_state_tx.clone();
        let pending_migration = Arc::clone(&self.pending_migration);

        let handle = tokio::spawn(async move {
            let mut auth_rx = auth_rx;
            // Helper: tear down old services and swap in a new database atomically.
            let swap_database = |db: Arc<Database>,
                                 database: &Arc<RwLock<Option<Arc<Database>>>>,
                                 db_services: &Arc<RwLock<Option<DbServices>>>,
                                 server: &Arc<RwLock<Option<Arc<TokioMutex<EmbeddedAgentServer>>>>>,
                                 bridge: &Arc<TokioMutex<Option<WorkspaceBridge>>>,
                                 db_state_tx: &broadcast::Sender<DatabaseReadyState>| {
                let database = Arc::clone(database);
                let db_services = Arc::clone(db_services);
                let server = Arc::clone(server);
                let bridge = Arc::clone(bridge);
                let db_state_tx = db_state_tx.clone();
                async move {
                    // Notify listeners that database is closing.
                    let _ = db_state_tx.send(DatabaseReadyState::Closed);

                    // Dispose bridge.
                    {
                        let mut b = bridge.lock().await;
                        if let Some(old_bridge) = b.take() {
                            old_bridge.dispose().await;
                        }
                    }
                    // Stop server if running (it holds old workspace_dao).
                    {
                        let mut srv = server.write().await;
                        if let Some(s) = srv.take() {
                            let mut guard = s.lock().await;
                            guard.stop().await;
                        }
                    }
                    // Atomically clear db_services and swap database
                    // (acquire database lock first to prevent deadlocks).
                    {
                        let mut db_guard = database.write().await;
                        let mut svc_guard = db_services.write().await;
                        *svc_guard = None;
                        *db_guard = Some(db);
                    }

                    // Notify listeners that new database is ready.
                    let _ = db_state_tx.send(DatabaseReadyState::Ready);
                }
            };

            loop {
                let state = match auth_rx.recv().await {
                    Ok(state) => state,
                    Err(_) => break,
                };
                tracing::info!(
                    mode = ?state.mode,
                    username = ?state.username,
                    "Auth state changed"
                );

                // Skip database open for undetermined mode — the user
                // must explicitly choose anonymous or login first.
                if state.mode == crate::domain::enums::AuthMode::Undetermined {
                    tracing::info!("Auth undetermined — waiting for explicit auth choice");
                    continue;
                }

                // Update hub client auth token.
                {
                    let mut hc = hub_client.write().await;
                    *hc = HubApiClient::new(
                        hc.base_url(),
                        state.token.clone(),
                    );
                }

                // Open the correct database.
                let username = state.username.as_deref();
                match db_manager.open_database(username) {
                    Ok(DatabaseState::Ready {
                        database: db,
                        health_status,
                    }) => {
                        tracing::info!(
                            health = ?health_status,
                            "Database opened"
                        );
                        swap_database(
                            Arc::new(db), &database, &db_services,
                            &server, &bridge, &db_state_tx,
                        ).await;
                    }
                    Ok(DatabaseState::MigrationAvailable { anonymous_db_path, user_db_path }) => {
                        // An anonymous DB exists but no per-user DB yet.
                        // Store the paths and notify the UI — do NOT auto-migrate.
                        tracing::info!(
                            from = %anonymous_db_path.display(),
                            to = %user_db_path.display(),
                            "Migration available — awaiting user decision"
                        );

                        *pending_migration.write().await = Some(PendingMigration {
                            anonymous_db_path,
                            user_db_path,
                            username: username.unwrap_or_default().to_string(),
                        });

                        let _ = db_state_tx.send(DatabaseReadyState::MigrationPending);
                    }
                    Ok(DatabaseState::Loading) => {
                        // Shouldn't happen with sync manager, but ignore.
                    }
                    Err(e) => {
                        tracing::error!("Failed to open database: {e}");
                    }
                }
            }
        });

        // Abort any existing watcher before storing the new one.
        let mut watcher = self.auth_watcher.lock().await;
        if let Some(old_handle) = watcher.take() {
            old_handle.abort();
        }
        *watcher = Some(handle);

        // Initialize auth AFTER watcher is subscribed so the initial
        // state emission is not missed.
        auth.initialize().await?;

        Ok(())
    }

    /// Spawns a background listener that runs workspace recovery whenever the
    /// database becomes ready (after auth + DB setup, or after user migration).
    ///
    /// Must be called once from the bridge layer which owns `Arc<DspatchSdk>`.
    /// Idempotent — only spawns the listener once.
    pub fn spawn_recovery_listener(self: &Arc<Self>) {
        if self.recovery_spawned.swap(true, std::sync::atomic::Ordering::SeqCst) {
            return;
        }
        let sdk = Arc::clone(self);
        let mut rx = self.db_state_tx.subscribe();

        tokio::spawn(async move {
            loop {
                match rx.recv().await {
                    Ok(DatabaseReadyState::Ready) => {
                        tracing::info!("Database ready — running post-init recovery");
                        if let Err(e) = sdk.post_db_ready().await {
                            tracing::error!(%e, "Post-DB-ready recovery failed");
                        }
                    }
                    Ok(_) => {} // Closed / MigrationPending — ignore
                    Err(_) => break, // Channel closed
                }
            }
        });
    }

    /// Runs after the database becomes ready: recovers active workspaces
    /// (starts server, reconnects running containers) and wires callbacks.
    async fn post_db_ready(&self) -> Result<()> {
        // Ensure DB-dependent services (DAOs, server, bridge) are built.
        self.ensure_db_services().await?;

        // Recover active workspaces via the bridge.
        {
            let bridge_guard = self.bridge.lock().await;
            if let Some(ref bridge) = *bridge_guard {
                if let Err(e) = bridge.recover_active_workspaces().await {
                    tracing::warn!(%e, "Workspace recovery encountered errors");
                }
            }
        }

        // Wire the send_user_input callback now that the server is running.
        self.ensure_send_user_input_wired().await?;

        Ok(())
    }

    // ── Database state ─────────────────────────────────────────────────

    /// Whether the database is open and ready for queries.
    pub async fn is_database_ready(&self) -> bool {
        self.database.read().await.is_some()
    }

    /// Returns a reference to the open database, or an error if not ready.
    pub async fn database(&self) -> Result<Arc<Database>> {
        let guard = self.database.read().await;
        guard.clone().ok_or_else(|| {
            AppError::Internal("Database not yet initialized".into())
        })
    }

    /// Returns a broadcast receiver for database state changes.
    ///
    /// Callers receive [`DatabaseReadyState::Ready`] when a new database is
    /// opened and [`DatabaseReadyState::Closed`] when it is closed during
    /// auth transitions.
    pub fn subscribe_database_state(&self) -> broadcast::Receiver<DatabaseReadyState> {
        self.db_state_tx.subscribe()
    }

    /// Waits for the database to become ready, with a timeout.
    ///
    /// Returns `Ok(())` if the database is already ready or becomes ready
    /// within the timeout. Returns an error if the timeout expires or if
    /// auth mode is still [`AuthMode::Undetermined`].
    pub async fn wait_for_database(&self, timeout: std::time::Duration) -> Result<()> {
        // Already ready?
        if self.is_database_ready().await {
            return Ok(());
        }

        // Check auth state — if undetermined, don't wait (user hasn't chosen)
        let auth_state = self.auth_service().current_auth_state();
        if auth_state.mode == crate::domain::enums::AuthMode::Undetermined {
            return Err(AppError::Auth(
                "Not authenticated. Run `dspatch auth login` or `dspatch auth anonymous` first."
                    .into(),
            ));
        }

        // Subscribe and wait for Ready signal
        let mut rx = self.subscribe_database_state();
        let result = tokio::time::timeout(timeout, async {
            loop {
                match rx.recv().await {
                    Ok(DatabaseReadyState::Ready) => return Ok(()),
                    Ok(DatabaseReadyState::Closed) | Ok(DatabaseReadyState::MigrationPending) => continue,
                    Err(_) => {
                        return Err(AppError::Internal(
                            "Database state channel closed".into(),
                        ))
                    }
                }
            }
        })
        .await;

        match result {
            Ok(inner) => inner,
            Err(_) => Err(AppError::Internal(
                "Timed out waiting for database to become ready".into(),
            )),
        }
    }

    // ── Migration ───────────────────────────────────────────────────────

    /// Returns `true` if a migration decision is pending.
    pub async fn is_migration_pending(&self) -> bool {
        self.pending_migration.read().await.is_some()
    }

    /// Migrates the anonymous database to the per-user path.
    ///
    /// Closes any currently open database, renames the anonymous DB files,
    /// then opens the per-user database. Broadcasts [`DatabaseReadyState::Ready`]
    /// on success.
    pub async fn perform_migration(&self) -> Result<()> {
        let migration = self.pending_migration.write().await.take().ok_or_else(|| {
            AppError::Internal("No pending migration".into())
        })?;

        // Tear down current DB (releases file handles).
        self.teardown_database().await;

        // Ensure the per-user directory exists.
        if let Some(parent) = migration.user_db_path.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                AppError::Internal(format!("Failed to create per-user DB directory: {e}"))
            })?;
        }

        // Move the anonymous DB file(s) to the per-user path.
        std::fs::rename(&migration.anonymous_db_path, &migration.user_db_path).map_err(|e| {
            AppError::Internal(format!("Failed to migrate anonymous DB: {e}"))
        })?;

        // Also move WAL and SHM files if they exist.
        let wal = migration.anonymous_db_path.with_extension("db-wal");
        let shm = migration.anonymous_db_path.with_extension("db-shm");
        if wal.exists() {
            let _ = std::fs::rename(&wal, migration.user_db_path.with_extension("db-wal"));
        }
        if shm.exists() {
            let _ = std::fs::rename(&shm, migration.user_db_path.with_extension("db-shm"));
        }

        tracing::info!("Anonymous DB migrated to per-user path");

        // Open the per-user DB.
        let username = &migration.username;
        match self.db_manager.open_database(Some(username))? {
            DatabaseState::Ready { database: db, health_status } => {
                tracing::info!(health = ?health_status, "Per-user database opened after migration");
                self.install_database(Arc::new(db)).await;
            }
            other => {
                tracing::error!(state = ?other, "Unexpected state after migration");
                return Err(AppError::Internal("Unexpected database state after migration".into()));
            }
        }

        Ok(())
    }

    /// Skips migration and opens a fresh per-user database.
    ///
    /// The anonymous database remains on disk untouched. Broadcasts
    /// [`DatabaseReadyState::Ready`] on success.
    pub async fn skip_migration(&self) -> Result<()> {
        let migration = self.pending_migration.write().await.take().ok_or_else(|| {
            AppError::Internal("No pending migration".into())
        })?;

        // Tear down current DB (releases file handles).
        self.teardown_database().await;

        // Open a fresh per-user DB (bypasses migration check).
        let username = &migration.username;
        match self.db_manager.open_user_database(username)? {
            DatabaseState::Ready { database: db, health_status } => {
                tracing::info!(health = ?health_status, "Fresh per-user database opened (migration skipped)");
                self.install_database(Arc::new(db)).await;
            }
            other => {
                tracing::error!(state = ?other, "Unexpected state opening fresh user DB");
                return Err(AppError::Internal("Unexpected database state".into()));
            }
        }

        Ok(())
    }

    /// Tears down the current database, services, server, and bridge.
    /// Broadcasts [`DatabaseReadyState::Closed`].
    async fn teardown_database(&self) {
        let _ = self.db_state_tx.send(DatabaseReadyState::Closed);

        // Dispose bridge.
        {
            let mut b = self.bridge.lock().await;
            if let Some(old_bridge) = b.take() {
                old_bridge.dispose().await;
            }
        }
        // Stop server.
        {
            let mut srv = self.server.write().await;
            if let Some(s) = srv.take() {
                let mut guard = s.lock().await;
                guard.stop().await;
            }
        }
        // Clear db_services and database.
        {
            let mut db_guard = self.database.write().await;
            let mut svc_guard = self.db_services.write().await;
            *svc_guard = None;
            *db_guard = None;
        }
    }

    /// Installs a new database and broadcasts [`DatabaseReadyState::Ready`].
    async fn install_database(&self, db: Arc<Database>) {
        {
            let mut db_guard = self.database.write().await;
            *db_guard = Some(db);
        }
        let _ = self.db_state_tx.send(DatabaseReadyState::Ready);
    }

    // ── Core service accessors ─────────────────────────────────────────

    /// Returns the auth service.
    pub fn auth_service(&self) -> &Arc<ConnectedAuthService> {
        &self.auth_service
    }

    /// Returns the docker service.
    pub fn docker_service(&self) -> &Arc<LocalDockerService> {
        &self.docker_service
    }

    /// Returns the device service.
    pub fn device_service(&self) -> &Arc<LocalDeviceService> {
        &self.device_service
    }

    /// Returns the sync service.
    pub fn sync_service(&self) -> &Arc<LocalSyncService> {
        &self.sync_service
    }

    /// Returns the connectivity service.
    pub fn connectivity_service(&self) -> &Arc<LocalConnectivityService> {
        &self.connectivity_service
    }

    /// Returns the crypto service.
    pub fn crypto(&self) -> &Arc<AesGcmCrypto> {
        &self.crypto
    }

    /// Returns the hub API client (behind RwLock for auth token updates).
    pub fn hub_client(&self) -> &Arc<RwLock<HubApiClient>> {
        &self.hub_client
    }

    /// Returns the docker client.
    pub fn docker_client(&self) -> &Arc<DockerClient> {
        &self.docker_client
    }

    /// Returns the embedded server (behind RwLock).
    pub fn server(&self) -> &Arc<RwLock<Option<Arc<TokioMutex<EmbeddedAgentServer>>>>> {
        &self.server
    }

    // ── DB-dependent service accessors ─────────────────────────────────

    /// Ensures DB-dependent services are built. Returns an error if the
    /// database is not yet ready.
    async fn ensure_db_services(&self) -> Result<()> {
        // Fast path: already built (read lock).
        {
            let guard = self.db_services.read().await;
            if guard.is_some() {
                return Ok(());
            }
        }

        // Slow path: acquire write lock and re-check to avoid TOCTOU race.
        let mut svc_guard = self.db_services.write().await;
        if svc_guard.is_some() {
            return Ok(()); // Another task beat us to it.
        }

        let db = {
            let guard = self.database.read().await;
            guard.clone().ok_or_else(|| {
                AppError::Internal("Database not yet initialized".into())
            })?
        };

        // Build DAOs.
        let agent_provider_dao = Arc::new(AgentProviderDao::new(Arc::clone(&db)));
        let agent_template_dao = Arc::new(AgentTemplateDao::new(Arc::clone(&db)));
        let workspace_template_dao = Arc::new(WorkspaceTemplateDao::new(Arc::clone(&db)));
        let api_key_dao = Arc::new(ApiKeyDao::new(Arc::clone(&db)));
        let preference_dao = Arc::new(PreferenceDao::new(Arc::clone(&db)));
        let workspace_dao = Arc::new(WorkspaceDao::new(Arc::clone(&db)));

        // Build services.
        let providers = Arc::new(LocalAgentProviderService::new(agent_provider_dao));
        let data_dir = default_data_dir();
        let templates = Arc::new(LocalAgentTemplateService::new(agent_template_dao, data_dir));
        let workspace_templates =
            Arc::new(LocalWorkspaceTemplateService::new(workspace_template_dao));
        let api_keys = Arc::new(LocalApiKeyService::new(api_key_dao));
        let preferences = Arc::new(LocalPreferenceService::new(preference_dao));
        let workspaces = Arc::new(LocalWorkspaceService::new(
            Arc::clone(&workspace_dao),
            Arc::clone(&self.bridge),
        ));
        let inquiries = Arc::new(LocalInquiryService::new(Arc::clone(&workspace_dao)));
        let agent_data = Arc::new(LocalAgentDataService::new(Arc::clone(&workspace_dao)));

        // Build HubVersionChecker (needs a hub client + trait objects).
        // Create a fresh HubApiClient with the current auth token.
        let hub_client_guard = self.hub_client().read().await;
        let hub_client_snapshot = Arc::new(HubApiClient::new(
            hub_client_guard.base_url(),
            hub_client_guard.auth_token().map(|s| s.to_string()),
        ));
        drop(hub_client_guard);

        let hub_version_checker = Arc::new(HubVersionChecker::new(
            hub_client_snapshot,
            Arc::clone(&providers) as Arc<dyn AgentProviderService>,
            Arc::clone(&workspace_templates) as Arc<dyn crate::domain::services::WorkspaceTemplateService>,
        ));

        // Build EmbeddedAgentServer + WorkspaceBridge (server not started yet).
        {
            let mut srv_guard = self.server.write().await;
            if srv_guard.is_none() {
                let docker_client = Arc::clone(self.docker_client());
                let server = Arc::new(TokioMutex::new(EmbeddedAgentServer::new(
                    Arc::clone(&workspace_dao),
                    docker_client,
                )));
                *srv_guard = Some(Arc::clone(&server));

                let crypto = Arc::clone(self.crypto());
                let docker_client2 = Arc::clone(self.docker_client());
                let docker_service = Arc::clone(self.docker_service());

                let bridge = WorkspaceBridge::new(
                    server,
                    Arc::clone(&workspace_dao),
                    Arc::clone(&providers) as Arc<dyn AgentProviderService>,
                    Arc::clone(&api_keys) as Arc<dyn ApiKeyService>,
                    crypto,
                    docker_client2,
                    Arc::clone(&docker_service) as Arc<dyn crate::domain::services::DockerService>,
                    Arc::new(PreferenceDao::new(Arc::clone(&db))),
                );
                *self.bridge.lock().await = Some(bridge);
            }
        }

        let services = DbServices {
            providers,
            templates,
            workspace_templates,
            api_keys,
            preferences,
            workspaces,
            inquiries,
            agent_data,
            hub_version_checker,
        };

        *svc_guard = Some(services);
        Ok(())
    }

    /// Returns the agent provider service.
    pub async fn providers(&self) -> Result<Arc<LocalAgentProviderService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.providers))
    }

    /// Returns the agent template service.
    pub async fn templates(&self) -> Result<Arc<LocalAgentTemplateService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.templates))
    }

    /// Returns the workspace template service.
    pub async fn workspace_templates(&self) -> Result<Arc<LocalWorkspaceTemplateService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.workspace_templates))
    }

    /// Returns the API key service.
    pub async fn api_keys(&self) -> Result<Arc<LocalApiKeyService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.api_keys))
    }

    /// Returns the preference service.
    pub async fn preferences(&self) -> Result<Arc<LocalPreferenceService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.preferences))
    }

    /// Returns the workspace service.
    pub async fn workspaces(&self) -> Result<Arc<LocalWorkspaceService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.workspaces))
    }

    /// Returns the inquiry service.
    pub async fn inquiries(&self) -> Result<Arc<LocalInquiryService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.inquiries))
    }

    /// Returns the agent data service.
    pub async fn agent_data(&self) -> Result<Arc<LocalAgentDataService>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.agent_data))
    }

    /// Returns the hub version checker (DB-dependent).
    pub async fn hub_version_checker(&self) -> Result<Arc<HubVersionChecker>> {
        self.ensure_db_services().await?;
        let guard = self.db_services.read().await;
        Ok(Arc::clone(&guard.as_ref().ok_or_else(|| AppError::Internal("Database services unavailable (auth transition in progress)".into()))?.hub_version_checker))
    }

    /// Creates a file browser for the given project path.
    pub fn create_file_browser(&self, project_path: &str) -> LocalFileBrowserService {
        LocalFileBrowserService::new(project_path.to_string())
    }

    // ── Server lifecycle ───────────────────────────────────────────────

    /// Starts the embedded agent server. Returns the bound port number.
    ///
    /// Ensures DB services (and the server instance) are created before
    /// starting the server.
    pub async fn start_server(&self, preferred_port: Option<u16>) -> Result<u16> {
        // Ensure DB services + server + bridge are created.
        self.ensure_db_services().await?;

        let server_arc = {
            let guard = self.server.read().await;
            guard.clone().ok_or_else(|| {
                AppError::Internal("Server not created (database not ready?)".into())
            })?
        };

        let mut server = server_arc.lock().await;
        let port = preferred_port.unwrap_or(self.config.server_port);
        let actual_port = server
            .start(port, false)
            .await
            .map_err(|e| AppError::Internal(format!("Server start failed: {e}")))?;

        drop(server);
        self.ensure_send_user_input_wired().await?;

        Ok(actual_port)
    }

    /// Ensures the `send_user_input` callback is wired to the running server.
    ///
    /// Idempotent — safe to call multiple times. Requires the server to be
    /// running (called automatically by `start_server` and `post_db_ready`).
    pub async fn ensure_send_user_input_wired(&self) -> Result<()> {
        let agent_data = self.agent_data().await?;

        // Already wired? Skip.
        {
            let guard = agent_data.send_user_input_ref().read().unwrap_or_else(|e| e.into_inner());
            if guard.is_some() {
                return Ok(());
            }
        }

        let server_arc = {
            let guard = self.server.read().await;
            guard.clone().ok_or_else(|| {
                AppError::Internal("Server not started".into())
            })?
        };
        let server = server_arc.lock().await;

        if let Some(host_router) = server.host_router() {
            let conn = Arc::clone(&host_router.connection_service);
            let dao = agent_data.dao();

            agent_data.set_send_user_input(Arc::new({
                let conn = Arc::clone(&conn);
                let dao = Arc::clone(&dao);
                move |run_id: &str, instance_id: &str, text: &str| {
                    let agent = dao
                        .find_workspace_agent_by_instance_id(run_id, instance_id)
                        .map_err(|e| format!("DB lookup failed: {e}"))?
                        .ok_or_else(|| format!("Agent instance {} not found in run {}", instance_id, run_id))?;

                    let agent_key = agent.agent_key;

                    if !conn.is_connected(run_id, &agent_key) {
                        return Err(format!("Agent {} is not connected", agent_key));
                    }

                    let pkg = crate::server::packages::Package::UserInput(
                        crate::server::packages::UserInputPackage {
                            instance_id: instance_id.to_string(),
                            content: text.to_string(),
                        },
                    );

                    let json_str = pkg.to_json().map_err(|e| format!("Serialize failed: {e}"))?;
                    let conn = Arc::clone(&conn);
                    let run_id = run_id.to_string();
                    let agent_key_clone = agent_key.clone();
                    let instance_id_owned = instance_id.to_string();

                    tokio::spawn(async move {
                        conn.send_json_to_agent(&run_id, &agent_key_clone, &json_str).await;
                    });

                    let _ = dao.update_agent_status(&instance_id_owned, &crate::domain::enums::AgentState::Generating);

                    Ok(())
                }
            }));

            agent_data.set_interrupt_instance(Arc::new({
                let conn = Arc::clone(&conn);
                let dao = Arc::clone(&dao);
                move |run_id: &str, instance_id: &str| {
                    let agent = dao
                        .find_workspace_agent_by_instance_id(run_id, instance_id)
                        .map_err(|e| format!("DB lookup failed: {e}"))?
                        .ok_or_else(|| format!("Agent instance {} not found in run {}", instance_id, run_id))?;

                    let agent_key = agent.agent_key;

                    if !conn.is_connected(run_id, &agent_key) {
                        return Err(format!("Agent {} is not connected", agent_key));
                    }

                    let pkg = crate::server::packages::Package::Interrupt(
                        crate::server::packages::InterruptPackage {
                            instance_id: instance_id.to_string(),
                        },
                    );

                    let json_str = pkg.to_json().map_err(|e| format!("Serialize failed: {e}"))?;
                    let conn = Arc::clone(&conn);
                    let run_id = run_id.to_string();
                    let agent_key_clone = agent_key.clone();

                    tokio::spawn(async move {
                        conn.send_json_to_agent(&run_id, &agent_key_clone, &json_str).await;
                    });

                    Ok(())
                }
            }));
        }

        Ok(())
    }

    /// Subscribes to real-time SDK lifecycle events.
    ///
    /// Returns a broadcast receiver. The server must be started first.
    pub async fn subscribe_events(
        &self,
    ) -> Result<broadcast::Receiver<crate::server::event_bus::SdkEvent>> {
        let server_arc = {
            let guard = self.server.read().await;
            guard.clone().ok_or_else(|| {
                AppError::Internal("Server not started".into())
            })?
        };
        let server = server_arc.lock().await;
        let router = server.host_router().ok_or_else(|| {
            AppError::Internal("Host router not available".into())
        })?;
        Ok(router.event_bus.subscribe())
    }

    /// Stops the embedded agent server.
    pub async fn stop_server(&self) -> Result<()> {
        let server_arc = {
            let guard = self.server.read().await;
            guard.clone()
        };
        if let Some(s) = server_arc {
            let mut server = s.lock().await;
            server.stop().await;
        }
        Ok(())
    }

    // ── Disposal ───────────────────────────────────────────────────────

    /// Shuts down all services and releases resources.
    pub async fn dispose(&self) -> Result<()> {
        // Cancel auth watcher task.
        {
            let mut handle = self.auth_watcher.lock().await;
            if let Some(h) = handle.take() {
                h.abort();
            }
        }

        // Dispose bridge.
        {
            let mut bridge_guard = self.bridge.lock().await;
            if let Some(old_bridge) = bridge_guard.take() {
                old_bridge.dispose().await;
            }
        }

        // Stop server.
        {
            let mut srv_guard = self.server.write().await;
            if let Some(s) = srv_guard.take() {
                let mut server = s.lock().await;
                server.stop().await;
            }
        }

        // Clear DB services.
        *self.db_services.write().await = None;
        *self.database.write().await = None;

        // Notify database state listeners.
        let _ = self.db_state_tx.send(DatabaseReadyState::Closed);

        Ok(())
    }
}

impl Drop for DspatchSdk {
    fn drop(&mut self) {
        if let Some(handle) = self.auth_watcher.get_mut().take() {
            handle.abort();
        }
    }
}

// ── Helper: adapt Arc<dyn SecretStore> → Box<dyn SecretStore> ──────────

/// Wraps an `Arc<dyn SecretStore>` so it can be passed as `Box<dyn SecretStore>`.
struct ArcSecretStoreAdapter(Arc<dyn SecretStore>);

impl SecretStore for ArcSecretStoreAdapter {
    fn read(&self, key: &str) -> Result<Option<String>> {
        self.0.read(key)
    }

    fn write(&self, key: &str, value: &str) -> Result<()> {
        self.0.write(key, value)
    }

    fn delete(&self, key: &str) -> Result<()> {
        self.0.delete(key)
    }
}

// ── Default data directory ─────────────────────────────────────────────

/// Returns the platform-specific application data directory for d:spatch.
///
/// - **Windows**: `%APPDATA%\dspatch` (e.g. `C:\Users\X\AppData\Roaming\dspatch`)
/// - **macOS**: `~/Library/Application Support/dspatch`
/// - **Linux**: `~/.local/share/dspatch`
///
/// Falls back to a `dspatch_data` directory in the current working directory
/// if the platform directory cannot be determined.
fn default_data_dir() -> PathBuf {
    dirs::data_dir()
        .map(|d| d.join("dspatch"))
        .unwrap_or_else(|| PathBuf::from("dspatch_data"))
}
