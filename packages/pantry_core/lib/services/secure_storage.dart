import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The one secure-storage handle every caller shares.
///
/// `resetOnError` is off. Left at the plugin's default, Android answers any
/// decrypt or migration fault by deleting every key the app owns — the login
/// and all ~35 preferences, including the pinned certificates that a
/// self-signed server needs to be reachable at all. A read that fails throws
/// instead, and callers degrade to "nothing stored yet": the store is left
/// intact and the user sees the sign-in screen rather than a reset app.
const secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: false),
);
