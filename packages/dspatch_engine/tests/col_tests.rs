// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

#[test]
fn col_returns_value_on_success() {
    use dspatch_engine::db::col::col;
    use dspatch_engine::util::result::Result;

    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch("CREATE TABLE t (name TEXT NOT NULL); INSERT INTO t VALUES ('hello');")
        .unwrap();

    let result: String = conn
        .query_row("SELECT name FROM t", [], |row| -> std::result::Result<Result<String>, _> {
            Ok(col(row, 0, "name"))
        })
        .unwrap()
        .unwrap();
    assert_eq!(result, "hello");
}

#[test]
fn col_returns_storage_error_on_type_mismatch() {
    use dspatch_engine::db::col::col;
    use dspatch_engine::util::result::Result;

    let conn = rusqlite::Connection::open_in_memory().unwrap();
    conn.execute_batch("CREATE TABLE t (name TEXT); INSERT INTO t VALUES (NULL);")
        .unwrap();

    let result: Result<String> = conn
        .query_row("SELECT name FROM t", [], |row| -> std::result::Result<Result<String>, _> {
            Ok(col(row, 0, "name"))
        })
        .unwrap();
    assert!(result.is_err());
    assert!(result.unwrap_err().to_string().contains("name"));
}
