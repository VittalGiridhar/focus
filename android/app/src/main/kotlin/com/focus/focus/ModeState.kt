package com.focus.focus

/**
 * A running block (a named mode or a quick block). The end is tracked on the
 * monotonic clock ([endElapsedMs]) so changing the phone's date or time cannot
 * shorten or extend it. After a reboot the monotonic clock restarts, so we fall
 * back to the wall-clock end, capped at the original duration so a changed
 * clock still cannot extend the block.
 */
data class ActiveMode(
    val id: String,
    val name: String,
    val packages: Set<String>,
    val startedAtWallMs: Long,
    val endsAtWallMs: Long,
    val endElapsedMs: Long,
    val bootCount: Int,
) {
    val durationMs: Long get() = (endsAtWallMs - startedAtWallMs).coerceAtLeast(0)

    fun remainingMs(nowWallMs: Long, nowElapsedMs: Long, currentBootCount: Int): Long {
        val sameBoot = bootCount >= 0 && bootCount == currentBootCount
        val remaining = if (sameBoot) endElapsedMs - nowElapsedMs else endsAtWallMs - nowWallMs
        return remaining.coerceIn(0, durationMs)
    }

    /** Re-anchors the monotonic end after a reboot so later checks are clock-proof again. */
    fun reanchored(nowWallMs: Long, nowElapsedMs: Long, currentBootCount: Int): ActiveMode {
        val remaining = remainingMs(nowWallMs, nowElapsedMs, currentBootCount)
        return copy(endElapsedMs = nowElapsedMs + remaining, bootCount = currentBootCount)
    }

    fun blocks(packageName: String) = packageName in packages
}

object ModeCodec {
    private const val SEP = '\t'

    private fun clean(s: String) = s.replace('\t', ' ').replace('\n', ' ').replace('\r', ' ')

    fun encode(m: ActiveMode): String = listOf(
        clean(m.id),
        clean(m.name),
        m.packages.joinToString(","),
        m.startedAtWallMs,
        m.endsAtWallMs,
        m.endElapsedMs,
        m.bootCount,
    ).joinToString(SEP.toString())

    fun decode(text: String): ActiveMode? {
        val p = text.split(SEP)
        if (p.size != 7 || p[0].isEmpty()) return null
        val started = p[3].toLongOrNull() ?: return null
        val ends = p[4].toLongOrNull() ?: return null
        val endElapsed = p[5].toLongOrNull() ?: return null
        val boot = p[6].toIntOrNull() ?: return null
        if (ends <= started) return null
        val packages = p[2].split(',').filter { it.isNotEmpty() }.toSet()
        if (packages.isEmpty()) return null
        return ActiveMode(p[0], p[1], packages, started, ends, endElapsed, boot)
    }

    fun encodeAll(modes: List<ActiveMode>): String = modes.joinToString("\n") { encode(it) }

    /** Corrupt lines are dropped individually so one bad entry cannot lose the others. */
    fun decodeAll(text: String): List<ActiveMode> =
        text.lineSequence().mapNotNull { decode(it) }.toList()
}
