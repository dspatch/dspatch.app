// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Community Hub API client and version checker.
//!
//! Ported from `data/hub/` in the Dart SDK.

pub mod client;
pub mod models;
pub mod version_checker;

pub use client::{HubApiClient, HubApiException};
pub use models::{
    HubAgentResolve, HubAgentSummary, HubCategoryCount, HubPagination, HubTag, HubTagRef,
    HubVersionInfo, HubWorkspaceResolve, HubWorkspaceSummary,
};
pub use version_checker::HubVersionChecker;
