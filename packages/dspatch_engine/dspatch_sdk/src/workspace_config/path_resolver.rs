// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use super::config::WorkspaceConfig;

/// Expands a leading `~` or `~/` to the user's home directory.
///
/// Returns the path unchanged if it does not start with `~`,
/// or if the home directory cannot be determined.
pub fn expand_tilde(path: &str) -> String {
    if !path.starts_with('~') {
        return path.to_string();
    }

    let home = std::env::var("HOME")
        .or_else(|_| std::env::var("USERPROFILE"))
        .unwrap_or_default();

    if home.is_empty() {
        return path.to_string();
    }

    if path == "~" {
        return home;
    }

    if path.starts_with("~/") || path.starts_with("~\\") {
        return format!("{}{}", home, &path[1..]);
    }

    path.to_string()
}

/// Expands tilde in all path fields of a [`WorkspaceConfig`].
///
/// Resolves:
/// - [`WorkspaceConfig::workspace_dir`]
/// - [`MountConfig::host_path`] for every mount
pub fn resolve_config_paths(config: &WorkspaceConfig) -> WorkspaceConfig {
    let resolved_dir = config.workspace_dir.as_ref().map(|d| expand_tilde(d));

    let resolved_mounts: Vec<_> = config
        .mounts
        .iter()
        .map(|m| {
            let resolved_host = expand_tilde(&m.host_path);
            if resolved_host == m.host_path {
                m.clone()
            } else {
                let mut mount = m.clone();
                mount.host_path = resolved_host;
                mount
            }
        })
        .collect();

    let dir_changed = resolved_dir != config.workspace_dir;
    let mounts_changed = resolved_mounts != config.mounts;

    if !dir_changed && !mounts_changed {
        return config.clone();
    }

    let mut result = config.clone();
    if dir_changed {
        result.workspace_dir = resolved_dir;
    }
    if mounts_changed {
        result.mounts = resolved_mounts;
    }
    result
}
