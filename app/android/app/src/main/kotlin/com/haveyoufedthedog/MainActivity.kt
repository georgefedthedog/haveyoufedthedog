package com.haveyoufedthedog

import io.flutter.embedding.android.FlutterActivity

// NFC tags are handled entirely via universal links now (the OS opens the app
// to /nfc-tap and the app_links plugin delivers it to Dart), so there's no
// NFC intent handling or MethodChannel here any more.
class MainActivity : FlutterActivity()
