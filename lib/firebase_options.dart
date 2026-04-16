import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
          'Web platformu için Firebase options eklenmedi. Web app eklemen gerekiyor.'
      );
    }
    return android;
  }

  // -------- ANDROID --------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBwirMCfZoNlN6Pc4zceFpkUek1cwhdfkI',
    appId: '1:452304782809:android:65fc4828409aa264c445c8',
    messagingSenderId: '452304782809',
    projectId: 'pregnova-38391',
    storageBucket: 'pregnova-38391.firebasestorage.app',
  );
}
