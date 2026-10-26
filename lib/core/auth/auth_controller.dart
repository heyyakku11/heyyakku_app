import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';
import 'package:yakku/data/models/device/login_device_model.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.userPreferences,
    required AuthTokenStore tokenStore,
    required AuthRemoteDataSource authRemote,
    this._draftPolls,
    bool isUserLogged = false,
    this._hasEnteredAsGuest = false,
    String? this._phoneNumber,
    String? this._displayName,
  }) : _tokenStore = tokenStore,
       _authRemote = authRemote,
       _isLoggedIn = isUserLogged;

  final UserPreferences userPreferences;
  final AuthTokenStore _tokenStore;
  final AuthRemoteDataSource _authRemote;
  final DraftPollStore? _draftPolls;

  bool _isLoggedIn;
  bool _hasEnteredAsGuest;
  String? _phoneNumber;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;
  bool get hasEnteredAsGuest => _hasEnteredAsGuest;
  bool get canEnterApp => _isLoggedIn || _hasEnteredAsGuest;
  String? get phoneNumber => _phoneNumber;
  String? get displayName => _displayName;

  Future<void> enterAsGuest() async {
    if (_hasEnteredAsGuest) return;
    await userPreferences.setHasEnteredAsGuest(true);
    _hasEnteredAsGuest = true;
    notifyListeners();
  }

  /// Clears local guest entry so GoRouter returns the user to onboarding.
  Future<void> revokeGuestEntry() async {
    if (!_hasEnteredAsGuest) return;
    await userPreferences.setHasEnteredAsGuest(false);
    _hasEnteredAsGuest = false;
    notifyListeners();
  }

  Future<SendOtpData> sendOtp(String phoneNumber, {String? name}) {
    return _authRemote.sendOtp(
      SendOtpRequestModel(phoneNumber: phoneNumber, name: name),
    );
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
    String? firstName,
    String? guestToken,
    LoginDeviceModel? device,
  }) async {
    final data = await _authRemote.verifyOtp(
      VerifyOtpRequestModel(phoneNumber: phone, otp: otp, device: device),
      guestToken: guestToken,
    );

    await _tokenStore.saveTokens(
      accessToken: data.auth.accessToken,
      refreshToken: data.auth.refreshToken,
    );

    final trimmedName = firstName?.trim() ?? '';
    final displayName = trimmedName.isNotEmpty
        ? trimmedName
        : (data.user.name.isNotEmpty
              ? data.user.name
              : data.user.anonymousName);

    await userPreferences.setPhoneNumber(phone);
    await userPreferences.setDisplayName(displayName);
    await userPreferences.setIsUserLogged(true);

    _isLoggedIn = true;
    _phoneNumber = phone;
    _displayName = displayName;
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

  /// Deletes the account on the server, then clears the local session so the
  /// router returns the user to onboarding. Throws if the API call fails, in
  /// which case the user stays signed in.
  Future<void> deleteAccount() async {
    await _authRemote.deleteAccount(accessToken: _tokenStore.accessToken);
    await clearLocalSession();
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

  /// Clears tokens, prefs, and local poll drafts without calling the logout API
  /// (e.g. after refresh failure).
  Future<void> clearLocalSession() async {
    final drafts = _draftPolls;
    if (drafts != null && drafts.isReady) {
      await drafts.clearAll();
    }
    await _tokenStore.clear();
    await userPreferences.clearAuth();

    _isLoggedIn = false;
    _hasEnteredAsGuest = false;
    _phoneNumber = null;
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
    final hasEnteredAsGuest = await userPreferences.getHasEnteredAsGuest();

    if (isUserLogged && hasTokens) {
      return AuthSessionBootstrap(
        isUserLogged: true,
        hasEnteredAsGuest: hasEnteredAsGuest,
        phoneNumber: await userPreferences.getPhoneNumber(),
        displayName: await userPreferences.getDisplayName(),
      );
    }

    if (isUserLogged ||
        tokenStore.hasAccessToken ||
        tokenStore.hasRefreshToken) {
      await tokenStore.clear();
      await userPreferences.clearAuth();
      return const AuthSessionBootstrap(isUserLogged: false);
    }

    return AuthSessionBootstrap(
      isUserLogged: false,
      hasEnteredAsGuest: hasEnteredAsGuest,
    );
  }
}

class AuthSessionBootstrap {
  const AuthSessionBootstrap({
    required this.isUserLogged,
    this.hasEnteredAsGuest = false,
    this.phoneNumber,
    this.displayName,
  });

  final bool isUserLogged;
  final bool hasEnteredAsGuest;
  final String? phoneNumber;
  final String? displayName;
}
