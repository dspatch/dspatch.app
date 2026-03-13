// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';

/// FFI signature for start_engine(config_json: *const c_char) -> i32
typedef StartEngineNative = Int32 Function(Pointer<Utf8>);
typedef StartEngineDart = int Function(Pointer<Utf8>);

/// FFI signature for stop_engine() -> i32
typedef StopEngineNative = Int32 Function();
typedef StopEngineDart = int Function();

/// Manages the in-process dspatch engine on mobile platforms.
///
/// Loads the compiled shared library and exposes [start] and [stop] methods
/// that delegate to the Rust FFI functions. The engine listens on localhost
/// and the same EngineClient connects to it.
class NativeEngine {
  NativeEngine._();

  static DynamicLibrary? _lib;
  static bool _running = false;

  /// Whether the native engine is currently running.
  static bool get isRunning => _running;

  /// Load the shared library for the current platform.
  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libdspatch_engine.so');
    } else if (Platform.isIOS) {
      // On iOS, the library is statically linked into the app binary.
      return DynamicLibrary.process();
    } else {
      throw UnsupportedError(
        'NativeEngine is only supported on mobile platforms (Android/iOS). '
        'On desktop, the engine runs as a separate process.',
      );
    }
  }

  /// Convert a Dart string to a null-terminated UTF-8 C string allocated
  /// with [malloc]. The caller must free the returned pointer.
  static Pointer<Utf8> _toCString(String s) => s.toNativeUtf8();

  /// Start the engine in-process with the given configuration.
  ///
  /// Returns the port the engine is listening on (from [clientApiPort]).
  /// Throws [StateError] if the engine is already running.
  /// Throws [Exception] on startup failure.
  static int start({
    required int clientApiPort,
    required String dbDir,
    String logLevel = 'info',
    int agentServerPort = 0,
    int invalidationDebounceMs = 50,
  }) {
    if (_running) {
      throw StateError('Native engine is already running');
    }

    _lib ??= _loadLibrary();

    final startEngine = _lib!
        .lookupFunction<StartEngineNative, StartEngineDart>('start_engine');

    final config = jsonEncode({
      'client_api_port': clientApiPort,
      'db_dir': dbDir,
      'log_level': logLevel,
      'agent_server_port': agentServerPort,
      'invalidation_debounce_ms': invalidationDebounceMs,
    });

    final configPtr = _toCString(config);

    try {
      final result = startEngine(configPtr);
      if (result != 0) {
        throw Exception(
          'start_engine failed with code $result '
          '(1=bad config, 2=already running, 3=startup failure)',
        );
      }
      _running = true;
      return clientApiPort;
    } finally {
      malloc.free(configPtr);
    }
  }

  /// Stop the engine gracefully.
  ///
  /// Throws [StateError] if the engine is not running.
  /// Throws [Exception] on shutdown failure.
  static void stop() {
    if (!_running) {
      throw StateError('Native engine is not running');
    }

    final stopEngine = _lib!
        .lookupFunction<StopEngineNative, StopEngineDart>('stop_engine');

    final result = stopEngine();
    _running = false;

    if (result != 0) {
      throw Exception('stop_engine failed with code $result');
    }
  }
}
