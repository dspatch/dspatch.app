#!/usr/bin/env bash
# Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
# dspatch v2 workspace entrypoint
# Reads dspatch.workspace.yml at runtime, clones template sources, installs deps,
# and launches all agents.
#
# Expects:
#   /workspace/dspatch.workspace.yml — workspace config (mounted from host)
#   /src/<template-dir>/             — local template sources (mounted read-only)
#   /agents/<template-dir>/          — template code (cloned to native Linux fs)
#   DSPATCH_TEMPLATE_SOURCES         — JSON map of template source info
#   DSPATCH_API_URL, DSPATCH_API_KEY, DSPATCH_WORKSPACE_ID — set by app
set -euo pipefail
trap 'echo "[dspatch-v2] Container exiting (code: $?)"' EXIT

TAG="[dspatch-v2]"
CONFIG="/workspace/dspatch.workspace.yml"

# ── Diagnostics ──────────────────────────────────────────────────────────
echo "$TAG ============================================"
echo "$TAG d:spatch Workspace Container Starting"
echo "$TAG ============================================"
echo "$TAG Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "$TAG Python: $(python --version 2>&1)"
echo "$TAG UV: $(uv --version 2>&1 || echo 'not installed')"
echo "$TAG Workspace ID: ${DSPATCH_WORKSPACE_ID:-<not set>}"
echo "$TAG API URL: ${DSPATCH_API_URL:-<not set>}"
echo "$TAG ============================================"

# ── Validate config ──────────────────────────────────────────────────────
if [ ! -f "$CONFIG" ]; then
    echo "$TAG ERROR: Config not found at $CONFIG"
    ls -la /workspace/ 2>/dev/null || true
    exit 1
fi

echo "$TAG Config: $CONFIG"
echo "$TAG Workspace name: $(yq e '.name' "$CONFIG")"

# ── Collect unique templates ─────────────────────────────────────────────
# Walk the agent tree (including sub_agents) and collect template names.
# yq: recurse into .agents, collect all .template values, deduplicate.
TEMPLATES=$(yq e '[.agents | .. | select(has("template")) | .template] | unique | .[]' "$CONFIG")

echo "$TAG Templates: $TEMPLATES"

# ── Helper: resolve template name → container directory ──────────────────
# Reads DSPATCH_TEMPLATE_SOURCES (preferred) or falls back to
# DSPATCH_TEMPLATE_DIRS (legacy) to map template names to /agents/<dirname>.
resolve_tmpl_dir() {
    local tmpl="$1"
    if [ -n "${DSPATCH_TEMPLATE_SOURCES:-}" ]; then
        local dirname
        dirname=$(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r --arg t "$tmpl" '.[$t].dir // empty')
        if [ -n "$dirname" ]; then
            echo "/agents/$dirname"
            return
        fi
    fi
    if [ -n "${DSPATCH_TEMPLATE_DIRS:-}" ]; then
        local dirname
        dirname=$(echo "$DSPATCH_TEMPLATE_DIRS" | jq -r --arg t "$tmpl" '.[$t] // empty')
        if [ -n "$dirname" ]; then
            echo "/agents/$dirname"
            return
        fi
    fi
    echo "/agents/$tmpl"
}

# ── Phase 0: GPU setup (conditional) ─────────────────────────────────────
if [ "${DSPATCH_GPU_ENABLED:-}" = "true" ]; then
    echo "$TAG ── Phase 0: GPU Setup ──"
    if command -v nvidia-smi &>/dev/null; then
        echo "$TAG GPU detected:"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>&1 | sed "s/^/$TAG   /"
        # Install Python NVIDIA management library for GPU monitoring
        pip install --no-cache-dir --break-system-packages pynvml 2>&1 | sed "s/^/$TAG   [gpu] /"
    else
        echo "$TAG WARNING: GPU passthrough enabled but nvidia-smi not found."
        echo "$TAG   Ensure the NVIDIA Container Toolkit is installed on the host."
        echo "$TAG   Continuing without GPU support."
    fi
    echo "$TAG ── Phase 0 complete ──"
fi

# ── Phase 0.5: Clone template sources ────────────────────────────────────
# Local templates are mounted read-only at /src/<dir> and cloned to
# /agents/<dir> on the native Linux fs. Git templates are cloned directly.
echo "$TAG ── Phase 0.5: Cloning template sources ──"

mkdir -p /agents

if [ -n "${DSPATCH_TEMPLATE_SOURCES:-}" ]; then
    for tmpl_name in $(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r 'keys[]'); do
        tmpl_type=$(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r --arg t "$tmpl_name" '.[$t].type')
        tmpl_dir=$(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r --arg t "$tmpl_name" '.[$t].dir')
        target="/agents/$tmpl_dir"

        if [ -d "$target" ]; then
            echo "$TAG   Skipping $tmpl_name — $target already exists"
            continue
        fi

        case "$tmpl_type" in
            local)
                tmpl_src=$(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r --arg t "$tmpl_name" '.[$t].src')
                echo "$TAG   Cloning local source: $tmpl_src → $target"
                if ! timeout 300 git clone "file://$tmpl_src" "$target" 2>&1 | sed "s/^/$TAG   [git] /"; then
                    echo "$TAG   WARNING: git clone failed, falling back to copy..."
                    cp -r "$tmpl_src"/. "$target"/ 2>&1 | sed "s/^/$TAG   [cp] /"
                fi
                ;;
            git)
                tmpl_url=$(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r --arg t "$tmpl_name" '.[$t].url')
                tmpl_branch=$(echo "$DSPATCH_TEMPLATE_SOURCES" | jq -r --arg t "$tmpl_name" '.[$t].branch // empty')

                # Strip GitHub /tree/<ref> or /commit/<ref> from URL and extract ref.
                tree_ref=""
                if [[ "$tmpl_url" =~ ^(https://[^/]+/[^/]+/[^/]+)/(tree|commit)/(.+)$ ]]; then
                    tmpl_url="${BASH_REMATCH[1]}"
                    tree_ref="${BASH_REMATCH[3]}"
                    echo "$TAG   Extracted ref from URL: $tree_ref"
                    # Use tree_ref as branch/commit if no explicit branch set.
                    if [ -z "$tmpl_branch" ]; then
                        tmpl_branch="$tree_ref"
                    fi
                fi

                echo "$TAG   Cloning git source: $tmpl_url (ref=$tmpl_branch) → $target"

                # Detect if ref looks like a full commit hash (40 hex chars).
                is_commit_hash=false
                if [[ "$tmpl_branch" =~ ^[0-9a-f]{40}$ ]]; then
                    is_commit_hash=true
                fi

                if [ -z "$tmpl_branch" ]; then
                    # No ref — shallow clone default branch.
                    if ! timeout 300 git clone --depth 1 "$tmpl_url" "$target" 2>&1 | sed "s/^/$TAG   [git] /"; then
                        echo "$TAG   ERROR: Failed to clone git source for $tmpl_name from $tmpl_url"
                        exit 1
                    fi
                elif [ "$is_commit_hash" = true ]; then
                    # Full commit hash — can't use --branch with --depth 1.
                    # Clone then checkout the specific commit.
                    if ! timeout 300 git clone "$tmpl_url" "$target" 2>&1 | sed "s/^/$TAG   [git] /"; then
                        echo "$TAG   ERROR: Failed to clone git source for $tmpl_name from $tmpl_url"
                        exit 1
                    fi
                    echo "$TAG   Checking out commit: $tmpl_branch"
                    if ! (cd "$target" && git checkout "$tmpl_branch" 2>&1 | sed "s/^/$TAG   [git] /"); then
                        echo "$TAG   ERROR: Failed to checkout $tmpl_branch for $tmpl_name"
                        exit 1
                    fi
                else
                    # Branch/tag name — shallow clone with --branch.
                    # shellcheck disable=SC2086
                    if ! timeout 300 git clone --depth 1 --branch "$tmpl_branch" "$tmpl_url" "$target" 2>&1 | sed "s/^/$TAG   [git] /"; then
                        echo "$TAG   ERROR: Failed to clone git source for $tmpl_name from $tmpl_url"
                        exit 1
                    fi
                fi
                ;;
            *)
                echo "$TAG   ERROR: Unknown source type '$tmpl_type' for template $tmpl_name"
                exit 1
                ;;
        esac
    done
else
    echo "$TAG   No DSPATCH_TEMPLATE_SOURCES set — templates expected to be pre-mounted"
fi

echo "$TAG ── Phase 0.5 complete ──"

# ── Phase 1: Install deps per template ───────────────────────────────────
echo "$TAG ── Phase 1: Installing dependencies ──"

while IFS= read -r tmpl; do
    [ -z "$tmpl" ] && continue
    TMPL_DIR=$(resolve_tmpl_dir "$tmpl")
    if [ ! -d "$TMPL_DIR" ]; then
        echo "$TAG WARNING: Template dir not found: $TMPL_DIR — skipping install"
        continue
    fi

    echo "$TAG Installing deps for template: $tmpl"
    (
        echo "$TAG   >>> SUBSHELL START for $tmpl <<<"
        set +e  # Disable errexit in subshell so we can see all debug output
        cd "$TMPL_DIR" || { echo "$TAG   ERROR: failed to cd to $TMPL_DIR"; exit 1; }

        # ── Detect agent config ──
        echo "$TAG   DEBUG: pwd=$(pwd)"
        echo "$TAG   DEBUG: listing files..."
        ls -1 2>&1 | sed "s/^/$TAG   DEBUG:   /"
        DSPATCH_YML=""
        [ -f "dspatch.agent.yml" ] && DSPATCH_YML="dspatch.agent.yml"
        echo "$TAG   DEBUG: DSPATCH_YML=$DSPATCH_YML"

        # ── Pre-install hook ──
        echo "$TAG   DEBUG: checking pre_install hook (DSPATCH_YML=$DSPATCH_YML)"
        if [ -n "$DSPATCH_YML" ]; then
            PRE_INSTALL=$(yq e '.pre_install // ""' "$DSPATCH_YML" 2>/dev/null || true)
            [ "$PRE_INSTALL" = "null" ] && PRE_INSTALL=""
            echo "$TAG   DEBUG: PRE_INSTALL=$PRE_INSTALL"
            if [ -n "$PRE_INSTALL" ]; then
                if [ ! -f "$PRE_INSTALL" ]; then
                    echo "$TAG   ERROR: pre_install script not found: $PRE_INSTALL"
                else
                    echo "$TAG   Running pre_install: $PRE_INSTALL"
                    if ! timeout 300 bash "$PRE_INSTALL" 2>&1 | sed "s/^/$TAG   [pre_install] /"; then
                        echo "$TAG   ERROR: pre_install hook failed"
                    fi
                fi
            else
                echo "$TAG   DEBUG: no pre_install hook declared"
            fi
        else
            echo "$TAG   DEBUG: no agent config found, skipping hooks"
        fi

        # ── Python dependencies ──
        echo "$TAG   DEBUG: checking Python deps"
        if [ -f "pyproject.toml" ]; then
            echo "$TAG   DEBUG: installing via uv sync"
            timeout 600 uv sync --no-dev 2>&1 | sed "s/^/$TAG   [uv] /"
        elif [ -f "requirements.txt" ]; then
            echo "$TAG   DEBUG: installing via pip (requirements.txt)"
            timeout 600 pip install --no-cache-dir --break-system-packages -r requirements.txt 2>&1 | sed "s/^/$TAG   [pip] /"
        else
            echo "$TAG   DEBUG: no Python deps found"
        fi

        # ── Node.js dependencies ──
        echo "$TAG   DEBUG: checking Node.js deps"
        if [ -f "pnpm-lock.yaml" ]; then
            echo "$TAG   Detected pnpm-lock.yaml"
            if ! command -v pnpm &>/dev/null; then
                echo "$TAG   Installing pnpm..."
                npm install -g pnpm 2>&1 | sed "s/^/$TAG   [pnpm] /"
            fi
            timeout 600 pnpm install 2>&1 | sed "s/^/$TAG   [pnpm] /"
        elif [ -f "yarn.lock" ]; then
            echo "$TAG   Detected yarn.lock"
            if ! command -v yarn &>/dev/null; then
                echo "$TAG   Installing yarn..."
                npm install -g yarn 2>&1 | sed "s/^/$TAG   [yarn] /"
            fi
            timeout 600 yarn install 2>&1 | sed "s/^/$TAG   [yarn] /"
        elif [ -f "package-lock.json" ]; then
            echo "$TAG   Detected package-lock.json"
            timeout 600 npm ci 2>&1 | sed "s/^/$TAG   [npm] /"
        elif [ -f "package.json" ]; then
            echo "$TAG   Detected package.json"
            timeout 600 npm install 2>&1 | sed "s/^/$TAG   [npm] /"
        else
            echo "$TAG   DEBUG: no Node.js deps found"
        fi

        # ── Post-install hook ──
        echo "$TAG   DEBUG: checking post_install hook (DSPATCH_YML=$DSPATCH_YML)"
        if [ -n "$DSPATCH_YML" ]; then
            POST_INSTALL=$(yq e '.post_install // ""' "$DSPATCH_YML" 2>/dev/null || true)
            [ "$POST_INSTALL" = "null" ] && POST_INSTALL=""
            echo "$TAG   DEBUG: POST_INSTALL=$POST_INSTALL"
            if [ -n "$POST_INSTALL" ]; then
                if [ ! -f "$POST_INSTALL" ]; then
                    echo "$TAG   ERROR: post_install script not found: $POST_INSTALL"
                else
                    echo "$TAG   Running post_install: $POST_INSTALL"
                    if ! timeout 300 bash "$POST_INSTALL" 2>&1 | sed "s/^/$TAG   [post_install] /"; then
                        echo "$TAG   ERROR: post_install hook failed"
                    fi
                fi
            else
                echo "$TAG   DEBUG: no post_install hook declared"
            fi
        else
            echo "$TAG   DEBUG: no agent config found, skipping post_install"
        fi
        echo "$TAG   >>> SUBSHELL END for $tmpl <<<"
    )
done <<< "$TEMPLATES"

echo "$TAG ── Phase 1 complete ──"

# ── Phase 2: Launch agents ───────────────────────────────────────────────
echo "$TAG ── Phase 2: Starting agents ──"

PIDS=()
declare -A PID_NAMES=()

cleanup() {
    echo "$TAG Received signal, shutting down..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait
}
trap cleanup SIGTERM SIGINT

# Agent system metadata — computed by the host app and passed as a single
# JSON env var.  Keyed by flat agent key:
#   { "lead": { "is_root": true, "peers": "coder,tester" }, ... }
AGENTS_META="${DSPATCH_AGENTS_META:-\{\}}"

# Walk the agent tree via jq, emitting one line per agent instance.
# Fields (tab-separated):
#   agent_key  template  instance_index  total_instances  env_json
#
# is_root and peers come from DSPATCH_AGENTS_META (set by host app),
# NOT from the jq walker — this avoids fragile tab-field parsing and
# makes the Dart app the single source of truth for agent identity.
#
# Use process substitution (not pipe) so the while loop runs in the
# current shell — PIDS accumulate correctly and `wait` works.
while IFS=$'\t' read -r AGENT_KEY TEMPLATE INSTANCE TOTAL_INSTANCES ENV_JSON; do

    # Agent ID: single instance → key, multi → key-index
    if [ "$TOTAL_INSTANCES" -eq 1 ]; then
        AGENT_ID="$AGENT_KEY"
    else
        AGENT_ID="${AGENT_KEY}-${INSTANCE}"
    fi

    TMPL_DIR=$(resolve_tmpl_dir "$TEMPLATE")
    if [ ! -d "$TMPL_DIR" ]; then
        echo "$TAG ERROR: Template dir not found for $AGENT_ID: $TMPL_DIR"
        continue
    fi

    # Resolve entry point from agent config (default: agent.py)
    ENTRY_POINT="agent.py"
    AGENT_CFG="$TMPL_DIR/dspatch.agent.yml"
    if [ -f "$AGENT_CFG" ]; then
        EP=$(yq e '.entry_point // ""' "$AGENT_CFG" 2>/dev/null || true)
        [ "$EP" = "null" ] && EP=""
        [ -n "$EP" ] && ENTRY_POINT="$EP"
    fi

    # Read agent metadata from DSPATCH_AGENTS_META (host is source of truth).
    IS_ROOT=$(echo "$AGENTS_META" | jq -r --arg k "$AGENT_KEY" '.[$k].is_root // false')
    PEERS=$(echo "$AGENTS_META" | jq -r --arg k "$AGENT_KEY" '.[$k].peers // ""')

    echo "$TAG Starting agent: $AGENT_ID (template=$TEMPLATE, entry=$ENTRY_POINT, is_root=$IS_ROOT, peers=$PEERS)"

    (
        cd /workspace

        # Activate venv if present (in template dir)
        if [ -f "$TMPL_DIR/.venv/bin/activate" ]; then
            . "$TMPL_DIR/.venv/bin/activate"
        fi

        # ── Layer 1: System env vars (DSPATCH_ prefix, protected) ──
        # These are set first and cannot be overridden by user env vars.
        export DSPATCH_AGENT_KEY="$AGENT_KEY"
        export DSPATCH_AGENT_INSTANCE="$INSTANCE"
        export DSPATCH_AGENT_ID="$AGENT_ID"

        if [ "$IS_ROOT" = "true" ]; then
            export DSPATCH_IS_ROOT="true"
        fi

        if [ -n "$PEERS" ]; then
            export DSPATCH_PEERS="$PEERS"
        fi

        # ── Layer 2+3: User env vars (workspace + agent, merged by host) ──
        # Prefer resolved vars from host (secrets decrypted, no {{apikey:*}}
        # placeholders) over raw config file values.
        # Written to a temp file and sourced to avoid eval on untrusted input.
        # Keys starting with DSPATCH_ are filtered out (defense in depth).
        RESOLVED_VAR="DSPATCH_RESOLVED_ENV_${AGENT_KEY}"
        RESOLVED_ENV="${!RESOLVED_VAR:-}"
        ENVFILE=$(mktemp)
        if [ -n "$RESOLVED_ENV" ]; then
            echo "$RESOLVED_ENV" | jq -r '
                to_entries[]
                | select(.key | startswith("DSPATCH_") | not)
                | "export \(.key)=\(.value | @sh)"
            ' > "$ENVFILE"
            . "$ENVFILE"
        elif [ "$ENV_JSON" != "{}" ] && [ -n "$ENV_JSON" ]; then
            echo "$ENV_JSON" | jq -r '
                to_entries[]
                | select(.key | startswith("DSPATCH_") | not)
                | "export \(.key)=\(.value | @sh)"
            ' > "$ENVFILE"
            . "$ENVFILE"
        fi
        rm -f "$ENVFILE"

        # ── Layer 4: Template fields (base64-encoded, from DSPATCH_AGENTS_META) ──
        # Each field becomes DSPATCH_FIELD_<KEY> (key uppercased).
        FIELDS_EXPORTS=$(echo "$AGENTS_META" | jq -r --arg k "$AGENT_KEY" '
            .[$k].fields // {} | to_entries[] |
            "export DSPATCH_FIELD_\(.key | ascii_upcase)=\(.value | @sh)"
        ' 2>/dev/null || true)
        if [ -n "$FIELDS_EXPORTS" ]; then
            FIELDSFILE=$(mktemp)
            echo "$FIELDS_EXPORTS" > "$FIELDSFILE"
            . "$FIELDSFILE"
            rm -f "$FIELDSFILE"
        fi

        export PYTHONUNBUFFERED=1
        exec python -u "$TMPL_DIR/$ENTRY_POINT"
    ) &
    PIDS+=($!)
    PID_NAMES[$!]="$AGENT_ID"

done < <(yq e -o=json '.' "$CONFIG" | jq -r '
  def walk_agents:
    to_entries[] |
    .key as $key |
    .value as $agent |
    ($agent.template) as $tmpl |
    ($agent.instances // 1) as $n |
    ($agent.env // {} | tojson) as $env_json |
    range($n) |
    "\($key)\t\($tmpl)\t\(.)\t\($n)\t\($env_json)"
    ,
    (if $agent.sub_agents then $agent.sub_agents | walk_agents else empty end)
  ;
  .agents | walk_agents
')

echo "$TAG All agents started (${#PIDS[@]} processes)"

# Monitor agent processes — log exit codes and wait for all to finish.
while [ ${#PIDS[@]} -gt 0 ]; do
    REMAINING=()
    for pid in "${PIDS[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            wait "$pid" 2>/dev/null
            code=$?
            agent_name="${PID_NAMES[$pid]:-unknown}"
            if [ "$code" -eq 0 ]; then
                echo "$TAG Agent '$agent_name' (PID $pid) exited successfully"
            else
                echo "$TAG ERROR: Agent '$agent_name' (PID $pid) exited with code $code"
            fi
            unset "PID_NAMES[$pid]"
        else
            REMAINING+=("$pid")
        fi
    done
    PIDS=("${REMAINING[@]}")
    [ ${#PIDS[@]} -gt 0 ] && sleep 2
done

echo "$TAG All agents exited"
