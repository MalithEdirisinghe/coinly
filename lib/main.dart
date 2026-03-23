import 'package:coinly/app/app.dart';
import 'package:coinly/core/services/firebase_bootstrap.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  runApp(CoinlyApp(firebaseReady: firebaseReady));
}
