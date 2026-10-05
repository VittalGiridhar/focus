package com.focus.focus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ModeStateTest {
    private val min = 60_000L

    // Started at wall 1_000_000 / elapsed 500_000 on boot #7 for 60 minutes.
    private val mode = ActiveMode(
        id = "m1",
        name = "Deep Work",
        packages = setOf("com.a", "com.b"),
        startedAtWallMs = 1_000_000,
        endsAtWallMs = 1_000_000 + 60 * min,
        endElapsedMs = 500_000 + 60 * min,
        bootCount = 7,
    )

    @Test
    fun remainingUsesMonotonicClockOnSameBoot() {
        assertEquals(40 * min, mode.remainingMs(1_000_000 + 20 * min, 500_000 + 20 * min, 7))
    }

    @Test
    fun changingWallClockForwardDoesNotEndModeEarly() {
        val r = mode.remainingMs(1_000_000 + 24 * 60 * min, 500_000 + 10 * min, 7)
        assertEquals(50 * min, r)
    }

    @Test
    fun changingWallClockBackwardDoesNotExtendMode() {
        val r = mode.remainingMs(1_000_000 - 5 * 60 * min, 500_000 + 30 * min, 7)
        assertEquals(30 * min, r)
    }

    @Test
    fun afterRebootFallsBackToWallClock() {
        assertEquals(25 * min, mode.remainingMs(1_000_000 + 35 * min, 12_345, 8))
    }

    @Test
    fun afterRebootWithClockSetBackIsCappedAtOriginalDuration() {
        val r = mode.remainingMs(1_000_000 - 10 * 60 * min, 1_000, 8)
        assertEquals(60 * min, r)
    }

    @Test
    fun expiredModeHasZeroRemaining() {
        assertEquals(0, mode.remainingMs(0, 500_000 + 90 * min, 7))
        assertEquals(0, mode.remainingMs(1_000_000 + 90 * min, 1, 8))
    }

    @Test
    fun reanchorMakesLaterChecksMonotonic() {
        val re = mode.reanchored(1_000_000 + 35 * min, 2_000, 8)
        assertEquals(8, re.bootCount)
        assertEquals(20 * min, re.remainingMs(1_000_000 + 999 * min, 2_000 + 5 * min, 8))
    }

    @Test
    fun unknownBootCountAlwaysUsesWallClock() {
        val unknown = mode.copy(bootCount = -1)
        assertEquals(40 * min, unknown.remainingMs(1_000_000 + 20 * min, 0, -1))
    }

    @Test
    fun blocksOnlySelectedPackages() {
        assertTrue(mode.blocks("com.a"))
        assertFalse(mode.blocks("com.z"))
    }

    @Test
    fun twoMinuteQuickBlockExpiresAfterTwoMinutes() {
        val quick = ActiveMode("quick-1", "Instagram", setOf("com.ig"), 0, 2 * min, 10_000 + 2 * min, 3)
        assertEquals(2 * min, quick.remainingMs(0, 10_000, 3))
        assertEquals(1 * min, quick.remainingMs(0, 10_000 + 1 * min, 3))
        assertEquals(0, quick.remainingMs(0, 10_000 + 2 * min, 3))
    }

    @Test
    fun codecRoundTrips() {
        assertEquals(mode, ModeCodec.decode(ModeCodec.encode(mode)))
    }

    @Test
    fun codecRejectsCorruptState() {
        assertNull(ModeCodec.decode(""))
        assertNull(ModeCodec.decode("only\tfour\tparts\there"))
        assertNull(ModeCodec.decode("id\tn\tcom.a\tx\t2\t3\t4"))
        assertNull(ModeCodec.decode("id\tn\t\t1\t2\t3\t4"))
        assertNull(ModeCodec.decode("id\tn\tcom.a\t5\t5\t3\t4"))
        assertNull(ModeCodec.decode("\tn\tcom.a\t1\t5\t3\t4"))
    }

    @Test
    fun listCodecKeepsGoodEntriesWhenOneIsCorrupt() {
        val other = mode.copy(id = "m2", name = "Sleep")
        val text = ModeCodec.encodeAll(listOf(mode, other)) + "\ngarbage line"
        assertEquals(listOf(mode, other), ModeCodec.decodeAll(text))
        assertTrue(ModeCodec.decodeAll("").isEmpty())
    }
}
