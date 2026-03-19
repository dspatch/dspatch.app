// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Retry utility for transient errors.
//!
//! Only use this for **idempotent** operations (GET requests, read-only queries).
//! Never wrap POST/PUT/DELETE calls — retrying mutations risks duplicate side effects.

use std::time::Duration;

use tokio::time::sleep;

/// Retry `operation` up to `max_attempts` times with exponential backoff.
///
/// Jitter is deterministic (scales with attempt number) to avoid adding a `rand`
/// dependency. Delay formula: `base_delay * 2^(attempt-1) * (0.5 + attempt * 0.1)`
/// capped so jitter stays in the range [0.5, 1.0].
///
/// # Panics
/// Does not panic. Returns the last error when all attempts are exhausted.
pub async fn with_retry<F, Fut, T, E>(
    max_attempts: u32,
    base_delay: Duration,
    mut operation: F,
) -> Result<T, E>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = Result<T, E>>,
    E: std::fmt::Display,
{
    let mut attempt = 0;
    loop {
        attempt += 1;
        match operation().await {
            Ok(val) => return Ok(val),
            Err(e) if attempt >= max_attempts => return Err(e),
            Err(e) => {
                let jitter = 0.5 + (attempt as f64 * 0.1).min(0.5); // range: [0.5, 1.0]
                let delay = base_delay.mul_f64(2f64.powi(attempt as i32 - 1) * jitter);
                tracing::warn!(
                    "Attempt {attempt}/{max_attempts} failed: {e}. Retrying in {delay:?}"
                );
                sleep(delay).await;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicU32, Ordering};
    use std::sync::Arc;

    #[tokio::test]
    async fn succeeds_on_first_attempt() {
        let result: Result<u32, String> =
            with_retry(3, Duration::from_millis(1), || async { Ok(42) }).await;
        assert_eq!(result.unwrap(), 42);
    }

    #[tokio::test]
    async fn retries_and_succeeds() {
        let attempts = Arc::new(AtomicU32::new(0));
        let attempts2 = Arc::clone(&attempts);
        let result: Result<u32, String> = with_retry(3, Duration::from_millis(1), move || {
            let counter = Arc::clone(&attempts2);
            async move {
                let n = counter.fetch_add(1, Ordering::SeqCst) + 1;
                if n < 3 { Err(format!("fail {n}")) } else { Ok(n) }
            }
        })
        .await;
        assert!(result.is_ok());
        assert_eq!(attempts.load(Ordering::SeqCst), 3);
    }

    #[tokio::test]
    async fn exhausts_attempts_and_returns_last_error() {
        let result: Result<u32, String> =
            with_retry(3, Duration::from_millis(1), || async { Err("always fails".to_string()) })
                .await;
        assert_eq!(result.unwrap_err(), "always fails");
    }
}
