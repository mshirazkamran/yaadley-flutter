import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App UI language (PRD D17). Roman Urdu is Urdu written in Latin script, so it is left-to-right
/// and not a real Flutter locale: we keep the Material locale `en` and switch our own strings.
enum AppLanguage { romanUrdu, english }

/// All user-facing strings. Shared strings are getters (add one here and in both implementations
/// below); copy used on a single screen is written inline with [tr].
sealed class AppStrings {
  const AppStrings();

  bool get isEnglish;

  /// Picks the string for the current language: `s.tr('Roman Urdu', 'English')`.
  String tr(String romanUrdu, String english) => isEnglish ? english : romanUrdu;

  String get tabToday;
  String get tabInbox;
  String get tabCalendar;
  String get tabLists;
  String get tabMore;
  String get back;

  String get welcomeKicker;
  String get welcomeTagline;
  String get welcomeTaglineStrong;
  String get welcomeStart;
  String get welcomeHaveAccount;
  String get welcomeSampleQuote;
  String get welcomeSampleWhen;
  String get welcomeSampleTitle;
  String get welcomeSampleSaved;

  String get todayTitle;
  String get todayEmpty;
  String get inboxTitle;
  String get inboxEmpty;
  String get calendarTitle;
  String get calendarEmpty;
  String get listsTitle;
  String get listsEmpty;
  String get moreTitle;

  String get serverStatus;
  String get serverOnline;
  String get serverOffline;
  String get serverChecking;
  String get language;
  String get appVersion;
}

final class _RomanUrdu extends AppStrings {
  const _RomanUrdu();

  @override
  bool get isEnglish => false;

  @override
  String get tabToday => 'Aaj';
  @override
  String get tabInbox => 'Inbox';
  @override
  String get tabCalendar => 'Calendar';
  @override
  String get tabLists => 'Lists';
  @override
  String get tabMore => 'More';
  @override
  String get back => 'Wapas';

  @override
  String get welcomeKicker => 'Roman Urdu · WhatsApp · Calendar';
  @override
  String get welcomeTagline => 'Roman Urdu mein boliye. ';
  @override
  String get welcomeTaglineStrong => 'Yaadly yaad rakhega.';
  @override
  String get welcomeStart => 'Shuru karein';
  @override
  String get welcomeHaveAccount => 'Pehle se account hai?';
  @override
  String get welcomeSampleQuote => '"mainay kal jana hai 2 bajay ali ki taraf"';
  @override
  String get welcomeSampleWhen => 'Kal · 2:00 PM';
  @override
  String get welcomeSampleTitle => 'Visit Ali';
  @override
  String get welcomeSampleSaved => 'Event add ho gaya';

  @override
  String get todayTitle => 'Aaj';
  @override
  String get todayEmpty => 'Aaj kuch plan nahi hai.';
  @override
  String get inboxTitle => 'Inbox';
  @override
  String get inboxEmpty => 'Sab theek hai, kuch pending nahi.';
  @override
  String get calendarTitle => 'Calendar';
  @override
  String get calendarEmpty => 'Is hafte koi event nahi.';
  @override
  String get listsTitle => 'Lists';
  @override
  String get listsEmpty => 'List khali hai.';
  @override
  String get moreTitle => 'More';

  @override
  String get serverStatus => 'Server';
  @override
  String get serverOnline => 'Online';
  @override
  String get serverOffline => 'Offline, dobara try karein';
  @override
  String get serverChecking => 'Check ho raha hai…';
  @override
  String get language => 'Zabaan';
  @override
  String get appVersion => 'Version';
}

final class _English extends AppStrings {
  const _English();

  @override
  bool get isEnglish => true;

  @override
  String get tabToday => 'Today';
  @override
  String get tabInbox => 'Inbox';
  @override
  String get tabCalendar => 'Calendar';
  @override
  String get tabLists => 'Lists';
  @override
  String get tabMore => 'More';
  @override
  String get back => 'Back';

  @override
  String get welcomeKicker => 'Roman Urdu · WhatsApp · Calendar';
  @override
  String get welcomeTagline => 'Say it in Roman Urdu. ';
  @override
  String get welcomeTaglineStrong => 'Yaadly remembers.';
  @override
  String get welcomeStart => 'Get started';
  @override
  String get welcomeHaveAccount => 'Already have an account?';
  @override
  String get welcomeSampleQuote => '"mainay kal jana hai 2 bajay ali ki taraf"';
  @override
  String get welcomeSampleWhen => 'Tomorrow · 2:00 PM';
  @override
  String get welcomeSampleTitle => 'Visit Ali';
  @override
  String get welcomeSampleSaved => 'Event added';

  @override
  String get todayTitle => 'Today';
  @override
  String get todayEmpty => 'Nothing planned today.';
  @override
  String get inboxTitle => 'Inbox';
  @override
  String get inboxEmpty => 'All clear, nothing pending.';
  @override
  String get calendarTitle => 'Calendar';
  @override
  String get calendarEmpty => 'No events this week.';
  @override
  String get listsTitle => 'Lists';
  @override
  String get listsEmpty => 'This list is empty.';
  @override
  String get moreTitle => 'More';

  @override
  String get serverStatus => 'Server';
  @override
  String get serverOnline => 'Online';
  @override
  String get serverOffline => 'Offline, try again';
  @override
  String get serverChecking => 'Checking…';
  @override
  String get language => 'Language';
  @override
  String get appVersion => 'Version';
}

/// Current UI language. Roman Urdu is the default (PRD US-04). It follows the user's server
/// setting once signed in (see `meProvider`), and the Settings toggle saves it back.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.romanUrdu;

  void set(AppLanguage language) => state = language;
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);

final stringsProvider = Provider<AppStrings>((ref) {
  return switch (ref.watch(languageProvider)) {
    AppLanguage.romanUrdu => const _RomanUrdu(),
    AppLanguage.english => const _English(),
  };
});
