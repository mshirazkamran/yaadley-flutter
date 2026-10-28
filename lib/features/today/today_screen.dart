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
import '../../core/widgets/yaadly_icon.dart';
import '../../core/widgets/yaadly_widgets.dart';
import '../calendar/event_sheet.dart';

/// A4/A5 Today with the Aaj/Kal toggle (PRD F-4): events, due tasks, and a banner when
/// something in the Inbox needs an answer.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _tomorrow = false;
  bool _bannerDismissed = false;

  DateTime get _day => dateOnly(DateTime.now()).add(Duration(days: _tomorrow ? 1 : 0));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final day = _day;
    final data = ref.watch(dayProvider(day));
    final pending = ref.watch(inboxProvider.select((v) => v.value?.pending.length ?? 0));

    return RefreshIndicator(
      color: YaadlyColors.ink,
      onRefresh: () => Future.wait([ref.read(inboxProvider.notifier).refresh(), ref.refresh(dayProvider(day).future)]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(title: _tomorrow ? s.tr('Kal', 'Tomorrow') : Fmt.longDay(day), kicker: _tomorrow ? Fmt.longDay(day) : s.todayTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YSegmented<bool>(
                  options: [(false, s.tr('Aaj', 'Today')), (true, s.tr('Kal', 'Tomorrow'))],
                  value: _tomorrow,
                  onChanged: (v) => setState(() => _tomorrow = v),
                ),
                const Gap(20),
                if (pending > 0 && !_bannerDismissed) ...[
                  _PendingBanner(count: pending, onOpen: () => context.go(Routes.inbox), onDismiss: () => setState(() => _bannerDismissed = true)),
                  const Gap(20),
                ],
              ],
            ),
          ),
          AsyncBody<DayData>(
            value: data,
            onRetry: () => ref.invalidate(dayProvider(day)),
            data: (d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (d.events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Text(_tomorrow ? s.tr('Kal kuch plan nahi hai.', 'Nothing planned tomorrow.') : s.todayEmpty,
                          textAlign: TextAlign.center, style: YaadlyText.body(color: YaadlyColors.clay)),
                    )
                  else
                    for (final (i, e) in d.events.indexed) Padding(padding: const EdgeInsets.only(bottom: 12), child: EventCard(event: e, alternate: i.isOdd)),
                  const Gap(12),
                  if (d.tasks.isNotEmpty) ...[
                    SectionLabel(s.tr('Kaam', 'Tasks')),
                    TaskBox(tasks: d.tasks, showList: true),
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

class _PendingBanner extends ConsumerWidget {
  const _PendingBanner({required this.count, required this.onOpen, required this.onDismiss});

  final int count;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return HardBox(
      color: YaadlyColors.butter,
      radius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const YaadlyIcon(YaadlyIcons.warn, color: YaadlyColors.rust),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.tr('Aap ka jawab chahiye', 'Needs your answer'), style: YaadlyText.display(size: 16)),
                Text(s.tr('$count cheez(ein) Inbox mein pending hain.', '$count item(s) waiting in your Inbox.'), style: YaadlyText.body(size: 14, color: YaadlyColors.clay)),
                const Gap(6),
                GestureDetector(
                  onTap: onOpen,
                  child: Text(s.tr('Dekhein', 'Open'), style: YaadlyText.body(size: 14, weight: FontWeight.w600).copyWith(decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
          GestureDetector(onTap: onDismiss, child: const YaadlyIcon(YaadlyIcons.x, size: 18, color: YaadlyColors.clay)),
        ],
      ),
    );
  }
}

/// Event card from the design: sun time block on the left, sand body. Tap to edit.
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event, this.alternate = false});

  final EventItem event;
  final bool alternate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final meta = [
      if (event.allDay) s.tr('Poora din', 'All day') else Fmt.duration(event.durationMin, s),
      ?event.location,
      if (event.fromGoogle) 'Google',
    ].join(' · ');
    final card = HardBox(
      color: YaadlyColors.sand,
      radius: alternate
          ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22))
          : const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(22)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                decoration: const BoxDecoration(color: YaadlyColors.sun, border: Border(right: BorderSide(color: YaadlyColors.ink, width: 2))),
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: event.allDay
                    ? const YaadlyIcon(YaadlyIcons.cal, size: 24)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Fmt.timeShort(event.start), style: YaadlyText.display(size: 22).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                          Text(event.start.hour < 12 ? 'AM' : 'PM', style: YaadlyText.labelCaps(color: YaadlyColors.ink)),
                        ],
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(event.title, style: YaadlyText.display(size: 17).copyWith(height: 1.15)),
                      const Gap(4),
                      Row(
                        children: [
                          if (event.meetingLink != null) ...[const YaadlyIcon(YaadlyIcons.link, size: 14, color: YaadlyColors.clay), const Gap(4)],
                          Expanded(child: Text(meta, style: YaadlyText.body(size: 13, color: YaadlyColors.clay), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(left: alternate ? 20 : 0, right: alternate ? 0 : 20),
      child: event.id == null ? card : Pressable(onTap: () => showEventSheet(context, event: event), semanticLabel: event.title, child: card),
    );
  }
}

/// Task rows with a checkbox; ticking updates the server and refreshes. Shared by Today and Lists.
class TaskBox extends ConsumerStatefulWidget {
  const TaskBox({super.key, required this.tasks, this.showList = false, this.onLongPress});

  final List<TaskItem> tasks;
  final bool showList;
  final void Function(TaskItem)? onLongPress;

  @override
  ConsumerState<TaskBox> createState() => _TaskBoxState();
}

class _TaskBoxState extends ConsumerState<TaskBox> {
  // Optimistic ticks, so the checkbox reacts at once.
  final _override = <String, bool>{};

  Future<void> _toggle(TaskItem t) async {
    final next = !(_override[t.id] ?? t.done);
    setState(() => _override[t.id] = next);
    try {
      await ref.read(apiProvider).updateItem(t.id, done: next);
      refreshData(ref);
    } catch (e) {
      if (!mounted) return;
      setState(() => _override.remove(t.id));
      showError(context, ref.read(stringsProvider), e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return HardBox(
      radius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(4), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
      child: Column(
        children: [
          for (final (i, t) in widget.tasks.indexed) ...[
            if (i > 0) Divider(height: 2, thickness: 2, color: YaadlyColors.ink.withValues(alpha: 0.1)),
            InkWell(
              onTap: () => _toggle(t),
              onLongPress: widget.onLongPress == null ? null : () => widget.onLongPress!(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    YCheck(done: _override[t.id] ?? t.done),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.text,
                            style: (_override[t.id] ?? t.done)
                                ? YaadlyText.body(color: YaadlyColors.clay).copyWith(decoration: TextDecoration.lineThrough)
                                : YaadlyText.body(weight: FontWeight.w500),
                          ),
                          if (widget.showList && t.listName != null) Text(t.listName!, style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
                        ],
                      ),
                    ),
                    if (t.dueDate != null && !(_override[t.id] ?? t.done)) ...[const Gap(8), _DueChip(date: t.dueDate!, s: s)],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({required this.date, required this.s});

  final DateTime date;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final (label, overdue) = Fmt.due(date, s);
    return YChip(label, tone: overdue ? YChipTone.rust : YChipTone.butter);
  }
}
