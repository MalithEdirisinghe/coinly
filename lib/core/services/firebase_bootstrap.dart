import 'package:firebase_core/firebase_core.dart';

abstract final class FirebaseBootstrap {
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();
      return true;
    } on Exception {
      return false;
    }
  }
}
