// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Auth CLI commands: login, register, logout, anonymous mode, status.
//!
//! Supports the full authentication lifecycle including:
//! - Login with 2FA verification and device registration
//! - Registration with email verification, 2FA setup (QR code as HTML), backup codes
//! - Resuming incomplete auth flows (e.g. email not yet verified)
//! - Anonymous (local-only) mode

use std::io::{self, BufRead, Write as _};
use std::sync::Arc;
use std::time::Duration;

use serde_json::{Map, Value};

use crate::cli::formatter::OutputFormatter;
use crate::cli::with_sdk_auth_only;
use crate::domain::enums::{AuthMode, TokenScope};
use crate::domain::models::DeviceRegistrationRequest;
use crate::domain::services::AuthService;
use crate::sdk::DspatchSdk;
use crate::util::error::AppError;
use crate::util::result::Result;

// ── Public command handlers ──────────────────────────────────────────────

/// Show current authentication status.
pub async fn status(json: bool) -> Result<()> {
    with_sdk_auth_only(|sdk| async move {
        let state = sdk.auth_service().current_auth_state();
        let fmt = OutputFormatter::new(json);

        let mode_str = match state.mode {
            AuthMode::Undetermined => "not authenticated",
            AuthMode::Anonymous => "anonymous (local-only)",
            AuthMode::Connected => "connected",
        };

        let scope_str = state.token_scope.map(scope_display_name);

        let mut item: Map<String, Value> = Map::new();
        item.insert("mode".into(), Value::String(mode_str.to_string()));
        if let Some(scope) = scope_str {
            item.insert("scope".into(), Value::String(scope.to_string()));
        }
        if let Some(ref u) = state.username {
            item.insert("username".into(), Value::String(u.to_string()));
        }
        if let Some(ref e) = state.email {
            item.insert("email".into(), Value::String(e.to_string()));
        }
        if let Some(ref d) = state.device_id {
            item.insert("device_id".into(), Value::String(d.to_string()));
        }
        item.insert(
            "db_ready".into(),
            Value::Bool(sdk.is_database_ready().await),
        );

        fmt.print_item(&item);
        Ok(())
    })
    .await
}

/// Interactive login. Detects and resumes incomplete auth states.
pub async fn login() -> Result<()> {
    with_sdk_auth_only(|sdk| async move {
        let current = sdk.auth_service().current_auth_state();

        // Already fully authenticated.
        if current.mode == AuthMode::Connected
            && current.token_scope == Some(TokenScope::Full)
        {
            println!(
                "Already logged in as \"{}\".",
                current.username.as_deref().unwrap_or("unknown")
            );
            return Ok(());
        }

        // Resume incomplete auth flow.
        if current.mode == AuthMode::Connected {
            if let Some(scope) = current.token_scope {
                if scope != TokenScope::Full {
                    println!("Resuming incomplete authentication...");
                    let username = current.username.as_deref().unwrap_or("unknown");
                    resume_from_scope(&sdk, scope, username).await?;
                    return wait_and_finish(&sdk).await;
                }
            }
        }

        // Fresh login.
        let (username, password) = read_credentials()?;
        println!("Logging in...");
        let tokens = sdk.auth_service().login(&username, &password).await?;
        resume_from_scope(&sdk, tokens.scope, &username).await?;
        wait_and_finish(&sdk).await
    })
    .await
}

/// Interactive registration: username + email + password, then drives
/// through email verification, 2FA setup, backup codes, device registration.
///
/// Only available in debug builds — production registration goes through the GUI.
#[cfg(debug_assertions)]
pub async fn register() -> Result<()> {
    with_sdk_auth_only(|sdk| async move {
        let current = sdk.auth_service().current_auth_state();

        // Resume incomplete registration.
        if current.mode == AuthMode::Connected {
            if let Some(scope) = current.token_scope {
                if scope != TokenScope::Full {
                    println!("Resuming incomplete registration...");
                    let username = current.username.as_deref().unwrap_or("unknown");
                    resume_from_scope(&sdk, scope, username).await?;
                    return wait_and_finish(&sdk).await;
                }
                println!(
                    "Already registered and logged in as \"{}\".",
                    current.username.as_deref().unwrap_or("unknown")
                );
                return Ok(());
            }
        }

        let username = read_line_prompt("Username: ")?;
        if username.is_empty() {
            return Err(AppError::Validation("Username cannot be empty".into()));
        }
        let email = read_line_prompt("Email: ")?;
        if email.is_empty() {
            return Err(AppError::Validation("Email cannot be empty".into()));
        }
        let password = read_password_prompt("Password (min 12 characters): ")?;
        if password.len() < 12 {
            return Err(AppError::Validation(
                "Password must be at least 12 characters".into(),
            ));
        }
        let confirm = read_password_prompt("Confirm password: ")?;
        if password != confirm {
            return Err(AppError::Validation("Passwords do not match".into()));
        }

        println!("Registering...");
        let tokens = sdk
            .auth_service()
            .register(&username, &email, &password)
            .await?;
        println!("Account created. Check your email for a verification code.");

        resume_from_scope(&sdk, tokens.scope, &username).await?;
        wait_and_finish(&sdk).await
    })
    .await
}

/// Enter anonymous (local-only) mode.
pub async fn anonymous() -> Result<()> {
    with_sdk_auth_only(|sdk| async move {
        let current = sdk.auth_service().current_auth_state();
        if current.mode == AuthMode::Anonymous {
            println!("Already in anonymous mode.");
            return Ok(());
        }
        sdk.auth_service().enter_anonymous_mode().await?;
        println!("Entering anonymous mode...");
        sdk.wait_for_database(Duration::from_secs(10)).await?;
        println!("Ready. Using local-only mode (no sync or multi-device).");
        Ok(())
    })
    .await
}

/// Logout and clear stored credentials.
pub async fn logout() -> Result<()> {
    with_sdk_auth_only(|sdk| async move {
        let current = sdk.auth_service().current_auth_state();
        if current.mode == AuthMode::Undetermined {
            println!("Not logged in.");
            return Ok(());
        }
        sdk.auth_service().logout().await?;
        println!("Logged out.");
        Ok(())
    })
    .await
}

// ── Scope-based flow resumption ──────────────────────────────────────────

/// Drive the user through all remaining auth steps until Full scope.
async fn resume_from_scope(
    sdk: &Arc<DspatchSdk>,
    mut scope: TokenScope,
    username: &str,
) -> Result<()> {
    loop {
        match scope {
            TokenScope::Full => {
                println!("Authentication complete.");
                return Ok(());
            }
            TokenScope::EmailVerification => {
                scope = step_verify_email(sdk).await?;
            }
            TokenScope::Partial2fa => {
                scope = step_verify_2fa(sdk).await?;
            }
            TokenScope::Setup2fa => {
                scope = step_setup_2fa(sdk).await?;
            }
            TokenScope::AwaitingBackupConfirmation => {
                scope = step_backup_codes(sdk).await?;
            }
            TokenScope::DeviceRegistration => {
                scope = step_register_device(sdk, username).await?;
            }
        }
    }
}

// ── Individual auth steps ────────────────────────────────────────────────

async fn step_verify_email(sdk: &Arc<DspatchSdk>) -> Result<TokenScope> {
    println!("\n── Email Verification ──");
    println!("A verification code was sent to your email.");
    loop {
        let code = read_line_prompt("Enter 6-digit code (or 'resend'): ")?;
        if code.eq_ignore_ascii_case("resend") {
            sdk.auth_service().resend_verification().await?;
            println!("Verification email resent.");
            continue;
        }
        match sdk.auth_service().verify_email(&code).await {
            Ok(()) => {
                println!("Email verified.");
                return Ok(TokenScope::Setup2fa);
            }
            Err(e) => eprintln!("Verification failed: {e}. Try again."),
        }
    }
}

async fn step_verify_2fa(sdk: &Arc<DspatchSdk>) -> Result<TokenScope> {
    println!("\n── Two-Factor Authentication ──");
    loop {
        let input =
            read_line_prompt("Enter 2FA code (or 'backup' to use a backup code): ")?;
        let (code, is_backup) = if input.eq_ignore_ascii_case("backup") {
            (read_line_prompt("Enter backup code: ")?, true)
        } else {
            (input, false)
        };
        match sdk.auth_service().verify_2fa(&code, is_backup).await {
            Ok(tokens) => {
                println!("2FA verified.");
                return Ok(tokens.scope);
            }
            Err(e) => eprintln!("Verification failed: {e}. Try again."),
        }
    }
}

async fn step_setup_2fa(sdk: &Arc<DspatchSdk>) -> Result<TokenScope> {
    println!("\n── Two-Factor Authentication Setup ──");
    println!("Setting up 2FA...");

    let totp_data = sdk.auth_service().setup_2fa().await?;

    // Write QR code HTML and open in browser.
    let html_path = write_totp_qr_html(&totp_data.totp_uri, &totp_data.secret)?;
    println!("QR code page: {}", html_path.display());
    if open_in_browser(&html_path).is_err() {
        println!("Could not open browser. Open the file manually.");
    }

    println!("\nScan the QR code with your authenticator app.");
    println!("Manual entry secret: {}", totp_data.secret);

    loop {
        let code =
            read_line_prompt("\nEnter the 6-digit code from your authenticator: ")?;
        match sdk.auth_service().confirm_2fa(&code).await {
            Ok(_) => {
                println!("2FA confirmed.");
                let _ = std::fs::remove_file(&html_path);
                return Ok(TokenScope::AwaitingBackupConfirmation);
            }
            Err(e) => eprintln!("Confirmation failed: {e}. Try again."),
        }
    }
}

async fn step_backup_codes(sdk: &Arc<DspatchSdk>) -> Result<TokenScope> {
    println!("\n── Backup Codes ──");
    println!("Save these codes somewhere safe. Each can only be used once.\n");

    if let Ok(Some(codes)) = sdk.auth_service().get_backup_codes().await {
        for (i, code) in codes.iter().enumerate() {
            println!("  {:2}. {}", i + 1, code);
        }
        println!();
    }

    read_line_prompt("Press Enter after saving your backup codes...")?;
    sdk.auth_service().acknowledge_backup_codes().await?;
    println!("Backup codes acknowledged.");
    Ok(TokenScope::DeviceRegistration)
}

async fn step_register_device(
    sdk: &Arc<DspatchSdk>,
    _username: &str,
) -> Result<TokenScope> {
    println!("\n── Device Registration ──");

    let hostname = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .unwrap_or_else(|| "cli-device".to_string());
    let platform = if cfg!(target_os = "windows") {
        "windows"
    } else if cfg!(target_os = "macos") {
        "macos"
    } else {
        "linux"
    };

    println!("Registering device \"{}\" ({})...", hostname, platform);

    use ed25519_dalek::{Signer, SigningKey};
    use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret as X25519StaticSecret};

    // ed25519-dalek and x25519-dalek use rand_core 0.6; use the OsRng re-exported
    // via aes_gcm::aead (which depends on rand_core 0.6).
    let mut legacy_rng = aes_gcm::aead::OsRng;
    let identity_signing_key = SigningKey::generate(&mut legacy_rng);
    let identity_public = identity_signing_key.verifying_key().to_bytes().to_vec();
    let identity_hex = hex::encode(identity_signing_key.to_bytes());

    let signed_pre_key_secret = X25519StaticSecret::random_from_rng(&mut legacy_rng);
    let signed_pre_key_public = X25519PublicKey::from(&signed_pre_key_secret);
    let signature = identity_signing_key.sign(signed_pre_key_public.as_bytes());

    let request = DeviceRegistrationRequest {
        name: hostname,
        device_type: "desktop".to_string(),
        platform: platform.to_string(),
        identity_key: identity_public,
        signed_pre_key: signed_pre_key_public.as_bytes().to_vec(),
        signed_pre_key_id: 1,
        signed_pre_key_signature: signature.to_bytes().to_vec(),
        one_time_pre_keys: vec![],
    };

    let tokens = sdk
        .auth_service()
        .register_device(request, Some(&identity_hex))
        .await?;
    println!("Device registered successfully.");
    Ok(tokens.scope)
}

// ── Shared helpers ───────────────────────────────────────────────────────

async fn wait_and_finish(sdk: &Arc<DspatchSdk>) -> Result<()> {
    println!("Initializing database...");
    sdk.wait_for_database(Duration::from_secs(10)).await?;
    println!("Ready.");
    Ok(())
}

fn read_credentials() -> Result<(String, String)> {
    let username = read_line_prompt("Username: ")?;
    if username.is_empty() {
        return Err(AppError::Validation("Username cannot be empty".into()));
    }
    let password = read_password_prompt("Password: ")?;
    if password.is_empty() {
        return Err(AppError::Validation("Password cannot be empty".into()));
    }
    Ok((username, password))
}

fn read_password_prompt(prompt: &str) -> Result<String> {
    eprint!("{prompt}");
    io::stderr().flush().ok();
    rpassword::read_password()
        .map(|s| s.trim().to_string())
        .map_err(|e| AppError::Internal(format!("Failed to read password: {e}")))
}

fn read_line_prompt(prompt: &str) -> Result<String> {
    eprint!("{prompt}");
    io::stderr().flush().ok();
    let mut line = String::new();
    io::stdin()
        .lock()
        .read_line(&mut line)
        .map_err(|e| AppError::Internal(format!("Failed to read stdin: {e}")))?;
    Ok(line.trim().to_string())
}

fn scope_display_name(scope: TokenScope) -> &'static str {
    match scope {
        TokenScope::EmailVerification => "email_verification",
        TokenScope::Partial2fa => "partial_2fa",
        TokenScope::Setup2fa => "setup_2fa",
        TokenScope::AwaitingBackupConfirmation => "awaiting_backup_confirmation",
        TokenScope::DeviceRegistration => "device_registration",
        TokenScope::Full => "full",
    }
}

// ── QR Code HTML ─────────────────────────────────────────────────────────

/// Writes an HTML page with a QR code for the TOTP URI. Uses a JS library
/// from CDN so no extra Rust dependencies are needed.
fn write_totp_qr_html(
    totp_uri: &str,
    secret: &str,
) -> Result<std::path::PathBuf> {
    let totp_uri_json =
        serde_json::to_string(totp_uri).unwrap_or_else(|_| "\"\"".to_string());
    let html = format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>d:spatch — 2FA Setup</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #0a0a0a; color: #e0e0e0;
    display: flex; justify-content: center; align-items: center;
    min-height: 100vh; padding: 2rem;
  }}
  .card {{
    background: #1a1a1a; border: 1px solid #333; border-radius: 12px;
    padding: 2.5rem; max-width: 420px; width: 100%; text-align: center;
  }}
  h1 {{ font-size: 1.5rem; margin-bottom: 0.5rem; color: #fff; }}
  .subtitle {{ color: #888; margin-bottom: 2rem; font-size: 0.9rem; }}
  #qrcode {{ margin: 1.5rem auto; }}
  .secret-label {{ color: #888; font-size: 0.8rem; margin-top: 1.5rem; }}
  .secret {{
    font-family: 'SF Mono', 'Fira Code', monospace; font-size: 1.1rem;
    color: #4fc3f7; word-break: break-all; margin: 0.5rem 0 1rem;
    background: #111; padding: 0.75rem; border-radius: 6px;
    border: 1px solid #333; cursor: pointer;
  }}
  .secret:hover {{ background: #1c1c1c; }}
  .copied {{ color: #66bb6a; font-size: 0.8rem; opacity: 0; transition: opacity 0.3s; }}
  .copied.show {{ opacity: 1; }}
  .note {{
    color: #666; font-size: 0.8rem; margin-top: 1.5rem;
    border-top: 1px solid #222; padding-top: 1rem;
  }}
</style>
</head>
<body>
<div class="card">
  <h1>d:spatch</h1>
  <p class="subtitle">Scan this QR code with your authenticator app</p>
  <div id="qrcode"></div>
  <p class="secret-label">Or enter this secret manually:</p>
  <p class="secret" id="secret" title="Click to copy">{secret}</p>
  <p class="copied" id="copied">Copied to clipboard!</p>
  <p class="note">
    Generated by the d:spatch CLI.<br>
    You can close this page after scanning.
  </p>
</div>
<script src="https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js"></script>
<script>
  var qr = qrcode(0, 'M');
  qr.addData({totp_uri_json});
  qr.make();
  var el = document.getElementById('qrcode');
  el.innerHTML = qr.createSvgTag(6, 0);
  var svg = el.querySelector('svg');
  if (svg) {{
    svg.style.width = '240px';
    svg.style.height = '240px';
    svg.style.background = '#fff';
    svg.style.borderRadius = '8px';
    svg.style.padding = '12px';
  }}
  document.getElementById('secret').addEventListener('click', function() {{
    navigator.clipboard.writeText('{secret}').then(function() {{
      var c = document.getElementById('copied');
      c.classList.add('show');
      setTimeout(function() {{ c.classList.remove('show'); }}, 2000);
    }});
  }});
</script>
</body>
</html>"#,
        secret = secret,
        totp_uri_json = totp_uri_json,
    );

    let path = std::env::temp_dir().join("dspatch-2fa-setup.html");
    std::fs::write(&path, html)
        .map_err(|e| AppError::Internal(format!("Failed to write QR HTML: {e}")))?;
    Ok(path)
}

/// Opens a file in the default browser.
fn open_in_browser(path: &std::path::Path) -> std::result::Result<(), ()> {
    let path_str = path.to_string_lossy();

    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("cmd")
            .args(["/C", "start", "", &path_str])
            .spawn()
            .map(|_| ())
            .map_err(|_| ())
    }

    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open")
            .arg(&*path_str)
            .spawn()
            .map(|_| ())
            .map_err(|_| ())
    }

    #[cfg(target_os = "linux")]
    {
        std::process::Command::new("xdg-open")
            .arg(&*path_str)
            .spawn()
            .map(|_| ())
            .map_err(|_| ())
    }

    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    {
        Err(())
    }
}
