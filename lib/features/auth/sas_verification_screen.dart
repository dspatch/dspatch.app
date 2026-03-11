// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

import 'widgets/auth_stub_layout.dart';

class SasVerificationScreen extends StatelessWidget {
  const SasVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthStubLayout(
      icon: LucideIcons.shield_check,
      title: 'Device verification',
      description:
          'Verify this device by confirming the short authentication string.',
    );
  }
}
