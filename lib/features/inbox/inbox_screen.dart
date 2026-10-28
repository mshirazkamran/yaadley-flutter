import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/data/yaadly_api.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_widgets.dart';
import '../calendar/event_sheet.dart';

/// A6 Inbox (PRD F-5): "Needs action" (open questions from WhatsApp or the app) and "Updates"
/// (everything Yaadly saved, changed or undid). Polls while open; opening it marks updates seen.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(inboxProvider.notifier).markSeen());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final inbox = ref.watch(inboxProvider);
    // New updates arriving while the screen is open count as seen.
    ref.listen(inboxProvider, (_, next) {
      if (next.hasValue) ref.read(inboxProvider.notifier).markSeen();
    });

    return RefreshIndicator(
      color: YaadlyColors.ink,
      onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(title: s.inboxTitle, kicker: s.tr('${inbox.value?.pending.length ?? 0} pending', '${inbox.value?.pending.length ?? 0} need action')),
          AsyncBody<InboxData>(
            value: inbox,
            onRetry: () => ref.invalidate(inboxProvider),
            data: (d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(s.tr('Jawab chahiye', 'Needs action')),
                  if (d.pending.isEmpty)
                    HardBox(
                      shadow: 2,
                      color: YaadlyColors.butter,
                      radius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(20),
                      child: Text(s.inboxEmpty, textAlign: TextAlign.center, style: YaadlyText.body(color: YaadlyColors.clay)),
                    )
                  else
                    for (final (i, p) in d.pending.indexed) Padding(padding: const EdgeInsets.only(bottom: 12), child: _PendingCard(item: p, alternate: i.isOdd)),
                  const Gap(24),
                  if (d.updates.isNotEmpty) ...[
                    SectionLabel(s.tr('Updates', 'Updates')),
                    HardBox(
                      radius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(4), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
                      child: Column(
                        children: [
                          for (final (i, u) in d.updates.indexed) ...[
                            if (i > 0) Divider(height: 2, thickness: 2, color: YaadlyColors.ink.withValues(alpha: 0.1)),
                            _UpdateRow(update: u, unread: d.seenAt == null || u.at.isAfter(d.seenAt!.toLocal())),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emoji + headline + one line of detail for an open question.
(String, String, String) pendingSummary(PendingItem p, AppStrings s) {
  final when = p.event == null ? '' : Fmt.dayTime(p.event!.start, s);
  return switch (p.kind) {
    PendingKind.confirmCreate => ('✅', s.tr('Event ready', 'Event ready'), '${p.title}, $when'),
    PendingKind.clarify => ('❓', s.tr('Batayein', 'Quick question'), clarifyQuestion(p, s)),
    PendingKind.clash => ('⚠️', s.tr('Clash mila', 'Schedule clash'), '${p.title}, $when'),
    PendingKind.awaitEdit => ('✏️', s.tr('Kya badalna hai?', 'What should change?'), p.title),
    PendingKind.pickTarget => ('🔎', s.tr('Kaun sa event?', 'Which event?'), p.candidates.map((c) => c.title).take(3).join(', ')),
    PendingKind.confirmChange => (
        p.change == 'cancel' ? '🗑️' : '✏️',
        p.change == 'cancel' ? s.tr('Cancel karun?', 'Cancel this?') : s.tr('Badal dun?', 'Make this change?'),
        p.newStart == null ? p.title : '${p.title} → ${Fmt.dayTime(p.newStart!, s)}',
      ),
  };
}

String clarifyQuestion(PendingItem p, AppStrings s) => switch (p.missing) {
      'meridiem' => s.tr('${p.hour ?? 12} bajay subah ya dopahar/raat?', "${p.hour ?? 12} o'clock: AM or PM?"),
      'date' => s.tr('Kis din?', 'Which day?'),
      'kal_after_midnight' => s.tr('"Kal" se murad kaun sa din?', 'Which day did you mean by "kal"?'),
      'time' => s.tr('Kis waqt?', 'What time?'),
      'title' => s.tr('Kis cheez ka event hai?', 'What is the event?'),
      _ => s.tr('Thori aur detail batayein.', 'Please add a bit more detail.'),
    };

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.item, required this.alternate});

  final PendingItem item;
  final bool alternate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final (emoji, title, text) = pendingSummary(item, s);
    Future<void> act(String action) async {
      try {
        final o = await ref.read(apiProvider).pendingAction(item.id, action);
        refreshData(ref);
        if (context.mounted) handleOutcome(context, ref, o);
      } catch (e) {
        if (context.mounted) showError(context, s, e);
      }
    }

    return Padding(
      padding: EdgeInsets.only(left: alternate ? 16 : 0, right: alternate ? 0 : 16),
      child: HardBox(
        color: YaadlyColors.butter,
        radius: alternate
            ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22))
            : const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(22)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.push(Routes.pending(item.id), extra: item),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(title, style: YaadlyText.display(size: 16))),
                            Text(Fmt.ago(item.createdAt, s), style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
                          ],
                        ),
                        Text(text, style: YaadlyText.body(size: 14, color: YaadlyColors.clay)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (item.kind == PendingKind.confirmCreate)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoicePill(label: s.tr('Confirm', 'Confirm'), selected: false, color: YaadlyColors.sun, onTap: () => act('confirm')),
                    ChoicePill(label: s.tr('Badlo', 'Edit'), selected: false, onTap: () => context.push(Routes.pending(item.id), extra: item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpdateRow extends ConsumerWidget {
  const _UpdateRow({required this.update, required this.unread});

  final UpdateItem update;
  final bool unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final u = update;
    final (emoji, title) = switch (u.kind) {
      'event_created' => ('📅', s.tr('Event add hua', 'Event added')),
      'event_updated' => ('✏️', s.tr('Event badla', 'Event changed')),
      'event_cancelled' => ('🗑️', s.tr('Event cancel hua', 'Event cancelled')),
      'list_created' => ('📋', s.tr('Nayi list', 'New list')),
      'list_items_added' => ('🛒', s.tr('${u.summary.length} item add hue', '${u.summary.length} item(s) added')),
      'list_items_done' => ('☑️', s.tr('Ho gaya', 'Done')),
      'list_items_removed' => ('🗑️', s.tr('List se hataya', 'Removed from list')),
      _ => ('•', u.kind),
    };
    final detail = [u.summary.take(4).join(', '), if (u.eventStart != null) Fmt.dayTime(u.eventStart!, s)].where((x) => x.isNotEmpty).join(' · ');

    return Opacity(
      opacity: u.undone ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(u.undone ? '$title ↩️' : title, style: YaadlyText.display(size: 15, weight: FontWeight.w600))),
                      if (unread) ...[const Gap(6), Container(width: 8, height: 8, decoration: const BoxDecoration(color: YaadlyColors.rust, shape: BoxShape.circle))],
                    ],
                  ),
                  if (detail.isNotEmpty) Text(detail, style: YaadlyText.body(size: 13, color: YaadlyColors.clay), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Gap(8),
            if (u.undoable)
              ChoicePill(
                label: s.tr('Wapas', 'Undo'),
                selected: false,
                onTap: () async {
                  try {
                    final done = await ref.read(apiProvider).undo(u.actionId);
                    refreshData(ref);
                    if (context.mounted) showSnack(context, done ? s.tr('Wapas kar diya ↩️', 'Undone ↩️') : s.tr('Ab wapas nahi ho sakta', "Can't undo anymore"));
                  } catch (e) {
                    if (context.mounted) showError(context, s, e);
                  }
                },
              )
            else
              Text(Fmt.ago(u.at, s), style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
          ],
        ),
      ),
    );
  }
}
