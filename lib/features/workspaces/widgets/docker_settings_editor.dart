// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';

import '../../../models/workspace_config.dart';
import '../../../core/utils/platform_info.dart';
import 'port_mapping_editor.dart';

/// Form for Docker container resource limits and networking.
///
/// Each field change calls [onChanged] with an updated [DockerConfig].
class DockerSettingsEditor extends StatefulWidget {
  const DockerSettingsEditor({
    super.key,
    required this.docker,
    required this.onChanged,
  });

  final DockerConfig docker;
  final ValueChanged<DockerConfig> onChanged;

  @override
  State<DockerSettingsEditor> createState() => _DockerSettingsEditorState();
}

class _DockerSettingsEditorState extends State<DockerSettingsEditor> {
  late final TextEditingController _memoryCtl;
  late final TextEditingController _cpuCtl;
  late final TextEditingController _homeSizeCtl;

  @override
  void initState() {
    super.initState();
    _memoryCtl =
        TextEditingController(text: widget.docker.memoryLimit ?? '');
    _cpuCtl = TextEditingController(
        text: widget.docker.cpuLimit?.toString() ?? '');
    _homeSizeCtl = TextEditingController(text: widget.docker.homeSize ?? '');
  }

  @override
  void didUpdateWidget(DockerSettingsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.docker != widget.docker) {
      final mem = widget.docker.memoryLimit ?? '';
      if (_memoryCtl.text != mem) _memoryCtl.text = mem;
      final cpu = widget.docker.cpuLimit?.toString() ?? '';
      if (_cpuCtl.text != cpu) _cpuCtl.text = cpu;
      final homeSize = widget.docker.homeSize ?? '';
      if (_homeSizeCtl.text != homeSize) _homeSizeCtl.text = homeSize;
    }
  }

  @override
  void dispose() {
    _memoryCtl.dispose();
    _cpuCtl.dispose();
    _homeSizeCtl.dispose();
    super.dispose();
  }

  void _emit(DockerConfig updated) => widget.onChanged(updated);

  static String _homeSizeNote() {
    if (PlatformInfo.isLinux) {
      return 'Advisory only — size enforcement requires overlay2/devicemapper '
          'with quota support configured on your Docker host.';
    }
    return 'Advisory only — Docker Desktop does not enforce named volume size limits.';
  }

  static String _networkModeDescription(String? mode) {
    return switch (mode) {
      'host' =>
        'Container shares the host network stack directly. '
        'No port mapping needed — all host ports are accessible. '
        'Less isolated but higher performance.',
      'none' =>
        'Container has no network access at all. '
        'Use for compute-only agents that don\'t need connectivity.',
      'bridge' =>
        'Each container gets its own isolated network. '
        'Use port mappings below to expose specific ports to the host.',
      _ =>
        'Container shares the host network stack directly. '
        'No port mapping needed — all host ports are accessible.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final docker = widget.docker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Field(
          label: 'Home Directory Persistence',
          description: 'Mount a named Docker volume at /root so files '
              'survive container restarts and image rebuilds. '
              'The volume persists until you delete the workspace.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DspatchSwitch(
                    value: docker.homePersistence,
                    onChanged: (val) =>
                        _emit(docker.copyWith(homePersistence: val)),
                  ),
                  const SizedBox(width: Spacing.sm),
                  const Text(
                    'Persist /root across runs',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
              if (docker.homePersistence) ...[
                const SizedBox(height: Spacing.lg),
                Input(
                  controller: _homeSizeCtl,
                  placeholder: 'No limit (e.g. 20g, 512m)',
                  onChanged: (val) {
                    final trimmed = val.trim();
                    _emit(docker.copyWith(
                      homeSize: trimmed.isEmpty ? null : trimmed,
                    ));
                  },
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _homeSizeNote(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: Spacing.md),
        // Row 1: Memory + CPU
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Field(
                label: 'Memory Limit',
                description: 'e.g. 4g, 512m',
                child: Input(
                  controller: _memoryCtl,
                  placeholder: 'No limit',
                  onChanged: (val) {
                    final trimmed = val.trim();
                    _emit(docker.copyWith(
                      memoryLimit: trimmed.isEmpty ? null : trimmed,
                    ));
                  },
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Field(
                label: 'CPU Limit',
                description: 'Number of cores, e.g. 2.0',
                child: Input(
                  controller: _cpuCtl,
                  placeholder: 'No limit',
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    _emit(docker.copyWith(cpuLimit: parsed));
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacing.md),

        // Row 2: Network + GPU
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Field(
                label: 'Network Mode',
                description: _networkModeDescription(docker.networkMode),
                child: Select<String>(
                  value: docker.networkMode,
                  hint: 'host (default)',
                  items: const [
                    SelectItem(
                      value: 'bridge',
                      label: 'bridge — isolated with port mapping',
                    ),
                    SelectItem(
                      value: 'host',
                      label: 'host — share host network',
                    ),
                    SelectItem(
                      value: 'none',
                      label: 'none — no networking',
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _emit(docker.copyWith(networkMode: val));
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Row(
                  children: [
                    DspatchSwitch(
                      value: docker.gpu,
                      onChanged: (val) =>
                          _emit(docker.copyWith(gpu: val)),
                    ),
                    const SizedBox(width: Spacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPU Passthrough',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            'Requires NVIDIA Container Toolkit',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Spacing.md),

        // Port mappings
        Field(
          label: 'Port Mappings',
          description: 'Format: host_port:container_port',
          child: PortMappingEditor(
            ports: docker.ports,
            onChanged: (ports) => _emit(docker.copyWith(ports: ports)),
          ),
        ),

      ],
    );
  }
}
