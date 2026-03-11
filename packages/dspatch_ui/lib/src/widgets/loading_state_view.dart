import 'package:flutter/material.dart';

/// Shared loading state view — a centered progress spinner.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
