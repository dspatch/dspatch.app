CREATE TABLE IF NOT EXISTS recent_projects (
    id TEXT NOT NULL PRIMARY KEY,
    path TEXT NOT NULL,
    name TEXT NOT NULL,
    is_git_repo INTEGER NOT NULL DEFAULT 0,
    last_used_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);