import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../network/api_client.dart';

String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_pad(d.month)}-${_pad(d.day)}';
String hhmm(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';
String _pad(int n) => n.toString().padLeft(2, '0');

/// Random UUID v4 for `Idempotency-Key` (a retried request must not create twice).
String newIdempotencyKey() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// Every call the app makes to the backend. Throws [ApiException] on failure.
class YaadlyApi {
  YaadlyApi(this._dio, this._public);

  final Dio _dio;
  final Dio _public;

  Future<T> _call<T>(Future<Response<dynamic>> Function() send, T Function(dynamic data) parse) async {
    try {
      return parse((await send()).data);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  // ---------------------------------------------------------------- auth

  Future<PairingStart> startPairing(String? deviceName) =>
      _call(() => _public.post<Json>('/v1/auth/pair/start', data: {'deviceName': ?deviceName}), (d) => PairingStart.fromJson(d as Json));

  /// `pending`, `expired`, or tokens once the user sent the code on WhatsApp.
  Future<(String, AuthTokens?)> pairingStatus(String pollToken) => _call(
        () => _public.get<Json>('/v1/auth/pair/status', options: Options(headers: {'x-poll-token': pollToken})),
        (d) {
          final j = d as Json;
          final status = j['status'] as String;
          return (status, status == 'linked' ? AuthTokens.fromJson(j) : null);
        },
      );

  Future<void> logout() => _call(() => _dio.post<void>('/v1/auth/logout'), (_) {});

  // ---------------------------------------------------------------- profile

  Future<Me> me() => _call(() => _dio.get<Json>('/v1/me'), (d) => Me.fromJson(d as Json));

  Future<Me> updateSettings(Map<String, Object> patch) => _call(() => _dio.patch<Json>('/v1/me/settings', data: patch), (d) => Me.fromJson(d as Json));

  Future<String> googleLinkUrl() => _call(() => _dio.post<Json>('/v1/google/link'), (d) => (d as Json)['url'] as String);

  Future<void> disconnectGoogle() => _call(() => _dio.delete<void>('/v1/google'), (_) {});

  // ---------------------------------------------------------------- calendar

  Future<DayData> day(DateTime date) => _call(() => _dio.get<Json>('/v1/day', queryParameters: {'date': isoDay(date)}), (d) => DayData.fromJson(d as Json));

  Future<RangeData> range(DateTime from, DateTime to) =>
      _call(() => _dio.get<Json>('/v1/calendar', queryParameters: {'from': isoDay(from), 'to': isoDay(to)}), (d) => RangeData.fromJson(d as Json));

  Future<List<EventItem>> freeSlots(DateTime date, int durationMin) => _call(
        () => _dio.get<Json>('/v1/free-slots', queryParameters: {'date': isoDay(date), 'duration': durationMin}),
        (d) => [for (final s in ((d as Json)['slots'] as List)) EventItem(title: '', start: wallClock((s as Json)['start'] as String), end: wallClock(s['end'] as String))],
      );

  Future<EventOutcome> createEvent({required String title, required DateTime start, required int durationMin, String? location, required String idempotencyKey}) => _call(
        () => _dio.post<Json>(
          '/v1/events',
          data: {'title': title, 'date': isoDay(start), 'time': hhmm(start), 'durationMin': durationMin, 'location': location},
          options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        ),
        _outcome,
      );

  Future<EventOutcome> updateEvent(String id, {String? title, DateTime? start, int? durationMin, String? location, bool clearLocation = false}) => _call(
        () => _dio.patch<Json>('/v1/events/$id', data: {
          'title': ?title,
          if (start != null) ...{'date': isoDay(start), 'time': hhmm(start)},
          'durationMin': ?durationMin,
          if (location != null || clearLocation) 'location': location,
        }),
        _outcome,
      );

  Future<EventOutcome> cancelEvent(String id) => _call(() => _dio.delete<Json>('/v1/events/$id'), _outcome);

  // ---------------------------------------------------------------- inbox

  Future<InboxData> inbox() => _call(() => _dio.get<Json>('/v1/inbox'), (d) => InboxData.fromJson(d as Json));

  Future<void> markInboxSeen() => _call(() => _dio.post<void>('/v1/inbox/seen'), (_) {});

  /// Same actions as the WhatsApp buttons: confirm, edit, cancel, opt+arg, keep, change, slot+arg, pick+arg, yes, no.
  Future<EventOutcome> pendingAction(String id, String action, [String? arg]) =>
      _call(() => _dio.post<Json>('/v1/pending/$id/action', data: {'action': action, 'arg': ?arg}), _outcome);

  Future<EventOutcome> answerPending(String id, String text) => _call(() => _dio.post<Json>('/v1/pending/$id/answer', data: {'text': text}), _outcome);

  /// Returns true when something was undone.
  Future<bool> undo([String? actionId]) =>
      _call(() => _dio.post<Json>('/v1/undo', data: {'actionId': ?actionId}), (d) => (d as Json)['source'] != 'none');

  // ---------------------------------------------------------------- lists

  Future<List<ListSummary>> lists() => _call(() => _dio.get<Json>('/v1/lists'), (d) => [for (final l in ((d as Json)['lists'] as List)) ListSummary.fromJson(l as Json)]);

  Future<ListDetail> list(String id) => _call(() => _dio.get<Json>('/v1/lists/$id'), (d) => ListDetail.fromJson(d as Json));

  Future<ListSummary> createList({required String name, String? purpose, required ListKind kind}) => _call(
        () => _dio.post<Json>('/v1/lists', data: {'name': name, 'purpose': purpose, 'kind': kind.name}),
        (d) => ListSummary.fromJson((d as Json)['list'] as Json),
      );

  Future<ListSummary> updateList(String id, {String? name, String? purpose, ListKind? kind, bool makeDefault = false}) => _call(
        () => _dio.patch<Json>('/v1/lists/$id', data: {'name': ?name, 'purpose': ?purpose, 'kind': ?kind?.name, if (makeDefault) 'isDefault': true}),
        (d) => ListSummary.fromJson((d as Json)['list'] as Json),
      );

  Future<void> deleteList(String id) => _call(() => _dio.delete<void>('/v1/lists/$id'), (_) {});

  Future<TaskItem> addItem(String listId, String text, {DateTime? dueDate}) => _call(
        () => _dio.post<Json>(
          '/v1/lists/$listId/items',
          data: {'text': text, 'dueDate': dueDate == null ? null : isoDay(dueDate)},
          options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
        ),
        (d) => TaskItem.fromJson((d as Json)['item'] as Json),
      );

  Future<TaskItem> updateItem(String id, {bool? done, String? text, DateTime? dueDate, bool clearDueDate = false, String? listId}) => _call(
        () => _dio.patch<Json>('/v1/items/$id', data: {
          'done': ?done,
          'text': ?text,
          if (dueDate != null || clearDueDate) 'dueDate': dueDate == null ? null : isoDay(dueDate),
          'listId': ?listId,
        }),
        (d) => TaskItem.fromJson((d as Json)['item'] as Json),
      );

  /// Returns the undo action id.
  Future<String?> deleteItem(String id) => _call(() => _dio.delete<Json>('/v1/items/$id'), (d) => (d as Json)['actionId'] as String?);

  static EventOutcome _outcome(dynamic d) => EventOutcome.fromJson((d as Json)['outcome'] as Json);
}

final apiProvider = Provider<YaadlyApi>((ref) => YaadlyApi(ref.watch(dioProvider), ref.watch(publicDioProvider)));
