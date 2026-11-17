import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';
import '../prefs.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier();

  static const accessTokenKey = 'auth_access_token';
  static const refreshTokenKey = 'auth_refresh_token';
  static const sessionStartedKey = 'auth_session_started_ms';
  static const maxSessionDuration = Duration(hours: 8);

  AuthApi? _api;
  String? _accessToken;
  String? _refreshToken;
  AppUser? _user;
  DateTime? _sessionStartedAt;
  bool _restoring = false;
  Completer<bool>? _refreshCompleter;

  String? get accessToken => _accessToken;

  AppUser? get user => _user;

  bool get isAuthenticated =>
      _accessToken != null &&
      _accessToken!.isNotEmpty &&
      _user != null &&
      !_sessionExpired;

  bool get isRestoring => _restoring;

  bool get _sessionExpired {
    final started = _sessionStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) > maxSessionDuration;
  }

  bool has(AppRole role) => _user?.role.hasAtLeast(role) ?? false;

  bool get canWriteCatalog => has(AppRole.sponsor);

  /// Арены и награды — только админ.
  bool get canManageDictionaries => has(AppRole.admin);

  bool get canManageUsers => has(AppRole.admin);

  bool get canAccessOffers => has(AppRole.sponsor);

  bool get canAccessScoutTools {
    final role = _user?.role;
    return role == AppRole.scout || role == AppRole.admin;
  }

  void bind(Dio dio) {
    _api = AuthApi(dio);
  }

  Future<void> restore() async {
    _restoring = true;
    notifyListeners();

    final prefs = AppPrefs.instance;
    _accessToken = prefs.getString(accessTokenKey);
    _refreshToken = prefs.getString(refreshTokenKey);
    final startedMs = prefs.getInt(sessionStartedKey);
    _sessionStartedAt = startedMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(startedMs);

    try {
      if (_accessToken == null || _accessToken!.isEmpty) {
        await _clearLocal();
        return;
      }

      if (_sessionExpired) {
        await logout();
        return;
      }

      final api = _api;
      if (api == null) {
        await _clearLocal();
        return;
      }

      try {
        _user = await api.me();
      } on UnauthorizedException {
        final refreshed = await refreshTokens();
        if (!refreshed) return;
        _user = await api.me();
      } on ApiException {
        final refreshed = await refreshTokens();
        if (!refreshed) return;
        _user = await api.me();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AUTH] restore failed: $error');
      }
      await _clearLocal();
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final api = _requireApi();
    final tokens = await api.login(username: username, password: password);
    await _applyTokens(tokens);
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
  }) async {
    final api = _requireApi();
    // Регистрация создаёт пользователя (роль scout), токены выдаёт /auth/login.
    await api.register(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
    );
    final tokens = await api.login(username: username, password: password);
    await _applyTokens(tokens);
  }

  Future<void> logout() async {
    final api = _api;
    final token = _accessToken;
    if (api != null && token != null && token.isNotEmpty) {
      try {
        await api.logout();
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[AUTH] logout request failed: $error');
        }
      }
    }
    await _clearLocal();
    notifyListeners();
  }

  /// Обновляет пару токенов. Возвращает `false` и выходит при неудаче.
  Future<bool> refreshTokens() async {
    final inflight = _refreshCompleter;
    if (inflight != null) return inflight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refresh = _refreshToken;
      final api = _api;
      if (refresh == null || refresh.isEmpty || api == null) {
        await logout();
        completer.complete(false);
        return false;
      }

      if (_sessionExpired) {
        await logout();
        completer.complete(false);
        return false;
      }

      final tokens = await api.refresh(refresh);
      await _applyTokens(tokens, keepSessionStart: true);
      completer.complete(true);
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AUTH] refresh failed: $error');
      }
      await logout();
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  AuthApi _requireApi() {
    final api = _api;
    if (api == null) {
      throw StateError('AuthApi не привязан. Вызовите bind(dio) в main.');
    }
    return api;
  }

  Future<void> _applyTokens(
    AuthTokens tokens, {
    bool keepSessionStart = false,
  }) async {
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _user = tokens.user;
    if (!keepSessionStart || _sessionStartedAt == null) {
      _sessionStartedAt = DateTime.now();
    }

    final prefs = AppPrefs.instance;
    await prefs.setString(accessTokenKey, tokens.accessToken);
    await prefs.setString(refreshTokenKey, tokens.refreshToken);
    await prefs.setInt(
      sessionStartedKey,
      _sessionStartedAt!.millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  Future<void> _clearLocal() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _sessionStartedAt = null;
    final prefs = AppPrefs.instance;
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(sessionStartedKey);
  }
}
