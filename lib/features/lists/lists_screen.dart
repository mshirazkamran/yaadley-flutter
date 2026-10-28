import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers.dart';
import '../../core/data/yaadly_api.dart';
import '../../core/l10n/strings.dart';
import '../../core/models/models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/yaadly_colors.dart';
import '../../core/theme/yaadly_theme.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/hard_box.dart';
import '../../core/widgets/yaadly_widgets.dart';
import '../calendar/event_sheet.dart';

String listIcon(ListKind k) => switch (k) {
      ListKind.grocery => '🛒',
      ListKind.tasks => '📝',
      ListKind.general => '📋',
    };

/// A11 Lists (PRD F-10, redesigned for many lists): one card per list with its purpose and open
/// count, plus "New list". New items from WhatsApp are routed by purpose.
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lists = ref.watch(listsProvider);

    return RefreshIndicator(
      color: YaadlyColors.ink,
      onRefresh: () => ref.refresh(listsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ScreenHeader(
            title: s.listsTitle,
            kicker: s.tr('Yaadly ne likha', 'Written by Yaadly'),
            trailing: YButton(label: s.tr('+ Nayi list', '+ New list'), onPressed: () => showListSheet(context)),
          ),
          AsyncBody<List<ListSummary>>(
            value: lists,
            onRetry: () => ref.invalidate(listsProvider),
            data: (all) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
              child: all.isEmpty
                  ? HardBox(
                      color: YaadlyColors.butter,
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        s.tr('Abhi koi list nahi. WhatsApp par bolein: "doodh aur anday lena hai", ya yahan nayi list banayein.',
                            'No lists yet. Say on WhatsApp: "buy milk and eggs", or create one here.'),
                        style: YaadlyText.body(),
                      ),
                    )
                  : Column(children: [for (final (i, l) in all.indexed) Padding(padding: const EdgeInsets.only(bottom: 12), child: _ListCard(list: l, alternate: i.isOdd))]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends ConsumerWidget {
  const _ListCard({required this.list, required this.alternate});

  final ListSummary list;
  final bool alternate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Pressable(
      onTap: () => context.go(Routes.list(list.id)),
      semanticLabel: list.name,
      child: HardBox(
        color: list.kind == ListKind.grocery ? YaadlyColors.butter : (alternate ? YaadlyColors.sand : YaadlyColors.paper),
        radius: alternate
            ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))
            : const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(4)),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(listIcon(list.kind), style: const TextStyle(fontSize: 28)),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(list.name, style: YaadlyText.display(size: 19))),
                      if (list.isDefault) ...[const Gap(8), const YChip('default', tone: YChipTone.sun)],
                    ],
                  ),
                  if (list.purpose != null) Text(list.purpose!, style: YaadlyText.body(size: 13, color: YaadlyColors.clay), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Gap(10),
            Text('${list.openCount}', style: YaadlyText.display(size: 26)),
            const Gap(2),
            Text(s.tr(' baqi', ' open'), style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
          ],
        ),
      ),
    );
  }
}

/// Create a list, or edit name/purpose/kind of an existing one.
Future<void> showListSheet(BuildContext context, {ListSummary? list}) => showYSheet<void>(context, (_) => _ListForm(list: list));

class _ListForm extends ConsumerStatefulWidget {
  const _ListForm({this.list});

  final ListSummary? list;

  @override
  ConsumerState<_ListForm> createState() => _ListFormState();
}

class _ListFormState extends ConsumerState<_ListForm> {
  late final _name = TextEditingController(text: widget.list?.name);
  late final _purpose = TextEditingController(text: widget.list?.purpose);
  late ListKind _kind = widget.list?.kind ?? ListKind.general;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final name = _name.text.trim();
    if (name.isEmpty) return showSnack(context, s.tr('Naam likhein', 'Add a name'));
    final purpose = _purpose.text.trim().isEmpty ? null : _purpose.text.trim();
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final l = widget.list;
      l == null ? await api.createList(name: name, purpose: purpose, kind: _kind) : await api.updateList(l.id, name: name, purpose: purpose ?? '', kind: _kind);
      refreshData(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showError(context, s, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.list == null ? s.tr('Nayi list', 'New list') : s.tr('List badlein', 'Edit list'), style: YaadlyText.display(size: 26)),
        const Gap(16),
        YField(controller: _name, hint: s.tr('Naam (misal: Office)', 'Name (e.g. Office)'), autofocus: widget.list == null, maxLength: 40),
        const Gap(12),
        YField(controller: _purpose, hint: s.tr('Kis cheez ke liye? (misal: office ke kaam)', "What's it for? (e.g. office work)"), maxLength: 200),
        const Gap(6),
        Text(s.tr('Yaadly naye items isi maqsad se sahi list mein daalta hai.', 'Yaadly uses the purpose to put new items in the right list.'),
            style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
        const Gap(16),
        SectionLabel(s.tr('Qisam', 'Type')),
        Wrap(
          spacing: 8,
          children: [
            for (final k in ListKind.values)
              ChoicePill(
                label: '${listIcon(k)} ${switch (k) {
                  ListKind.grocery => s.tr('Saman', 'Grocery'),
                  ListKind.tasks => s.tr('Kaam', 'Tasks'),
                  ListKind.general => s.tr('Aam', 'General'),
                }}',
                selected: _kind == k,
                onTap: () => setState(() => _kind = k),
              ),
          ],
        ),
        const Gap(24),
        YButton(label: _busy ? '…' : s.tr('Save karo', 'Save'), expand: true, onPressed: _busy ? null : _save),
      ],
    );
  }
}
