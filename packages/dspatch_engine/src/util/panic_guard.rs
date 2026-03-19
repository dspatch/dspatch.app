// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Panic-safe task spawning helpers.
//!
//! [`spawn_guarded`] wraps a tokio task so that any panic is logged rather
//! than silently dropped or propagated. Use this for one-off spawns that are
//! not already tracked by a `JoinSet`.

use tokio::task::JoinHandle;

/// Spawn a task and log any panic or unexpected cancellation.
///
/// Returns the outer [`JoinHandle`] for optional tracking. The inner future's
/// panic is caught by the tokio runtime and surfaced via `JoinError::is_panic`.
pub fn spawn_guarded<F>(name: &'static str, fut: F) -> JoinHandle<()>
where
    F: std::future::Future<Output = ()> + Send + 'static,
{
    tokio::spawn(async move {
        match tokio::spawn(fut).await {
            Ok(()) => {}
            Err(e) if e.is_panic() => {
                tracing::error!("[{name}] task panicked: {e:?}");
            }
            Err(e) => {
                tracing::warn!("[{name}] task cancelled: {e:?}");
            }
        }
    })
}
