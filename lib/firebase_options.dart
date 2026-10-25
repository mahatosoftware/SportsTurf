import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Sports Turf, sourced from google-services.json.
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
      default:
        return android;
    }
  }

  static const String serverClientId = '485736064883-bdvc4f52o7v8aakmufnl7vfvqskmvb2o.apps.googleusercontent.com';

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRhBXHXrcPO_FhZ90oif8gS9y3ImPuW-g',
    appId: '1:485736064883:android:c25cb08681a14070178706',
    messagingSenderId: '485736064883',
    projectId: 'sportsturf-prod',
    storageBucket: 'sportsturf-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRhBXHXrcPO_FhZ90oif8gS9y3ImPuW-g',
    appId: '1:485736064883:android:c25cb08681a14070178706',
    messagingSenderId: '485736064883',
    projectId: 'sportsturf-prod',
    storageBucket: 'sportsturf-prod.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCRhBXHXrcPO_FhZ90oif8gS9y3ImPuW-g',
    appId: '1:485736064883:android:c25cb08681a14070178706',
    messagingSenderId: '485736064883',
    projectId: 'sportsturf-prod',
    storageBucket: 'sportsturf-prod.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCRhBXHXrcPO_FhZ90oif8gS9y3ImPuW-g',
    appId: '1:485736064883:android:c25cb08681a14070178706',
    messagingSenderId: '485736064883',
    projectId: 'sportsturf-prod',
    storageBucket: 'sportsturf-prod.firebasestorage.app',
  );
}
