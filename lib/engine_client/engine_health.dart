// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

/// Parsed response from the engine's `GET /health` endpoint.
class HealthStatus {
  final String status;
  final int uptimeSeconds;
  final bool dockerAvailable;
  final bool authenticated;
  final int connectedDevices;

  const HealthStatus({
    required this.status,
    required this.uptimeSeconds,
    required this.dockerAvailable,
    required this.authenticated,
    required this.connectedDevices,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      uptimeSeconds: json['uptime_seconds'] as int? ?? 0,
      dockerAvailable: json['docker_available'] as bool? ?? false,
      authenticated: json['authenticated'] as bool? ?? false,
      connectedDevices: json['connected_devices'] as int? ?? 0,
    );
  }

  /// Whether the engine reports healthy status.
  bool get isRunning => status == 'running';
}

/// HTTP client for the engine's `/health` endpoint.
///
/// Used to detect if the engine is already running and to display
/// engine health in the GUI. Pure Dart — no Flutter imports.
class EngineHealth {
  final String host;
  final int port;
  final http.Client _httpClient;

  EngineHealth({
    required this.host,
    required this.port,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Checks the engine's health status.
  ///
  /// Returns [HealthStatus] if the engine is reachable, or `null` if the
  /// engine is not running (connection refused, timeout, etc.).
  Future<HealthStatus?> checkHealth({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final uri = Uri.parse('http://$host:$port/health');
      final response = await _httpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return HealthStatus.fromJson(json);
      }

      developer.log(
        'Health check returned status ${response.statusCode}',
        name: 'EngineHealth',
      );
      return null;
    } catch (e) {
      // Connection refused, timeout, DNS failure — engine is not running.
      return null;
    }
  }

  /// Polls the health endpoint until the engine is ready or timeout expires.
  ///
  /// Returns `true` if the engine became healthy, `false` on timeout.
  Future<bool> waitForReady({
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final status = await checkHealth();
      if (status != null && status.isRunning) return true;
      await Future.delayed(pollInterval);
    }

    return false;
  }

  void dispose() {
    _httpClient.close();
  }
}
