package com.focus.focus

import android.content.Context
import android.os.SystemClock
import android.provider.Settings

object DeviceClock {
    fun bootCount(context: Context): Int =
        Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, -1)
}

/** Persists running blocks (or partner grants) so they survive process death and reboots. */
class ModeStore(private val context: Context, file: String = FILE) {
    private val prefs = context.applicationContext.getSharedPreferences(file, Context.MODE_PRIVATE)

    /** Every stored block, including ones that have expired but not yet been finished. */
    fun all(): List<ActiveMode> = ModeCodec.decodeAll(prefs.getString(KEY, "") ?: "")

    private fun write(modes: List<ActiveMode>) {
        prefs.edit().putString(KEY, ModeCodec.encodeAll(modes)).apply()
    }

    fun save(mode: ActiveMode) = write(all().filter { it.id != mode.id } + mode)

    fun remove(id: String) = write(all().filter { it.id != id })

    fun clear() {
        prefs.edit().remove(KEY).apply()
    }

    fun find(id: String): ActiveMode? = all().firstOrNull { it.id == id }

    fun remainingMs(mode: ActiveMode): Long = mode.remainingMs(
        System.currentTimeMillis(), SystemClock.elapsedRealtime(), DeviceClock.bootCount(context)
    )

    /** Entries that are still running. Expired ones are left for the end receiver to finish. */
    fun active(): List<ActiveMode> = all().filter { remainingMs(it) > 0 }

    /** Drops expired entries (used for grants, which need no "ended" handling). */
    fun prune() = write(active())

    companion object {
        const val FILE = "focus_mode"
        const val GRANTS_FILE = "focus_grants"
        private const val KEY = "active_modes"
    }
}
