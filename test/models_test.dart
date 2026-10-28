import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadley/core/data/yaadly_api.dart';
import 'package:yaadley/core/format.dart';
import 'package:yaadley/core/l10n/strings.dart';
import 'package:yaadley/core/models/models.dart';

void main() {
  test('wallClock keeps the user-timezone time from the API (drops the offset)', () {
    expect(wallClock('2026-10-29T16:00:00.000+05:00'), DateTime(2026, 10, 29, 16));
  });

  test('parses an event outcome and an inbox clash', () {
    final o = EventOutcome.fromJson({
      'type': 'clash',
      'pendingId': 'p1',
      'event': {'title': 'Call', 'start': '2026-10-29T16:15:00.000+05:00', 'end': '2026-10-29T17:15:00.000+05:00'},
      'conflicts': [
        {'title': null, 'start': '2026-10-29T16:00:00.000+05:00', 'end': '2026-10-29T16:30:00.000+05:00'},
      ],
    });
    expect(o.needsAttention, isTrue);
    expect(o.event!.durationMin, 60);
    expect(o.conflicts.single.title, isNull);

    final saved = EventOutcome.fromJson({'type': 'saved', 'actionId': '', 'event': {'title': 'X', 'start': '2026-10-29T16:00:00.000+05:00', 'end': '2026-10-29T17:00:00.000+05:00'}});
    expect(saved.actionId, isNull, reason: 'a retried create has no undo entry');
  });

  test('idempotency keys are random UUID v4', () {
    final a = newIdempotencyKey();
    expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(a, isNot(newIdempotencyKey()));
  });

  test('due chips: overdue, today, tomorrow', () {
    final s = ProviderContainer().read(stringsProvider);
    final now = DateTime(2026, 10, 28, 15);
    expect(Fmt.due(DateTime(2026, 10, 26), s, now: now), ('2 din late', true));
    expect(Fmt.due(DateTime(2026, 10, 28), s, now: now), ('Aaj', false));
    expect(Fmt.due(DateTime(2026, 10, 29), s, now: now), ('Kal', false));
    expect(isoDay(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
