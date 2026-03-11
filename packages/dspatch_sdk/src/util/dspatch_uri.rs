// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Parser for `dspatch://` URIs.

use crate::util::error::AppError;
use crate::util::result::Result;

/// Parsed `dspatch://` URI.
#[derive(Debug, Clone, PartialEq)]
pub enum DspatchUri {
    /// `dspatch://agent/<author>/<slug>` — references an agent provider.
    Agent { author: String, slug: String },
    /// `dspatch://template/<author>/<slug>` — references an agent template.
    Template { author: String, slug: String },
}

impl DspatchUri {
    /// Parse a `dspatch://` URI string.
    ///
    /// Accepted formats:
    /// - `dspatch://agent/<author>/<slug>`
    /// - `dspatch://template/<author>/<slug>`
    pub fn parse(uri: &str) -> Result<Self> {
        let rest = uri.strip_prefix("dspatch://").ok_or_else(|| {
            AppError::Validation(format!("Invalid dspatch URI: must start with 'dspatch://', got '{uri}'"))
        })?;

        let (kind, remainder) = if let Some(r) = rest.strip_prefix("agent/") {
            ("agent", r)
        } else if let Some(r) = rest.strip_prefix("template/") {
            ("template", r)
        } else {
            return Err(AppError::Validation(format!(
                "Invalid dspatch URI: unknown type in '{uri}', expected 'agent' or 'template'"
            )));
        };

        let parts: Vec<&str> = remainder.splitn(2, '/').collect();
        if parts.len() != 2 || parts[0].is_empty() || parts[1].is_empty() {
            return Err(AppError::Validation(format!(
                "Invalid dspatch URI: expected dspatch://{kind}/<author>/<slug>, got '{uri}'"
            )));
        }

        let author = parts[0].to_string();
        let slug = parts[1].to_string();

        match kind {
            "agent" => Ok(DspatchUri::Agent { author, slug }),
            "template" => Ok(DspatchUri::Template { author, slug }),
            _ => unreachable!(),
        }
    }

    /// Format back to a URI string.
    pub fn to_uri_string(&self) -> String {
        match self {
            DspatchUri::Agent { author, slug } => format!("dspatch://agent/{author}/{slug}"),
            DspatchUri::Template { author, slug } => format!("dspatch://template/{author}/{slug}"),
        }
    }

    /// Returns the author component.
    pub fn author(&self) -> &str {
        match self {
            DspatchUri::Agent { author, .. } | DspatchUri::Template { author, .. } => author,
        }
    }

    /// Returns the slug component.
    pub fn slug(&self) -> &str {
        match self {
            DspatchUri::Agent { slug, .. } | DspatchUri::Template { slug, .. } => slug,
        }
    }
}

impl std::fmt::Display for DspatchUri {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_uri_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_agent_uri() {
        let uri = DspatchUri::parse("dspatch://agent/oakisnotree/claude-code").unwrap();
        assert_eq!(uri, DspatchUri::Agent {
            author: "oakisnotree".into(),
            slug: "claude-code".into(),
        });
    }

    #[test]
    fn parse_template_uri() {
        let uri = DspatchUri::parse("dspatch://template/oakisnotree/claude-reviewer").unwrap();
        assert_eq!(uri, DspatchUri::Template {
            author: "oakisnotree".into(),
            slug: "claude-reviewer".into(),
        });
    }

    #[test]
    fn reject_old_single_segment_format() {
        assert!(DspatchUri::parse("dspatch://agent/claude-code").is_err());
    }

    #[test]
    fn reject_invalid_scheme() {
        assert!(DspatchUri::parse("https://example.com").is_err());
    }

    #[test]
    fn reject_empty_segments() {
        assert!(DspatchUri::parse("dspatch://agent//slug").is_err());
        assert!(DspatchUri::parse("dspatch://agent/author/").is_err());
    }

    #[test]
    fn roundtrip() {
        let uri = DspatchUri::Agent { author: "oak".into(), slug: "test".into() };
        assert_eq!(DspatchUri::parse(&uri.to_uri_string()).unwrap(), uri);
    }

    #[test]
    fn display_trait() {
        let uri = DspatchUri::Template { author: "oak".into(), slug: "test".into() };
        assert_eq!(format!("{uri}"), "dspatch://template/oak/test");
    }
}
