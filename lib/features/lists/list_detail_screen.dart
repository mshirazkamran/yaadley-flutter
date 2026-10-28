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
import '../today/today_screen.dart';
import 'lists_screen.dart';

/// One list: open items (tap to tick, long-press to edit/move/delete), an add field, done items,
/// and a menu to rename, make default or delete the list (PRD E-4, E-6).
class ListDetailScreen extends ConsumerStatefulWidget {
  const ListDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _draft = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _draft.text.trim();
    if (text.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      await ref.read(apiProvider).addItem(widget.id, text);
      _draft.clear();
      refreshData(ref);
    } catch (e) {
      if (mounted) showError(context, ref.read(stringsProvider), e);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _menu(ListSummary list) async {
    final s = ref.read(stringsProvider);
    final choice = await showYSheet<String>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(list.name, style: YaadlyText.display(size: 24)),
          const Gap(16),
          YButton(label: s.tr('Naam / maqsad badlo', 'Rename / edit purpose'), variant: YButtonVariant.paper, expand: true, onPressed: () => Navigator.pop(ctx, 'edit')),
          if (!list.isDefault) ...[
            const Gap(10),
            YButton(label: s.tr('Default list banao', 'Make default'), variant: YButtonVariant.paper, expand: true, onPressed: () => Navigator.pop(ctx, 'default')),
          ],
          const Gap(10),
          YButton(label: s.tr('List delete karo', 'Delete list'), variant: YButtonVariant.ink, expand: true, onPressed: () => Navigator.pop(ctx, 'delete')),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    final api = ref.read(apiProvider);
    try {
      switch (choice) {
        case 'edit':
          await showListSheet(context, list: list);
        case 'default':
          await api.updateList(list.id, makeDefault: true);
          refreshData(ref);
          if (mounted) showSnack(context, s.tr('Ab ye default list hai', 'This is now your default list'));
        case 'delete':
          final ok = await confirmDialog(context,
              title: s.tr('"${list.name}" aur us ke saare items delete karun?', 'Delete "${list.name}" and all its items?'), yes: s.tr('Haan, delete', 'Yes, delete'), no: s.tr('Nahi', 'No'));
          if (!ok) return;
          await api.deleteList(list.id);
          refreshData(ref);
          if (mounted) context.go(Routes.lists);
      }
    } catch (e) {
      if (mounted) showError(context, s, e);
    }
  }

  Future<void> _itemMenu(TaskItem item, List<ListSummary> lists) async {
    await showYSheet<void>(context, (_) => _ItemForm(item: item, listId: widget.id, lists: lists));
    if (mounted) refreshData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final detail = ref.watch(listDetailProvider(widget.id));
    final allLists = ref.watch(listsProvider).value ?? const <ListSummary>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: YaadlyColors.ink,
          onRefresh: () => ref.refresh(listDetailProvider(widget.id).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ScreenHeader(
                title: detail.value?.list.name ?? '',
                kicker: detail.value?.list.purpose,
                onBack: () => context.go(Routes.lists),
                backLabel: s.back,
                trailing: detail.value == null
                    ? null
                    : Pressable(
                        onTap: () => _menu(detail.value!.list),
                        semanticLabel: s.tr('List options', 'List options'),
                        child: const HardBox.small(child: SizedBox(width: 40, height: 40, child: Center(child: YaadlyIcon(YaadlyIcons.more)))),
                      ),
              ),
              AsyncBody<ListDetail>(
                value: detail,
                onRetry: () => ref.invalidate(listDetailProvider(widget.id)),
                data: (d) {
                  final open = d.items.where((i) => !i.done).toList();
                  final done = d.items.where((i) => i.done).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: YaadlySpace.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HardBox(
                          color: YaadlyColors.butter,
                          radius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30), bottomLeft: Radius.circular(30), bottomRight: Radius.circular(6)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: YaadlyColors.sun,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                                  border: Border(bottom: BorderSide(color: YaadlyColors.ink, width: 2)),
                                ),
                                child: Row(
                                  children: [
                                    Text(listIcon(d.list.kind), style: const TextStyle(fontSize: 24)),
                                    const Gap(12),
                                    Text(s.tr('${open.length} baqi', '${open.length} open'), style: YaadlyText.display(size: 18)),
                                  ],
                                ),
                              ),
                              if (open.isEmpty)
                                Padding(padding: const EdgeInsets.all(16), child: Text(s.listsEmpty, style: YaadlyText.body(color: YaadlyColors.clay)))
                              else
                                for (final item in open) _ItemRow(item: item, onLongPress: () => _itemMenu(item, allLists)),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(child: YField(controller: _draft, hint: s.tr('Item add karein…', 'Add an item…'), pill: true, maxLength: 200, onSubmitted: (_) => _add())),
                                    const Gap(8),
                                    Pressable(
                                      onTap: _adding ? null : _add,
                                      semanticLabel: s.tr('Add', 'Add'),
                                      child: const HardBox.small(color: YaadlyColors.sun, child: SizedBox(width: 44, height: 44, child: Center(child: YaadlyIcon(YaadlyIcons.plus)))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (done.isNotEmpty) ...[
                          const Gap(24),
                          SectionLabel(s.tr('Ho chuke', 'Done')),
                          TaskBox(tasks: done, onLongPress: (t) => _itemMenu(t, allLists)),
                        ],
                        const Gap(12),
                        Text(s.tr('Tip: item ko dabaye rakhein to badal, move ya delete kar sakte hain.', 'Tip: long-press an item to edit, move or delete it.'),
                            style: YaadlyText.body(size: 12, color: YaadlyColors.clay)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends ConsumerStatefulWidget {
  const _ItemRow({required this.item, required this.onLongPress});

  final TaskItem item;
  final VoidCallback onLongPress;

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  bool? _done;

  Future<void> _toggle() async {
    final next = !(_done ?? widget.item.done);
    setState(() => _done = next);
    try {
      await ref.read(apiProvider).updateItem(widget.item.id, done: next);
      refreshData(ref);
    } catch (e) {
      if (!mounted) return;
      setState(() => _done = null);
      showError(context, ref.read(stringsProvider), e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final done = _done ?? widget.item.done;
    final due = widget.item.dueDate == null ? null : Fmt.due(widget.item.dueDate!, s);
    return InkWell(
      onTap: _toggle,
      onLongPress: widget.onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: YaadlyColors.ink.withValues(alpha: 0.1)))),
        child: Row(
          children: [
            YCheck(done: done),
            const Gap(12),
            Expanded(
              child: Text(widget.item.text,
                  style: done ? YaadlyText.body(color: YaadlyColors.clay).copyWith(decoration: TextDecoration.lineThrough) : YaadlyText.body(weight: FontWeight.w500)),
            ),
            if (due != null && !done) YChip(due.$1, tone: due.$2 ? YChipTone.rust : YChipTone.butter),
          ],
        ),
      ),
    );
  }
}

/// Edit text and due date, move to another list, or delete (with Undo).
class _ItemForm extends ConsumerStatefulWidget {
  const _ItemForm({required this.item, required this.listId, required this.lists});

  final TaskItem item;
  final String listId;
  final List<ListSummary> lists;

  @override
  ConsumerState<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<_ItemForm> {
  late final _text = TextEditingController(text: widget.item.text);
  late DateTime? _due = widget.item.dueDate;
  late String _listId = widget.listId;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    try {
      await ref.read(apiProvider).updateItem(
            widget.item.id,
            text: _text.text.trim().isEmpty ? null : _text.text.trim(),
            dueDate: _due,
            clearDueDate: _due == null && widget.item.dueDate != null,
            listId: _listId == widget.listId ? null : _listId,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, s, e);
    }
  }

  Future<void> _delete() async {
    final s = ref.read(stringsProvider);
    final api = ref.read(apiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final actionId = await api.deleteItem(widget.item.id);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(s.tr('"${widget.item.text}" hata diya', 'Removed "${widget.item.text}"')),
        duration: const Duration(seconds: 6),
        action: actionId == null
            ? null
            : SnackBarAction(
                label: s.tr('Wapas', 'Undo'),
                textColor: YaadlyColors.sun,
                onPressed: () async {
                  await api.undo(actionId);
                  refreshData(ref);
                },
              ),
      ));
    } catch (e) {
      if (mounted) showError(context, s, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.tr('Item badlein', 'Edit item'), style: YaadlyText.display(size: 24)),
        const Gap(16),
        YField(controller: _text, maxLength: 200),
        const Gap(16),
        SectionLabel(s.tr('Akhri tareekh', 'Due date')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoicePill(label: s.tr('Koi nahi', 'None'), selected: _due == null, onTap: () => setState(() => _due = null)),
            ChoicePill(
              label: _due == null ? s.tr('Tareekh chunein', 'Pick a date') : Fmt.due(_due!, s).$1,
              selected: _due != null,
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _due ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (d != null) setState(() => _due = d);
              },
            ),
          ],
        ),
        if (widget.lists.length > 1) ...[
          const Gap(16),
          SectionLabel(s.tr('List', 'List')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final l in widget.lists) ChoicePill(label: '${listIcon(l.kind)} ${l.name}', selected: l.id == _listId, onTap: () => setState(() => _listId = l.id))],
          ),
        ],
        const Gap(24),
        YButton(label: s.tr('Save karo', 'Save'), expand: true, onPressed: _save),
        const Gap(10),
        YButton(label: s.tr('Delete karo', 'Delete'), variant: YButtonVariant.ink, expand: true, onPressed: _delete),
      ],
    );
  }
}
