package com.focus.focus

import android.content.Context
import android.os.SystemClock

/**
 * Partner-approved temporary access. A grant reuses [ActiveMode] (monotonic end,
 * reboot-safe) but lives in its own store, and simply expires; when it does, the
 * accessibility service re-checks the app and blocks it again if needed.
 */
object Grants {
    const val MAX_MS = 60L * 60 * 1000

    fun store(context: Context) = ModeStore(context, ModeStore.GRANTS_FILE)

    fun grant(context: Context, packageName: String, label: String, durationMs: Long): ActiveMode {
        val store = store(context)
        store.prune()
        val wall = System.currentTimeMillis()
        val grant = ActiveMode(
            id = "grant-$packageName",
            name = label,
            packages = setOf(packageName),
            startedAtWallMs = wall,
            endsAtWallMs = wall + durationMs,
            endElapsedMs = SystemClock.elapsedRealtime() + durationMs,
            bootCount = DeviceClock.bootCount(context),
        )
        store.save(grant)
        ModeNotifications.postGrant(context, grant, durationMs)
        return grant
    }

    /** Takes [packageName] out of every running block; a block left with no apps ends. */
    fun removeFromBlocks(context: Context, packageName: String) {
        val modes = ModeStore(context)
        for (mode in modes.active().filter { it.blocks(packageName) }) {
            val rest = mode.packages - packageName
            if (rest.isEmpty()) {
                ModeRestorer.finish(context, modes, mode)
            } else {
                modes.save(mode.copy(packages = rest))
            }
        }
        ModeScheduler.scheduleNext(context)
    }
}
