import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

/// Keeps the app's tokens: in memory for requests, in the Android Keystore-backed secure storage
/// across restarts. The access token lives 15 min; the refresh token rotates on every refresh.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _kAccess = 'yaadly.access';
  static const _kRefresh = 'yaadly.refresh';

  final FlutterSecureStorage _storage;
  String? _access;
  String? _refresh;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;

  Future<bool> load() async {
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
    return _refresh != null;
  }

  Future<void> save(AuthTokens t) async {
    _access = t.accessToken;
    _refresh = t.refreshToken;
    await _storage.write(key: _kAccess, value: t.accessToken);
    await _storage.write(key: _kRefresh, value: t.refreshToken);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

enum SessionStatus { signedOut, signedIn }

/// Whether this install is linked to a WhatsApp account. The router redirects on changes.
class SessionController extends AsyncNotifier<SessionStatus> {
  @override
  Future<SessionStatus> build() async {
    final hasSession = await ref.read(tokenStoreProvider).load();
    return hasSession ? SessionStatus.signedIn : SessionStatus.signedOut;
  }

  Future<void> signedIn(AuthTokens tokens) async {
    await ref.read(tokenStoreProvider).save(tokens);
    state = const AsyncData(SessionStatus.signedIn);
  }

  /// Local sign-out (also used when the server rejects our refresh token).
  Future<void> signedOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(SessionStatus.signedOut);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, SessionStatus>(SessionController.new);
