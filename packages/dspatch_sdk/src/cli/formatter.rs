// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Output formatting for CLI commands.
//!
//! Supports two modes:
//! - **JSON mode** (`--json`): machine-readable `serde_json` output.
//! - **Human mode** (default): key-value pairs for items, `comfy-table` for lists.

use comfy_table::{Cell, ContentArrangement, Table};
use serde_json::{Map, Value};

/// Formats CLI output as either human-readable text or JSON.
pub struct OutputFormatter {
    pub json: bool,
}

impl OutputFormatter {
    pub fn new(json: bool) -> Self {
        Self { json }
    }

    /// Prints a single item as key-value pairs (human) or a JSON object.
    pub fn print_item(&self, data: &Map<String, Value>) {
        if self.json {
            let val = Value::Object(data.clone());
            println!("{}", serde_json::to_string_pretty(&val).unwrap_or_default());
        } else {
            // Find the longest key for alignment.
            let max_key_len = data.keys().map(|k| k.len()).max().unwrap_or(0);
            for (key, value) in data {
                let display = format_value(value);
                println!("{:>width$}:  {}", key, display, width = max_key_len);
            }
        }
    }

    /// Prints a list of items as a table (human) or a JSON array.
    pub fn print_list(&self, items: &[Map<String, Value>], columns: &[&str]) {
        if self.json {
            let arr: Vec<Value> = items.iter().map(|m| Value::Object(m.clone())).collect();
            println!("{}", serde_json::to_string_pretty(&arr).unwrap_or_default());
        } else {
            if items.is_empty() {
                println!("(none)");
                return;
            }

            let mut table = Table::new();
            table.set_content_arrangement(ContentArrangement::Dynamic);
            table.load_preset(comfy_table::presets::UTF8_FULL);

            // Header row.
            table.set_header(columns.iter().map(|c| Cell::new(c)));

            for item in items {
                let row: Vec<Cell> = columns
                    .iter()
                    .map(|col| {
                        let val = item.get(*col).cloned().unwrap_or(Value::Null);
                        Cell::new(format_value(&val))
                    })
                    .collect();
                table.add_row(row);
            }

            println!("{table}");
        }
    }
}

/// Converts a JSON value to a display string.
fn format_value(value: &Value) -> String {
    match value {
        Value::String(s) => s.clone(),
        Value::Null => String::new(),
        Value::Bool(b) => b.to_string(),
        Value::Number(n) => n.to_string(),
        Value::Array(arr) => {
            let strs: Vec<String> = arr.iter().map(|v| format_value(v)).collect();
            strs.join(", ")
        }
        Value::Object(_) => serde_json::to_string(value).unwrap_or_default(),
    }
}
