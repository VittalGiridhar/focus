package com.focus.focus

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/** Device-admin receiver with no policies; it only makes uninstalling a deliberate extra step. */
class FocusDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence =
        "Turning this off lets Focus be uninstalled and ends its protection while your blocks run."
}

/**
 * Recognises the system screens that would remove Focus or its device-admin
 * status. Pure so it can be unit tested; it is only a best-effort match because
 * screen class names and texts differ between phone makers.
 */
object UninstallGuard {
    private val INSTALLERS = setOf(
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
    )
    private const val SETTINGS = "com.android.settings"

    fun isCandidatePackage(packageName: String) =
        packageName in INSTALLERS || packageName == SETTINGS

    fun isProtectedScreen(
        packageName: String,
        className: String?,
        texts: List<String>,
        appLabel: String,
        ownPackage: String,
    ): Boolean {
        if (!isCandidatePackage(packageName) || className == null) return false
        val mentionsUs = texts.any { it.contains(appLabel, ignoreCase = true) || it.contains(ownPackage) }
        if (!mentionsUs) return false
        return when (packageName) {
            SETTINGS -> className.contains("DeviceAdminAdd")
            else -> className.contains("Uninstall", ignoreCase = true)
        }
    }
}
