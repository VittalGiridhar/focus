package com.focus.focus

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock

object ModeNotifications {
    private const val CHANNEL_ACTIVE = "mode_active"
    private const val CHANNEL_ENDED = "mode_ended"
    private const val ACCENT = 0xFF3CF0DC.toInt()

    private fun activeId(id: String) = 2000 + (id.hashCode() and 0x3FFF)
    private fun endedId(id: String) = 20000 + (id.hashCode() and 0x3FFF)

    private fun manager(context: Context): NotificationManager {
        val m = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        m.createNotificationChannel(
            NotificationChannel(CHANNEL_ACTIVE, "Active blocks", NotificationManager.IMPORTANCE_LOW)
                .apply { description = "Shows the time left in a running block" }
        )
        m.createNotificationChannel(
            NotificationChannel(CHANNEL_ENDED, "Block ended", NotificationManager.IMPORTANCE_DEFAULT)
                .apply { description = "Tells you when a block has finished" }
        )
        return m
    }

    private fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
        context, 0,
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    fun postActive(context: Context, mode: ActiveMode, remainingMs: Long) {
        val endsAt = System.currentTimeMillis() + remainingMs
        val n = Notification.Builder(context, CHANNEL_ACTIVE)
            .setSmallIcon(R.drawable.ic_stat_focus)
            .setContentTitle("${mode.name} is on")
            .setContentText("Selected apps are paused until it ends")
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(endsAt)
            .setShowWhen(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setTimeoutAfter(remainingMs)
            .setContentIntent(openApp(context))
            .build()
        try {
            manager(context).notify(activeId(mode.id), n)
        } catch (_: SecurityException) {
            // Notification permission denied; the block itself still runs.
        }
    }

    fun postGrant(context: Context, grant: ActiveMode, remainingMs: Long) {
        val n = Notification.Builder(context, CHANNEL_ACTIVE)
            .setSmallIcon(R.drawable.ic_stat_focus)
            .setColor(ACCENT)
            .setContentTitle("${grant.name} unlocked")
            .setContentText("Your partner allowed a short break. It locks again when the timer ends.")
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(System.currentTimeMillis() + remainingMs)
            .setShowWhen(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setTimeoutAfter(remainingMs)
            .setContentIntent(openApp(context))
            .build()
        try {
            manager(context).notify(activeId(grant.id), n)
        } catch (_: SecurityException) {
        }
    }

    fun postEnded(context: Context, mode: ActiveMode) {
        val n = Notification.Builder(context, CHANNEL_ENDED)
            .setSmallIcon(R.drawable.ic_stat_focus)
            .setContentTitle("${mode.name} has ended")
            .setContentText("Your apps are available again.")
            .setAutoCancel(true)
            .setContentIntent(openApp(context))
            .build()
        try {
            manager(context).notify(endedId(mode.id), n)
        } catch (_: SecurityException) {
        }
    }

    fun cancelActive(context: Context, id: String) = manager(context).cancel(activeId(id))
}

object ModeScheduler {
    private const val ACTION = "com.focus.focus.MODE_END"

    private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, 1,
        Intent(context, ModeEndReceiver::class.java).setAction(ACTION),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    /**
     * One alarm for the soonest end. Inexact on purpose: it needs no special
     * permission, and blocking itself is checked against real time.
     */
    fun scheduleNext(context: Context) {
        val store = ModeStore(context)
        val next = store.active().minOfOrNull { store.remainingMs(it) }
        if (next == null) {
            cancel(context)
            return
        }
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.setAndAllowWhileIdle(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + next,
            pending(context),
        )
    }

    fun cancel(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending(context))
    }
}
