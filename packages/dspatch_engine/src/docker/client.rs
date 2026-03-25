// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Docker CLI client that shells out to the `docker` binary.
//!
//! All methods invoke `docker <subcommand>` via [`DockerCli`] and parse the
//! result. This approach works on all platforms without extra configuration.
//!
//! Ported from `data/docker/docker_client.dart`.

use std::collections::HashMap;
use std::process::Output;

use async_stream::stream;
use futures::Stream;
use tokio::io::{AsyncBufReadExt, BufReader};

use super::cli::{DockerCli, DockerCliException};
use super::models::*;

/// Docker CLI client that shells out to the `docker` binary.
///
/// ## Testing
///
/// Inject a custom [`DockerCli`] to control process results.
///
/// ## Streaming
///
/// [`build_image`] and [`container_logs`] use [`DockerCli::start`] for streaming
/// stdout line-by-line. All other methods use [`DockerCli::run`] and wait for
/// completion.
pub struct DockerClient {
    cli: DockerCli,
}

impl DockerClient {
    pub fn new(cli: DockerCli) -> Self {
        Self { cli }
    }

    /// Creates a client using the default [`DockerCli`] (real process calls).
    pub fn for_platform() -> Self {
        Self::new(DockerCli::new())
    }

    // ─── Helpers ────────────────────────────────────────────────────────

    /// Returns `Err` if the output has a non-zero exit code.
    fn check_result(output: &Output) -> Result<(), DockerCliException> {
        if !output.status.success() {
            let exit_code = output.status.code().unwrap_or(-1);
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            return Err(DockerCliException::new(stderr, exit_code));
        }
        Ok(())
    }

    /// Parses NDJSON (one JSON object per line) from CLI stdout.
    fn parse_ndjson(stdout: &str) -> Vec<serde_json::Value> {
        let trimmed = stdout.trim();
        if trimmed.is_empty() {
            return Vec::new();
        }
        trimmed
            .lines()
            .filter(|line| !line.trim().is_empty())
            .filter_map(|line| serde_json::from_str(line).ok())
            .collect()
    }

    /// Parses a Docker CLI labels string (`key=val,key2=val2`) into a map.
    fn parse_labels(labels: &str) -> HashMap<String, String> {
        if labels.is_empty() {
            return HashMap::new();
        }
        labels
            .split(',')
            .map(|pair| {
                if let Some(idx) = pair.find('=') {
                    (pair[..idx].to_string(), pair[idx + 1..].to_string())
                } else {
                    (pair.to_string(), String::new())
                }
            })
            .collect()
    }

    // ─── Daemon ──────────────────────────────────────────────────────────

    /// Checks if the Docker daemon is reachable. Returns `Err` on failure.
    pub async fn ping(&self) -> Result<(), DockerCliException> {
        match self.cli.run(&["version"]).await {
            Ok(output) => Self::check_result(&output),
            Err(e) => Err(DockerCliException::new(
                format!("Docker not found: {e}"),
                -1,
            )),
        }
    }

    /// Returns daemon information including available runtimes.
    pub async fn info(&self) -> Result<DockerInfo, DockerCliException> {
        let output = self
            .cli
            .run(&["info", "--format", "{{json .}}"])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        serde_json::from_str(stdout.trim())
            .map_err(|e| DockerCliException::new(format!("Failed to parse info: {e}"), 0))
    }

    /// Returns Docker daemon version details.
    pub async fn version(&self) -> Result<DockerVersion, DockerCliException> {
        let output = self
            .cli
            .run(&["version", "--format", "{{json .Server}}"])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        let json: serde_json::Value = serde_json::from_str(stdout.trim())
            .map_err(|e| DockerCliException::new(format!("Failed to parse version: {e}"), 0))?;

        Ok(DockerVersion {
            version: json["Version"].as_str().unwrap_or("").to_string(),
            api_version: json["APIVersion"]
                .as_str()
                .or_else(|| json["ApiVersion"].as_str())
                .unwrap_or("")
                .to_string(),
            os: json["Os"].as_str().unwrap_or("").to_string(),
            arch: json["Arch"].as_str().unwrap_or("").to_string(),
        })
    }

    // ─── Images ──────────────────────────────────────────────────────────

    /// Lists images. Optionally filter by reference (e.g. `dspatch/runtime`).
    ///
    /// Two-step: get IDs with `docker images -q`, then `docker image inspect`.
    pub async fn list_images(
        &self,
        filter: Option<&str>,
    ) -> Result<Vec<DockerImage>, DockerCliException> {
        // Step 1: Get image IDs.
        let mut args = vec!["images", "-q", "--no-trunc"];
        let filter_arg;
        if let Some(f) = filter {
            filter_arg = format!("reference={f}");
            args.push("--filter");
            args.push(&filter_arg);
        }

        let id_output = self
            .cli
            .run(&args)
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&id_output)?;

        let stdout = String::from_utf8_lossy(&id_output.stdout);
        let ids: Vec<&str> = stdout
            .trim()
            .lines()
            .filter(|l| !l.trim().is_empty())
            .collect();
        if ids.is_empty() {
            return Ok(Vec::new());
        }

        // Step 2: Inspect for full details.
        let mut inspect_args = vec!["image", "inspect"];
        for id in &ids {
            inspect_args.push(id);
        }

        let inspect_output = self
            .cli
            .run(&inspect_args)
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&inspect_output)?;

        let stdout = String::from_utf8_lossy(&inspect_output.stdout);
        let json_array: Vec<serde_json::Value> = serde_json::from_str(stdout.trim())
            .map_err(|e| DockerCliException::new(format!("Failed to parse images: {e}"), 0))?;

        Ok(json_array
            .into_iter()
            .map(|json| {
                // docker image inspect returns Created as ISO string; convert to epoch.
                let created = if let Some(s) = json["Created"].as_str() {
                    chrono::DateTime::parse_from_rfc3339(s)
                        .map(|dt| dt.timestamp())
                        .unwrap_or(0)
                } else {
                    json["Created"].as_i64().unwrap_or(0)
                };

                DockerImage {
                    id: json["Id"].as_str().unwrap_or("").to_string(),
                    repo_tags: json["RepoTags"]
                        .as_array()
                        .map(|arr| {
                            arr.iter()
                                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                                .collect()
                        })
                        .unwrap_or_default(),
                    size: json["Size"].as_i64().unwrap_or(0),
                    created,
                }
            })
            .collect())
    }

    /// Builds a Docker image from `dockerfile` content, tagged as `tag`.
    ///
    /// Writes the Dockerfile to a temporary directory and streams build
    /// output line-by-line. The temp directory is cleaned up when the
    /// stream completes.
    pub fn build_image(
        &self,
        dockerfile: String,
        tag: String,
    ) -> impl Stream<Item = Result<String, DockerCliException>> + '_ {
        stream! {
            let temp_dir: tempfile::TempDir = tempfile::tempdir()
                .map_err(|e| DockerCliException::new(format!("Failed to create temp dir: {e}"), -1))?;

            let dockerfile_path = temp_dir.path().join("Dockerfile");
            let _: () = tokio::fs::write(&dockerfile_path, &dockerfile)
                .await
                .map_err(|e| DockerCliException::new(format!("Failed to write Dockerfile: {e}"), -1))?;

            let context_path = temp_dir.path().to_string_lossy().to_string();
            let mut child = self.cli.start(&[
                "build", "-t", &tag, "--rm", "--force-rm", "--progress=plain", &context_path,
            ]).await
            .map_err(|e| DockerCliException::new(format!("Failed to start build: {e}"), -1))?;

            let stdout = child.stdout.take();
            let stderr = child.stderr.take();

            // Read stdout lines.
            if let Some(stdout) = stdout {
                let mut reader = BufReader::new(stdout).lines();
                while let Ok(Some(line)) = reader.next_line().await {
                    if !line.is_empty() {
                        yield Ok(line);
                    }
                }
            }

            // Read stderr lines (BuildKit output goes here).
            if let Some(stderr) = stderr {
                let mut reader = BufReader::new(stderr).lines();
                while let Ok(Some(line)) = reader.next_line().await {
                    if !line.is_empty() {
                        yield Ok(line);
                    }
                }
            }

            let status = child.wait().await
                .map_err(|e| DockerCliException::new(format!("Failed to wait for build: {e}"), -1))?;
            if !status.success() {
                yield Err(DockerCliException::new(
                    "Build failed",
                    status.code().unwrap_or(-1),
                ));
            }
        }
    }

    /// Builds a Docker image from a pre-assembled build context directory.
    ///
    /// Unlike [`build_image`], this does NOT create or clean up the context dir.
    /// Each `(key, value)` pair in `build_args` is passed as `--build-arg KEY=VALUE`.
    pub fn build_image_from_context<'a>(
        &'a self,
        context_dir: &'a str,
        tag: &'a str,
        build_args: &'a [(&'a str, &'a str)],
    ) -> impl Stream<Item = Result<String, DockerCliException>> + 'a {
        stream! {
            let mut args = vec![
                "build".to_string(), "-t".to_string(), tag.to_string(),
                "--no-cache".to_string(), "--rm".to_string(), "--force-rm".to_string(),
                "--progress=plain".to_string(),
            ];
            for (key, value) in build_args {
                args.push("--build-arg".to_string());
                args.push(format!("{key}={value}"));
            }
            args.push(context_dir.to_string());
            let args_refs: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
            let mut child = self.cli.start(&args_refs).await
            .map_err(|e| DockerCliException::new(format!("Failed to start build: {e}"), -1))?;

            let stdout = child.stdout.take();
            let stderr = child.stderr.take();

            // Read stdout and stderr concurrently so output streams in real-time.
            // Docker build with --progress=plain sends step output to stderr.
            let mut stdout_reader = stdout.map(|s| BufReader::new(s).lines());
            let mut stderr_reader = stderr.map(|s| BufReader::new(s).lines());
            let mut stdout_done = stdout_reader.is_none();
            let mut stderr_done = stderr_reader.is_none();

            while !stdout_done || !stderr_done {
                tokio::select! {
                    line = async { stdout_reader.as_mut().unwrap().next_line().await }, if !stdout_done => {
                        match line {
                            Ok(Some(l)) if !l.is_empty() => yield Ok(l),
                            Ok(Some(_)) => {} // empty line
                            _ => stdout_done = true,
                        }
                    }
                    line = async { stderr_reader.as_mut().unwrap().next_line().await }, if !stderr_done => {
                        match line {
                            Ok(Some(l)) if !l.is_empty() => yield Ok(l),
                            Ok(Some(_)) => {} // empty line
                            _ => stderr_done = true,
                        }
                    }
                }
            }

            let status = child.wait().await
                .map_err(|e| DockerCliException::new(format!("Failed to wait for build: {e}"), -1))?;
            if !status.success() {
                yield Err(DockerCliException::new(
                    "Build failed",
                    status.code().unwrap_or(-1),
                ));
            }
        }
    }

    /// Deletes an image by `id` (name:tag or sha256 digest).
    pub async fn remove_image(
        &self,
        id: &str,
        force: bool,
    ) -> Result<(), DockerCliException> {
        let mut args = vec!["rmi"];
        if force {
            args.push("--force");
        }
        args.push(id);
        let output = self
            .cli
            .run(&args)
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    // ─── Containers ──────────────────────────────────────────────────────

    /// Creates a container from `config`. Returns the container ID.
    pub async fn create_container(
        &self,
        config: &CreateContainerRequest,
        name: Option<&str>,
    ) -> Result<String, DockerCliException> {
        let mut args: Vec<String> = vec!["create".to_string()];
        if let Some(n) = name {
            args.push("--name".to_string());
            args.push(n.to_string());
        }

        for env in &config.env {
            args.push("-e".to_string());
            args.push(env.clone());
        }
        for (k, v) in &config.labels {
            args.push("-l".to_string());
            args.push(format!("{k}={v}"));
        }
        for port in config.exposed_ports.keys() {
            args.push("--expose".to_string());
            args.push(port.clone());
        }

        if let Some(ref hc) = config.host_config {
            for bind in &hc.binds {
                args.push("-v".to_string());
                args.push(bind.clone());
            }
            if hc.privileged {
                args.push("--privileged".to_string());
            }
            if let Some(ref rt) = hc.runtime {
                args.push("--runtime".to_string());
                args.push(rt.clone());
            }
            if hc.auto_remove {
                args.push("--rm".to_string());
            }
            for (container_port_proto, bindings) in &hc.port_bindings {
                let container_port = container_port_proto
                    .split('/')
                    .next()
                    .unwrap_or(container_port_proto);
                for binding in bindings {
                    let host = if !binding.host_ip.is_empty() {
                        format!("{}:{}", binding.host_ip, binding.host_port)
                    } else {
                        binding.host_port.clone()
                    };
                    args.push("-p".to_string());
                    args.push(format!("{host}:{container_port}"));
                }
            }
            for host in &hc.extra_hosts {
                args.push("--add-host".to_string());
                args.push(host.clone());
            }
            if let Some(memory) = hc.memory {
                args.push("--memory".to_string());
                args.push(memory.to_string());
            }
            if let Some(nano_cpus) = hc.nano_cpus {
                let cpus = nano_cpus as f64 / 1e9;
                args.push("--cpus".to_string());
                args.push(cpus.to_string());
            }
            if let Some(ref network_mode) = hc.network_mode {
                if !network_mode.is_empty() {
                    args.push("--network".to_string());
                    args.push(network_mode.clone());
                }
            }
            if let Some(ref device_requests) = hc.device_requests {
                if !device_requests.is_empty() {
                    args.push("--gpus".to_string());
                    args.push("all".to_string());
                }
            }
        }

        args.push(config.image.clone());

        let args_refs: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
        let output = self
            .cli
            .run(&args_refs)
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)?;
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    }

    /// Starts a stopped container.
    pub async fn start_container(&self, id: &str) -> Result<(), DockerCliException> {
        let output = self
            .cli
            .run(&["start", id])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    /// Gracefully stops a running container.
    pub async fn stop_container(
        &self,
        id: &str,
        wait_seconds: u32,
    ) -> Result<(), DockerCliException> {
        let wait = wait_seconds.to_string();
        let output = self
            .cli
            .run(&["stop", "-t", &wait, id])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    /// Forcefully kills a container.
    pub async fn kill_container(&self, id: &str) -> Result<(), DockerCliException> {
        let output = self
            .cli
            .run(&["kill", id])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    /// Removes a container.
    pub async fn remove_container(
        &self,
        id: &str,
        force: bool,
    ) -> Result<(), DockerCliException> {
        let mut args = vec!["rm", "-v"];
        if force {
            args.push("--force");
        }
        args.push(id);
        let output = self
            .cli
            .run(&args)
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    // ─── Volume operations ────────────────────────────────────────────────

    /// Creates a named Docker volume. Idempotent.
    pub async fn create_volume(&self, name: &str) -> Result<(), DockerCliException> {
        let output = self
            .cli
            .run(&["volume", "create", name])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    /// Removes a named Docker volume.
    pub async fn remove_volume(&self, name: &str) -> Result<(), DockerCliException> {
        let output = self
            .cli
            .run(&["volume", "rm", name])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)
    }

    /// Returns true if the named volume exists, false otherwise.
    pub async fn volume_exists(&self, name: &str) -> Result<bool, DockerCliException> {
        let output = self
            .cli
            .run(&["volume", "inspect", name])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Ok(output.status.success())
    }

    /// Returns detailed inspection of a container.
    pub async fn inspect_container(
        &self,
        id: &str,
    ) -> Result<ContainerInspect, DockerCliException> {
        let output = self
            .cli
            .run(&["inspect", id])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let json_array: Vec<serde_json::Value> = serde_json::from_str(stdout.trim())
            .map_err(|e| DockerCliException::new(format!("Failed to parse inspect: {e}"), 0))?;
        let first = json_array
            .into_iter()
            .next()
            .ok_or_else(|| DockerCliException::new("Empty inspect result", 0))?;
        serde_json::from_value(first)
            .map_err(|e| DockerCliException::new(format!("Failed to parse container: {e}"), 0))
    }

    /// Lists containers. Set `all` to include stopped containers.
    pub async fn list_containers(
        &self,
        all: bool,
        filters: Option<&HashMap<String, Vec<String>>>,
    ) -> Result<Vec<crate::domain::services::ContainerSummary>, DockerCliException> {
        let mut args = vec!["ps", "--format", "{{json .}}"];
        if all {
            args.push("-a");
        }

        let mut filter_strs = Vec::new();
        if let Some(filters) = filters {
            for (key, values) in filters {
                for value in values {
                    filter_strs.push(format!("{key}={value}"));
                }
            }
        }
        for f in &filter_strs {
            args.push("--filter");
            args.push(f.as_str());
        }

        let output = self
            .cli
            .run(&args)
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let items = Self::parse_ndjson(&stdout);

        Ok(items
            .into_iter()
            .map(|json| {
                // docker ps --format outputs Names without leading '/'
                let names_str = json["Names"].as_str().unwrap_or("");
                let names: Vec<String> = names_str
                    .split(',')
                    .filter(|n| !n.is_empty())
                    .map(|n| format!("/{n}"))
                    .collect();

                // CreatedAt format: "2024-01-15 09:30:00 +0000 UTC"
                let mut created: i64 = 0;
                if let Some(created_at) = json["CreatedAt"].as_str() {
                    if !created_at.is_empty() {
                        // Strip trailing " UTC" and normalize tz offset.
                        let normalized = created_at
                            .replace(" UTC", "")
                            .trim()
                            .to_string();
                        // Try parse with chrono.
                        if let Ok(dt) = chrono::NaiveDateTime::parse_from_str(
                            &normalized,
                            "%Y-%m-%d %H:%M:%S %z",
                        ) {
                            created = dt.and_utc().timestamp();
                        }
                    }
                }

                let labels = Self::parse_labels(json["Labels"].as_str().unwrap_or(""));

                crate::domain::services::ContainerSummary {
                    id: json["ID"].as_str().unwrap_or("").to_string(),
                    names,
                    image: json["Image"].as_str().unwrap_or("").to_string(),
                    state: json["State"]
                        .as_str()
                        .unwrap_or("")
                        .to_lowercase(),
                    status: json["Status"].as_str().unwrap_or("").to_string(),
                    labels,
                    created,
                }
            })
            .collect())
    }

    /// Streams container logs. Set `follow` to continuously tail.
    pub fn container_logs(
        &self,
        id: &str,
        follow: bool,
    ) -> impl Stream<Item = Result<String, DockerCliException>> + '_ {
        let id = id.to_string();
        stream! {
            let mut args = vec!["logs", "--timestamps"];
            if follow {
                args.push("--follow");
            }
            args.push(&id);

            if follow {
                let mut child = self.cli.start(&args).await
                    .map_err(|e| DockerCliException::new(format!("Failed to start logs: {e}"), -1))?;

                let stdout = child.stdout.take();
                let stderr = child.stderr.take();

                // Read stdout and stderr concurrently for real-time interleaved output.
                let mut stdout_reader = stdout.map(|s| BufReader::new(s).lines());
                let mut stderr_reader = stderr.map(|s| BufReader::new(s).lines());
                let mut stdout_done = stdout_reader.is_none();
                let mut stderr_done = stderr_reader.is_none();

                while !stdout_done || !stderr_done {
                    tokio::select! {
                        line = async { stdout_reader.as_mut().unwrap().next_line().await }, if !stdout_done => {
                            match line {
                                Ok(Some(l)) if !l.is_empty() => yield Ok(l),
                                Ok(Some(_)) => {}
                                _ => stdout_done = true,
                            }
                        }
                        line = async { stderr_reader.as_mut().unwrap().next_line().await }, if !stderr_done => {
                            match line {
                                Ok(Some(l)) if !l.is_empty() => yield Ok(l),
                                Ok(Some(_)) => {}
                                _ => stderr_done = true,
                            }
                        }
                    }
                }

                let _ = child.wait().await;
            } else {
                let output = self.cli.run(&args).await
                    .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
                Self::check_result(&output)?;

                let stdout = String::from_utf8_lossy(&output.stdout);
                for line in stdout.lines() {
                    if !line.trim().is_empty() {
                        yield Ok(line.to_string());
                    }
                }
            }
        }
    }

    /// Returns one-shot resource usage stats for a running container.
    pub async fn container_stats(
        &self,
        id: &str,
    ) -> Result<ContainerStats, DockerCliException> {
        let output = self
            .cli
            .run(&[
                "stats",
                "--no-stream",
                "--format",
                "{{.MemUsage}}||{{.CPUPerc}}||{{.NetIO}}||{{.BlockIO}}||{{.PIDs}}",
                id,
            ])
            .await
            .map_err(|e| DockerCliException::new(e.to_string(), -1))?;
        Self::check_result(&output)?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let parts: Vec<&str> = stdout.trim().split("||").collect();
        Ok(ContainerStats {
            mem_usage: parts.first().map(|s| s.trim().to_string()).unwrap_or_default(),
            cpu_perc: parts.get(1).map(|s| s.trim().to_string()).unwrap_or_default(),
            net_io: parts.get(2).map(|s| s.trim().to_string()).unwrap_or_default(),
            block_io: parts.get(3).map(|s| s.trim().to_string()).unwrap_or_default(),
            pids: parts.get(4).map(|s| s.trim().to_string()).unwrap_or_default(),
        })
    }

    /// Reads a file from inside a running container via `docker exec cat`.
    pub async fn read_file_from_container(
        &self,
        container_id: &str,
        file_path: &str,
    ) -> Option<String> {
        match self.cli.run(&["exec", container_id, "cat", file_path]).await {
            Ok(output) if output.status.success() => {
                Some(String::from_utf8_lossy(&output.stdout).to_string())
            }
            _ => None,
        }
    }
}
