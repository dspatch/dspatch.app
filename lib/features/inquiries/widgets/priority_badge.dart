// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_engine/dspatch_engine.dart';
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';


class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final InquiryPriority priority;

  @override
  Widget build(BuildContext context) {
    return DspatchBadge(
      label: priority == InquiryPriority.high ? 'High' : 'Normal',
      variant: priority == InquiryPriority.high
          ? BadgeVariant.destructive
          : BadgeVariant.secondary,
    );
  }
}
