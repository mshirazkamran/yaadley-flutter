import 'package:flutter_test/flutter_test.dart';
import 'package:yaadley/core/ics.dart';
import 'package:yaadley/core/models/models.dart';

void main() {
  test('builds an escaped .ics in the user timezone', () {
    final e = EventItem(id: 'abc', title: 'Ali, Sara; dinner', start: DateTime(2026, 11, 20, 18), end: DateTime(2026, 11, 20, 19), location: 'Monal');
    final ics = buildIcs(e, timezone: 'Asia/Karachi', now: DateTime.utc(2026, 11, 19));
    expect(ics, contains('DTSTART;TZID=Asia/Karachi:20261120T180000'));
    expect(ics, contains(r'SUMMARY:Ali\, Sara\; dinner'));
    expect(ics, contains('LOCATION:Monal'));
    expect(icsFilename('lab AST'), 'lab-AST-invite.ics');
  });

  test('applies a settings patch for optimistic updates', () {
    const s = Settings(language: Language.romanUr, deliveryMode: DeliveryMode.chat, testingMode: false, autoSave: true, reminderMinutes: 30);
    final next = s.withPatch({'deliveryMode': 'app', 'reminderMinutes': 10});
    expect(next.deliveryMode, DeliveryMode.app);
    expect(next.reminderMinutes, 10);
    expect(next.autoSave, isTrue);
  });
}
