import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for NextGen Excellence Academy CMS.
/// Configured for Firebase project: `next-gen-excellence`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      default:
        return web;
    }
  }

  /// Web Firebase configuration for NextGen CMS.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCaF5TridslGTbJXzm8PnyYWxt9NWPx8hE',
    appId: '1:612098739916:web:965086175400ae93a87c69',
    messagingSenderId: '612098739916',
    projectId: 'next-gen-excellence',
    authDomain: 'next-gen-excellence.firebaseapp.com',
    storageBucket: 'next-gen-excellence.firebasestorage.app',
    measurementId: 'G-XLLV89NPV6',
  );

  /// Android Firebase configuration fallback.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQbltqnmc6JGrajv27XD35_UU4aurwqxY',
    appId: '1:612098739916:android:b6f2cbe04c07161ca87c69',
    messagingSenderId: '612098739916',
    projectId: 'next-gen-excellence',
    storageBucket: 'next-gen-excellence.firebasestorage.app',
  );
}

