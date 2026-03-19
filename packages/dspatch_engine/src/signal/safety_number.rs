// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Safety number derivation for identity verification.
//!
//! Generates a human-readable numeric code from two identity keys (local + remote)
//! that users can compare out-of-band to verify they're communicating with
//! the intended device and not a MITM.

use sha2::{Sha256, Digest};

/// Derives a safety number from two identity key public key bytes.
///
/// The safety number is a 60-digit numeric string formatted in 12 groups of 5,
/// following Signal's approach:
/// 1. Sort the two public keys lexicographically
/// 2. Concatenate them
/// 3. Hash with SHA-256 iterated 5200 times (following Signal's specification)
/// 4. Convert to numeric digits
/// 5. Format as 12 groups of 5 digits
///
/// **Breaking change**: existing safety numbers derived with 1 iteration are
/// no longer valid — users must re-verify after upgrading.
pub fn derive_safety_number(
    local_identity_key: &[u8],
    remote_identity_key: &[u8],
) -> String {
    // Sort keys to ensure both sides produce the same number.
    let (first, second) = if local_identity_key <= remote_identity_key {
        (local_identity_key, remote_identity_key)
    } else {
        (remote_identity_key, local_identity_key)
    };

    // Build the combined key material (sorted concatenation) used in every iteration.
    let mut identity_bytes = Vec::with_capacity(first.len() + second.len());
    identity_bytes.extend_from_slice(first);
    identity_bytes.extend_from_slice(second);

    // First hash seeds the iteration.
    let mut hash: Vec<u8> = Sha256::digest(&identity_bytes).to_vec();

    // Iterate 5200 times per Signal's safety-number specification.
    for _ in 0..5200 {
        let mut input = Vec::with_capacity(identity_bytes.len() + hash.len());
        input.extend_from_slice(&identity_bytes);
        input.extend_from_slice(&hash);
        hash = Sha256::digest(&input).to_vec();
    }

    // Convert hash bytes to numeric digits.
    // Take 30 bytes (60 digits when each byte maps to 2 digits mod 100).
    let digits: String = hash.iter()
        .take(30)
        .map(|b| format!("{:02}", b % 100))
        .collect();

    // Format as 12 groups of 5 digits.
    digits.as_bytes()
        .chunks(5)
        .map(|chunk| std::str::from_utf8(chunk).unwrap_or("?????"))
        .collect::<Vec<_>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn safety_number_is_deterministic() {
        let key_a = b"alice_identity_key_public_bytes!";
        let key_b = b"bobs_identity_key__public_bytes!";

        let sn1 = derive_safety_number(key_a, key_b);
        let sn2 = derive_safety_number(key_a, key_b);
        assert_eq!(sn1, sn2);
    }

    #[test]
    fn safety_number_is_symmetric() {
        let key_a = b"alice_identity_key_public_bytes!";
        let key_b = b"bobs_identity_key__public_bytes!";

        let sn_ab = derive_safety_number(key_a, key_b);
        let sn_ba = derive_safety_number(key_b, key_a);
        assert_eq!(sn_ab, sn_ba);
    }

    #[test]
    fn safety_number_format() {
        let key_a = b"alice_identity_key_public_bytes!";
        let key_b = b"bobs_identity_key__public_bytes!";

        let sn = derive_safety_number(key_a, key_b);
        // Should be 12 groups of 5 digits separated by spaces
        let groups: Vec<&str> = sn.split(' ').collect();
        assert_eq!(groups.len(), 12);
        for group in &groups {
            assert_eq!(group.len(), 5);
            assert!(group.chars().all(|c| c.is_ascii_digit()));
        }
    }
}
