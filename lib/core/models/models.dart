/// Data shapes returned by the Yaadly API (`/v1`). Parsed by hand: the API is small and this
/// keeps the build free of code generation. Dates arrive as ISO strings with the user's offset
/// and are kept as local wall-clock values for display.
library;

typedef Json = Map<String, dynamic>;

DateTime _dt(Object? v) => DateTime.parse(v as String);
DateTime? _dtOrNull(Object? v) => v == null ? null : DateTime.parse(v as String);
List<T> _list<T>(Object? v, T Function(Json) f) => [for (final e in (v as List? ?? const [])) f(e as Json)];

/// Wall-clock time of an ISO string with offset, e.g. `2026-10-29T16:00:00.000+05:00` → 16:00.
/// The API already speaks in the user's timezone, so we drop the offset instead of converting.
DateTime wallClock(String iso) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})').firstMatch(iso);
  if (m == null) return DateTime.parse(iso);
  int g(int i) => int.parse(m.group(i)!);
  return DateTime(g(1), g(2), g(3), g(4), g(5));
}

DateTime _wall(Object? v) => wallClock(v as String);

// ------------------------------------------------------------------ profile

enum Language { romanUr, en }

enum DeliveryMode { chat, app }

class Settings {
  const Settings({required this.language, required this.deliveryMode, required this.testingMode, required this.autoSave, required this.reminderMinutes});

  factory Settings.fromJson(Json j) => Settings(
        language: j['language'] == 'en' ? Language.en : Language.romanUr,
        deliveryMode: j['deliveryMode'] == 'app' ? DeliveryMode.app : DeliveryMode.chat,
        testingMode: j['testingMode'] as bool,
        autoSave: j['autoSave'] as bool,
        reminderMinutes: j['reminderMinutes'] as int,
      );

  final Language language;
  final DeliveryMode deliveryMode;
  final bool testingMode;
  final bool autoSave;
  final int reminderMinutes;
}

class GoogleStatus {
  const GoogleStatus({required this.available, required this.connected, required this.email, required this.revoked});

  factory GoogleStatus.fromJson(Json j) =>
      GoogleStatus(available: j['available'] as bool, connected: j['connected'] as bool, email: j['email'] as String?, revoked: j['revoked'] as bool);

  final bool available;
  final bool connected;
  final String? email;
  final bool revoked;
}

class Me {
  const Me({required this.id, required this.waNumber, required this.displayName, required this.timezone, required this.settings, required this.google, required this.botNumber});

  factory Me.fromJson(Json j) => Me(
        id: j['id'] as String,
        waNumber: j['waNumber'] as String,
        displayName: j['displayName'] as String?,
        timezone: j['timezone'] as String,
        settings: Settings.fromJson(j['settings'] as Json),
        google: GoogleStatus.fromJson(j['google'] as Json),
        botNumber: j['botNumber'] as String?,
      );

  final String id;
  final String waNumber;
  final String? displayName;
  final String timezone;
  final Settings settings;
  final GoogleStatus google;
  final String? botNumber;

  /// "+92 300 ••• 4471"
  String get maskedNumber {
    final n = waNumber;
    if (n.length < 7) return '+$n';
    return '+${n.substring(0, 2)} ${n.substring(2, 5)} ••• ${n.substring(n.length - 4)}';
  }
}

// ------------------------------------------------------------------ events

class EventItem {
  const EventItem({this.id, required this.title, required this.start, required this.end, this.location, this.meetingLink, this.fromGoogle = false, this.allDay = false});

  factory EventItem.fromJson(Json j) => EventItem(
        id: j['id'] as String?,
        title: j['title'] as String,
        start: _wall(j['start']),
        end: _wall(j['end']),
        location: j['location'] as String?,
        meetingLink: j['meetingLink'] as String?,
        fromGoogle: j['source'] == 'google',
        allDay: j['allDay'] as bool? ?? false,
      );

  /// Null for events that live only in Google Calendar (read-only in Yaadly).
  final String? id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? meetingLink;
  final bool fromGoogle;
  final bool allDay;

  int get durationMin => end.difference(start).inMinutes;
}

class Conflict {
  const Conflict({required this.title, required this.start, required this.end});

  factory Conflict.fromJson(Json j) => Conflict(title: j['title'] as String?, start: _wall(j['start']), end: _wall(j['end']));

  /// Null for busy time from Google (free/busy has no titles).
  final String? title;
  final DateTime start;
  final DateTime end;
}

class TaskItem {
  const TaskItem({required this.id, required this.text, required this.done, required this.dueDate, this.listName});

  factory TaskItem.fromJson(Json j) => TaskItem(
        id: j['id'] as String,
        text: j['text'] as String,
        done: j['done'] as bool,
        dueDate: j['dueDate'] == null ? null : DateTime.parse(j['dueDate'] as String),
        listName: j['listName'] as String?,
      );

  final String id;
  final String text;
  final bool done;
  final DateTime? dueDate;
  final String? listName;

  TaskItem copyWith({bool? done}) => TaskItem(id: id, text: text, done: done ?? this.done, dueDate: dueDate, listName: listName);
}

class DayData {
  const DayData({required this.date, required this.events, required this.tasks});

  factory DayData.fromJson(Json j) =>
      DayData(date: DateTime.parse(j['date'] as String), events: _list(j['events'], EventItem.fromJson), tasks: _list(j['tasks'], TaskItem.fromJson));

  final DateTime date;
  final List<EventItem> events;
  final List<TaskItem> tasks;
}

class RangeData {
  const RangeData({required this.events, required this.tasks});

  factory RangeData.fromJson(Json j) => RangeData(events: _list(j['events'], EventItem.fromJson), tasks: _list(j['tasks'], TaskItem.fromJson));

  final List<EventItem> events;
  final List<TaskItem> tasks;
}

/// Result of an event action (create, confirm, clarify, clash choice, edit, cancel). Only the
/// fields the app uses are typed; see `EventOutcome` in the backend for the full union.
class EventOutcome {
  const EventOutcome({required this.type, this.event, this.pendingId, this.actionId, this.sync, this.conflicts = const [], this.slots = const []});

  factory EventOutcome.fromJson(Json j) => EventOutcome(
        type: j['type'] as String,
        event: j['event'] == null ? null : EventItem.fromJson(j['event'] as Json),
        pendingId: j['pendingId'] as String?,
        actionId: (j['actionId'] as String?)?.isEmpty ?? true ? null : j['actionId'] as String,
        sync: j['sync'] as String?,
        conflicts: _list(j['conflicts'], Conflict.fromJson),
        slots: _list(j['slots'], EventItem.fromJson),
      );

  final String type;
  final EventItem? event;
  final String? pendingId;
  final String? actionId;
  final String? sync;
  final List<Conflict> conflicts;
  final List<EventItem> slots;

  bool get isSaved => type == 'saved' || type == 'updated' || type == 'cancelled';
  bool get needsAttention => pendingId != null;
}

// ------------------------------------------------------------------ inbox

enum PendingKind { confirmCreate, clarify, clash, awaitEdit, pickTarget, confirmChange }

class PendingItem {
  const PendingItem({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.event,
    this.sourceText,
    this.missing,
    this.options = const [],
    this.hour,
    this.draftTitle,
    this.conflicts = const [],
    this.slots = const [],
    this.change,
    this.candidates = const [],
    this.newStart,
    this.newTitle,
  });

  factory PendingItem.fromJson(Json j) {
    final draft = j['draft'] as Json?;
    return PendingItem(
      id: j['id'] as String,
      kind: switch (j['kind']) {
        'confirm_create' => PendingKind.confirmCreate,
        'clarify' => PendingKind.clarify,
        'clash' => PendingKind.clash,
        'await_edit' => PendingKind.awaitEdit,
        'pick_target' => PendingKind.pickTarget,
        _ => PendingKind.confirmChange,
      },
      createdAt: _wall(j['createdAt']),
      event: j['event'] == null ? null : EventItem.fromJson(j['event'] as Json),
      sourceText: (j['sourceText'] ?? draft?['sourceText']) as String?,
      missing: j['missing'] as String?,
      options: [for (final o in (j['options'] as List? ?? const [])) o as String],
      hour: draft?['hour'] as int?,
      draftTitle: draft?['title'] as String?,
      conflicts: _list(j['conflicts'], Conflict.fromJson),
      slots: _list(j['slots'], EventItem.fromJson),
      change: j['change'] as String?,
      candidates: _list(j['candidates'], EventItem.fromJson),
      newStart: j['newStart'] == null ? null : _wall(j['newStart']),
      newTitle: j['newTitle'] as String?,
    );
  }

  final String id;
  final PendingKind kind;
  final DateTime createdAt;
  final EventItem? event;
  final String? sourceText;

  /// clarify: which field is missing (`meridiem`, `date`, `kal_after_midnight`, `time`, `title`).
  final String? missing;
  final List<String> options;
  final int? hour;
  final String? draftTitle;
  final List<Conflict> conflicts;
  final List<EventItem> slots;

  /// pick_target / confirm_change: `edit` or `cancel`.
  final String? change;
  final List<EventItem> candidates;
  final DateTime? newStart;
  final String? newTitle;

  String get title => event?.title ?? draftTitle ?? newTitle ?? (candidates.isNotEmpty ? candidates.first.title : 'Event');
}

class UpdateItem {
  const UpdateItem({required this.actionId, required this.kind, required this.at, required this.summary, required this.eventStart, required this.undone, required this.undoable});

  factory UpdateItem.fromJson(Json j) => UpdateItem(
        actionId: j['actionId'] as String,
        kind: j['kind'] as String,
        at: _wall(j['at']),
        summary: [for (final s in (j['summary'] as List? ?? const [])) s as String],
        eventStart: j['eventStart'] == null ? null : _wall(j['eventStart']),
        undone: j['undone'] as bool,
        undoable: j['undoable'] as bool,
      );

  final String actionId;
  final String kind;
  final DateTime at;
  final List<String> summary;
  final DateTime? eventStart;
  final bool undone;
  final bool undoable;
}

class InboxData {
  const InboxData({required this.pending, required this.updates, required this.unread, required this.seenAt});

  factory InboxData.fromJson(Json j) => InboxData(
        pending: _list(j['pending'], PendingItem.fromJson),
        updates: _list(j['updates'], UpdateItem.fromJson),
        unread: j['unread'] as int,
        seenAt: _dtOrNull(j['seenAt']),
      );

  final List<PendingItem> pending;
  final List<UpdateItem> updates;
  final int unread;
  final DateTime? seenAt;
}

// ------------------------------------------------------------------ lists

enum ListKind { grocery, tasks, general }

ListKind _kind(Object? v) => switch (v) {
      'grocery' => ListKind.grocery,
      'tasks' => ListKind.tasks,
      _ => ListKind.general,
    };

class ListSummary {
  const ListSummary({required this.id, required this.name, required this.kind, required this.purpose, required this.isDefault, required this.openCount});

  factory ListSummary.fromJson(Json j) => ListSummary(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: _kind(j['kind']),
        purpose: j['purpose'] as String?,
        isDefault: j['isDefault'] as bool,
        openCount: j['openCount'] as int? ?? 0,
      );

  final String id;
  final String name;
  final ListKind kind;
  final String? purpose;
  final bool isDefault;
  final int openCount;
}

class ListDetail {
  const ListDetail({required this.list, required this.items});

  factory ListDetail.fromJson(Json j) => ListDetail(list: ListSummary.fromJson(j['list'] as Json), items: _list(j['items'], TaskItem.fromJson));

  final ListSummary list;
  final List<TaskItem> items;
}

// ------------------------------------------------------------------ auth

class PairingStart {
  const PairingStart({required this.code, required this.pollToken, required this.expiresAt, required this.message, required this.whatsappUrl});

  factory PairingStart.fromJson(Json j) => PairingStart(
        code: j['code'] as String,
        pollToken: j['pollToken'] as String,
        expiresAt: _dt(j['expiresAt']),
        message: j['message'] as String,
        whatsappUrl: j['whatsappUrl'] as String?,
      );

  final String code;
  final String pollToken;
  final DateTime expiresAt;
  final String message;
  final String? whatsappUrl;
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Json j) => AuthTokens(accessToken: j['accessToken'] as String, refreshToken: j['refreshToken'] as String);

  final String accessToken;
  final String refreshToken;
}
