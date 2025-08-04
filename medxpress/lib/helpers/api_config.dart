import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8000/api';
  } else if (Platform.isAndroid) {
    return 'https://4d622eba37e3.ngrok-free.app';
  } else {
    return 'http://10.0.2.2:8000/api';
  }
}
