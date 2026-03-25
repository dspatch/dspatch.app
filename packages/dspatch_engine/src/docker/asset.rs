// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker build context assembly for the d:spatch runtime image.
//!
//! The Dockerfile and entrypoint.sh are embedded in the binary at compile
//! time via `include_str!`, so no external assets directory is needed.

/// Compute the Docker image tag for the runtime image.
///
/// Tagged versions (e.g., "v0.1.0") produce stable tags: `dspatch-runtime:v0.1.0`
/// The "main" branch produces date-stamped tags: `dspatch-runtime:main-20260325`
pub fn runtime_image_tag(router_version: &str) -> String {
    if router_version == "main" {
        let today = chrono::Utc::now().format("%Y%m%d");
        format!("dspatch-runtime:main-{today}")
    } else {
        format!("dspatch-runtime:{router_version}")
    }
}

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
/// Returns the temp directory path. The directory is owned by the caller and
/// will be deleted when the returned `tempfile::TempDir` is dropped.
pub async fn assemble_build_context() -> Result<(String, tempfile::TempDir), Box<dyn std::error::Error + Send + Sync>> {
    let temp_dir = tempfile::tempdir()?;
    let root = temp_dir.path();

    tokio::fs::write(root.join("Dockerfile"), DOCKERFILE.replace('\r', "")).await?;

    let entrypoint_path = root.join("entrypoint.sh");
    tokio::fs::write(&entrypoint_path, ENTRYPOINT_SH.replace('\r', "")).await?;

    // Set execute permission on entrypoint.sh on Unix systems.
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let perms = std::fs::Permissions::from_mode(0o755);
        std::fs::set_permissions(&entrypoint_path, perms)?;
    }

    let path = root.to_string_lossy().to_string();
    Ok((path, temp_dir))
}
