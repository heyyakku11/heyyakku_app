import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.userPreferences,
    required AuthTokenStore tokenStore,
    required AuthRemoteDataSource authRemote,
    bool isUserLogged = false,
    String? this._email,
    String? this._displayName,
  }) : _tokenStore = tokenStore,
       _authRemote = authRemote,
       _isLoggedIn = isUserLogged;

  final UserPreferences userPreferences;
  final AuthTokenStore _tokenStore;
  final AuthRemoteDataSource _authRemote;

  bool _isLoggedIn;
  String? _email;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;
  String? get email => _email;
  String? get displayName => _displayName;

  Future<SendOtpData> sendOtp(String email) {
    return _authRemote.sendOtp(SendOtpRequestModel(email: email));
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final data = await _authRemote.verifyOtp(
      VerifyOtpRequestModel(email: email, otp: otp),
    );

    await _tokenStore.saveTokens(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
    );

    await userPreferences.setEmail(email);
    await userPreferences.setDisplayName(data.displayName);
    await userPreferences.setIsUserLogged(true);

    _isLoggedIn = true;
    _email = email;
    _displayName = data.displayName;
    notifyListeners();
  }

  Future<void> logout() async {
    final refreshToken = _tokenStore.refreshToken;
    final accessToken = _tokenStore.accessToken;

    await clearLocalSession();

    if (refreshToken == null || refreshToken.isEmpty) return;

    unawaited(
      _logoutRemote(refreshToken: refreshToken, accessToken: accessToken),
    );
  }

  Future<void> _logoutRemote({
    required String refreshToken,
    required String? accessToken,
  }) async {
    try {
      await _authRemote.logout(
        LogoutRequestModel(refreshToken: refreshToken),
        accessToken: accessToken,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AUTH] Background logout failed: $error');
      }
    }
  }

  /// Clears tokens and prefs without calling the logout API (e.g. after refresh failure).
  Future<void> clearLocalSession() async {
    await _tokenStore.clear();
    await userPreferences.clearAuth();

    _isLoggedIn = false;
    _email = null;
    _displayName = null;
    notifyListeners();
  }

  /// Resolves session from prefs + secure tokens. Hydrates [tokenStore].
  /// Clears stale half-sessions (prefs without tokens or tokens without prefs).
  static Future<AuthSessionBootstrap> bootstrap({
    required UserPreferences userPreferences,
    required AuthTokenStore tokenStore,
  }) async {
    await tokenStore.hydrate();

    final isUserLogged = await userPreferences.getIsUserLogged();
    final hasTokens = tokenStore.hasSessionTokens;

    if (isUserLogged && hasTokens) {
      return AuthSessionBootstrap(
        isUserLogged: true,
        email: await userPreferences.getEmail(),
        displayName: await userPreferences.getDisplayName(),
      );
    }

    if (isUserLogged ||
        tokenStore.hasAccessToken ||
        tokenStore.hasRefreshToken) {
      await tokenStore.clear();
      await userPreferences.clearAuth();
    }

    return const AuthSessionBootstrap(isUserLogged: false);
  }
}

class AuthSessionBootstrap {
  const AuthSessionBootstrap({
    required this.isUserLogged,
    this.email,
    this.displayName,
  });

  final bool isUserLogged;
  final String? email;
  final String? displayName;
}
