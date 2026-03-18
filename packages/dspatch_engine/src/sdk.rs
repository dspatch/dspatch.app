// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Central SDK facade that wires all d:spatch services together.
//!
//! Both the Flutter app and the CLI use this struct. It replaces manual
//! Riverpod wiring with plain Rust + `Arc` sharing.
//!
//! ```rust,no_run
//! use dspatch_engine::sdk::DspatchSdk;
//! use dspatch_engine::config::DspatchConfig;
//!
//! # async fn example() -> dspatch_engine::util::result::Result<()> {
//! let sdk = DspatchSdk::new(DspatchConfig::default());
//! sdk.initialize().await?;
//! // ... use sdk.services(), etc.
//! sdk.dispose().await?;
//! # Ok(())
//! # }
//! ```

use std::path::{Path, PathBuf};
use std::sync::Arc;

use tokio::sync::{broadcast, RwLock};

use crate::api::HttpApiClient;
use crate::client_api::invalidation::{InvalidationBroadcaster, InvalidationHandle};
use crate::config::DspatchConfig;
use crate::crypto::aes_gcm::AesGcmCrypto;
#[cfg(not(any(target_os = "ios", target_os = "android")))]
use crate::crypto::secure_storage::KeyringSecretStore;
use crate::db::key_manager::{DatabaseKeyManager, SecretStore};
use crate::db::manager::{DatabaseManager, DatabaseState};
use crate::db::Database;
use crate::docker::{DockerCli, DockerClient};
use crate::engine::config::EngineConfig;
use crate::engine::service_registry::ServiceRegistry;
use crate::engine::startup::ClientApiRuntime;
use crate::hub::HubApiClient;
use crate::services::{
    LocalConnectivityService, LocalDeviceService, LocalDockerService,
    LocalSyncService,
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

// ── DspatchSdk ─────────────────────────────────────────────────────────

/// Central facade that wires all d:spatch services together.
///
/// Services are created lazily on first access after the database becomes
/// ready. Authentication is handled by the Dart client; the engine opens
/// the anonymous database on initialization and can switch to a per-user
/// database when requested via `open_user_database()`.
#[allow(dead_code)] // Fields held for Arc ownership / future use
pub struct DspatchSdk {
    config: DspatchConfig,

    // Core services (always present after construction via with_secret_store)
    crypto: Arc<AesGcmCrypto>,
    db_key_manager: Arc<DatabaseKeyManager>,
    db_manager: Arc<DatabaseManager>,
    api_client: Arc<HttpApiClient>,
    hub_client: Arc<RwLock<HubApiClient>>,
    docker_client: Arc<DockerClient>,
    docker_service: Arc<LocalDockerService>,
    device_service: Arc<LocalDeviceService>,
    sync_service: Arc<LocalSyncService>,
    connectivity_service: Arc<LocalConnectivityService>,

    // Database + DB-dependent services
    database: Arc<RwLock<Option<Arc<Database>>>>,

    // Current database file path (set when a database is installed, cleared on teardown).
    current_db_path: Arc<RwLock<Option<String>>>,

    // Database state broadcast
    db_state_tx: broadcast::Sender<DatabaseReadyState>,

    // Pending migration (set when MigrationAvailable, cleared by perform/skip)
    pending_migration: Arc<RwLock<Option<PendingMigration>>>,

    // Data directory for ServiceRegistry (same as db_manager.base_path).
    data_dir: PathBuf,

    /// ServiceRegistry — created when DB is ready, cleared on DB close.
    services: Arc<RwLock<Option<Arc<ServiceRegistry>>>>,

    /// Invalidation broadcaster handle — created when DB opens, rebound on DB change.
    invalidation_handle: Arc<RwLock<Option<InvalidationHandle>>>,
    invalidation_debounce_ms: u64,

    /// Client API runtime — created during initialize().
    runtime: Arc<RwLock<Option<Arc<ClientApiRuntime>>>>,

    // Initialization guards
    initialized: std::sync::atomic::AtomicBool,
}

impl DspatchSdk {
    /// Creates a new SDK instance with default `KeyringSecretStore` and
    /// platform data directory. Call [`initialize`](Self::initialize) to
    /// start services.
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
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

        let backend_url = config
            .backend_url
            .clone()
            .unwrap_or_else(|| DEFAULT_BACKEND_URL.to_string());
        let api_client = Arc::new(HttpApiClient::new(&backend_url));
        let hub_client = Arc::new(RwLock::new(HubApiClient::new(&backend_url, None)));

        let data_dir_clone = data_dir.clone();
        let db_manager = Arc::new(DatabaseManager::new(
            DatabaseKeyManager::new(Box::new(ArcSecretStoreAdapter(Arc::clone(&store_arc)))),
            data_dir,
        ));

        let docker_client = Arc::new(DockerClient::new(DockerCli::new()));
        let docker_service = Arc::new(LocalDockerService::new(
            DockerClient::new(DockerCli::new()),
        ));

        let device_service = Arc::new(LocalDeviceService::new());
        let sync_service = Arc::new(LocalSyncService::new());
        let connectivity_service = Arc::new(LocalConnectivityService::new());

        let (db_state_tx, _) = broadcast::channel(16);

        Self {
            config,
            crypto,
            db_key_manager,
            db_manager,
            api_client,
            hub_client,
            docker_client,
            docker_service,
            device_service,
            sync_service,
            connectivity_service,
            database: Arc::new(RwLock::new(None)),
            current_db_path: Arc::new(RwLock::new(None)),
            db_state_tx,
            pending_migration: Arc::new(RwLock::new(None)),
            data_dir: data_dir_clone,
            services: Arc::new(RwLock::new(None)),
            invalidation_handle: Arc::new(RwLock::new(None)),
            invalidation_debounce_ms: 50,
            runtime: Arc::new(RwLock::new(None)),
            initialized: std::sync::atomic::AtomicBool::new(false),
        }
    }

    // ── Initialization ─────────────────────────────────────────────────

    /// Boots the engine by running setup for an anonymous session.
    ///
    /// Call this once at startup. The engine always starts anonymous; when
    /// the Dart client authenticates via `/auth/connect`, call
    /// [`run_setup`] again with the username to switch databases.
    ///
    /// Idempotent — subsequent calls return immediately.
    pub async fn initialize(&self) -> Result<()> {
        if self.initialized.swap(true, std::sync::atomic::Ordering::SeqCst) {
            return Ok(());
        }

        self.run_setup(None).await
    }

    /// Opens a per-user database, replacing the current anonymous database.
    ///
    /// Called by the Dart client after successful authentication via
    /// `/auth/connect`.
    pub async fn open_user_database(&self, username: &str) -> Result<()> {
        self.run_setup(Some(username)).await
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
    /// within the timeout. Returns an error if the timeout expires.
    pub async fn wait_for_database(&self, timeout: std::time::Duration) -> Result<()> {
        // Already ready?
        if self.is_database_ready().await {
            return Ok(());
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
            DatabaseState::Ready { database: db, health_status, db_path } => {
                tracing::info!(health = ?health_status, "Per-user database opened after migration");
                self.install_database(Arc::new(db), &db_path).await;
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
            DatabaseState::Ready { database: db, health_status, db_path } => {
                tracing::info!(health = ?health_status, "Fresh per-user database opened (migration skipped)");
                self.install_database(Arc::new(db), &db_path).await;
            }
            other => {
                tracing::error!(state = ?other, "Unexpected state opening fresh user DB");
                return Err(AppError::Internal("Unexpected database state".into()));
            }
        }

        Ok(())
    }

    /// Tears down the current database and services.
    /// Broadcasts [`DatabaseReadyState::Closed`].
    async fn teardown_database(&self) {
        // Clear database reference and path.
        {
            let mut db_guard = self.database.write().await;
            let mut path_guard = self.current_db_path.write().await;
            *db_guard = None;
            *path_guard = None;
        }

        // Clear ServiceRegistry + invalidation (releases Arc<Database>).
        self.clear_services().await;

        // Notify database state listeners.
        let _ = self.db_state_tx.send(DatabaseReadyState::Closed);
    }

    /// Central setup orchestrator. Runs on every auth transition:
    ///
    /// - `username = None` → anonymous session (engine startup)
    /// - `username = Some("alice")` → authenticated session (after `/auth/connect`)
    ///
    /// Responsibilities:
    /// 1. Open the correct database (anonymous or per-user)
    /// 2. Handle anonymous→user migration (signal app, wait for decision)
    /// 3. Run post-database-open initialization
    ///
    /// All setup logic belongs here — this is the single hook that runs
    /// regardless of auth mode. Future tasks (preference loading, sync
    /// bootstrap, scheduled jobs, etc.) go in this method.
    async fn run_setup(&self, username: Option<&str>) -> Result<()> {
        tracing::info!(user = ?username, "Running engine setup");

        // Step 1: Open the appropriate database.
        match self.db_manager.open_database(username) {
            Ok(DatabaseState::Ready {
                database: db,
                health_status,
                db_path,
            }) => {
                tracing::info!(
                    health = ?health_status,
                    user = ?username,
                    db_path = %db_path.display(),
                    "Database opened"
                );

                // If switching from an existing DB (anonymous → user), tear
                // down old services first.
                if self.is_database_ready().await {
                    self.teardown_database().await;
                }

                self.install_database(Arc::new(db), &db_path).await;
            }
            Ok(DatabaseState::MigrationAvailable { anonymous_db_path, user_db_path }) => {
                tracing::info!(
                    from = %anonymous_db_path.display(),
                    to = %user_db_path.display(),
                    "Migration available — awaiting user decision"
                );

                *self.pending_migration.write().await = Some(PendingMigration {
                    anonymous_db_path,
                    user_db_path,
                    username: username.unwrap_or_default().to_string(),
                });

                // Signal the app to display migration UI. The app sends
                // back a WS command (perform_migration / skip_migration)
                // which calls the corresponding method on this struct.
                let _ = self.db_state_tx.send(DatabaseReadyState::MigrationPending);
                return Ok(());
            }
            Ok(DatabaseState::Loading) => {
                // Shouldn't happen with sync manager, but not fatal.
            }
            Err(e) => {
                tracing::error!(user = ?username, "Failed to open database: {e}");
                return Err(e);
            }
        }

        // Step 2: Post-database-open initialization.
        // TODO: Add setup tasks here as needed (preference defaults, sync
        // initialization, scheduled cleanup, hub token propagation, etc.)

        Ok(())
    }

    /// Installs a new database reference and broadcasts [`DatabaseReadyState::Ready`].
    async fn install_database(&self, db: Arc<Database>, db_path: &Path) {
        {
            let mut db_guard = self.database.write().await;
            *db_guard = Some(db);
        }
        {
            let mut path_guard = self.current_db_path.write().await;
            *path_guard = Some(db_path.to_string_lossy().into_owned());
        }
        let _ = self.db_state_tx.send(DatabaseReadyState::Ready);
        self.rebuild_services().await;
    }

    /// Returns the file path of the currently open database, or `None` if
    /// no database is open.
    pub async fn database_path(&self) -> Option<String> {
        self.current_db_path.read().await.clone()
    }

    // ── ServiceRegistry / Invalidation / Runtime ───────────────────────

    /// Returns the SDK configuration.
    pub fn config(&self) -> &DspatchConfig {
        &self.config
    }

    /// Returns the current ServiceRegistry, if the database is ready.
    pub async fn services(&self) -> Option<Arc<ServiceRegistry>> {
        self.services.read().await.clone()
    }

    /// Synchronous non-blocking variant — returns None if lock is held or DB not ready.
    pub fn services_sync(&self) -> Option<Arc<ServiceRegistry>> {
        self.services.try_read().ok().and_then(|g| g.clone())
    }

    /// Returns a subscription to table invalidation events, if available.
    pub async fn subscribe_invalidation(&self) -> Option<broadcast::Receiver<Vec<String>>> {
        let guard = self.invalidation_handle.read().await;
        guard.as_ref().map(|h| h.subscribe())
    }

    /// Creates the ClientApiRuntime. Must be called before starting the client API.
    pub async fn create_runtime(&self, config: EngineConfig) -> Arc<ClientApiRuntime> {
        let runtime = Arc::new(ClientApiRuntime::new(config));

        // Wire hub client to session store for backend token forwarding.
        let hub = self.hub_client.read().await;
        runtime.session_store().set_hub_client(Arc::new(
            HubApiClient::new(hub.base_url(), hub.auth_token()),
        ));

        *self.runtime.write().await = Some(Arc::clone(&runtime));
        runtime
    }

    /// Returns the ClientApiRuntime, if created.
    pub async fn runtime(&self) -> Option<Arc<ClientApiRuntime>> {
        self.runtime.read().await.clone()
    }

    /// Rebuilds the ServiceRegistry from the current database.
    /// Called internally when the database transitions to Ready.
    async fn rebuild_services(&self) {
        let db = match self.database.read().await.clone() {
            Some(db) => db,
            None => {
                tracing::error!("Cannot rebuild ServiceRegistry — no database open");
                return;
            }
        };

        // Create or rebind invalidation broadcaster.
        let broadcaster = InvalidationBroadcaster::new(
            db.tracker().clone(),
            self.invalidation_debounce_ms,
        );
        let handle = broadcaster.start();
        *self.invalidation_handle.write().await = Some(handle);

        // Reuse the session store's hub client so auth token updates propagate
        // to the ServiceRegistry automatically (single shared instance).
        let hub_client = match self.runtime.read().await.as_ref() {
            Some(rt) => rt.session_store().hub_client(),
            None => {
                let guard = self.hub_client.read().await;
                Some(Arc::new(HubApiClient::new(guard.base_url(), guard.auth_token())))
            }
        };

        let registry = Arc::new(ServiceRegistry::new(
            db,
            self.data_dir.clone(),
            hub_client,
        ));
        *self.services.write().await = Some(registry);
        tracing::info!("ServiceRegistry built from database");

        // Recover any workspaces that were running before engine restart.
        {
            let guard = self.services.read().await;
            if let Some(ref services) = *guard {
                if let Err(e) = services.workspaces().recover_active_workspaces().await {
                    tracing::warn!(%e, "Workspace recovery encountered errors");
                }
            }
        }
    }

    /// Clears the ServiceRegistry and invalidation broadcaster,
    /// releasing the Arc<Database>.
    async fn clear_services(&self) {
        *self.services.write().await = None;
        *self.invalidation_handle.write().await = None;
        tracing::info!("ServiceRegistry cleared");
    }

    // ── Core service accessors ─────────────────────────────────────────

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

    // ── Disposal ───────────────────────────────────────────────────────

    /// Shuts down all services and releases resources.
    pub async fn dispose(&self) -> Result<()> {
        self.teardown_database().await;
        Ok(())
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
