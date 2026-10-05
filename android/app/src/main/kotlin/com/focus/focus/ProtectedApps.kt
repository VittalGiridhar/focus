package com.focus.focus

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.telecom.TelecomManager

/**
 * Packages that are never blocked or offered for limiting, so the user always
 * keeps calls, emergency access, Settings (to recover) and their launcher.
 */
class ProtectedApps(private val context: Context) {
    private val protectedSet: Set<String> by lazy { resolve() }

    fun isProtected(packageName: String): Boolean = packageName in protectedSet

    private fun resolve(): Set<String> {
        val pm = context.packageManager
        val result = HashSet<String>(FIXED)
        result.add(context.packageName)
        try {
            (context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)
                ?.defaultDialerPackage?.let(result::add)
        } catch (_: SecurityException) {
        }
        val intents = listOf(
            Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
            Intent(Intent.ACTION_DIAL, Uri.parse("tel:")),
            Intent(Settings.ACTION_SETTINGS),
        )
        for (intent in intents) {
            pm.queryIntentActivities(intent, 0).forEach { result.add(it.activityInfo.packageName) }
        }
        return result
    }

    private companion object {
        val FIXED = setOf(
            "com.android.systemui",
            "com.android.settings",
            "com.android.emergency",
            "com.android.phone",
            "com.android.server.telecom",
            "com.google.android.dialer",
            "com.google.android.apps.safetyhub",
            "com.android.packageinstaller",
            "com.google.android.packageinstaller",
        )
    }
}
