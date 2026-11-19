import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'models/models.dart';

/// Calendar invite (.ics) for one event, same format as the WhatsApp "Invite file" button.
/// Event times are wall-clock values in the user's [timezone], so they go out with that TZID.
String buildIcs(EventItem e, {required String timezone, DateTime? now}) {
  String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll(RegExp(r'\r?\n'), r'\n');
  String two(int n) => n.toString().padLeft(2, '0');
  String local(DateTime d) => '${d.year}${two(d.month)}${two(d.day)}T${two(d.hour)}${two(d.minute)}00';
  final stamp = (now ?? DateTime.now()).toUtc();
  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Yaadly//Invite//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    'UID:${e.id ?? local(e.start)}@yaadly',
    'DTSTAMP:${local(stamp)}Z',
    'DTSTART;TZID=$timezone:${local(e.start)}',
    'DTEND;TZID=$timezone:${local(e.end)}',
    'SUMMARY:${esc(e.title)}',
    if (e.location != null) 'LOCATION:${esc(e.location!)}',
    if (e.meetingLink != null) ...['URL:${e.meetingLink}', 'DESCRIPTION:${esc('Join: ${e.meetingLink}')}'],
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// Folds lines over 75 octets (RFC 5545 §3.1).
String _fold(String line) {
  if (utf8.encode(line).length <= 75) return line;
  final parts = <String>[];
  var cur = StringBuffer();
  for (final ch in line.runes.map(String.fromCharCode)) {
    if (utf8.encode('$cur$ch').length > (parts.isEmpty ? 75 : 74)) {
      parts.add(cur.toString());
      cur = StringBuffer();
    }
    cur.write(ch);
  }
  parts.add(cur.toString());
  return parts.join('\r\n ');
}

/// "lab AST" → "lab-AST-invite.ics".
String icsFilename(String title) {
  final slug = title.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'event' : (slug.length > 40 ? slug.substring(0, 40) : slug)}-invite.ics';
}

/// Opens the Android share sheet with the event's .ics file.
Future<void> shareInvite(EventItem e, {required String timezone}) {
  final name = icsFilename(e.title);
  final bytes = Uint8List.fromList(utf8.encode(buildIcs(e, timezone: timezone)));
  return SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, name: name, mimeType: 'text/calendar')], fileNameOverrides: [name]));
}
