package com.focus.focus

data class UsageEvent(val packageName: String, val type: Int, val timestamp: Long)

data class Session(val packageName: String, val start: Long, val end: Long)

/**
 * Turns raw UsageStatsManager foreground/background events into foreground
 * sessions. Pure and Android-free so it can be unit tested on the JVM.
 */
object SessionBuilder {
    const val ACTIVITY_RESUMED = 1
    const val ACTIVITY_PAUSED = 2
    const val SCREEN_NON_INTERACTIVE = 16

    /** Pause->resume gaps shorter than this are activity transitions, not real breaks. */
    const val MERGE_GAP_MS = 1500L

    fun build(events: List<UsageEvent>, windowStart: Long, windowEnd: Long): List<Session> {
        val open = HashMap<String, Long>()
        val out = ArrayList<Session>()
        val lastIndex = HashMap<String, Int>()

        fun add(pkg: String, start: Long, end: Long) {
            if (end <= start) return
            val idx = lastIndex[pkg]
            if (idx != null && start - out[idx].end <= MERGE_GAP_MS) {
                out[idx] = out[idx].copy(end = maxOf(out[idx].end, end))
            } else {
                out.add(Session(pkg, start, end))
                lastIndex[pkg] = out.size - 1
            }
        }

        fun close(pkg: String, end: Long) {
            val start = open.remove(pkg) ?: return
            add(pkg, start, end)
        }

        for (e in events.sortedBy { it.timestamp }) {
            when (e.type) {
                ACTIVITY_RESUMED -> if (!open.containsKey(e.packageName)) open[e.packageName] = e.timestamp
                ACTIVITY_PAUSED -> close(e.packageName, e.timestamp)
                SCREEN_NON_INTERACTIVE -> open.keys.toList().forEach { close(it, e.timestamp) }
            }
        }
        open.keys.toList().forEach { close(it, windowEnd) }

        return out.mapNotNull {
            val s = maxOf(it.start, windowStart)
            val e = minOf(it.end, windowEnd)
            if (e > s) Session(it.packageName, s, e) else null
        }
    }
}
