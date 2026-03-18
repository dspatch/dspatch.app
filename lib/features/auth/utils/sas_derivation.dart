// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derive a 6-digit Short Authentication String (SAS) from two identity keys.
///
/// Both devices compute SHA-256(sorted(keyA, keyB)) and truncate to 6 digits.
/// Sorting ensures both sides produce the same result regardless of order.
Future<String> deriveSas(String identityKeyA, String identityKeyB) async {
  // Sort keys lexicographically so both sides get the same input order
  final keys = [identityKeyA, identityKeyB]..sort();
  final input = utf8.encode('${keys[0]}:${keys[1]}');

  final sha256 = Sha256();
  final hash = await sha256.hash(input);
  final bytes = Uint8List.fromList(hash.bytes);

  // Truncate first 4 bytes to a 6-digit number
  final num = ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) & 0x7FFFFFFF;
  return (num % 1000000).toString().padLeft(6, '0');
}
