// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.
import '../../../core/extensions/drift_extensions.dart';
import '../../../database/engine_database.dart';
import '../../../core/extensions/agent_state_ext.dart';
import '../../../core/utils/datetime_ext.dart';
import 'dart:convert';

import 'package:dspatch_ui/dspatch_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../di/providers.dart';
import '../../../shared/widgets/markdown_view.dart';
import 'agent_input_field.dart';
import '../workspace_controller.dart';

// ── Unified timeline item ──

sealed class _TimelineItem implements Comparable<_TimelineItem> {
  DateTime get timestamp;

  @override
  int compareTo(_TimelineItem other) => timestamp.compareTo(other.timestamp);
}

class _MessageItem extends _TimelineItem {
  _MessageItem(this.message);
  final AgentMessage message;

  @override
  DateTime get timestamp => message.createdAtDate;
}

class _ActivityItem extends _TimelineItem {
  _ActivityItem(this.activity);
  final AgentActivityEvent activity;

  @override
  DateTime get timestamp => activity.timestampDate;
}

// ── Activity helpers ──

/// Cache parsed JSON data per activity ID to avoid repeated jsonDecode calls.
/// Cleared when the widget rebuilds with new data.
final _activityDataCache = <String, Map<String, dynamic>?>{};

Map<String, dynamic>? _activityData(AgentActivityEvent a) {
  if (a.dataJson == null) return null;
  return _activityDataCache.putIfAbsent(a.id, () {
    try {
      return jsonDecode(a.dataJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  });
}

String? _activityTool(AgentActivityEvent a) => _activityData(a)?['tool'] as String?;

String? _activityInquiryId(AgentActivityEvent a) =>
    _activityData(a)?['inquiry_id'] as String?;

String _activityDescription(AgentActivityEvent a) {
  final data = _activityData(a);
  final desc = data?['description'] as String?;
  if (desc != null && desc.isNotEmpty) return desc;
  return _activityTool(a) ?? a.eventType;
}

/// Parse a talk_to input string (Python repr dict or plain text) into
/// ``(text, continueConversation)``.
(String, bool) _parseTalkToInput(String raw) {
  // Try extracting 'text' value via regex — handles both single- and
  // double-quoted Python repr without corrupting apostrophes in the value.
  final textMatch = RegExp(r"""['"]text['"]\s*:\s*['"](.+?)['"](?:\s*[,}])""",
          dotAll: true)
      .firstMatch(raw);
  final contMatch =
      RegExp(r"""['"]continue_previous_conversation['"]\s*:\s*(True|true|False|false)""")
          .firstMatch(raw);

  if (textMatch != null) {
    final text = textMatch.group(1) ?? raw;
    final cont = contMatch != null &&
        (contMatch.group(1) == 'True' || contMatch.group(1) == 'true');
    return (text, cont);
  }

  // Fallback: try JSON parse.
  try {
    final parsed = jsonDecode(raw);
    if (parsed is Map) {
      return (
        parsed['text'] as String? ?? raw,
        parsed['continue_previous_conversation'] as bool? ?? false,
      );
    }
  } catch (_) {}

  return (raw, false);
}

/// Try to parse the `input` field from activity data.
/// The input is typically `str(dict)` from Python — a repr of a dict.
/// We try JSON first, then attempt to fix common Python repr differences.
Map<String, dynamic>? _parseInputField(Map<String, dynamic> data) {
  final raw = data['input'];
  if (raw == null) return null;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  final str = raw.toString();
  if (str.isEmpty) return null;

  // Try JSON first.
  try {
    final parsed = jsonDecode(str);
    if (parsed is Map) return Map<String, dynamic>.from(parsed);
  } catch (_) {}

  // Try fixing Python repr: True→true, False→false, None→null, '→"
  // Note: this breaks when values contain apostrophes, so it's best-effort.
  try {
    var fixed = str
        .replaceAll("True", "true")
        .replaceAll("False", "false")
        .replaceAll("None", "null")
        .replaceAll("'", '"');
    final parsed = jsonDecode(fixed);
    if (parsed is Map) return Map<String, dynamic>.from(parsed);
  } catch (_) {}

  return null;
}

/// Extract a specific string value from a Python repr dict string.
/// Uses regex to find `'key': '...'` patterns, handling escaped quotes.
/// Returns null if not found.
String? _extractPythonStrValue(String repr, String key) {
  // Match 'key': '...' where the value may span multiple lines and
  // contain escaped single-quotes (\'). The value ends at an unescaped
  // single-quote followed by , or }.
  final pattern = RegExp(
    """['"]$key['"]\\s*:\\s*'(.*?)(?<!\\\\)'(?:\\s*[,}])""",
    dotAll: true,
  );
  final match = pattern.firstMatch(repr);
  if (match != null) {
    return match
        .group(1)
        ?.replaceAll("\\'", "'")
        .replaceAll("\\n", "\n")
        .replaceAll("\\\\", "\\");
  }
  return null;
}

Color _activityDotColor(String? tool, String eventType) {
  return switch (tool) {
    'Read' || 'Glob' || 'Grep' => AppColors.terminalBlue,
    'Write' || 'Edit' || 'NotebookEdit' => AppColors.terminalAmber,
    'Bash' => AppColors.terminalGreen,
    'ExitPlanMode' => AppColors.terminalBlue,
    'TodoWrite' => AppColors.terminalGreen,
    _ => AppColors.mutedForeground,
  };
}

// ── Constants ──

const _timelineColumnWidth = 40.0;
const _timelineLineWidth = 1.5;

// ── Widget ──

class AgentTimelineView extends ConsumerStatefulWidget {
  const AgentTimelineView({
    super.key,
    required this.workspaceId,
    required this.runId,
    required this.instanceId,
    required this.agents,
  });

  final String workspaceId;
  final String runId;
  final String instanceId;
  final List<WorkspaceAgent> agents;

  @override
  ConsumerState<AgentTimelineView> createState() => _AgentTimelineViewState();
}

class _AgentTimelineViewState extends ConsumerState<AgentTimelineView> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _expandedActivities = <String>{};
  bool _autoScroll = true;
  bool _isSending = false;
  int _previousCount = 0;
  double _inputHeight = 120;
  Map<String, WorkspaceInquiry> _inquiryMap = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 50;
    if (_autoScroll != atBottom) {
      setState(() => _autoScroll = atBottom);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  /// Find the agent matching this instance to get status and agentKey.
  WorkspaceAgent? get _agent {
    for (final a in widget.agents) {
      if (a.instanceId == widget.instanceId) return a;
    }
    return null;
  }

  String? get _agentStatus => _agent?.status;
  String get _agentKey => _agent?.agentKey ?? '';
  String get _displayName => _agent?.displayName ?? '';

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(agentMessagesProvider((
      runId: widget.runId,
      instanceId: widget.instanceId,
    )));
    final activityAsync = ref.watch(agentActivityProvider((
      runId: widget.runId,
      instanceId: widget.instanceId,
    )));
    // Inquiries are still watched for _inquiryMap (used by inquiry tool-call
    // activity cards), but no longer inserted as standalone timeline items.
    final agent = _agent;
    final inquiriesAsync = agent != null
        ? ref.watch(workspaceInquiriesProvider(agent.runId))
        : null;

    final messages = messagesAsync.valueOrNull ?? [];
    final activities = activityAsync.valueOrNull ?? [];
    final allInquiries = inquiriesAsync?.valueOrNull ?? [];
    final status = _agentStatus;

    // Only rebuild inquiry map when the list identity changes.
    if (allInquiries.length != _inquiryMap.length ||
        allInquiries.any((i) => _inquiryMap[i.id] != i)) {
      _inquiryMap = {for (final i in allInquiries) i.id: i};
    }
    // Evict stale entries from activity data cache when activities change.
    if (activities.length != _activityDataCache.length) {
      _activityDataCache.removeWhere((id, _) => !activities.any((a) => a.id == id));
    }
    final items = _buildTimelineItems(messages, activities);

    // Auto-scroll on new items
    if (_autoScroll && items.length > _previousCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    _previousCount = items.length;

    final showWorking = status == AgentState.generating;

    return Column(
      children: [
        // ── Agent header bar ──
        _AgentHeader(
          agentKey: _agentKey,
          displayName: _displayName,
          status: status,
        ),
        const Separator(),

        // ── Timeline + input ──
        Expanded(
          child: ContentArea(
            padding: EdgeInsets.zero,
            child: Stack(
            children: [
              // Chat list
              Padding(
                padding: EdgeInsets.only(bottom: _inputHeight),
                child: items.isEmpty && !showWorking
                    ? const EmptyState(
                        icon: LucideIcons.message_circle,
                        title: 'No Messages',
                        description:
                            'Messages will appear as the agent works.',
                      )
                    : SelectionArea(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.lg,
                          vertical: Spacing.md,
                        ),
                        itemCount: items.length + (showWorking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return _buildWorkingIndicator();
                          }
                          final item = items[index];
                          final isFirst = index == 0;
                          final isLast =
                              index == items.length - 1 && !showWorking;
                          return switch (item) {
                            _MessageItem(:final message) =>
                              message.senderName != null
                                  ? _buildTalkToReceivedCard(
                                      message, isFirst, isLast)
                                  : _buildMessageRow(
                                      message, isFirst, isLast),
                            _ActivityItem(:final activity) =>
                              _buildActivityNode(
                                  activity, isFirst, isLast),
                          };
                        },
                      ),
                    ),
              ),

              // Jump to bottom
              if (!_autoScroll)
                Positioned(
                  right: Spacing.lg,
                  bottom: _inputHeight + Spacing.sm,
                  child: Button(
                    label: 'Jump to bottom',
                    icon: LucideIcons.arrow_down,
                    variant: ButtonVariant.primary,
                    onPressed: () {
                      _scrollToBottom();
                      setState(() => _autoScroll = true);
                    },
                  ),
                ),

              // Floating input
              Positioned(
                left: Spacing.lg,
                right: Spacing.lg,
                bottom: 0,
                child: _MeasureSize(
                  onChange: (size) {
                    if (size.height != _inputHeight) {
                      setState(() => _inputHeight = size.height);
                    }
                  },
                  child: _buildInput(status),
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  // ── Timeline item builder ──

  /// Tool names whose tool_call activities are redundant with dedicated
  /// activity types (inquiry.*, talk_to.*).  The SDK still emits tool_call
  /// activities for these — we just hide them in the UI.
  static final _dspatchToolPrefixes = [
    'send_inquiry', 'receive_incoming_inquiry', 'reply_to_inquiry',
    'talk_to_', 'continue_waiting_for_agent_response',
  ];

  static bool _isDspatchToolCall(AgentActivityEvent a) {
    if (a.eventType != 'tool_call') return false;
    final tool = _activityTool(a);
    if (tool == null) return false;
    return _dspatchToolPrefixes.any((p) => tool.contains(p));
  }

  List<_TimelineItem> _buildTimelineItems(
    List<AgentMessage> messages,
    List<AgentActivityEvent> activities,
  ) {
    final items = <_TimelineItem>[
      for (final m in messages) _MessageItem(m),
      for (final a in activities)
        if (!_isDspatchToolCall(a)) _ActivityItem(a),
    ]..sort();

    // Deduplicate: skip inquiry.response if it directly follows
    // inquiry.request with the same inquiry_id.
    for (int i = items.length - 1; i > 0; i--) {
      final cur = items[i];
      final prev = items[i - 1];
      if (cur is _ActivityItem &&
          prev is _ActivityItem &&
          cur.activity.eventType == 'inquiry.response' &&
          prev.activity.eventType == 'inquiry.request' &&
          _activityInquiryId(cur.activity) ==
              _activityInquiryId(prev.activity)) {
        items.removeAt(i);
      }
    }

    return items;
  }

  // ── Timeline gutter ──

  static const _lineLeft =
      (_timelineColumnWidth - _timelineLineWidth) / 2;

  /// Wraps content in a timeline row with a marker and optional vertical line.
  Widget _timelineRow({
    required Widget marker,
    required Widget content,
    bool isLast = false,
    double lineTop = 20,
  }) {
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: _lineLeft,
            top: lineTop,
            bottom: 0,
            child: Container(
              width: _timelineLineWidth,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _timelineColumnWidth,
              child: Center(child: marker),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(child: content),
          ],
        ),
      ],
    );
  }

  /// A timeline row with no marker and no vertical line.
  Widget _timelinePassthroughRow({required Widget content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: _timelineColumnWidth + Spacing.sm),
        Expanded(child: content),
      ],
    );
  }

  // ── Message rows ──

  Widget _buildMessageRow(AgentMessage msg, bool isFirst, bool isLast) {
    final isUser = msg.role == 'user';
    if (isUser) return _buildUserMessage(msg, isFirst, isLast);
    return _buildAgentMessage(msg, isFirst, isLast);
  }

  Widget _buildAgentMessage(AgentMessage msg, bool isFirst, bool isLast) {
    return _timelineRow(
      marker: Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(top: Spacing.sm),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.mutedForeground.withValues(alpha: 0.4),
        ),
      ),
      lineTop: 16,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.model != null) ...[
              Text(
                msg.model!,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: Spacing.xs),
            ],
            MarkdownView(data: msg.content),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Text(
                  msg.createdAtDate.timeAgo(),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                CopyButton(textToCopy: msg.content, iconSize: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(AgentMessage msg, bool isFirst, bool isLast) {
    return _timelinePassthroughRow(
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CopyButton(textToCopy: msg.content, iconSize: 12),
                const SizedBox(width: Spacing.sm),
                Text(
                  msg.createdAtDate.timeAgo(),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Talk-to cards (unified) ──
  Widget _buildTalkToReceivedCard(
      AgentMessage message, bool isFirst, bool isLast) {
    final (messageText, continueConv) = _parseTalkToInput(message.content);

    return _timelinePassthroughRow(
      content: _buildTalkToCard(
        id: 'recv_${message.id}',
        label: 'From ${message.senderName!}',
        message: messageText,
        timestamp: message.createdAtDate,
        isOutgoing: false,
        continueConversation: continueConv,
        alignment: CrossAxisAlignment.end,
      ),
    );
  }

  /// Shared card for all talk_to variants.
  Widget _buildTalkToCard({
    required String id,
    required String label,
    required String message,
    required DateTime timestamp,
    required bool isOutgoing,
    bool continueConversation = false,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
    VoidCallback? onJump,
    String? jumpLabel,
    GlobalKey? itemKey,
  }) {
    final isExpanded = _expandedActivities.contains(id);
    final icon = Transform.rotate(
      angle: isOutgoing ? 1.5708 : -1.5708, // ±90°
      child: const Icon(LucideIcons.wifi, size: 12, color: AppColors.terminalBlue),
    );

    return Padding(
        key: itemKey,
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isExpanded) {
                    _expandedActivities.remove(id);
                  } else {
                    _expandedActivities.add(id);
                  }
                }),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.terminalBlue.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.terminalBlue.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            icon,
                            const SizedBox(width: Spacing.xs),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: AppColors.terminalBlue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (continueConversation) ...[
                                    const SizedBox(width: Spacing.xs),
                                    Tooltip(
                                      message: 'Continuing previous conversation',
                                      child: Icon(
                                        LucideIcons.history,
                                        size: 12,
                                        color: AppColors.terminalBlue.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (onJump != null)
                              GestureDetector(
                                onTap: onJump,
                                behavior: HitTestBehavior.opaque,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        jumpLabel ?? 'Jump',
                                        style: const TextStyle(
                                          color: AppColors.terminalBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        LucideIcons.arrow_up_right,
                                        size: 12,
                                        color: AppColors.terminalBlue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(width: Spacing.xs),
                            AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                LucideIcons.chevron_right,
                                size: 14,
                                color: AppColors.terminalBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.sm),
                        AnimatedCrossFade(
                          firstChild: Text(
                            message.trim(),
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 13,
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisAlignment: alignment == CrossAxisAlignment.end
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  timestamp.timeAgo(),
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 10,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(width: Spacing.sm),
                  CopyButton(textToCopy: message, iconSize: 12),
                ],
              ],
            ),
          ],
        ),
    );
  }

  // ── Activity node (collapsible) ──

  Widget _buildActivityNode(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    final tool = _activityTool(act);
    final eventType = act.eventType;

    if (eventType == 'thinking') {
      return _buildThinkingNode(act, isFirst, isLast);
    }

    // ── Dedicated activity types (talk_to.*, inquiry.*) ──

    if (eventType == 'talk_to.request') {
      return _buildTalkToActivityCard(act, isFirst, isLast);
    }
    if (eventType == 'talk_to.response') {
      return _buildTalkToResponseCard(act, isFirst, isLast);
    }
    if (eventType == 'talk_to.waiting') {
      return _buildContinueWaitingNode(act, isFirst, isLast);
    }

    if (eventType == 'inquiry.request') {
      final inquiryId = _activityInquiryId(act);
      if (inquiryId != null) {
        final inquiry = _inquiryMap[inquiryId];
        if (inquiry != null) {
          return _buildInquiryCard(inquiry, isFirst, isLast);
        }
      }
      return _buildInquiryPlaceholder(isFirst, isLast);
    }
    if (eventType == 'inquiry.receive') {
      final inquiryId = _activityInquiryId(act);
      if (inquiryId != null) {
        final inquiry = _inquiryMap[inquiryId];
        if (inquiry != null) {
          return _buildInquiryCard(inquiry, isFirst, isLast,
              forcePending: true);
        }
      }
      return _buildInquiryPlaceholder(isFirst, isLast);
    }
    if (eventType == 'inquiry.responded') {
      final inquiryId = _activityInquiryId(act);
      if (inquiryId != null) {
        final inquiry = _inquiryMap[inquiryId];
        if (inquiry != null) {
          return _buildInquiryCard(inquiry, isFirst, isLast);
        }
      }
      return _buildInquiryPlaceholder(isFirst, isLast);
    }
    if (eventType == 'inquiry.response') {
      final inquiryId = _activityInquiryId(act);
      if (inquiryId != null) {
        final inquiry = _inquiryMap[inquiryId];
        if (inquiry != null) {
          return _buildInquiryCard(inquiry, isFirst, isLast);
        }
      }
      return _buildInquiryPlaceholder(isFirst, isLast);
    }

    // ── Inline tool cards (ExitPlanMode, TodoWrite) ──

    if (tool == 'ExitPlanMode') {
      return _buildPlanNode(act, isFirst, isLast);
    }
    if (tool == 'TodoWrite') {
      return _buildTodoNode(act, isFirst, isLast);
    }

    final data = _activityData(act);
    final color = _activityDotColor(tool, eventType);
    final activityId = act.id;
    final isExpanded = _expandedActivities.contains(activityId);

    final icon = switch (tool) {
      'Read' => LucideIcons.file_text,
      'Write' || 'Edit' || 'NotebookEdit' => LucideIcons.pencil,
      'Glob' || 'Grep' => LucideIcons.search,
      'Bash' => LucideIcons.terminal,
      _ => switch (eventType) {
        'tool_call' => LucideIcons.wrench,
        _ => LucideIcons.circle,
      },
    };

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(icon, size: 16, color: color),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (clickable)
            GestureDetector(
              onTap: data != null
                  ? () => setState(() {
                        if (isExpanded) {
                          _expandedActivities.remove(activityId);
                        } else {
                          _expandedActivities.add(activityId);
                        }
                      })
                  : null,
              child: MouseRegion(
                cursor: data != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Spacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDescriptionText(act, tool, color),
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        act.timestampDate.timeAgo(),
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 10,
                          fontFamily: AppFonts.mono,
                        ),
                      ),
                      if (data != null) ...[
                        const SizedBox(width: Spacing.sm),
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            LucideIcons.chevron_right,
                            size: 16,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Expanded detail view
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: isExpanded && data != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: Spacing.xs,
                        bottom: Spacing.xs,
                      ),
                      child: _buildActivityDetail(data, tool, eventType),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Inquiry card (shared) ──

  /// Shared inquiry card content used by all inquiry-related timeline items.
  Widget _inquiryCardContent({
    required String badgeLabel,
    required BadgeVariant badgeVariant,
    required String content,
    required DateTime timestamp,
    required Color borderColor,
    required Color bgColor,
    String? responseText,
    DateTime? responseTimestamp,
    VoidCallback? onTap,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DspatchBadge(
                        label: badgeLabel,
                        variant: badgeVariant,
                      ),
                      const Spacer(),
                      Text(
                        timestamp.timeAgo(),
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 10,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: Spacing.xs),
                        const Icon(LucideIcons.chevron_right,
                            size: 14, color: AppColors.mutedForeground),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    content,
                    style: const TextStyle(
                      color: AppColors.foreground,
                      fontSize: 12,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (responseText != null) ...[
                    const SizedBox(height: Spacing.xs),
                    Row(
                      children: [
                        const Icon(LucideIcons.reply,
                            size: 11, color: AppColors.mutedForeground),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(
                            responseText,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (responseTimestamp != null) ...[
                          const SizedBox(width: Spacing.xs),
                          Text(
                            responseTimestamp.timeAgo(),
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryCard(
      WorkspaceInquiry inquiry, bool isFirst, bool isLast,
      {bool forcePending = false}) {
    final isPending = forcePending || inquiry.isPending;
    final isExpired = !forcePending && inquiry.isExpired;

    final Color color;
    final String badgeLabel;
    final BadgeVariant badgeVariant;
    final IconData icon;
    if (isExpired) {
      color = AppColors.mutedForeground;
      badgeLabel = 'Expired';
      badgeVariant = BadgeVariant.secondary;
      icon = LucideIcons.timer_off;
    } else if (isPending) {
      color = AppColors.warning;
      badgeLabel = 'Pending';
      badgeVariant = BadgeVariant.warning;
      icon = LucideIcons.circle_question_mark;
    } else {
      color = AppColors.success;
      badgeLabel = 'Responded';
      badgeVariant = BadgeVariant.success;
      icon = LucideIcons.circle_check;
    }

    final workspaceId = widget.workspaceId;

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 16, color: color),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: _inquiryCardContent(
          badgeLabel: badgeLabel,
          badgeVariant: badgeVariant,
          content: inquiry.contentMarkdown,
          timestamp: inquiry.createdAtDate,
          borderColor: color.withValues(alpha: 0.4),
          bgColor: color.withValues(alpha: 0.05),
          responseText: isPending ? null : inquiry.responseText,
          responseTimestamp: inquiry.respondedAtDate,
          onTap: () => context.go(
            '/workspaces/$workspaceId/inquiries/${inquiry.id}',
          ),
        ),
      ),
    );
  }

  // ── Dspatch tool card builders ──

  Widget _buildTalkToActivityCard(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    final data = _activityData(act) ?? {};
    final peer = data['target_agent'] as String? ?? 'unknown';
    final messageText = data['text'] as String? ?? '';
    final continueConv = data['continue_conversation'] as bool? ?? false;

    // Find the target agent's instance for jump-to
    String? targetInstanceId;
    for (final a in widget.agents) {
      if (a.agentKey == peer) {
        targetInstanceId = a.instanceId;
        break;
      }
    }

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(LucideIcons.messages_square,
            size: 16, color: AppColors.terminalBlue),
      ),
      lineTop: 22,
      isLast: isLast,
      content: _buildTalkToCard(
        id: act.id,
        label: 'Sent to $peer',
        message: messageText,
        timestamp: act.timestampDate,
        isOutgoing: true,
        continueConversation: continueConv,
        onJump: targetInstanceId != null
            ? () => ref
                .read(
                    selectedInstanceProvider(widget.workspaceId).notifier)
                .state = targetInstanceId
            : null,
        jumpLabel: 'View',
      ),
    );
  }

  Widget _buildTalkToResponseCard(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    final data = _activityData(act) ?? {};
    final peer = data['target_agent'] as String? ?? 'unknown';
    final responseText = data['response'] as String? ?? '';

    // Find the peer agent's instance for jump-to.
    String? peerInstanceId;
    for (final a in widget.agents) {
      if (a.agentKey == peer) {
        peerInstanceId = a.instanceId;
        break;
      }
    }

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(LucideIcons.messages_square,
            size: 16, color: AppColors.terminalBlue),
      ),
      lineTop: 22,
      isLast: isLast,
      content: _buildTalkToCard(
        id: act.id,
        label: 'Response from $peer',
        message: responseText,
        timestamp: act.timestampDate,
        isOutgoing: false,
        onJump: peerInstanceId != null
            ? () => ref
                .read(
                    selectedInstanceProvider(widget.workspaceId).notifier)
                .state = peerInstanceId
            : null,
        jumpLabel: 'View',
      ),
    );
  }

  Widget _buildInquiryPlaceholder(bool isFirst, bool isLast) {
    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: _inquiryCardContent(
          badgeLabel: 'Loading',
          badgeVariant: BadgeVariant.secondary,
          content: 'Loading inquiry...',
          timestamp: DateTime.now(),
          borderColor: AppColors.mutedForeground.withValues(alpha: 0.4),
          bgColor: AppColors.mutedForeground.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  // ── Plan node (ExitPlanMode) ──

  Widget _buildPlanNode(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    final data = _activityData(act);
    // Try structured parse first, then regex extract from Python repr,
    // then fall back to act.content.
    var input = data != null ? _parseInputField(data) : null;
    if (input == null && act.content != null && act.content!.isNotEmpty) {
      try {
        final parsed = jsonDecode(act.content!);
        if (parsed is Map) input = Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    final rawInput = data?['input']?.toString() ?? '';
    final plan = input?['plan'] as String?
        ?? _extractPythonStrValue(rawInput, 'plan')
        ?? act.content
        ?? '';
    final activityId = act.id;
    final isExpanded = _expandedActivities.contains(activityId);

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(LucideIcons.map,
            size: 16, color: AppColors.mutedForeground),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — always visible, toggles expand
                GestureDetector(
                  onTap: plan.isNotEmpty
                      ? () => setState(() {
                            if (isExpanded) {
                              _expandedActivities.remove(activityId);
                            } else {
                              _expandedActivities.add(activityId);
                            }
                          })
                      : null,
                  child: MouseRegion(
                    cursor: plan.isNotEmpty
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Spacing.xs,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Implementation Plan',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFonts.mono,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            act.timestampDate.timeAgo(),
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                              fontFamily: AppFonts.mono,
                            ),
                          ),
                          if (plan.isNotEmpty) ...[
                            const SizedBox(width: Spacing.sm),
                            AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                LucideIcons.chevron_right,
                                size: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Plan content — collapsible
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: plan.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(Spacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.border),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: isExpanded
                                ? ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 600),
                                    child: SingleChildScrollView(
                                      child: MarkdownView(
                                          data: plan, compact: true),
                                    ),
                                  )
                                : ClipRect(
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxHeight: 72),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white,
                                            Colors.white,
                                            Colors.transparent,
                                          ],
                                          stops: [0.0, 0.5, 1.0],
                                        ).createShader(bounds),
                                        blendMode: BlendMode.dstIn,
                                        child: MarkdownView(
                                            data: plan, compact: true),
                                      ),
                                    ),
                                  ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Todo node (TodoWrite) ──

  Widget _buildTodoNode(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    final data = _activityData(act);
    // Try parsing from data.input first, then fall back to act.content.
    var input = data != null ? _parseInputField(data) : null;
    if (input == null && act.content != null && act.content!.isNotEmpty) {
      try {
        final parsed = jsonDecode(act.content!);
        if (parsed is Map) input = Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    final todos = (input?['todos'] as List<dynamic>?) ?? [];

    final completed =
        todos.where((t) => t is Map && t['status'] == 'completed').length;
    final total = todos.length;

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(LucideIcons.list_checks,
            size: 16, color: AppColors.mutedForeground),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with progress
                Row(
                  children: [
                    Text(
                      'Tasks',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '$completed/$total',
                      style: TextStyle(
                        color: completed == total && total > 0
                            ? AppColors.terminalGreen
                            : AppColors.mutedForeground,
                        fontSize: 11,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      act.timestampDate.timeAgo(),
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 11,
                        fontFamily: AppFonts.mono,
                      ),
                    ),
                  ],
                ),
                // Progress bar
                if (total > 0) ...[
                  const SizedBox(height: Spacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(
                        value: completed / total,
                        backgroundColor:
                            AppColors.muted.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completed == total
                              ? AppColors.terminalGreen.withValues(alpha: 0.5)
                              : AppColors.mutedForeground.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
                // Todo items
                const SizedBox(height: Spacing.xs),
                ...todos.map((t) {
                  if (t is! Map) return const SizedBox.shrink();
                  final content = t['content'] as String? ?? '';
                  final status = t['status'] as String? ?? 'pending';

                  final (icon, iconColor) = switch (status) {
                    'completed' => (
                        LucideIcons.circle_check,
                        AppColors.terminalGreen.withValues(alpha: 0.6)
                      ),
                    'in_progress' => (
                        LucideIcons.loader,
                        AppColors.terminalAmber.withValues(alpha: 0.7)
                      ),
                    _ => (
                        LucideIcons.circle,
                        AppColors.muted
                      ),
                  };

                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(icon, size: 13, color: iconColor),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            content,
                            style: TextStyle(
                              color: status == 'completed'
                                  ? AppColors.mutedForeground.withValues(alpha: 0.6)
                                  : AppColors.secondaryForeground,
                              fontSize: 12,
                              fontFamily: AppFonts.mono,
                              decoration: status == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.mutedForeground.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueWaitingNode(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(LucideIcons.timer,
            size: 16, color: AppColors.terminalBlue),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Text(
            'Resumed waiting for agent response',
            style: TextStyle(
              color: AppColors.terminalBlue,
              fontSize: 12,
              fontFamily: AppFonts.mono,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingNode(
      AgentActivityEvent act, bool isFirst, bool isLast) {
    final thinking = act.content ?? '';
    final activityId = act.id;
    final isExpanded = _expandedActivities.contains(activityId);

    return _timelineRow(
      marker: Padding(
        padding: const EdgeInsets.only(top: Spacing.xs),
        child: Icon(LucideIcons.brain,
            size: 16, color: AppColors.mutedForeground),
      ),
      lineTop: 22,
      isLast: isLast,
      content: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: GestureDetector(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedActivities.remove(activityId);
            } else {
              _expandedActivities.add(activityId);
            }
          }),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: Spacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Thinking...',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                            fontFamily: AppFonts.mono,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        act.timestampDate.timeAgo(),
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 10,
                          fontFamily: AppFonts.mono,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          LucideIcons.chevron_right,
                          size: 16,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(
                              top: Spacing.xs, bottom: Spacing.xs),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(Spacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.bgDeep,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: SelectableText(
                              thinking,
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
                                fontFamily: AppFonts.mono,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Description text with colored tool name ──

  static const _coloredTools = {'Read', 'Write', 'Edit', 'NotebookEdit', 'Bash', 'Glob', 'Grep'};

  Widget _buildDescriptionText(AgentActivityEvent act, String? tool, Color color) {
    final desc = _activityDescription(act);
    // If the tool has a dedicated color, highlight the tool name prefix.
    if (tool != null && _coloredTools.contains(tool) && desc.startsWith(tool)) {
      final rest = desc.substring(tool.length);
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: tool,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: AppFonts.mono,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (rest.isNotEmpty)
              TextSpan(
                text: rest,
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                  fontFamily: AppFonts.mono,
                ),
              ),
          ],
        ),
      );
    }
    return Text(
      desc,
      style: TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 12,
        fontFamily: AppFonts.mono,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Activity detail views ──

  Widget _buildActivityDetail(
    Map<String, dynamic> data,
    String? tool,
    String eventType,
  ) {
    final specific = switch (tool) {
      'Read' => _buildReadDetail(data),
      'Write' || 'Edit' || 'NotebookEdit' => _buildWriteDetail(data),
      'Bash' => _buildBashDetail(data),
      'Glob' || 'Grep' => _buildSearchDetail(data),
      _ => null,
    };
    if (specific != null) return specific;
    return _buildJsonDetail(data);
  }

  Widget _buildReadDetail(Map<String, dynamic> data) {
    final filePath = data['file_path'] as String?;
    final inputPreview = data['input_preview'] as String?;
    final logs = <LogEntry>[];
    if (filePath != null) logs.add(LogEntry('file  $filePath'));
    if (inputPreview != null && inputPreview.isNotEmpty) {
      logs.add(LogEntry(inputPreview, level: 'debug'));
    }
    if (logs.isEmpty) return _buildJsonDetail(data);
    return _detailTerminal(logs, data);
  }

  Widget _buildWriteDetail(Map<String, dynamic> data) {
    final filePath = data['file_path'] as String?;
    final desc = data['description'] as String?;
    final inputPreview = data['input_preview'] as String?;
    final logs = <LogEntry>[];
    if (filePath != null) logs.add(LogEntry('file  $filePath'));
    if (desc != null && desc.isNotEmpty) logs.add(LogEntry(desc));
    if (inputPreview != null && inputPreview.isNotEmpty) {
      logs.add(LogEntry(inputPreview, level: 'debug'));
    }
    if (logs.isEmpty) return _buildJsonDetail(data);
    return _detailTerminal(logs, data);
  }

  Widget _buildBashDetail(Map<String, dynamic> data) {
    final command =
        data['command'] as String? ?? data['input_preview'] as String?;
    final exitCode = data['exit_code'];
    final logs = <LogEntry>[];
    if (command != null) logs.add(LogEntry('\$ $command'));
    if (exitCode != null) {
      final code = exitCode.toString();
      logs.add(
        LogEntry('exit_code=$code', level: code == '0' ? 'info' : 'error'),
      );
    }
    if (logs.isEmpty) return _buildJsonDetail(data);
    return _detailTerminal(logs, data);
  }

  Widget _buildSearchDetail(Map<String, dynamic> data) {
    final pattern =
        data['pattern'] as String? ?? data['input_preview'] as String?;
    final matchCount = data['match_count'];
    final logs = <LogEntry>[];
    if (pattern != null) logs.add(LogEntry("pattern  '$pattern'"));
    if (matchCount != null) logs.add(LogEntry('matches  $matchCount'));
    if (logs.isEmpty) return _buildJsonDetail(data);
    return _detailTerminal(logs, data);
  }

  Widget _buildJsonDetail(Map<String, dynamic> data) {
    final display = Map<String, dynamic>.from(data)
      ..remove('activity_id')
      ..remove('event_type');
    if (display.isEmpty) return const SizedBox.shrink();
    final logs = <LogEntry>[];
    for (final entry in display.entries) {
      final value = entry.value;
      final valueStr = value is Map || value is List
          ? const JsonEncoder.withIndent('  ').convert(value)
          : value.toString();
      logs.add(LogEntry('${entry.key}=$valueStr'));
    }
    return _detailTerminal(logs, data);
  }

  Widget _detailTerminal(List<LogEntry> logs, Map<String, dynamic> data) {
    return TerminalLogView(
      logs: logs,
      expand: false,
      maxHeight: 200,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      copyText: const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  // ── Working indicator ──

  Widget _buildWorkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _timelineColumnWidth,
            child: Center(
              child: Spinner(
                size: SpinnerSize.sm,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          const Text(
            'Working...',
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontFamily: AppFonts.mono,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input ──

  Widget _buildInput(String? status) {
    final isWaiting = status == AgentState.idle;
    final isTerminal = status?.isTerminal ?? false;
    final isRunning = status == AgentState.generating;
    final isInquiry = status == AgentState.waitingForInquiry;

    final String hint;
    final String? statusText;
    if (isWaiting) {
      hint = 'Send a message to the agent...';
      statusText = null;
    } else if (isInquiry) {
      hint = 'Agent is waiting for inquiry response';
      statusText = 'Waiting for inquiry response';
    } else if (isTerminal) {
      hint = 'Agent has finished';
      statusText = 'Agent has finished';
    } else if (isRunning) {
      hint = 'Agent is working...';
      statusText = 'Agent is working...';
    } else {
      hint = 'Agent is idle';
      statusText = 'Agent is idle';
    }

    return AgentInputField(
      controller: _inputController,
      focusNode: _inputFocusNode,
      onSubmit: _sendInput,
      enabled: isWaiting,
      isSending: _isSending,
      isInterruptMode: isRunning,
      onInterrupt: _interruptAgent,
      placeholder: hint,
      statusText: statusText,
    );
  }

  Future<void> _interruptAgent() async {
    await ref.read(workspaceControllerProvider.notifier).interruptInstance(
          widget.runId,
          widget.instanceId,
        );
  }

  Future<void> _sendInput() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final success =
        await ref.read(workspaceControllerProvider.notifier).sendUserInput(
              widget.runId,
              widget.instanceId,
              text,
            );

    if (success) {
      _inputController.clear();
    }
    if (mounted) {
      setState(() => _isSending = false);
    }
  }
}

// ── Agent header ──

class _AgentHeader extends StatelessWidget {
  const _AgentHeader({
    required this.agentKey,
    required this.displayName,
    required this.status,
  });

  final String agentKey;
  final String displayName;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Text(
            agentKey,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
              fontFamily: AppFonts.mono,
            ),
          ),
          if (displayName.isNotEmpty) ...[
            const SizedBox(width: Spacing.xs),
            Text(
              '#$displayName',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
                fontFamily: AppFonts.mono,
              ),
            ),
          ],
          const SizedBox(width: Spacing.sm),
          if (status != null)
            DspatchBadge(
              label: status!,
              variant: _statusBadgeVariant(status!),
            ),
        ],
      ),
    );
  }

  BadgeVariant _statusBadgeVariant(String s) {
    return switch (s) {
      AgentState.disconnected => BadgeVariant.secondary,
      AgentState.idle => BadgeVariant.secondary,
      AgentState.generating => BadgeVariant.success,
      AgentState.waitingForInquiry => BadgeVariant.warning,
      AgentState.waitingForAgent => BadgeVariant.warning,
      AgentState.completed => BadgeVariant.primary,
      AgentState.failed => BadgeVariant.destructive,
      AgentState.crashed => BadgeVariant.destructive,
      _ => BadgeVariant.secondary,
    };
  }
}


// ── Measure size helper ──

class _MeasureSize extends StatefulWidget {
  const _MeasureSize({required this.onChange, required this.child});

  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size _lastSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return widget.child;
  }

  void _measure() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    if (size != _lastSize) {
      _lastSize = size;
      widget.onChange(size);
    }
  }
}
