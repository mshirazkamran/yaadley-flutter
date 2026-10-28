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
import 'inbox_screen.dart';

/// A7 Pending, A8 Clarify, A9 Clash and the edit/cancel confirmations (PRD F-6..F-8). Every
/// answer goes through the same pending-action API as the WhatsApp buttons.
class PendingScreen extends ConsumerStatefulWidget {
  const PendingScreen({super.key, required this.id, this.initial});

  final String id;
  final PendingItem? initial;

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  final _answer = TextEditingController();
  bool _busy = false;
  bool _refreshed = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.inbox);

  /// Runs an action; a follow-up question replaces this screen, a final result goes back.
  Future<void> _run(Future<EventOutcome> Function(YaadlyApi api) call) async {
    setState(() => _busy = true);
    final s = ref.read(stringsProvider);
    try {
      final o = await call(ref.read(apiProvider));
      refreshData(ref);
      if (!mounted) return;
      if (o.needsAttention) {
        context.pushReplacement(Routes.pending(o.pendingId!));
      } else {
        _back();
        handleOutcome(context, ref, o);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, s, e);
    }
  }

  void _act(String id, String action, [String? arg]) => _run((api) => api.pendingAction(id, action, arg));

  void _submitAnswer(String id) {
    final text = _answer.text.trim();
    if (text.isNotEmpty) _run((api) => api.answerPending(id, text));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final inbox = ref.watch(inboxProvider);
    final fromInbox = inbox.value?.pending.where((p) => p.id == widget.id).firstOrNull;
    final item = fromInbox ?? widget.initial;

    // A brand-new question (just created by an action) may not be in the last poll yet.
    if (item == null && inbox.hasValue && !_refreshed) {
      _refreshed = true;
      Future.microtask(() => ref.read(inboxProvider.notifier).refresh());
    }

    return Scaffold(
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (item == null) ...[
                ScreenHeader(title: s.inboxTitle, onBack: _back, backLabel: s.back),
                if (inbox.isLoading || !_refreshed)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: YaadlyColors.ink)))
                else
                  EmptyStateText(s.tr('Ye sawal purana ho gaya ya pehle hi jawab mil chuka hai.', 'This question has expired or was already answered.')),
              ] else ...[
                ScreenHeader(title: pendingSummary(item, s).$2, kicker: _kicker(item, s), onBack: _back, backLabel: s.back),
                Padding(padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page), child: _body(item, s)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _kicker(PendingItem p, AppStrings s) => switch (p.kind) {
        PendingKind.clash => s.tr('⚠️ Overlap', '⚠️ Overlap'),
        PendingKind.clarify || PendingKind.awaitEdit => s.tr('❓ Aap ka jawab', '❓ Needs your input'),
        _ => 'Pending',
      };

  Widget _body(PendingItem p, AppStrings s) {
    final quote = p.sourceText == null || p.sourceText == 'app'
        ? null
        : HardBox(
            shadow: 2,
            color: YaadlyColors.butter,
            radius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
            padding: const EdgeInsets.all(14),
            child: Text('"${p.sourceText}"', style: YaadlyText.body(size: 14).copyWith(fontStyle: FontStyle.italic)),
          );

    final children = <Widget>[
      if (quote != null) ...[quote, const Gap(20)],
      ...switch (p.kind) {
        PendingKind.confirmCreate => _confirmCreate(p, s),
        PendingKind.clarify => _clarify(p, s),
        PendingKind.clash => _clash(p, s),
        PendingKind.awaitEdit => _typedAnswer(p, s, s.tr('Kya badalna hai? (misal: "5 bajay kar do")', 'What should change? (e.g. "make it 5pm")')),
        PendingKind.pickTarget => _pickTarget(p, s),
        PendingKind.confirmChange => _confirmChange(p, s),
      },
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  List<Widget> _confirmCreate(PendingItem p, AppStrings s) {
    final e = p.event!;
    return [
      _EventFields(event: e),
      const Gap(24),
      Row(
        children: [
          Expanded(flex: 14, child: YButton(label: s.tr('Confirm', 'Confirm'), onPressed: () => _act(p.id, 'confirm'))),
          const Gap(10),
          Expanded(flex: 10, child: YButton(label: s.tr('Badlo', 'Edit'), variant: YButtonVariant.paper, onPressed: () => _act(p.id, 'edit'))),
          const Gap(10),
          Expanded(flex: 10, child: YButton(label: s.tr('Cancel', 'Cancel'), variant: YButtonVariant.ink, onPressed: () => _act(p.id, 'cancel'))),
        ],
      ),
    ];
  }

  List<Widget> _clarify(PendingItem p, AppStrings s) {
    final labels = {
      'am': s.tr('Subah (AM)', 'Morning (AM)'),
      'pm': s.tr('Dopahar/Raat (PM)', 'Afternoon (PM)'),
      'today': s.tr('Aaj', 'Today'),
      'tomorrow': s.tr('Kal', 'Tomorrow'),
      'day_after': s.tr('Parson', 'Day after'),
    };
    return [
      Text(clarifyQuestion(p, s), style: YaadlyText.display(size: 34).copyWith(height: 1.05)),
      const Gap(20),
      if (p.options.isEmpty)
        ..._typedAnswer(p, s, p.missing == 'time' ? s.tr('Misal: "4 bajay"', 'e.g. "4pm"') : s.tr('Misal: "Doctor"', 'e.g. "Doctor"'))
      else ...[
        Row(
          children: [
            for (final (i, o) in p.options.indexed) ...[
              if (i > 0) const Gap(12),
              Expanded(
                child: Pressable(
                  onTap: () => _act(p.id, 'opt', o),
                  semanticLabel: labels[o],
                  child: HardBox(
                    color: YaadlyColors.sun,
                    radius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
                    child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: YaadlyText.display(size: 18)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const Gap(16),
        YButton(label: s.tr('Chhor dein', 'Discard'), variant: YButtonVariant.paper, expand: true, onPressed: () => _act(p.id, 'cancel')),
      ],
    ];
  }

  List<Widget> _typedAnswer(PendingItem p, AppStrings s, String hint) => [
        YField(controller: _answer, hint: hint, autofocus: true, maxLength: 500, onSubmitted: (_) => _submitAnswer(p.id)),
        const Gap(14),
        YButton(label: s.tr('Bhejein', 'Send'), expand: true, onPressed: () => _submitAnswer(p.id)),
        const Gap(10),
        YButton(label: s.tr('Chhor dein', 'Discard'), variant: YButtonVariant.paper, expand: true, onPressed: () => _act(p.id, 'cancel')),
      ];

  List<Widget> _clash(PendingItem p, AppStrings s) {
    final e = p.event!;
    String span(DateTime a, DateTime b) => '${Fmt.day(a, s)} · ${Fmt.time(a)} – ${Fmt.time(b)}';
    return [
      HardBox(
        color: YaadlyColors.butter,
        radius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(24)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YChip(s.tr('Naya', 'New'), tone: YChipTone.sun),
            const Gap(8),
            Text(e.title, style: YaadlyText.display(size: 24)),
            Text(span(e.start, e.end), style: YaadlyText.body(size: 14, color: YaadlyColors.clay)),
          ],
        ),
      ),
      for (final c in p.conflicts)
        Padding(
          padding: const EdgeInsets.only(left: 32, top: 8),
          child: HardBox(
            color: YaadlyColors.sand,
            radius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YChip(s.tr('Pehle se', 'Existing'), tone: YChipTone.ink),
                const Gap(8),
                Text(c.title ?? s.tr('Calendar mein busy', 'Busy in your calendar'), style: YaadlyText.display(size: 22)),
                Text(span(c.start, c.end), style: YaadlyText.body(size: 14, color: YaadlyColors.clay)),
              ],
            ),
          ),
        ),
      const Gap(20),
      if (p.slots.isNotEmpty) ...[
        SectionLabel(s.tr('Khali slots', 'Free slots')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, slot) in p.slots.indexed) ChoicePill(label: Fmt.time(slot.start), selected: false, color: YaadlyColors.sun, onTap: () => _act(p.id, 'slot', '$i')),
          ],
        ),
        const Gap(20),
      ],
      YButton(label: s.tr('Dono rakho', 'Keep both'), expand: true, onPressed: () => _act(p.id, 'keep')),
      const Gap(10),
      if (p.slots.isEmpty) ...[
        YButton(label: s.tr('Time badlo', 'Change time'), variant: YButtonVariant.paper, expand: true, onPressed: () => _act(p.id, 'change')),
        const Gap(10),
      ],
      YButton(label: s.tr('Naya cancel karo', 'Cancel new'), variant: YButtonVariant.ink, expand: true, onPressed: () => _act(p.id, 'cancel')),
    ];
  }

  List<Widget> _pickTarget(PendingItem p, AppStrings s) => [
        Text(p.change == 'cancel' ? s.tr('Kaun sa event cancel karun?', 'Which event should I cancel?') : s.tr('Kaun sa event badlun?', 'Which event should I change?'),
            style: YaadlyText.display(size: 24)),
        const Gap(16),
        for (final (i, c) in p.candidates.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Pressable(
              onTap: () => _act(p.id, 'pick', '$i'),
              semanticLabel: c.title,
              child: HardBox(
                color: YaadlyColors.sand,
                radius: BorderRadius.circular(18),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(c.title, style: YaadlyText.display(size: 17))),
                    Text(Fmt.dayTime(c.start, s), style: YaadlyText.body(size: 13, color: YaadlyColors.clay)),
                  ],
                ),
              ),
            ),
          ),
        const Gap(8),
        YButton(label: s.tr('Chhor dein', 'Never mind'), variant: YButtonVariant.paper, expand: true, onPressed: () => _act(p.id, 'cancel')),
      ];

  List<Widget> _confirmChange(PendingItem p, AppStrings s) {
    final e = p.event!;
    final cancel = p.change == 'cancel';
    return [
      _EventFields(event: e),
      if (!cancel && p.newStart != null) ...[
        const Gap(12),
        HardBox(
          color: YaadlyColors.sun,
          radius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(16),
          child: Text('${p.newTitle ?? e.title} → ${Fmt.dayTime(p.newStart!, s)}', style: YaadlyText.display(size: 17)),
        ),
      ],
      const Gap(24),
      YButton(
        label: cancel ? s.tr('Haan, cancel', 'Yes, cancel') : s.tr('Haan, badlo', 'Yes, change'),
        variant: cancel ? YButtonVariant.ink : YButtonVariant.sun,
        expand: true,
        onPressed: () => _act(p.id, 'yes'),
      ),
      const Gap(10),
      YButton(label: s.tr('Nahi', 'No'), variant: YButtonVariant.paper, expand: true, onPressed: () => _act(p.id, 'no')),
    ];
  }
}

class _EventFields extends ConsumerWidget {
  const _EventFields({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final rows = [
      (s.tr('Din', 'Date'), Fmt.day(event.start, s)),
      (s.tr('Waqt', 'Time'), Fmt.time(event.start)),
      (s.tr('Kitni der', 'Duration'), Fmt.duration(event.durationMin, s)),
      if (event.location != null) (s.tr('Jagah', 'Place'), event.location!),
      if (event.meetingLink != null) ('Link', event.meetingLink!),
    ];
    return HardBox(
      color: YaadlyColors.sand,
      radius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26), bottomLeft: Radius.circular(26), bottomRight: Radius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(event.title, style: YaadlyText.display(size: 22))),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  SizedBox(width: 92, child: Text(label.toUpperCase(), style: YaadlyText.labelCaps())),
                  Expanded(child: Text(value, style: YaadlyText.display(size: 15, weight: FontWeight.w600))),
                ],
              ),
            ),
          const Gap(8),
        ],
      ),
    );
  }
}

/// Plain centered message for empty or expired states.
class EmptyStateText extends StatelessWidget {
  const EmptyStateText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(32), child: Text(text, textAlign: TextAlign.center, style: YaadlyText.body(color: YaadlyColors.clay)));
}
