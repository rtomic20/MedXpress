import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8000/api'; // for web
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api'; // for Android emulator
  } else {
    return 'http://localhost:8000/api'; // for desktop, iOS...
  }
}
