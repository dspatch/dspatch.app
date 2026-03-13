CREATE TABLE IF NOT EXISTS workspace_templates (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    hub_slug TEXT NOT NULL,
    hub_author TEXT NOT NULL,
    hub_category TEXT,
    hub_tags_json TEXT NOT NULL DEFAULT '[]',
    hub_version INTEGER NOT NULL,
    config_json TEXT NOT NULL,
    agent_refs_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);