import 'package:flutter_test/flutter_test.dart';
import 'package:dspatch_app/engine_client/engine_health.dart';

void main() {
  group('HealthStatus', () {
    test('parses valid health JSON', () {
      final json = {
        'status': 'running',
        'uptime_seconds': 3600,
        'docker_available': true,
        'authenticated': true,
        'connected_devices': 2,
      };

      final status = HealthStatus.fromJson(json);
      expect(status.status, 'running');
      expect(status.uptimeSeconds, 3600);
      expect(status.dockerAvailable, isTrue);
      expect(status.authenticated, isTrue);
      expect(status.connectedDevices, 2);
    });

    test('handles missing optional fields with defaults', () {
      final json = {'status': 'running'};

      final status = HealthStatus.fromJson(json);
      expect(status.status, 'running');
      expect(status.uptimeSeconds, 0);
      expect(status.dockerAvailable, isFalse);
      expect(status.authenticated, isFalse);
      expect(status.connectedDevices, 0);
    });
  });

  group('EngineHealth', () {
    test('checkHealth returns null when engine is not running', () async {
      // Use a port where nothing is listening.
      final health = EngineHealth(host: '127.0.0.1', port: 1);
      final status = await health.checkHealth();
      expect(status, isNull);
    });
  });
}
