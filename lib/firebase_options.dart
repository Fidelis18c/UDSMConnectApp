// Generated from Firebase project `udsm-connect` (Android app tz.ac.udsm.udsm_connect).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions is only configured for Android in this project.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjUiYv2_Z6J6yHYs-N9V0FB8qDirMI420',
    appId: '1:939981785979:android:1b5c3f1f1d0a27ab270bde',
    messagingSenderId: '939981785979',
    projectId: 'udsm-connect',
    storageBucket: 'udsm-connect.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjUiYv2_Z6J6yHYs-N9V0FB8qDirMI420',
    appId: '1:939981785979:web:2fbd76040bce447e', 
    messagingSenderId: '939981785979',
    projectId: 'udsm-connect',
    authDomain: 'udsm-connect.firebaseapp.com',
    storageBucket: 'udsm-connect.firebasestorage.app',
  );
}
