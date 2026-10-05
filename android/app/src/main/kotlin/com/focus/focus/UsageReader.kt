package com.focus.focus

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context

class UsageReader(private val context: Context) {
    private val manager =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    /** Foreground sessions in [sinceMs, untilMs], optionally for a single package. */
    fun sessions(sinceMs: Long, untilMs: Long, onlyPackage: String? = null): List<Session> {
        // Look back so sessions already open at the window start are not missed.
        val events = manager.queryEvents(sinceMs - LOOKBACK_MS, untilMs)
        val collected = ArrayList<UsageEvent>()
        val e = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            val type = e.eventType
            val relevant = type == SessionBuilder.ACTIVITY_RESUMED ||
                type == SessionBuilder.ACTIVITY_PAUSED ||
                type == SessionBuilder.SCREEN_NON_INTERACTIVE
            if (!relevant) continue
            val pkg = e.packageName ?: ""
            if (onlyPackage != null && type != SessionBuilder.SCREEN_NON_INTERACTIVE && pkg != onlyPackage) continue
            collected.add(UsageEvent(pkg, type, e.timeStamp))
        }
        return SessionBuilder.build(collected, sinceMs, untilMs)
            .filter { it.packageName != context.packageName }
            .filter { onlyPackage == null || it.packageName == onlyPackage }
    }

    fun usedMs(packageName: String, sinceMs: Long, untilMs: Long): Long =
        sessions(sinceMs, untilMs, packageName).sumOf { it.end - it.start }

    private companion object {
        const val LOOKBACK_MS = 6L * 60 * 60 * 1000
    }
}
