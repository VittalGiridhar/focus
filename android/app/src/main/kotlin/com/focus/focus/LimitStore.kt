package com.focus.focus

import android.content.Context

/** Native copy of the user's limits so enforcement works while Flutter is not running. */
class LimitStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun save(limits: List<AppLimit>) {
        prefs.edit().putString(KEY, LimitCodec.encode(limits)).apply()
    }

    fun all(): List<AppLimit> = LimitCodec.decode(prefs.getString(KEY, "") ?: "")

    fun get(packageName: String): AppLimit? = all().firstOrNull { it.packageName == packageName }

    fun saveQuiet(q: QuietHours) {
        prefs.edit()
            .putBoolean(QUIET_ENABLED, q.enabled)
            .putInt(QUIET_START, q.startMinute)
            .putInt(QUIET_END, q.endMinute)
            .apply()
    }

    fun quiet(): QuietHours = QuietHours(
        prefs.getBoolean(QUIET_ENABLED, false),
        prefs.getInt(QUIET_START, 0),
        prefs.getInt(QUIET_END, 0),
    )

    fun setPartnerConfigured(configured: Boolean) {
        prefs.edit().putBoolean(PARTNER, configured).apply()
    }

    fun partnerConfigured(): Boolean = prefs.getBoolean(PARTNER, false)

    fun clearAll() {
        prefs.edit().clear().apply()
    }

    private companion object {
        const val FILE = "focus_limits"
        const val KEY = "limits"
        const val QUIET_ENABLED = "quiet_enabled"
        const val QUIET_START = "quiet_start"
        const val QUIET_END = "quiet_end"
        const val PARTNER = "partner_configured"
    }
}
