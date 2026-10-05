package com.focus.focus

import java.time.Instant
import java.time.ZoneId

data class AppLimit(
    val packageName: String,
    val label: String,
    val limitMs: Long,
    val enabled: Boolean,
)

/** Plain-text codec so limits can be stored and unit tested without org.json. */
object LimitCodec {
    private const val SEP = '\t'

    fun encode(limits: List<AppLimit>): String = limits.joinToString("\n") {
        listOf(clean(it.packageName), clean(it.label), it.limitMs, it.enabled).joinToString(SEP.toString())
    }

    fun decode(text: String): List<AppLimit> = text.lineSequence().mapNotNull { line ->
        val parts = line.split(SEP)
        if (parts.size != 4) return@mapNotNull null
        val ms = parts[2].toLongOrNull() ?: return@mapNotNull null
        if (parts[0].isEmpty() || ms <= 0) return@mapNotNull null
        AppLimit(parts[0], parts[1], ms, parts[3] == "true")
    }.toList()

    private fun clean(s: String) = s.replace('\t', ' ').replace('\n', ' ').replace('\r', ' ')
}

sealed interface Decision {
    object Block : Decision
    data class Allow(val remainingMs: Long) : Decision
}

object Enforcement {
    fun decide(limitMs: Long, usedMs: Long): Decision =
        if (usedMs >= limitMs) Decision.Block else Decision.Allow(limitMs - usedMs)
}

/** A daily wind-down window in local minutes-of-day; may wrap past midnight. */
data class QuietHours(val enabled: Boolean, val startMinute: Int, val endMinute: Int) {
    fun isActive(minuteOfDay: Int): Boolean {
        if (!enabled || startMinute == endMinute) return false
        return if (startMinute < endMinute) {
            minuteOfDay in startMinute until endMinute
        } else {
            minuteOfDay >= startMinute || minuteOfDay < endMinute
        }
    }

    fun isActiveAt(nowMs: Long, zone: ZoneId = ZoneId.systemDefault()): Boolean {
        val t = Instant.ofEpochMilli(nowMs).atZone(zone)
        return isActive(t.hour * 60 + t.minute)
    }

    /** When the current window ends. Only meaningful while [isActiveAt] is true. */
    fun endsAtMs(nowMs: Long, zone: ZoneId = ZoneId.systemDefault()): Long {
        val now = Instant.ofEpochMilli(nowMs).atZone(zone)
        var end = now.toLocalDate().atTime(endMinute / 60, endMinute % 60).atZone(zone)
        if (!end.isAfter(now)) end = end.plusDays(1)
        return end.toInstant().toEpochMilli()
    }

    companion object {
        val OFF = QuietHours(false, 0, 0)
    }
}

object DayWindow {
    fun startOfDay(nowMs: Long, zone: ZoneId = ZoneId.systemDefault()): Long =
        Instant.ofEpochMilli(nowMs).atZone(zone).toLocalDate().atStartOfDay(zone).toInstant().toEpochMilli()

    /** Calendar arithmetic, so DST days (23h/25h) roll over at the right local midnight. */
    fun nextReset(nowMs: Long, zone: ZoneId = ZoneId.systemDefault()): Long =
        Instant.ofEpochMilli(nowMs).atZone(zone).toLocalDate().plusDays(1)
            .atStartOfDay(zone).toInstant().toEpochMilli()
}
