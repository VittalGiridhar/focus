package com.focus.focus

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UninstallGuardTest {
    private val label = "Focus"
    private val own = "com.focus.focus"

    private fun check(pkg: String, cls: String?, vararg texts: String) =
        UninstallGuard.isProtectedScreen(pkg, cls, texts.toList(), label, own)

    @Test
    fun coversUninstallConfirmationForFocus() {
        assertTrue(check("com.google.android.packageinstaller", "com.android.packageinstaller.UninstallerActivity", "Do you want to uninstall this app?", "Focus"))
        assertTrue(check("com.android.packageinstaller", "com.android.packageinstaller.UninstallerActivity", "Focus"))
    }

    @Test
    fun coversDeviceAdminDeactivationForFocus() {
        assertTrue(check("com.android.settings", "com.android.settings.DeviceAdminAdd", "Focus", "Deactivate this device admin app"))
    }

    @Test
    fun doesNotCoverUninstallOfOtherApps() {
        assertFalse(check("com.google.android.packageinstaller", "com.android.packageinstaller.UninstallerActivity", "Do you want to uninstall this app?", "Calculator"))
    }

    @Test
    fun doesNotCoverOtherSettingsScreens() {
        assertFalse(check("com.android.settings", "com.android.settings.Settings\$WifiSettingsActivity", "Focus"))
        assertFalse(check("com.android.settings", "com.android.settings.Settings\$AccessibilitySettingsActivity", "Focus"))
    }

    @Test
    fun ignoresUnrelatedPackagesAndMissingClass() {
        assertFalse(check("com.instagram.android", "UninstallerActivity", "Focus"))
        assertFalse(check("com.android.settings", null, "Focus"))
    }

    @Test
    fun matchesOnPackageNameWhenLabelIsMissing() {
        assertTrue(check("com.android.packageinstaller", "UninstallerActivity", "package:com.focus.focus"))
    }
}
