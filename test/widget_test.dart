import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yaadley/core/auth/session.dart';
import 'package:yaadley/core/data/yaadly_api.dart';
import 'package:yaadley/core/l10n/strings.dart';
import 'package:yaadley/core/models/models.dart';
import 'package:yaadley/core/network/api_client.dart';
import 'package:yaadley/main.dart';

/// Session that starts signed out and never touches secure storage.
class _SignedOut extends SessionController {
  @override
  Future<SessionStatus> build() async => SessionStatus.signedOut;
}

/// API double: pairing returns a fixed code, then reports "pending".
class _FakeApi implements YaadlyApi {
  @override
  Future<PairingStart> startPairing(String? deviceName) async => PairingStart(
        code: '482913',
        pollToken: 'poll-token-0123456789abcdef',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        message: 'Yaadly code: 482 913',
        whatsappUrl: null,
      );

  @override
  Future<(String, AuthTokens?)> pairingStatus(String pollToken) async => ('pending', null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  // Tests must not hit the network for fonts; fall back to the default font.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app() => ProviderScope(
        overrides: [
          serverHealthProvider.overrideWith((ref) async => true),
          sessionProvider.overrideWith(_SignedOut.new),
          apiProvider.overrideWithValue(_FakeApi()),
        ],
        child: const YaadlyApp(),
      );

  testWidgets('signed out: Welcome → Link WhatsApp shows the pairing code', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Shuru karein'), findsOneWidget);
    await tester.tap(find.text('Shuru karein'));
    // Route transition, then the (fake) pairing request resolves. Not pumpAndSettle: the countdown ticks forever.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('WhatsApp link karein'), findsOneWidget);
    expect(find.text('9'), findsOneWidget); // digits of 482913 are drawn one per box
    expect(find.text('Intezar…'), findsOneWidget);

    // Leave the screen so its timers are cancelled before the test ends.
    await tester.tap(find.text('Wapas'));
    await tester.pumpAndSettle();
    expect(find.text('Shuru karein'), findsOneWidget);
  });

  testWidgets('switching language updates the UI', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(YaadlyApp)));
    container.read(languageProvider.notifier).set(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
  });
}
