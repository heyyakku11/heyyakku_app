// File generated for the `production` flavor.
// Replace with real FlutterFire / Firebase console values for `com.yakku.app`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptionsProduction {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptionsProduction have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptionsProduction are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE_ME:android:REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'yakku-production',
    storageBucket: 'yakku-production.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE_ME:ios:REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'yakku-production',
    storageBucket: 'yakku-production.firebasestorage.app',
    iosBundleId: 'com.yakku.app',
  );
}
