import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/data/providers.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/models.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_icon.dart';
import '../../core/widgets/yaadly_widgets.dart';
import '../today/today_screen.dart';
import 'event_sheet.dart';

/// A10 Calendar (PRD F-9): month grid with dots, the selected day's events and tasks, and "+"
/// to add an event manually.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = dateOnly(DateTime.now());

  void _shiftMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
        final today = dateOnly(DateTime.now());
        _selected = today.year == _month.year && today.month == _month.month ? today : _month;
      });

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final data = ref.watch(monthProvider(_month));

    return Stack(
      children: [
        RefreshIndicator(
          color: YaadlyColors.ink,
          onRefresh: () => ref.refresh(monthProvider(_month).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              ScreenHeader(
                title: Fmt.month(_month),
                kicker: '${_month.year}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundButton(icon: YaadlyIcons.back, label: s.tr('Pichla mahina', 'Previous month'), onTap: () => _shiftMonth(-1)),
                    const Gap(8),
                    _RoundButton(icon: YaadlyIcons.chev, label: s.tr('Agla mahina', 'Next month'), onTap: () => _shiftMonth(1)),
                  ],
                ),
              ),
              AsyncBody<RangeData>(
                value: data,
                onRetry: () => ref.invalidate(monthProvider(_month)),
                data: (d) {
                  final events = d.events.where((e) => _sameDay(e.start, _selected)).toList();
                  final tasks = d.tasks.where((t) => t.dueDate != null && _sameDay(t.dueDate!, _selected)).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MonthGrid(
                          month: _month,
                          selected: _selected,
                          busy: {for (final e in d.events) dateOnly(e.start), for (final t in d.tasks) ?t.dueDate},
                          onSelect: (day) => setState(() => _selected = day),
                        ),
                        const Gap(20),
                        SectionLabel(Fmt.day(_selected, s)),
                        if (events.isEmpty && tasks.isEmpty)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s.tr('Is din kuch plan nahi.', 'Nothing planned this day.'), style: YaadlyText.body(color: YaadlyColors.clay))),
                        for (final (i, e) in events.indexed) Padding(padding: const EdgeInsets.only(bottom: 12), child: EventCard(event: e, alternate: i.isOdd)),
                        if (tasks.isNotEmpty) ...[const Gap(4), TaskBox(tasks: tasks, showList: true)],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: YaadlySpace.page,
          bottom: 20,
          child: Pressable(
            onTap: () => showEventSheet(context, day: _selected),
            semanticLabel: s.tr('Event add karein', 'Add event'),
            child: const HardBox(
              color: YaadlyColors.sun,
              radius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4)),
              child: SizedBox(width: 56, height: 56, child: Center(child: YaadlyIcon(YaadlyIcons.plus, size: 26))),
            ),
          ),
        ),
      ],
    );
  }
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.selected, required this.busy, required this.onSelect});

  final DateTime month;
  final DateTime selected;
  final Set<DateTime> busy;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(month.year, month.month).weekday - 1; // Monday-first grid
    final days = DateTime(month.year, month.month + 1, 0).day;
    final today = dateOnly(DateTime.now());
    final cells = [...List<int?>.filled(offset, null), for (var d = 1; d <= days; d++) d];

    return HardBox(
      radius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(26)),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(children: [for (final l in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(l, style: YaadlyText.labelCaps())))]),
          const Gap(6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            children: [
              for (final d in cells)
                if (d == null)
                  const SizedBox.shrink()
                else
                  _DayCell(
                    day: DateTime(month.year, month.month, d),
                    selected: _sameDay(selected, DateTime(month.year, month.month, d)),
                    today: _sameDay(today, DateTime(month.year, month.month, d)),
                    busy: busy.contains(DateTime(month.year, month.month, d)),
                    onTap: onSelect,
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.today, required this.busy, required this.onTap});

  final DateTime day;
  final bool selected;
  final bool today;
  final bool busy;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? YaadlyColors.butter : YaadlyColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: '${day.day}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => onTap(day),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? YaadlyColors.ink : (today ? YaadlyColors.sun : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: today && !selected ? Border.all(color: YaadlyColors.ink, width: 2) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('${day.day}', style: YaadlyText.display(size: 14, weight: FontWeight.w600, color: fg)),
              if (busy)
                Positioned(
                  bottom: 5,
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(color: selected ? YaadlyColors.sun : YaadlyColors.ink, shape: BoxShape.circle)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final YaadlyIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: HardBox.small(child: SizedBox(width: 40, height: 40, child: Center(child: YaadlyIcon(icon, size: 20)))),
    );
  }
}
