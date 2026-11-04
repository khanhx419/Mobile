import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated options configuration for QLTLHT Flutter multiplatform.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    appId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    messagingSenderId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    projectId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    authDomain: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    storageBucket: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    appId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    messagingSenderId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    projectId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    storageBucket: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    appId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    messagingSenderId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    projectId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    storageBucket: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    iosBundleId: 'com.qltlht.qltlht',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    appId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    messagingSenderId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    projectId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    storageBucket: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    iosBundleId: 'com.qltlht.qltlht',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    appId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    messagingSenderId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    projectId: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    authDomain: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
    storageBucket: 'CONFIGURE_YOUR_FIREBASE_PROJECT',
  );
}
