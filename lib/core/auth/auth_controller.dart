import 'package:flutter/foundation.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.userPreferences,
    required SecureStorageService secureStorage,
    required AuthRemoteDataSource authRemote,
    bool isUserLogged = false,
    String? this._email,
    String? this._displayName,
  })  : _secureStorage = secureStorage,
        _authRemote = authRemote,
        _isLoggedIn = isUserLogged;

  final UserPreferences userPreferences;
  final SecureStorageService _secureStorage;
  final AuthRemoteDataSource _authRemote;

  bool _isLoggedIn;
  String? _email;
  String? _displayName;

  bool get isLoggedIn => _isLoggedIn;
  String? get email => _email;
  String? get displayName => _displayName;

  Future<void> sendOtp(String email) async {
    await _authRemote.sendOtp(SendOtpRequestModel(email: email));
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _authRemote.verifyOtp(
      VerifyOtpRequestModel(email: email, otp: otp),
    );

    await _secureStorage.update(StorageKeys.accessToken, data.accessToken);
    await _secureStorage.update(StorageKeys.refreshToken, data.refreshToken);

    await userPreferences.setEmail(data.email);
    await userPreferences.setDisplayName(data.displayName);
    await userPreferences.setIsUserLogged(true);

    _isLoggedIn = true;
    _email = data.email;
    _displayName = data.displayName;
    notifyListeners();
  }

  Future<void> login({String? email}) async {
    _isLoggedIn = true;
    _email = email;
    await userPreferences.setIsUserLogged(true);
    if (email != null) {
      await userPreferences.setEmail(email);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    final accessToken = await _secureStorage.read(StorageKeys.accessToken);

    Object? remoteError;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _authRemote.logout(
          LogoutRequestModel(refreshToken: refreshToken),
          accessToken: accessToken,
        );
      } catch (error) {
        remoteError = error;
      }
    }

    await _secureStorage.clearKeys([
      StorageKeys.accessToken,
      StorageKeys.refreshToken,
    ]);
    await userPreferences.clearAuth();

    _isLoggedIn = false;
    _email = null;
    _displayName = null;
    notifyListeners();

    if (remoteError != null) {
      throw remoteError;
    }
  }

  /// Resolves session from prefs + secure token. Clears stale sessions.
  static Future<AuthSessionBootstrap> bootstrap({
    required UserPreferences userPreferences,
    required SecureStorageService secureStorage,
  }) async {
    final isUserLogged = await userPreferences.getIsUserLogged();
    final accessToken = await secureStorage.read(StorageKeys.accessToken);
    final hasToken = accessToken != null && accessToken.isNotEmpty;

    if (isUserLogged && hasToken) {
      return AuthSessionBootstrap(
        isUserLogged: true,
        email: await userPreferences.getEmail(),
        displayName: await userPreferences.getDisplayName(),
      );
    }

    if (isUserLogged || hasToken) {
      await secureStorage.clearKeys([
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
      ]);
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
