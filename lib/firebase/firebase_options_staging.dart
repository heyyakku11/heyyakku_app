// File generated for the `staging` flavor.
// Replace with real FlutterFire / Firebase console values for `com.yakku.app.staging`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract final class DefaultFirebaseOptionsStaging {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptionsStaging have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptionsStaging are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE_ME:android:REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'yakku-staging',
    storageBucket: 'yakku-staging.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:REPLACE_ME:ios:REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'yakku-staging',
    storageBucket: 'yakku-staging.firebasestorage.app',
    iosBundleId: 'com.yakku.app.staging',
  );
}
