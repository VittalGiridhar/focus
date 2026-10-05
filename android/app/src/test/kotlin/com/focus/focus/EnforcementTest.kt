package com.focus.focus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

class EnforcementTest {
    private val min = 60_000L

    @Test
    fun blocksExactlyAtLimit() {
        assertEquals(Decision.Block, Enforcement.decide(60 * min, 60 * min))
        assertEquals(Decision.Block, Enforcement.decide(60 * min, 61 * min))
    }

    @Test
    fun allowsBelowLimitWithRemaining() {
        assertEquals(Decision.Allow(20 * min), Enforcement.decide(60 * min, 40 * min))
    }

    @Test
    fun codecRoundTrips() {
        val limits = listOf(
            AppLimit("com.a", "Alpha", 30 * min, true),
            AppLimit("com.b", "Beta", 45 * min, false),
        )
        assertEquals(limits, LimitCodec.decode(LimitCodec.encode(limits)))
    }

    @Test
    fun codecSanitizesSeparatorsInLabels() {
        val decoded = LimitCodec.decode(LimitCodec.encode(listOf(AppLimit("com.a", "Al\tpha\nX", min, true))))
        assertEquals("Al pha X", decoded.single().label)
    }

    @Test
    fun codecSkipsCorruptLines() {
        val text = "com.a\tAlpha\t60000\ttrue\ngarbage\ncom.b\tBeta\tnotanumber\ttrue\n\tNoPkg\t5\ttrue\ncom.c\tC\t-5\ttrue"
        assertEquals(listOf("com.a"), LimitCodec.decode(text).map { it.packageName })
    }

    @Test
    fun emptyInputDecodesToNothing() {
        assertTrue(LimitCodec.decode("").isEmpty())
    }

    @Test
    fun dayStartAndNextResetAreLocalMidnights() {
        val zone = ZoneId.of("Asia/Kolkata")
        val now = ZonedDateTime.of(2026, 3, 10, 15, 30, 0, 0, zone).toInstant().toEpochMilli()
        val start = DayWindow.startOfDay(now, zone)
        val reset = DayWindow.nextReset(now, zone)
        assertEquals(ZonedDateTime.of(2026, 3, 10, 0, 0, 0, 0, zone).toInstant().toEpochMilli(), start)
        assertEquals(24 * 60 * min, reset - start)
    }

    @Test
    fun dstSpringForwardDayIs23Hours() {
        val zone = ZoneId.of("America/New_York")
        val now = ZonedDateTime.of(2026, 3, 8, 12, 0, 0, 0, zone).toInstant().toEpochMilli()
        val start = DayWindow.startOfDay(now, zone)
        val reset = DayWindow.nextReset(now, zone)
        assertEquals(23 * 60 * min, reset - start)
    }

    @Test
    fun dstFallBackDayIs25Hours() {
        val zone = ZoneId.of("America/New_York")
        val now = ZonedDateTime.of(2026, 11, 1, 12, 0, 0, 0, zone).toInstant().toEpochMilli()
        assertEquals(25 * 60 * min, DayWindow.nextReset(now, zone) - DayWindow.startOfDay(now, zone))
    }
}
