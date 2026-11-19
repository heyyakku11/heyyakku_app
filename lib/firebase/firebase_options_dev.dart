// File generated for the `dev` flavor.
// Replace by re-running FlutterFire for package `com.yakku.app.dev` if values change.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptionsDev {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptionsDev have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptionsDev are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPHiH1XkyFDZR-FUJ7qBalAXqyRW7x5XI',
    appId: '1:756654278705:android:f0710f30910453398c2d10',
    messagingSenderId: '756654278705',
    projectId: 'yakku-dev',
    storageBucket: 'yakku-dev.firebasestorage.app',
  );

  /// Replace with iOS values from `GoogleService-Info.plist` for `com.yakku.app.dev`.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE_ME:ios:REPLACE_ME',
    messagingSenderId: '756654278705',
    projectId: 'yakku-dev',
    storageBucket: 'yakku-dev.firebasestorage.app',
    iosBundleId: 'com.yakku.app.dev',
  );
}
