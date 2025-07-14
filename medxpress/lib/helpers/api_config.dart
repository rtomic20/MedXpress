import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8000/api'; // for web
  } else if (Platform.isAndroid) {
    return 'http://10.57.135.208:8000/'; // for Android emulator
  } else {
    return 'http://localhost:8000/api'; // for desktop, iOS...
  }
}
