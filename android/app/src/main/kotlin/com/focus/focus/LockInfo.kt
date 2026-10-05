package com.focus.focus

/**
 * Answers "is the user currently committed?" - true while a block is running, quiet
 * hours are active for limited apps, or any limited app has used up its allowance.
 */
class LockInfo(
    private val limits: LimitStore,
    private val modes: ModeStore,
    private val reader: UsageReader,
) {
    /** Epoch ms when the longest-running lock ends, or null when nothing is locked. */
    fun lockedUntil(nowMs: Long): Long? {
        var until: Long? = null
        fun bump(t: Long) {
            until = maxOf(until ?: t, t)
        }

        modes.active().forEach { bump(nowMs + modes.remainingMs(it)) }

        val enabledLimits = limits.all().filter { it.enabled }
        val quiet = limits.quiet()
        if (enabledLimits.isNotEmpty() && quiet.isActiveAt(nowMs)) bump(quiet.endsAtMs(nowMs))

        try {
            val dayStart = DayWindow.startOfDay(nowMs)
            for (limit in enabledLimits) {
                if (reader.usedMs(limit.packageName, dayStart, nowMs) >= limit.limitMs) {
                    bump(DayWindow.nextReset(nowMs))
                    break
                }
            }
        } catch (_: SecurityException) {
            // Usage access revoked: limits cannot be evaluated, so they do not count as a lock.
        }
        return until
    }
}
