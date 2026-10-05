package com.focus.focus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId
import java.time.ZonedDateTime

class QuietHoursTest {
    private val zone = ZoneId.of("Asia/Kolkata")
    private fun at(h: Int, m: Int = 0, day: Int = 10) =
        ZonedDateTime.of(2026, 3, day, h, m, 0, 0, zone).toInstant().toEpochMilli()

    private val overnight = QuietHours(true, 22 * 60, 7 * 60)
    private val daytime = QuietHours(true, 13 * 60, 14 * 60)

    @Test
    fun overnightWindowWrapsPastMidnight() {
        assertTrue(overnight.isActiveAt(at(23), zone))
        assertTrue(overnight.isActiveAt(at(0, 30), zone))
        assertTrue(overnight.isActiveAt(at(6, 59), zone))
        assertFalse(overnight.isActiveAt(at(7), zone))
        assertFalse(overnight.isActiveAt(at(12), zone))
        assertFalse(overnight.isActiveAt(at(21, 59), zone))
        assertTrue(overnight.isActiveAt(at(22), zone))
    }

    @Test
    fun sameDayWindowIncludesStartExcludesEnd() {
        assertFalse(daytime.isActiveAt(at(12, 59), zone))
        assertTrue(daytime.isActiveAt(at(13), zone))
        assertTrue(daytime.isActiveAt(at(13, 59), zone))
        assertFalse(daytime.isActiveAt(at(14), zone))
    }

    @Test
    fun disabledOrEmptyWindowIsNeverActive() {
        assertFalse(QuietHours(false, 22 * 60, 7 * 60).isActiveAt(at(23), zone))
        assertFalse(QuietHours(true, 600, 600).isActiveAt(at(10), zone))
        assertFalse(QuietHours.OFF.isActiveAt(at(3), zone))
    }

    @Test
    fun endsAtTomorrowMorningWhenStartedTonight() {
        assertEquals(at(7, 0, day = 11), overnight.endsAtMs(at(23), zone))
    }

    @Test
    fun endsAtTodayMorningWhenPastMidnight() {
        assertEquals(at(7, 0, day = 10), overnight.endsAtMs(at(3), zone))
    }

    @Test
    fun sameDayWindowEndsToday() {
        assertEquals(at(14), daytime.endsAtMs(at(13, 15), zone))
    }
}
