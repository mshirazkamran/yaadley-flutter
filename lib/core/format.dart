import 'package:intl/intl.dart';

import 'data/providers.dart';
import 'l10n/strings.dart';

/// Display formats shared by all screens. Dates are wall-clock values in the user's timezone.
abstract final class Fmt {
  static final _time = DateFormat('h:mm a');
  static final _timeShort = DateFormat('h:mm');
  static final _day = DateFormat('EEE, d MMM');
  static final _longDay = DateFormat('EEEE, d MMM');
  static final _month = DateFormat('MMMM');

  static String time(DateTime d) => _time.format(d);

  /// "4:00" (no AM/PM) for the big time block on event cards.
  static String timeShort(DateTime d) => _timeShort.format(d);

  static String longDay(DateTime d) => _longDay.format(d);

  static String month(DateTime d) => _month.format(d);

  /// Aaj / Kal / Parson, otherwise "Fri, 30 Oct".
  static String day(DateTime d, AppStrings s, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final diff = dateOnly(d).difference(today).inDays;
    return switch (diff) {
      0 => s.tr('Aaj', 'Today'),
      1 => s.tr('Kal', 'Tomorrow'),
      2 => s.tr('Parson', 'Day after'),
      -1 => s.tr('Kal (guzra)', 'Yesterday'),
      _ => _day.format(d),
    };
  }

  static String dayTime(DateTime d, AppStrings s) => '${day(d, s)} · ${time(d)}';

  static String duration(int minutes, AppStrings s) {
    if (minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return s.tr('$h ghanta', '$h hour${h == 1 ? '' : 's'}');
    }
    if (minutes > 60) return '${minutes ~/ 60}h ${minutes % 60}m';
    return '$minutes min';
  }

  /// "2m", "3h", "Kal", "Mon": compact age for Inbox rows.
  static String ago(DateTime at, AppStrings s, {DateTime? now}) {
    final d = (now ?? DateTime.now()).difference(at);
    if (d.inMinutes < 1) return s.tr('abhi', 'now');
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return day(at, s, now: now);
  }

  /// Due-date chip text and whether it is overdue (PRD E-5).
  static (String, bool) due(DateTime date, AppStrings s, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final diff = dateOnly(date).difference(today).inDays;
    if (diff < 0) return (s.tr('${-diff} din late', '${-diff}d overdue'), true);
    if (diff == 0) return (s.tr('Aaj', 'Today'), false);
    if (diff == 1) return (s.tr('Kal', 'Tomorrow'), false);
    return (_day.format(date), false);
  }
}
