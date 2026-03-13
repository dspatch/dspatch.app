// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker build context assembly for the d:spatch runtime image.
//!
//! Ported from `data/docker/dockerfile_asset.dart`.

use std::path::Path;

/// Tag for the d:spatch agent runtime Docker image.
pub const RUNTIME_IMAGE_TAG: &str = "dspatch/runtime:latest";

/// Label applied to all d:spatch-managed containers.
pub const DSPATCH_CONTAINER_LABEL: &str = "com.dspatch.managed";

/// Docker container state value for a running container.
#[allow(dead_code)]
pub const CONTAINER_STATE_RUNNING: &str = "running";

/// Docker container state value for a cleanly exited container.
#[allow(dead_code)]
pub const CONTAINER_STATE_EXITED: &str = "exited";

/// Assembles a Docker build context directory containing:
/// - `Dockerfile` (from `assets_dir`)
/// - `entrypoint.sh` (from `assets_dir`)
///
/// Returns the temp directory path. Caller must delete after use.
pub async fn assemble_build_context(
    assets_dir: &str,
) -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
    let temp_dir = tempfile::tempdir()?;
    let root = temp_dir.path();

    // Dockerfile
    let dockerfile_src = Path::new(assets_dir)
        .join("docker")
        .join("runtime")
        .join("Dockerfile");
    let dockerfile_content = tokio::fs::read_to_string(&dockerfile_src).await?;
    tokio::fs::write(root.join("Dockerfile"), &dockerfile_content).await?;

    // Entrypoint
    let entrypoint_src = Path::new(assets_dir)
        .join("docker")
        .join("runtime")
        .join("entrypoint.sh");
    let entrypoint_content = tokio::fs::read_to_string(&entrypoint_src).await?;
    tokio::fs::write(root.join("entrypoint.sh"), &entrypoint_content).await?;

    // Persist the temp dir (don't let it be deleted on drop).
    let path = root.to_string_lossy().to_string();
    // We intentionally leak the TempDir so the caller controls cleanup.
    std::mem::forget(temp_dir);
    Ok(path)
}
