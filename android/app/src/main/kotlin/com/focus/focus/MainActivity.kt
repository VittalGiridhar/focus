package com.focus.focus

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var usageChannel: UsageChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usageChannel = UsageChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureUnlockRequest(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureUnlockRequest(intent)
    }

    /** "Ask partner to unlock" from the block screen; Dart picks it up on start or resume. */
    private fun captureUnlockRequest(intent: Intent?) {
        val pkg = intent?.getStringExtra(EXTRA_UNLOCK_PACKAGE) ?: return
        val label = intent.getStringExtra(EXTRA_UNLOCK_LABEL) ?: pkg
        usageChannel?.pendingUnlock = pkg to label
        intent.removeExtra(EXTRA_UNLOCK_PACKAGE)
        intent.removeExtra(EXTRA_UNLOCK_LABEL)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        usageChannel?.onRequestPermissionsResult(requestCode, grantResults)
    }

    companion object {
        const val EXTRA_UNLOCK_PACKAGE = "unlockPackage"
        const val EXTRA_UNLOCK_LABEL = "unlockLabel"
    }
}
