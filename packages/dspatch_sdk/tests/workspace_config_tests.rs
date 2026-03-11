// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

use std::collections::HashMap;

use dspatch_sdk::workspace_config::config::*;
use dspatch_sdk::workspace_config::env_resolver;
use dspatch_sdk::workspace_config::flat_agent::{self, flatten_agent_hierarchy};
use dspatch_sdk::workspace_config::parser::{encode_yaml, parse_workspace_config};
use dspatch_sdk::workspace_config::path_resolver;
use dspatch_sdk::workspace_config::validation::validate_config;

fn valid_yaml() -> &'static str {
    r#"
name: my-workspace
env:
  OPENAI_API_KEY: "sk-test-123"
agents:
  coder:
    template: claude-coder
    env:
      EXTRA: "val"
    peers:
      - reviewer
  reviewer:
    template: gpt-reviewer
    sub_agents:
      linter:
        template: eslint-linter
mounts:
  - host_path: /home/user/data
    container_path: /data
    read_only: true
docker:
  memory_limit: 4g
  cpu_limit: 2.0
  network_mode: bridge
  ports:
    - "8080:80"
  gpu: false
"#
}

// --- Parse tests ---

#[test]
fn parse_valid_yaml() {
    let config = parse_workspace_config(valid_yaml()).unwrap();
    assert_eq!(config.name, "my-workspace");
    assert_eq!(config.agents.len(), 2);
    assert_eq!(config.agents["coder"].template, "claude-coder");
    assert_eq!(config.agents["reviewer"].template, "gpt-reviewer");
    assert_eq!(config.agents["reviewer"].sub_agents.len(), 1);
    assert_eq!(
        config.agents["reviewer"].sub_agents["linter"].template,
        "eslint-linter"
    );
    assert_eq!(config.mounts.len(), 1);
    assert_eq!(config.mounts[0].host_path, "/home/user/data");
    assert_eq!(config.mounts[0].container_path, "/data");
    assert!(config.mounts[0].read_only);
    assert_eq!(config.docker.memory_limit.as_deref(), Some("4g"));
    assert_eq!(config.docker.cpu_limit, Some(2.0));
    assert_eq!(config.docker.network_mode, "bridge");
    assert_eq!(config.docker.ports, vec!["8080:80"]);
    assert!(!config.docker.gpu);
}

#[test]
fn parse_minimal_yaml() {
    let yaml = r#"
name: minimal
agents:
  bot:
    template: simple-bot
"#;
    let config = parse_workspace_config(yaml).unwrap();
    assert_eq!(config.name, "minimal");
    assert_eq!(config.agents.len(), 1);
    assert_eq!(config.docker, DockerConfig::default());
}

#[test]
fn parse_invalid_yaml_returns_error() {
    let result = parse_workspace_config("{{invalid yaml}}");
    assert!(result.is_err());
}

#[test]
fn parse_empty_yaml_returns_error() {
    // Empty string parses as null in YAML which won't deserialize to WorkspaceConfig
    let result = parse_workspace_config("");
    assert!(result.is_err());
}

// --- Validation tests ---

#[test]
fn validate_valid_config_no_errors() {
    let config = parse_workspace_config(valid_yaml()).unwrap();
    let errors = validate_config(&config);
    assert!(errors.is_empty(), "Expected no errors, got: {:?}", errors);
}

#[test]
fn validate_missing_name() {
    let yaml = r#"
name: ""
agents:
  bot:
    template: simple-bot
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors.iter().any(|e| e.field == "name"));
}

#[test]
fn validate_empty_agents() {
    let yaml = r#"
name: test-workspace
agents: {}
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors.iter().any(|e| e.field == "agents"));
}

#[test]
fn validate_empty_template() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: ""
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors
        .iter()
        .any(|e| e.field.contains("template") && e.message.contains("required")));
}

#[test]
fn validate_peer_references_nonexistent() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
    peers:
      - ghost
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors
        .iter()
        .any(|e| e.field.contains("peers") && e.message.contains("ghost")));
}

#[test]
fn validate_reserved_env_prefix() {
    let yaml = r#"
name: test-workspace
env:
  DSPATCH_INTERNAL: forbidden
agents:
  bot:
    template: simple-bot
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors
        .iter()
        .any(|e| e.message.contains("reserved prefix")));
}

#[test]
fn validate_invalid_mount_paths() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
mounts:
  - host_path: ""
    container_path: ""
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors.iter().any(|e| e.field.contains("host_path")));
    assert!(errors.iter().any(|e| e.field.contains("container_path")));
}

#[test]
fn validate_reserved_container_path() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
mounts:
  - host_path: /tmp/data
    container_path: /workspace/stuff
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors
        .iter()
        .any(|e| e.message.contains("reserved path")));
}

#[test]
fn validate_invalid_docker_memory() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
docker:
  memory_limit: invalid
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors
        .iter()
        .any(|e| e.field == "docker.memory_limit"));
}

#[test]
fn validate_invalid_docker_cpu() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
docker:
  cpu_limit: -1.0
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors.iter().any(|e| e.field == "docker.cpu_limit"));
}

#[test]
fn validate_invalid_network_mode() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
docker:
  network_mode: custom
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors
        .iter()
        .any(|e| e.field == "docker.network_mode"));
}

#[test]
fn validate_invalid_port_mapping() {
    let yaml = r#"
name: test-workspace
agents:
  bot:
    template: simple-bot
docker:
  ports:
    - "bad-port"
"#;
    let config = parse_workspace_config(yaml).unwrap();
    let errors = validate_config(&config);
    assert!(errors.iter().any(|e| e.field.contains("docker.ports")));
}

// --- Flatten tests ---

#[test]
fn flatten_nested_agents() {
    let config = parse_workspace_config(valid_yaml()).unwrap();
    let flat = flatten_agent_hierarchy(&config);

    assert_eq!(flat.len(), 3);

    let coder = flat.iter().find(|a| a.agent_key == "coder").unwrap();
    assert_eq!(coder.template_name, "claude-coder");
    assert!(coder.parent_key.is_none());
    assert!(coder.auto_start); // root agent defaults to true

    let reviewer = flat.iter().find(|a| a.agent_key == "reviewer").unwrap();
    assert_eq!(reviewer.template_name, "gpt-reviewer");
    assert!(reviewer.parent_key.is_none());

    let linter = flat.iter().find(|a| a.agent_key == "linter").unwrap();
    assert_eq!(linter.template_name, "eslint-linter");
    assert_eq!(linter.parent_key.as_deref(), Some("reviewer"));
    assert!(!linter.auto_start); // sub-agent defaults to false
}

// --- Encode round-trip test ---

#[test]
fn encode_then_parse_roundtrip() {
    let config = parse_workspace_config(valid_yaml()).unwrap();
    let yaml_out = encode_yaml(&config).unwrap();
    let reparsed = parse_workspace_config(&yaml_out).unwrap();
    assert_eq!(config, reparsed);
}

// --- File I/O tests ---

#[test]
fn parse_and_write_file_roundtrip() {
    let config = parse_workspace_config(valid_yaml()).unwrap();

    let tmp = tempfile::tempdir().unwrap();
    dspatch_sdk::workspace_config::parser::write_workspace_config(tmp.path(), &config).unwrap();

    let reparsed =
        dspatch_sdk::workspace_config::parser::parse_workspace_config_file(tmp.path()).unwrap();
    assert_eq!(config, reparsed);
}

#[test]
fn parse_file_not_found() {
    let tmp = tempfile::tempdir().unwrap();
    let result =
        dspatch_sdk::workspace_config::parser::parse_workspace_config_file(tmp.path());
    assert!(result.is_err());
}

// --- EnvResolver tests ---

#[test]
fn resolve_agent_env_merges_global_and_agent() {
    let mut global = HashMap::new();
    global.insert("KEY1".to_string(), "global1".to_string());
    global.insert("KEY2".to_string(), "global2".to_string());

    let mut agent = HashMap::new();
    agent.insert("KEY2".to_string(), "agent2".to_string());
    agent.insert("KEY3".to_string(), "agent3".to_string());

    let result = env_resolver::resolve_agent_env(&global, &agent, &[]);
    assert_eq!(result["KEY1"], "global1");
    assert_eq!(result["KEY2"], "agent2"); // agent override
    assert_eq!(result["KEY3"], "agent3");
}

#[test]
fn resolve_agent_env_filters_required() {
    let mut global = HashMap::new();
    global.insert("KEY1".to_string(), "val1".to_string());
    global.insert("KEY2".to_string(), "val2".to_string());

    let agent = HashMap::new();

    let result = env_resolver::resolve_agent_env(
        &global,
        &agent,
        &["KEY1".to_string()],
    );
    assert_eq!(result.len(), 1);
    assert_eq!(result["KEY1"], "val1");
}

#[test]
fn resolve_agent_env_strips_system_prefix() {
    let mut global = HashMap::new();
    global.insert("DSPATCH_INTERNAL".to_string(), "bad".to_string());
    global.insert("SAFE_KEY".to_string(), "good".to_string());

    let result = env_resolver::resolve_agent_env(&global, &HashMap::new(), &[]);
    assert!(!result.contains_key("DSPATCH_INTERNAL"));
    assert_eq!(result["SAFE_KEY"], "good");
}

// --- PathResolver tests ---

#[test]
fn expand_tilde_with_home() {
    // This test is platform-dependent; if HOME is not set, it won't expand.
    // We test the no-tilde case which is platform-independent.
    assert_eq!(path_resolver::expand_tilde("/absolute/path"), "/absolute/path");
    assert_eq!(path_resolver::expand_tilde("relative/path"), "relative/path");
}

// --- AgentMapHelpers tests ---

#[test]
fn add_agent_creates_unique_key() {
    let mut agents = HashMap::new();
    agents.insert(
        "agent-1".to_string(),
        AgentConfig {
            template: "t".to_string(),
            env: HashMap::new(),
            sub_agents: HashMap::new(),
            peers: Vec::new(),
            auto_start: None,
        },
    );

    let result = flat_agent::add_agent(&agents, "agent");
    assert_eq!(result.len(), 2);
    // The new key should be agent-2 (since len was 1, so 1+1=2)
    assert!(result.contains_key("agent-2"));
}

#[test]
fn remove_agent_cleans_peers() {
    let mut agents = HashMap::new();
    agents.insert(
        "a".to_string(),
        AgentConfig {
            template: "t".to_string(),
            env: HashMap::new(),
            sub_agents: HashMap::new(),
            peers: vec!["b".to_string()],
            auto_start: None,
        },
    );
    agents.insert(
        "b".to_string(),
        AgentConfig {
            template: "t".to_string(),
            env: HashMap::new(),
            sub_agents: HashMap::new(),
            peers: Vec::new(),
            auto_start: None,
        },
    );

    let result = flat_agent::remove_agent(&agents, "b");
    assert_eq!(result.len(), 1);
    assert!(result["a"].peers.is_empty());
}

#[test]
fn rename_agent_updates_peers() {
    let mut agents = HashMap::new();
    agents.insert(
        "old".to_string(),
        AgentConfig {
            template: "t".to_string(),
            env: HashMap::new(),
            sub_agents: HashMap::new(),
            peers: Vec::new(),
            auto_start: None,
        },
    );
    agents.insert(
        "other".to_string(),
        AgentConfig {
            template: "t".to_string(),
            env: HashMap::new(),
            sub_agents: HashMap::new(),
            peers: vec!["old".to_string()],
            auto_start: None,
        },
    );

    let result = flat_agent::rename_agent(&agents, "old", "new");
    assert!(result.contains_key("new"));
    assert!(!result.contains_key("old"));
    assert_eq!(result["other"].peers, vec!["new"]);
}

// --- YAML coercion: numeric env values parsed as strings ---

#[test]
fn parse_numeric_env_values_as_strings() {
    let yaml = r#"
name: test
agents:
  bot:
    template: t
    env:
      PORT: 8080
      DEBUG: true
"#;
    // serde_yaml coerces these to strings via HashMap<String, String>
    let config = parse_workspace_config(yaml).unwrap();
    assert_eq!(config.agents["bot"].env["PORT"], "8080");
    assert_eq!(config.agents["bot"].env["DEBUG"], "true");
}

// --- Docker defaults ---

#[test]
fn docker_config_defaults() {
    let yaml = r#"
name: test
agents:
  bot:
    template: t
"#;
    let config = parse_workspace_config(yaml).unwrap();
    assert_eq!(config.docker.network_mode, "host");
    assert!(config.docker.home_persistence);
    assert!(!config.docker.gpu);
    assert!(config.docker.ports.is_empty());
    assert!(config.docker.memory_limit.is_none());
    assert!(config.docker.cpu_limit.is_none());
}
