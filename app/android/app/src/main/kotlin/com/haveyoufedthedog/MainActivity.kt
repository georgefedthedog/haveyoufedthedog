package com.haveyoufedthedog

import io.flutter.embedding.android.FlutterActivity

// NFC tags carry a /nfc-tap URL and are dispatched to the app by the OS: an
// NDEF_DISCOVERED intent-filter in AndroidManifest.xml launches the app
// straight from a tag tap (no generic NFC dialog), and the app_links plugin
// reads the intent's data URI and delivers it to Dart. So there's no NFC
// intent handling or MethodChannel needed here.
class MainActivity : FlutterActivity()
