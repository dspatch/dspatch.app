use dspatch_engine::sync::table_class::{SyncStrategy, TableClassification};

#[test]
fn account_level_tables_are_lww() {
    assert_eq!(
        TableClassification::for_table("api_keys"),
        Some(SyncStrategy::AccountLww)
    );
    assert_eq!(
        TableClassification::for_table("preferences"),
        Some(SyncStrategy::AccountLww)
    );
    assert_eq!(
        TableClassification::for_table("agent_providers"),
        Some(SyncStrategy::AccountLww)
    );
    assert_eq!(
        TableClassification::for_table("agent_templates"),
        Some(SyncStrategy::AccountLww)
    );
    assert_eq!(
        TableClassification::for_table("workspace_templates"),
        Some(SyncStrategy::AccountLww)
    );
}

#[test]
fn workspace_owned_tables_are_classified() {
    assert_eq!(
        TableClassification::for_table("workspaces"),
        Some(SyncStrategy::WorkspaceOwned)
    );
    assert_eq!(
        TableClassification::for_table("agent_messages"),
        Some(SyncStrategy::WorkspaceOwned)
    );
    assert_eq!(
        TableClassification::for_table("agent_logs"),
        Some(SyncStrategy::WorkspaceOwned)
    );
}

#[test]
fn device_local_tables_return_none() {
    assert_eq!(TableClassification::for_table("signal_identities"), None);
    assert_eq!(TableClassification::for_table("sync_outbox"), None);
    assert_eq!(TableClassification::for_table("sync_cursors"), None);
    assert_eq!(TableClassification::for_table("recent_projects"), None);
}

#[test]
fn unknown_tables_return_none() {
    assert_eq!(TableClassification::for_table("nonexistent_table"), None);
}

#[test]
fn synced_tables_returns_all_15() {
    let tables = TableClassification::synced_tables();
    assert_eq!(tables.len(), 15);
}
