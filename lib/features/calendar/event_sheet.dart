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

const _durations = [15, 30, 45, 60, 90, 120];

/// Add (event == null) or edit a Yaadly event. Google-only events are read-only and never get here.
Future<void> showEventSheet(BuildContext context, {EventItem? event, DateTime? day}) {
  return showYSheet<void>(context, (_) => _EventForm(event: event, day: day ?? DateTime.now()));
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({required this.event, required this.day});

  final EventItem? event;
  final DateTime day;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  late final _title = TextEditingController(text: widget.event?.title);
  late final _location = TextEditingController(text: widget.event?.location);
  late DateTime _date = dateOnly(widget.event?.start ?? widget.day);
  late TimeOfDay _time = widget.event == null ? _nextHalfHour() : TimeOfDay.fromDateTime(widget.event!.start);
  late int _duration = widget.event?.durationMin ?? 60;
  // One key per form: tapping Save twice (or a retry) creates the event once.
  final _idempotencyKey = newIdempotencyKey();
  bool _busy = false;

  static TimeOfDay _nextHalfHour() {
    final n = DateTime.now().add(const Duration(minutes: 30));
    return TimeOfDay(hour: n.hour, minute: n.minute < 30 ? 30 : 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final title = _title.text.trim();
    if (title.isEmpty) return showSnack(context, s.tr('Title likhein', 'Add a title'));
    setState(() => _busy = true);
    final api = ref.read(apiProvider);
    final location = _location.text.trim().isEmpty ? null : _location.text.trim();
    try {
      final e = widget.event;
      final outcome = e == null
          ? await api.createEvent(title: title, start: _start, durationMin: _duration, location: location, idempotencyKey: _idempotencyKey)
          : await api.updateEvent(e.id!, title: title, start: _start, durationMin: _duration, location: location, clearLocation: location == null && e.location != null);
      if (!mounted) return;
      refreshData(ref);
      Navigator.pop(context);
      handleOutcome(context, ref, outcome);
    } catch (err) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, s, err);
      }
    }
  }

  Future<void> _delete() async {
    final s = ref.read(stringsProvider);
    final ok = await confirmDialog(context, title: s.tr('Ye event cancel karun?', 'Cancel this event?'), yes: s.tr('Haan, cancel', 'Yes, cancel'), no: s.tr('Nahi', 'No'));
    if (!ok || !mounted) return;
    try {
      final outcome = await ref.read(apiProvider).cancelEvent(widget.event!.id!);
      if (!mounted) return;
      refreshData(ref);
      Navigator.pop(context);
      handleOutcome(context, ref, outcome);
    } catch (err) {
      if (mounted) showError(context, s, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final editing = widget.event != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(editing ? s.tr('Event badlein', 'Edit event') : s.tr('Naya event', 'New event'), style: YaadlyText.display(size: 26)),
        const Gap(16),
        YField(controller: _title, hint: s.tr('Kya hai? (misal: Dentist)', "What's it? (e.g. Dentist)"), autofocus: !editing, maxLength: 200),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                label: Fmt.day(_date, s),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)));
                  if (d != null) setState(() => _date = d);
                },
              ),
            ),
            const Gap(10),
            Expanded(
              child: _PickerButton(
                label: Fmt.time(_start),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _time);
                  if (t != null) setState(() => _time = t);
                },
              ),
            ),
          ],
        ),
        const Gap(16),
        SectionLabel(s.tr('Kitni der', 'Duration')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in {..._durations, _duration}.toList()..sort())
              ChoicePill(label: Fmt.duration(m, s), selected: m == _duration, onTap: () => setState(() => _duration = m)),
          ],
        ),
        const Gap(16),
        YField(controller: _location, hint: s.tr('Jagah (optional)', 'Place (optional)'), maxLength: 200),
        const Gap(24),
        YButton(label: _busy ? '…' : s.tr('Save karo', 'Save'), expand: true, onPressed: _busy ? null : _save),
        if (editing) ...[
          const Gap(10),
          YButton(label: s.tr('Event cancel karo', 'Cancel event'), variant: YButtonVariant.ink, expand: true, onPressed: _busy ? null : _delete),
        ],
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: HardBox.small(
        radius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Text(label, style: YaadlyText.display(size: 16, weight: FontWeight.w600)),
      ),
    );
  }
}

/// Small selectable pill (durations, days, slots).
class ChoicePill extends StatelessWidget {
  const ChoicePill({super.key, required this.label, required this.selected, required this.onTap, this.color = YaadlyColors.paper});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: HardBox.small(
        color: selected ? YaadlyColors.ink : color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label, style: YaadlyText.display(size: 14, weight: FontWeight.w600, color: selected ? YaadlyColors.butter : YaadlyColors.ink)),
      ),
    );
  }
}

/// Shows the result of an event action: a snack (with Undo) when it's done, or opens the
/// follow-up question (clash, clarify…) when the backend needs an answer.
void handleOutcome(BuildContext context, WidgetRef ref, EventOutcome o) {
  final s = ref.read(stringsProvider);
  if (o.needsAttention) {
    context.push(Routes.pending(o.pendingId!));
    return;
  }
  final text = switch (o.type) {
    'saved' => s.tr('Calendar mein add ho gaya ✅', 'Added to your calendar ✅'),
    'updated' => s.tr('Badal diya ✅', 'Updated ✅'),
    'cancelled' => s.tr('Cancel kar diya', 'Cancelled'),
    'discarded' => s.tr('Theek hai, chhor diya', 'OK, discarded'),
    'expired' => s.tr('Ye sawal purana ho gaya.', 'This question expired.'),
    'not_found' => s.tr('Event nahi mila.', 'Event not found.'),
    _ => s.tr('Ho gaya', 'Done'),
  };
  final syncNote = switch (o.sync) {
    'disconnected' => s.tr(' · Google ka link toot gaya', ' · Google disconnected'),
    'sync_failed' => s.tr(' · Google update nahi hua', " · Google wasn't updated"),
    _ => '',
  };
  final actionId = o.actionId;
  showSnack(
    context,
    '$text$syncNote',
    actionLabel: actionId == null ? null : s.tr('Wapas', 'Undo'),
    onAction: actionId == null
        ? null
        : () async {
            await ref.read(apiProvider).undo(actionId);
            refreshData(ref);
          },
  );
}
