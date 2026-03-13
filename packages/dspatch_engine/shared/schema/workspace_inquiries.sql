CREATE TABLE IF NOT EXISTS workspace_inquiries (
    id TEXT NOT NULL PRIMARY KEY,
    run_id TEXT NOT NULL REFERENCES workspace_runs(id),
    agent_key TEXT NOT NULL,
    instance_id TEXT NOT NULL,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    content_markdown TEXT NOT NULL,
    attachments_json TEXT,
    suggestions_json TEXT,
    response_text TEXT,
    response_suggestion_index INTEGER,
    responded_by_agent_key TEXT,
    forwarding_chain_json TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    responded_at TEXT
);