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
import 'event_sheet.dart';

const _slotDurations = [30, 60, 90, 120];

/// "Kab free hoon?" (PRD G-3): up to 3 free slots on [day] across all calendars (9:00–22:00).
/// Tapping a slot opens the new-event form at that time.
Future<void> showFreeSlotsSheet(BuildContext context, DateTime day) async {
  final pick = await showYSheet<(DateTime, int)>(context, (_) => _FreeSlots(day: day));
  if (pick != null && context.mounted) await showEventSheet(context, start: pick.$1, durationMin: pick.$2);
}

class _FreeSlots extends ConsumerStatefulWidget {
  const _FreeSlots({required this.day});

  final DateTime day;

  @override
  ConsumerState<_FreeSlots> createState() => _FreeSlotsState();
}

class _FreeSlotsState extends ConsumerState<_FreeSlots> {
  int _duration = 60;
  late Future<List<EventItem>> _slots = _load();

  Future<List<EventItem>> _load() => ref.read(apiProvider).freeSlots(widget.day, _duration);

  void _setDuration(int m) => setState(() {
        _duration = m;
        _slots = _load();
      });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr('Kab free hoon?', 'When am I free?'), style: YaadlyText.display(size: 26)),
        const Gap(4),
        Text(
          s.tr('${Fmt.day(widget.day, s)} · aap ke saare calendars', '${Fmt.day(widget.day, s)} · across all your calendars'),
          style: YaadlyText.body(size: 13, color: YaadlyColors.clay),
        ),
        const Gap(16),
        SectionLabel(s.tr('Kitna waqt chahiye', 'How long')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final m in _slotDurations) ChoicePill(label: Fmt.duration(m, s), selected: m == _duration, onTap: () => _setDuration(m))],
        ),
        const Gap(20),
        SectionLabel(s.tr('Khali waqt', 'Free slots')),
        FutureBuilder<List<EventItem>>(
          future: _slots,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: YaadlyColors.ink)));
            }
            if (snap.hasError) {
              return Text(s.tr('Slots load nahi hue. Dobara try karein.', "Couldn't load slots. Try again."), style: YaadlyText.body(color: YaadlyColors.rust));
            }
            final slots = snap.data ?? const [];
            if (slots.isEmpty) {
              return Text(s.tr('Is din (9 se 10 baje tak) koi khali waqt nahi.', 'No free time this day (9 AM–10 PM).'), style: YaadlyText.body(color: YaadlyColors.clay));
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in slots)
                  ChoicePill(
                    label: '${Fmt.time(slot.start)} – ${Fmt.time(slot.end)}',
                    selected: false,
                    color: YaadlyColors.butter,
                    onTap: () => Navigator.pop(context, (slot.start, _duration)),
                  ),
              ],
            );
          },
        ),
        const Gap(8),
        Text(s.tr('Slot par tap karein to event ban jayega.', 'Tap a slot to create an event.'), style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
      ],
    );
  }
}
