package com.focus.focus

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionBuilderTest {
    private val ig = "com.instagram.android"
    private val yt = "com.google.android.youtube"
    private val min = 60_000L

    private fun ev(pkg: String, type: Int, ts: Long) = UsageEvent(pkg, type, ts)

    @Test
    fun simpleSession() {
        val s = SessionBuilder.build(
            listOf(ev(ig, 1, 10 * min), ev(ig, 2, 30 * min)), 0, 100 * min
        )
        assertEquals(listOf(Session(ig, 10 * min, 30 * min)), s)
    }

    @Test
    fun activityTransitionGapIsMerged() {
        val s = SessionBuilder.build(
            listOf(
                ev(ig, 1, 10 * min), ev(ig, 2, 20 * min),
                ev(ig, 1, 20 * min + 500), ev(ig, 2, 30 * min),
            ),
            0, 100 * min,
        )
        assertEquals(listOf(Session(ig, 10 * min, 30 * min)), s)
    }

    @Test
    fun realBreakKeepsSessionsSeparate() {
        val s = SessionBuilder.build(
            listOf(
                ev(ig, 1, 10 * min), ev(ig, 2, 20 * min),
                ev(ig, 1, 60 * min), ev(ig, 2, 100 * min),
            ),
            0, 200 * min,
        )
        assertEquals(2, s.size)
    }

    @Test
    fun screenOffClosesOpenSessions() {
        val s = SessionBuilder.build(
            listOf(ev(ig, 1, 10 * min), ev(ig, 16, 15 * min)), 0, 100 * min
        )
        assertEquals(listOf(Session(ig, 10 * min, 15 * min)), s)
    }

    @Test
    fun stillOpenSessionEndsAtWindowEnd() {
        val s = SessionBuilder.build(listOf(ev(yt, 1, 50 * min)), 0, 80 * min)
        assertEquals(listOf(Session(yt, 50 * min, 80 * min)), s)
    }

    @Test
    fun sessionOpenBeforeWindowIsClamped() {
        val s = SessionBuilder.build(
            listOf(ev(ig, 1, 5 * min), ev(ig, 2, 25 * min)), 10 * min, 100 * min
        )
        assertEquals(listOf(Session(ig, 10 * min, 25 * min)), s)
    }

    @Test
    fun strayPauseWithoutResumeIsIgnored() {
        val s = SessionBuilder.build(listOf(ev(ig, 2, 20 * min)), 0, 100 * min)
        assertTrue(s.isEmpty())
    }

    @Test
    fun unorderedEventsAreSorted() {
        val s = SessionBuilder.build(
            listOf(ev(ig, 2, 30 * min), ev(ig, 1, 10 * min)), 0, 100 * min
        )
        assertEquals(listOf(Session(ig, 10 * min, 30 * min)), s)
    }

    @Test
    fun appsAreTrackedIndependently() {
        val s = SessionBuilder.build(
            listOf(
                ev(ig, 1, 10 * min), ev(ig, 2, 20 * min),
                ev(yt, 1, 20 * min), ev(yt, 2, 50 * min),
            ),
            0, 100 * min,
        )
        assertEquals(setOf(Session(ig, 10 * min, 20 * min), Session(yt, 20 * min, 50 * min)), s.toSet())
    }
}
