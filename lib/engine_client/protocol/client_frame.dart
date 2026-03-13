// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

/// A frame sent from the client to the engine over WebSocket.
///
/// Currently only [command] exists. Additional frame types (e.g. ping)
/// can be added as needed.
class ClientFrame {
  final String id;
  final String method;
  final Map<String, dynamic> params;

  const ClientFrame.command({
    required this.id,
    required this.method,
    required this.params,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'command',
        'method': method,
        'params': params,
      };
}
