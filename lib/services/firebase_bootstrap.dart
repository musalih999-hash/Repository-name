import 'package:firebase_core/firebase_core.dart';

Future<bool> initializeFirebaseSafely() async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    return true;
  } catch (_) {
    // The app stays usable with local server data until google-services.json
    // and FirebaseOptions are supplied for the target platform.
    return false;
  }
}
