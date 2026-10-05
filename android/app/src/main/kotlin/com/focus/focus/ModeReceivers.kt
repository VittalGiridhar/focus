package com.focus.focus

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock

object ModeRestorer {
    /** Finishes expired blocks, and re-arms the alarm and notifications for running ones. */
    fun restore(context: Context) {
        val store = ModeStore(context)
        for (mode in store.all()) {
            val remaining = store.remainingMs(mode)
            if (remaining <= 0) {
                finish(context, store, mode)
            } else {
                val anchored = mode.reanchored(
                    System.currentTimeMillis(), SystemClock.elapsedRealtime(), DeviceClock.bootCount(context)
                )
                store.save(anchored)
                ModeNotifications.postActive(context, anchored, remaining)
            }
        }
        ModeScheduler.scheduleNext(context)
    }

    fun finish(context: Context, store: ModeStore, mode: ActiveMode) {
        store.remove(mode.id)
        ModeNotifications.cancelActive(context, mode.id)
        ModeNotifications.postEnded(context, mode)
    }
}

class ModeEndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val store = ModeStore(context)
        store.all().filter { store.remainingMs(it) <= 0 }.forEach {
            ModeRestorer.finish(context, store, it)
        }
        // Also covers an alarm that fired early: wait for the next real end.
        ModeScheduler.scheduleNext(context)
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> ModeRestorer.restore(context)
        }
    }
}
