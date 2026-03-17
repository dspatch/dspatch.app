// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker build context assembly for the d:spatch runtime image.
//!
//! The Dockerfile and entrypoint.sh are embedded in the binary at compile
//! time via `include_str!`, so no external assets directory is needed.

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

/// Dockerfile content, embedded at compile time.
const DOCKERFILE: &str = include_str!("../../../../assets/docker/runtime/Dockerfile");

/// Entrypoint script content, embedded at compile time.
const ENTRYPOINT_SH: &str = include_str!("../../../../assets/docker/runtime/entrypoint.sh");

/// Assembles a Docker build context directory containing the embedded
/// Dockerfile and entrypoint.sh.
///
/// Returns the temp directory path. Caller must delete after use.
pub async fn assemble_build_context() -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
    let temp_dir = tempfile::tempdir()?;
    let root = temp_dir.path();

    tokio::fs::write(root.join("Dockerfile"), DOCKERFILE.replace('\r', "")).await?;
    tokio::fs::write(root.join("entrypoint.sh"), ENTRYPOINT_SH.replace('\r', "")).await?;

    // Persist the temp dir (don't let it be deleted on drop).
    let path = root.to_string_lossy().to_string();
    std::mem::forget(temp_dir);
    Ok(path)
}
