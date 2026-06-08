package com.haveyoufedthedog

import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.haveyoufedthedog/nfc_launch"
    private var channel: MethodChannel? = null

    // If the app was launched/resumed by an NFC tap before Flutter wired
    // up the MethodChannel handler, hold the tag id here so Dart can ask
    // for it via `getPendingTag` once it's ready.
    private var pendingTagId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingTag" -> {
                    val id = pendingTagId
                    pendingTagId = null
                    result.success(id)
                }
                else -> result.notImplemented()
            }
        }
        intent?.let { processIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        processIntent(intent)
    }

    private fun processIntent(intent: Intent) {
        val action = intent.action ?: return
        if (action != NfcAdapter.ACTION_TECH_DISCOVERED &&
            action != NfcAdapter.ACTION_NDEF_DISCOVERED &&
            action != NfcAdapter.ACTION_TAG_DISCOVERED
        ) {
            return
        }
        val tag: Tag? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        }
        val idBytes = tag?.id ?: return
        val hex = idBytes.joinToString("") { byte -> "%02x".format(byte) }
        pendingTagId = hex
        try {
            channel?.invokeMethod("onTag", hex)
        } catch (e: Exception) {
            // No-op: Dart will pick it up via getPendingTag.
        }
    }
}
