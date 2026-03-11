// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Standalone CLI for the d:spatch agent platform.
//!
//! Uses `clap` derive macros for argument parsing and dispatches to
//! per-command handlers in [`commands`].

pub mod commands;
pub mod formatter;

use std::sync::Arc;

use clap::{Parser, Subcommand};

use crate::config::DspatchConfig;
use crate::sdk::DspatchSdk;
use crate::util::result::Result;

/// Initializes the SDK, waits for the database to become ready, runs the
/// given closure, and always disposes — even on error.
///
/// Use this for commands that need database access (most commands).
/// Returns a clear error if the user hasn't authenticated yet.
pub(crate) async fn with_sdk<F, Fut>(f: F) -> Result<()>
where
    F: FnOnce(Arc<DspatchSdk>) -> Fut,
    Fut: std::future::Future<Output = Result<()>>,
{
    let sdk = Arc::new(DspatchSdk::new(DspatchConfig::default()));
    sdk.initialize().await?;

    // Check if the user had stored credentials that turned out to be invalid.
    {
        use crate::domain::enums::AuthMode;
        use crate::domain::services::AuthService;
        let state = sdk.auth_service().current_auth_state();
        if state.mode == AuthMode::Undetermined {
            let _ = sdk.dispose().await;
            return Err(crate::util::error::AppError::Auth(
                "Not authenticated. Run `dspatch auth login` or `dspatch auth anonymous` first.\n\
                 Hint: If you were previously logged in, your session may have expired."
                    .into(),
            ));
        }
    }

    // Wait for the database to become ready (requires prior auth).
    if let Err(e) = sdk
        .wait_for_database(std::time::Duration::from_secs(10))
        .await
    {
        let _ = sdk.dispose().await;
        return Err(e);
    }

    let result = f(Arc::clone(&sdk)).await;
    let _ = sdk.dispose().await;
    result
}

/// Initializes the SDK without waiting for the database. Used by auth
/// commands that need the SDK but may operate before a DB exists (login,
/// anonymous, status, logout).
pub(crate) async fn with_sdk_auth_only<F, Fut>(f: F) -> Result<()>
where
    F: FnOnce(Arc<DspatchSdk>) -> Fut,
    Fut: std::future::Future<Output = Result<()>>,
{
    let sdk = Arc::new(DspatchSdk::new(DspatchConfig::default()));
    sdk.initialize().await?;
    let result = f(Arc::clone(&sdk)).await;
    let _ = sdk.dispose().await;
    result
}

/// d:spatch -- Agent Orchestration CLI.
#[derive(Parser)]
#[command(name = "dspatch", about = "d:spatch -- Agent Orchestration CLI")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

/// Top-level commands.
#[derive(Subcommand)]
pub enum Commands {
    /// List all workspaces.
    List {
        #[arg(long)]
        json: bool,
    },
    /// Show workspace status.
    Status {
        workspace_id: String,
        #[arg(long)]
        json: bool,
    },
    /// Launch a workspace.
    Launch {
        workspace_id: String,
    },
    /// Stop a workspace.
    Stop {
        workspace_id: String,
    },
    /// View agent logs for a run.
    Logs {
        run_id: String,
        #[arg(short, long)]
        follow: bool,
        #[arg(short, long)]
        instance: Option<String>,
        #[arg(long)]
        json: bool,
    },
    /// View agent messages for a run.
    Messages {
        run_id: String,
        instance_id: String,
        #[arg(short, long)]
        follow: bool,
        #[arg(long)]
        json: bool,
    },
    /// Manage inquiries.
    Inquiries {
        #[command(subcommand)]
        cmd: InquiriesCmd,
    },
    /// Manage agent providers.
    Provider {
        #[command(subcommand)]
        cmd: ProviderCmd,
    },
    /// Manage agent templates (config presets).
    Template {
        #[command(subcommand)]
        cmd: TemplateCmd,
    },
    /// Manage workspaces.
    Workspace {
        #[command(subcommand)]
        cmd: WorkspaceCmd,
    },
    /// Manage API keys.
    Keys {
        #[command(subcommand)]
        cmd: KeysCmd,
    },
    /// Docker engine management.
    Engine {
        #[command(subcommand)]
        cmd: EngineCmd,
    },
    /// Authentication management.
    Auth {
        #[command(subcommand)]
        cmd: AuthCmd,
    },
    /// Scaffold a dspatch.workspace.yml config file.
    Init {
        #[arg(short, long)]
        path: Option<String>,
    },
    /// Validate a dspatch.workspace.yml config file.
    Validate {
        #[arg(short, long)]
        path: Option<String>,
    },
}

/// Inquiry subcommands.
#[derive(Subcommand)]
pub enum InquiriesCmd {
    /// List inquiries.
    List {
        #[arg(long)]
        json: bool,
        #[arg(long)]
        pending: bool,
    },
    /// Respond to an inquiry.
    Respond {
        inquiry_id: String,
        /// The answer text.
        answer: Vec<String>,
    },
    /// Show inquiry details.
    Info {
        inquiry_id: String,
        #[arg(long)]
        json: bool,
    },
}

/// Provider subcommands.
#[derive(Subcommand)]
pub enum ProviderCmd {
    /// List agent providers.
    List {
        #[arg(long)]
        json: bool,
    },
    /// Show provider details.
    Info {
        provider_id: String,
        #[arg(long)]
        json: bool,
    },
    /// Import an agent provider from a local directory or git URL.
    Add {
        /// Local directory path or git repository URL.
        source: String,
        /// Git branch (only used with git URLs).
        #[arg(short, long)]
        branch: Option<String>,
    },
    /// Edit a property of an existing agent provider.
    Edit {
        /// Provider ID or name.
        provider_id: String,
        /// Property to edit (name, description, entry_point, source_path, git_url, git_branch).
        property: String,
        /// New value for the property.
        value: String,
    },
    /// Remove an agent provider.
    Remove {
        provider_id: String,
    },
}

/// Template subcommands.
#[derive(Subcommand)]
pub enum TemplateCmd {
    /// List all agent templates.
    List {
        #[arg(long)]
        json: bool,
    },
    /// Show template details and print config file contents.
    Info {
        /// Template ID or name.
        id_or_name: String,
        #[arg(long)]
        json: bool,
    },
    /// Create a template from a provider name or dspatch:// URI.
    Create {
        /// Provider name or dspatch://agent/<author>/<slug> URI.
        source: String,
        /// Optional template name (defaults to provider name).
        #[arg(long)]
        name: Option<String>,
        #[arg(long)]
        json: bool,
    },
    /// Remove a template and its config files.
    Remove {
        /// Template ID.
        id: String,
        #[arg(long)]
        json: bool,
    },
    /// Submit a template to the community hub.
    Submit {
        /// Template name or ID.
        name_or_id: String,
        /// Optional description for the hub listing.
        #[arg(long)]
        description: Option<String>,
        /// Optional category slug.
        #[arg(long)]
        category: Option<String>,
        /// Optional comma-separated tag slugs.
        #[arg(long)]
        tags: Option<String>,
        #[arg(long)]
        json: bool,
    },
}

/// Workspace subcommands.
#[derive(Subcommand)]
pub enum WorkspaceCmd {
    /// Create a workspace from dspatch.workspace.yml.
    Create {
        #[arg(short, long)]
        path: Option<String>,
        #[arg(long)]
        json: bool,
    },
    /// Delete a workspace.
    Delete {
        workspace_id: String,
    },
    /// Show workspace details.
    Info {
        workspace_id: String,
        #[arg(long)]
        json: bool,
    },
}

/// API key subcommands.
#[derive(Subcommand)]
pub enum KeysCmd {
    /// List API keys.
    List {
        #[arg(long)]
        json: bool,
    },
    /// Add a new API key.
    Add {
        #[arg(short = 'n', long)]
        name: String,
        #[arg(short = 'p', long)]
        provider: String,
        #[arg(short = 'k', long)]
        key: Option<String>,
    },
    /// Remove an API key.
    Remove {
        key_id: String,
    },
}

/// Auth subcommands.
#[derive(Subcommand)]
pub enum AuthCmd {
    /// Show current authentication status.
    Status {
        #[arg(long)]
        json: bool,
    },
    /// Log in with username and password.
    Login,
    /// Create a new account (debug builds only).
    #[cfg(debug_assertions)]
    Register,
    /// Enter anonymous (local-only) mode.
    Anonymous,
    /// Log out and clear stored credentials.
    Logout,
}

/// Engine subcommands.
#[derive(Subcommand)]
pub enum EngineCmd {
    /// Show Docker engine status.
    Status {
        #[arg(long)]
        json: bool,
    },
    /// Build the d:spatch runtime image.
    BuildRuntime,
    /// List d:spatch containers.
    Containers {
        #[arg(long)]
        json: bool,
    },
    /// Clean up orphaned and stopped containers.
    Cleanup,
}

/// Dispatches the parsed CLI to the appropriate command handler.
pub async fn run_command(cli: Cli) -> Result<()> {
    match cli.command {
        Commands::List { json } => commands::list::run(json).await,
        Commands::Status { workspace_id, json } => {
            commands::status::run(&workspace_id, json).await
        }
        Commands::Launch { workspace_id } => commands::launch::run(&workspace_id).await,
        Commands::Stop { workspace_id } => commands::stop::run(&workspace_id).await,
        Commands::Logs {
            run_id,
            follow,
            instance,
            json,
        } => commands::logs::run(&run_id, follow, instance.as_deref(), json).await,
        Commands::Messages {
            run_id,
            instance_id,
            follow,
            json,
        } => commands::messages::run(&run_id, &instance_id, follow, json).await,
        Commands::Inquiries { cmd } => match cmd {
            InquiriesCmd::List { json, pending } => commands::inquiries::list(json, pending).await,
            InquiriesCmd::Respond { inquiry_id, answer } => {
                let answer_text = answer.join(" ");
                commands::inquiries::respond(&inquiry_id, &answer_text).await
            }
            InquiriesCmd::Info { inquiry_id, json } => {
                commands::inquiries::info(&inquiry_id, json).await
            }
        },
        Commands::Provider { cmd } => match cmd {
            ProviderCmd::List { json } => commands::provider::list(json).await,
            ProviderCmd::Info { provider_id, json } => {
                commands::provider::info(&provider_id, json).await
            }
            ProviderCmd::Add { source, branch } => {
                commands::provider::add(&source, branch.as_deref()).await
            }
            ProviderCmd::Edit {
                provider_id,
                property,
                value,
            } => commands::provider::edit(&provider_id, &property, &value).await,
            ProviderCmd::Remove { provider_id } => {
                commands::provider::remove(&provider_id).await
            }
        },
        Commands::Template { cmd } => match cmd {
            TemplateCmd::List { json } => commands::template::list(json).await,
            TemplateCmd::Info { id_or_name, json } => {
                commands::template::info(&id_or_name, json).await
            }
            TemplateCmd::Create { source, name, json } => {
                commands::template::create(&source, name.as_deref(), json).await
            }
            TemplateCmd::Remove { id, json } => commands::template::remove(&id, json).await,
            TemplateCmd::Submit {
                name_or_id,
                description,
                category,
                tags,
                json,
            } => {
                commands::template::submit(
                    &name_or_id,
                    description.as_deref(),
                    category.as_deref(),
                    tags.as_deref(),
                    json,
                )
                .await
            }
        },
        Commands::Workspace { cmd } => match cmd {
            WorkspaceCmd::Create { path, json } => {
                commands::workspace::create(path.as_deref(), json).await
            }
            WorkspaceCmd::Delete { workspace_id } => {
                commands::workspace::delete(&workspace_id).await
            }
            WorkspaceCmd::Info { workspace_id, json } => {
                commands::workspace::info(&workspace_id, json).await
            }
        },
        Commands::Keys { cmd } => match cmd {
            KeysCmd::List { json } => commands::keys::list(json).await,
            KeysCmd::Add {
                name,
                provider,
                key,
            } => commands::keys::add(&name, &provider, key.as_deref()).await,
            KeysCmd::Remove { key_id } => commands::keys::remove(&key_id).await,
        },
        Commands::Engine { cmd } => match cmd {
            EngineCmd::Status { json } => commands::engine::status(json).await,
            EngineCmd::BuildRuntime => commands::engine::build_runtime().await,
            EngineCmd::Containers { json } => commands::engine::containers(json).await,
            EngineCmd::Cleanup => commands::engine::cleanup().await,
        },
        Commands::Auth { cmd } => match cmd {
            AuthCmd::Status { json } => commands::auth::status(json).await,
            AuthCmd::Login => commands::auth::login().await,
            #[cfg(debug_assertions)]
            AuthCmd::Register => commands::auth::register().await,
            AuthCmd::Anonymous => commands::auth::anonymous().await,
            AuthCmd::Logout => commands::auth::logout().await,
        },
        Commands::Init { path } => commands::init::run(path.as_deref()).await,
        Commands::Validate { path } => commands::validate::run(path.as_deref()).await,
    }
}
