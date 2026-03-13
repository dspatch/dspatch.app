// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Source type for agent providers.
enum SourceType { local, git, hub }

/// Status of a workspace inquiry.
enum InquiryStatus { pending, responded, expired, delivered }

/// Priority level of a workspace inquiry.
enum InquiryPriority { normal, high }
