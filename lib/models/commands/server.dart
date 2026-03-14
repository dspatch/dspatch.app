// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// Typed commands for engine server lifecycle.
library;

import 'command.dart';

class StartServer extends VoidEngineCommand {
  StartServer({this.preferredPort});
  final int? preferredPort;

  @override
  String get method => 'start_server';

  @override
  Map<String, dynamic> get params => {
        if (preferredPort != null) 'preferred_port': preferredPort,
      };
}

class StopServer extends VoidEngineCommand {
  @override
  String get method => 'stop_server';

  @override
  Map<String, dynamic>? get params => null;
}
