// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';

import '../../../core/extensions/drift_extensions.dart';
import '../../../database/engine_database.dart' show WorkspaceInquiry;
import 'package:flutter/material.dart';


class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.inquiry});
  final WorkspaceInquiry inquiry;

  @override
  Widget build(BuildContext context) {
    return DspatchBadge(
      label: inquiry.isHighPriority ? 'High' : 'Normal',
      variant: inquiry.isHighPriority
          ? BadgeVariant.destructive
          : BadgeVariant.secondary,
    );
  }
}
