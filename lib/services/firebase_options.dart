import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for BudgetBuddy configured with Project: my--budgetbuddy-flutter
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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDD7F12inftEoUt1OcfOXeoZ8EIlaLiqQ',
    appId: '1:534651230919:web:db5632dd73ae2af7aebce2',
    messagingSenderId: '534651230919',
    projectId: 'my--budgetbuddy-flutter',
    authDomain: 'my--budgetbuddy-flutter.firebaseapp.com',
    storageBucket: 'my--budgetbuddy-flutter.firebasestorage.app',
    measurementId: 'G-KNDXJPZL2J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDD7F12inftEoUt1OcfOXeoZ8EIlaLiqQ',
    appId: '1:534651230919:android:db5632dd73ae2af7aebce2',
    messagingSenderId: '534651230919',
    projectId: 'my--budgetbuddy-flutter',
    storageBucket: 'my--budgetbuddy-flutter.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDD7F12inftEoUt1OcfOXeoZ8EIlaLiqQ',
    appId: '1:534651230919:ios:db5632dd73ae2af7aebce2',
    messagingSenderId: '534651230919',
    projectId: 'my--budgetbuddy-flutter',
    storageBucket: 'my--budgetbuddy-flutter.firebasestorage.app',
    iosBundleId: 'com.budgetbuddy.budgetBuddy',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDDD7F12inftEoUt1OcfOXeoZ8EIlaLiqQ',
    appId: '1:534651230919:ios:db5632dd73ae2af7aebce2',
    messagingSenderId: '534651230919',
    projectId: 'my--budgetbuddy-flutter',
    storageBucket: 'my--budgetbuddy-flutter.firebasestorage.app',
    iosBundleId: 'com.budgetbuddy.budgetBuddy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDDD7F12inftEoUt1OcfOXeoZ8EIlaLiqQ',
    appId: '1:534651230919:web:db5632dd73ae2af7aebce2',
    messagingSenderId: '534651230919',
    projectId: 'my--budgetbuddy-flutter',
    authDomain: 'my--budgetbuddy-flutter.firebaseapp.com',
    storageBucket: 'my--budgetbuddy-flutter.firebasestorage.app',
  );
}
