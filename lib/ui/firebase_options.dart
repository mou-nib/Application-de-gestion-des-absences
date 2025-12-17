import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
    //case TargetPlatform.iOS:
    //return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBEj0vdlDQpXdH3VrSG9nQULkMVNo-116I",
    authDomain: "abstracker-663d8.firebaseapp.com",
    projectId: "abstracker-663d8",
    storageBucket: "abstracker-663d8.firebasestorage.app",
    messagingSenderId: "836059393525",
    appId: "1:836059393525:web:c810b5044723bd1c8a44bc",
    measurementId: "G-0J4XMTBEMG",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBEj0vdlDQpXdH3VrSG9nQULkMVNo-116I",
    appId: "1:836059393525:android:414ac208c35b4ded8a44bc",
    messagingSenderId: "836059393525",
    projectId: "abstracker-663d8",
    storageBucket: "abstracker-663d8.firebasestorage.app",
  );
}
