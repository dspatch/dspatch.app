// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Tests for workspace_bridge pure utility functions.
//!
//! Integration tests (Docker, server, database) are out of scope.

use std::collections::HashMap;

use dspatch_engine::server::workspace_bridge::{
    build_agents_meta, classify_log_level, dir_name_from_git_url, docker_path,
    parse_docker_timestamp, parse_git_url, strip_docker_timestamp,
};
use dspatch_engine::domain::enums::LogLevel;
use dspatch_engine::workspace_config::config::AgentConfig;

// ═══════════════════════════════════════════════════════════════════════
// docker_path tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn docker_path_converts_backslashes() {
    assert_eq!(docker_path(r"C:\Users\oak\project"), "C:/Users/oak/project");
}

#[test]
fn docker_path_preserves_forward_slashes() {
    assert_eq!(docker_path("/home/user/project"), "/home/user/project");
}

#[test]
fn docker_path_handles_mixed_slashes() {
    assert_eq!(
        docker_path(r"C:\Users/oak\project/src"),
        "C:/Users/oak/project/src"
    );
}

#[test]
fn docker_path_handles_empty_string() {
    assert_eq!(docker_path(""), "");
}

// ═══════════════════════════════════════════════════════════════════════
// dir_name_from_git_url tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn dir_name_from_https_url() {
    assert_eq!(
        dir_name_from_git_url("https://github.com/org/my-agent.git"),
        "my-agent"
    );
}

#[test]
fn dir_name_from_https_url_no_git_suffix() {
    assert_eq!(
        dir_name_from_git_url("https://github.com/org/my-agent"),
        "my-agent"
    );
}

#[test]
fn dir_name_from_ssh_url() {
    assert_eq!(
        dir_name_from_git_url("git@github.com:org/my-agent.git"),
        "my-agent"
    );
}

#[test]
fn dir_name_strips_tree_ref() {
    assert_eq!(
        dir_name_from_git_url("https://github.com/org/repo/tree/main"),
        "repo"
    );
}

#[test]
fn dir_name_strips_commit_ref() {
    assert_eq!(
        dir_name_from_git_url("https://github.com/org/repo/commit/abc123"),
        "repo"
    );
}

// ═══════════════════════════════════════════════════════════════════════
// parse_git_url tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn parse_git_url_with_tree_ref() {
    let (base, git_ref) =
        parse_git_url("https://github.com/org/repo/tree/feature-branch");
    assert_eq!(base, "https://github.com/org/repo");
    assert_eq!(git_ref, Some("feature-branch"));
}

#[test]
fn parse_git_url_with_commit_ref() {
    let (base, git_ref) =
        parse_git_url("https://github.com/org/repo/commit/abc123def");
    assert_eq!(base, "https://github.com/org/repo");
    assert_eq!(git_ref, Some("abc123def"));
}

#[test]
fn parse_git_url_plain() {
    let (base, git_ref) = parse_git_url("https://github.com/org/repo");
    assert_eq!(base, "https://github.com/org/repo");
    assert_eq!(git_ref, None);
}

#[test]
fn parse_git_url_ssh() {
    let (base, git_ref) = parse_git_url("git@github.com:org/repo.git");
    assert_eq!(base, "git@github.com:org/repo.git");
    assert_eq!(git_ref, None);
}

// ═══════════════════════════════════════════════════════════════════════
// build_agents_meta tests
// ═══════════════════════════════════════════════════════════════════════

fn make_agent(template: &str, peers: Vec<&str>, sub_agents: HashMap<String, AgentConfig>) -> AgentConfig {
    AgentConfig {
        template: template.to_string(),
        env: HashMap::new(),
        sub_agents,
        peers: peers.into_iter().map(|s| s.to_string()).collect(),
        auto_start: None,
    }
}

#[test]
fn build_agents_meta_single_root() {
    let agents = HashMap::from([
        ("lead".to_string(), make_agent("tmpl-a", vec![], HashMap::new())),
    ]);
    let template_fields = HashMap::new();

    let meta = build_agents_meta(&agents, &template_fields, true);
    assert_eq!(meta.len(), 1);
    assert_eq!(meta["lead"]["is_root"], true);
    assert_eq!(meta["lead"]["peers"], "");
}

#[test]
fn build_agents_meta_with_peers() {
    let agents = HashMap::from([
        ("lead".to_string(), make_agent("tmpl-a", vec!["coder"], HashMap::new())),
        ("coder".to_string(), make_agent("tmpl-b", vec![], HashMap::new())),
    ]);
    let template_fields = HashMap::new();

    let meta = build_agents_meta(&agents, &template_fields, true);
    assert_eq!(meta.len(), 2);
    assert_eq!(meta["lead"]["is_root"], true);
    assert_eq!(meta["lead"]["peers"], "coder");
    assert_eq!(meta["coder"]["is_root"], true);
    assert_eq!(meta["coder"]["peers"], "");
}

#[test]
fn build_agents_meta_with_sub_agents() {
    let sub = HashMap::from([
        ("worker".to_string(), make_agent("tmpl-c", vec![], HashMap::new())),
    ]);
    let agents = HashMap::from([
        ("lead".to_string(), make_agent("tmpl-a", vec![], sub)),
    ]);
    let template_fields = HashMap::new();

    let meta = build_agents_meta(&agents, &template_fields, true);
    assert_eq!(meta.len(), 2);
    assert_eq!(meta["lead"]["is_root"], true);
    // Sub-agents are automatically added as peers.
    assert_eq!(meta["lead"]["peers"], "worker");
    assert_eq!(meta["worker"]["is_root"], false);
    assert_eq!(meta["worker"]["peers"], "");
}

#[test]
fn build_agents_meta_with_template_fields() {
    let agents = HashMap::from([
        ("lead".to_string(), make_agent("tmpl-a", vec![], HashMap::new())),
    ]);
    let template_fields = HashMap::from([
        (
            "tmpl-a".to_string(),
            HashMap::from([
                ("role".to_string(), "coordinator".to_string()),
            ]),
        ),
    ]);

    let meta = build_agents_meta(&agents, &template_fields, true);
    assert_eq!(meta["lead"]["fields"]["role"], "coordinator");
}

// ═══════════════════════════════════════════════════════════════════════
// classify_log_level tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn classify_error_keywords() {
    assert_eq!(classify_log_level("Something ERROR happened", LogLevel::Info), LogLevel::Error);
    assert_eq!(classify_log_level("Traceback (most recent call last):", LogLevel::Info), LogLevel::Error);
    assert_eq!(classify_log_level("ValueError: invalid value", LogLevel::Info), LogLevel::Error);
    assert_eq!(classify_log_level("FATAL: cannot continue", LogLevel::Info), LogLevel::Error);
}

#[test]
fn classify_warn_keyword() {
    assert_eq!(classify_log_level("WARNING: deprecated function", LogLevel::Info), LogLevel::Warn);
    assert_eq!(classify_log_level("warn: something", LogLevel::Info), LogLevel::Warn);
}

#[test]
fn classify_normal_line() {
    assert_eq!(classify_log_level("Starting agent...", LogLevel::Info), LogLevel::Info);
}

#[test]
fn classify_continuation_in_error_block() {
    // Indented line after error inherits error level.
    assert_eq!(classify_log_level("  File \"main.py\", line 42", LogLevel::Error), LogLevel::Error);
    assert_eq!(classify_log_level("    in <module>", LogLevel::Error), LogLevel::Error);
}

#[test]
fn classify_non_continuation_resets_to_info() {
    // Non-indented, no keywords, previous was error -> info.
    assert_eq!(classify_log_level("Starting new task", LogLevel::Error), LogLevel::Info);
}

// ═══════════════════════════════════════════════════════════════════════
// strip_docker_timestamp tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn strip_docker_timestamp_valid() {
    let line = "2026-03-04T06:47:27.123456789Z Starting agent...";
    assert_eq!(strip_docker_timestamp(line), "Starting agent...");
}

#[test]
fn strip_docker_timestamp_no_timestamp() {
    let line = "No timestamp here";
    assert_eq!(strip_docker_timestamp(line), "No timestamp here");
}

#[test]
fn strip_docker_timestamp_short_prefix() {
    // Space index too early — not a Docker timestamp.
    let line = "hi there";
    assert_eq!(strip_docker_timestamp(line), "hi there");
}

// ═══════════════════════════════════════════════════════════════════════
// parse_docker_timestamp tests
// ═══════════════════════════════════════════════════════════════════════

#[test]
fn parse_docker_timestamp_valid() {
    let line = "2026-03-04T06:47:27.123456789Z Starting agent...";
    let parsed = parse_docker_timestamp(line);
    assert_eq!(parsed.message, "Starting agent...");
    // The timestamp should be around 2026-03-04
    assert_eq!(parsed.timestamp.date().year(), 2026);
}

#[test]
fn parse_docker_timestamp_no_timestamp() {
    let line = "Just a message";
    let parsed = parse_docker_timestamp(line);
    assert_eq!(parsed.message, "Just a message");
}

use chrono::Datelike;
