import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/data/yaadly_api.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/models.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import 'event_sheet.dart';

/// "Kab free hoon?" (PRD G-3): every free window on [day] across all calendars (9:00–22:00), plus
/// "is waqt free hoon?" for a picked time. Tapping a window opens the new-event form there.
Future<void> showFreeSlotsSheet(BuildContext context, DateTime day) async {
  final pick = await showYSheet<(DateTime, int)>(context, (_) => _FreeTimeSheet(day: day));
  if (pick != null && context.mounted) await showEventSheet(context, start: pick.$1, durationMin: pick.$2);
}

class _FreeTimeSheet extends ConsumerStatefulWidget {
  const _FreeTimeSheet({required this.day});

  final DateTime day;

  @override
  ConsumerState<_FreeTimeSheet> createState() => _FreeTimeSheetState();
}

class _FreeTimeSheetState extends ConsumerState<_FreeTimeSheet> {
  DateTime? _checkAt;
  late Future<FreeTime> _data = _load();

  Future<FreeTime> _load() => ref.read(apiProvider).freeTime(widget.day, time: _checkAt);

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_checkAt ?? DateTime.now()));
    if (t == null) return;
    setState(() {
      _checkAt = DateTime(widget.day.year, widget.day.month, widget.day.day, t.hour, t.minute);
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr('Kab free hoon?', 'When am I free?'), style: YaadlyText.display(size: 26)),
        const Gap(4),
        Text(s.tr('${Fmt.day(widget.day, s)} · aap ke saare calendars', '${Fmt.day(widget.day, s)} · across all your calendars'), style: YaadlyText.body(size: 13, color: YaadlyColors.clay)),
        const Gap(16),
        Align(
          alignment: Alignment.centerLeft,
          child: ChoicePill(
            label: _checkAt == null ? s.tr('🕒 Kisi waqt check karein', '🕒 Check a time') : s.tr('🕒 ${Fmt.time(_checkAt!)} badlein', '🕒 Change ${Fmt.time(_checkAt!)}'),
            selected: false,
            color: YaadlyColors.butter,
            onTap: _pickTime,
          ),
        ),
        const Gap(16),
        FutureBuilder<FreeTime>(
          future: _data,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: YaadlyColors.ink)));
            }
            if (snap.hasError) {
              return Text(s.tr('Load nahi hua. Dobara try karein.', "Couldn't load. Try again."), style: YaadlyText.body(color: YaadlyColors.rust));
            }
            final d = snap.requireData;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (d.check != null) ...[_CheckResult(check: d.check!), const Gap(20)],
                SectionLabel(s.tr('Khali waqt', 'Free time')),
                if (d.windows.isEmpty)
                  Text(s.tr('Is din (9 se 10 baje tak) koi khali waqt nahi.', 'No free time this day (9 AM–10 PM).'), style: YaadlyText.body(color: YaadlyColors.clay))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in d.windows)
                        ChoicePill(
                          label: '${Fmt.time(w.start)} – ${Fmt.time(w.end)}',
                          selected: false,
                          onTap: () => Navigator.pop(context, (w.start, w.durationMin.clamp(15, 60))),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
        const Gap(8),
        Text(s.tr('Waqt par tap karein to event ban jayega.', 'Tap a time to create an event.'), style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
      ],
    );
  }
}

class _CheckResult extends ConsumerWidget {
  const _CheckResult({required this.check});

  final FreeCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final at = Fmt.time(check.start);
    return HardBox(
      color: check.free ? YaadlyColors.butter : YaadlyColors.paper,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(check.free ? s.tr('✅ Haan, $at par free hain', '✅ Yes, free at $at') : s.tr('❌ $at par busy hain', '❌ Busy at $at'), style: YaadlyText.display(size: 17)),
          for (final c in check.conflicts)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${c.title ?? s.tr('Calendar mein busy', 'Busy in your calendar')} (${Fmt.time(c.start)}–${Fmt.time(c.end)})', style: YaadlyText.body(size: 13, color: YaadlyColors.clay)),
            ),
        ],
      ),
    );
  }
}
