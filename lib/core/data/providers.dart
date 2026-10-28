import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import 'yaadly_api.dart';

/// How often the Inbox refreshes while the app is in the foreground (PRD F-5: no push yet).
const inboxPollInterval = Duration(seconds: 15);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The signed-in user. Also applies their language setting to the UI.
final meProvider = FutureProvider<Me>((ref) async {
  final me = await ref.watch(apiProvider).me();
  ref.read(languageProvider.notifier).set(me.settings.language == Language.en ? AppLanguage.english : AppLanguage.romanUrdu);
  return me;
});

final dayProvider = FutureProvider.autoDispose.family<DayData, DateTime>((ref, day) => ref.watch(apiProvider).day(day));

/// Events and due tasks for one month (key: the 1st of the month).
final monthProvider = FutureProvider.autoDispose.family<RangeData, DateTime>((ref, first) {
  final last = DateTime(first.year, first.month + 1, 0);
  return ref.watch(apiProvider).range(first, last);
});

/// Inbox, refreshed every [inboxPollInterval] while the app is visible. The tab badge watches it,
/// so it keeps polling on every tab; it stops while the app is in the background.
class InboxController extends AsyncNotifier<InboxData> {
  @override
  Future<InboxData> build() async {
    final timer = Timer.periodic(inboxPollInterval, (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) refresh();
    });
    ref.onDispose(timer.cancel);
    return ref.read(apiProvider).inbox();
  }

  /// Background refresh: keeps the current data visible and ignores transient errors.
  Future<void> refresh() async {
    try {
      state = AsyncData(await ref.read(apiProvider).inbox());
    } catch (_) {
      if (!state.hasValue) rethrow;
    }
  }

  Future<void> markSeen() async {
    final current = state.value;
    if (current == null || current.unread == current.pending.length) return;
    await ref.read(apiProvider).markInboxSeen();
    await refresh();
  }
}

final inboxProvider = AsyncNotifierProvider<InboxController, InboxData>(InboxController.new);

final listsProvider = FutureProvider.autoDispose<List<ListSummary>>((ref) => ref.watch(apiProvider).lists());

final listDetailProvider = FutureProvider.autoDispose.family<ListDetail, String>((ref, id) => ref.watch(apiProvider).list(id));

/// After any change, refresh everything that may show it.
void refreshData(WidgetRef ref) {
  ref.invalidate(dayProvider);
  ref.invalidate(monthProvider);
  ref.invalidate(listsProvider);
  ref.invalidate(listDetailProvider);
  ref.read(inboxProvider.notifier).refresh();
}
