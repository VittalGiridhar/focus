package com.focus.focus

import android.accessibilityservice.AccessibilityService
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

/**
 * Detects which app has come to the foreground (package name only; it does not
 * read screen content) and shows [BlockActivity] when that app is blocked by a
 * running block, quiet hours or a used-up daily limit.
 */
class FocusAccessibilityService : AccessibilityService() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var store: LimitStore
    private lateinit var modeStore: ModeStore
    private lateinit var grantStore: ModeStore
    private lateinit var reader: UsageReader
    private lateinit var protectedApps: ProtectedApps
    private lateinit var lockInfo: LockInfo

    private var currentPackage: String? = null
    private var pendingCheck: Runnable? = null
    private var launchable: Set<String> = emptySet()
    private var launchableLoadedAt = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        store = LimitStore(this)
        modeStore = ModeStore(this)
        grantStore = Grants.store(this)
        reader = UsageReader(this)
        protectedApps = ProtectedApps(this)
        lockInfo = LockInfo(store, modeStore, reader)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        // An enforcement failure must never crash the service or the user's current app.
        try {
            handleWindowChange(event)
        } catch (_: RuntimeException) {
        }
    }

    private fun handleWindowChange(event: AccessibilityEvent) {
        val pkg = event.packageName?.toString() ?: return

        if (pkg == packageName) {
            cancelPending()
            currentPackage = pkg
            return
        }
        if (coverUninstallScreen(event, pkg)) return
        // Keyboards, system UI and overlays are not apps the user switched to.
        if (!isLaunchable(pkg)) return

        currentPackage = pkg
        enforce(pkg)
    }

    private fun enforce(pkg: String) {
        cancelPending()
        if (protectedApps.isProtected(pkg)) return

        // A partner-approved break overrides everything until it runs out, then re-checks.
        val grant = grantStore.active().filter { it.blocks(pkg) }.maxByOrNull { grantStore.remainingMs(it) }
        if (grant != null) {
            recheckLater(pkg, grantStore.remainingMs(grant))
            return
        }

        val blocking = modeStore.active().filter { it.blocks(pkg) }
        if (blocking.isNotEmpty()) {
            // Show the block that lasts longest so the user sees the real end time.
            showModeBlock(blocking.maxByOrNull { modeStore.remainingMs(it) }!!, pkg)
            return
        }

        val limit = store.get(pkg)
        if (limit == null || !limit.enabled) return

        val quiet = store.quiet()
        val now = System.currentTimeMillis()
        if (quiet.isActiveAt(now)) {
            showQuietBlock(limit, quiet.endsAtMs(now))
            return
        }

        val used = try {
            reader.usedMs(limit.packageName, DayWindow.startOfDay(now), now)
        } catch (_: SecurityException) {
            return // usage access was revoked; nothing safe to enforce
        }
        when (val decision = Enforcement.decide(limit.limitMs, used)) {
            Decision.Block -> showBlock(limit)
            // Re-check when the allowance should run out. The check recomputes real usage,
            // so a screen-off or switch-away in the meantime cannot cause a wrong block.
            is Decision.Allow -> recheckLater(pkg, decision.remainingMs)
        }
    }

    private fun recheckLater(pkg: String, delayMs: Long) {
        val check = Runnable { if (currentPackage == pkg) enforce(pkg) }
        pendingCheck = check
        handler.postDelayed(check, delayMs.coerceAtLeast(1_000L) + 250L)
    }

    private fun cancelPending() {
        pendingCheck?.let(handler::removeCallbacks)
        pendingCheck = null
    }

    private fun blockIntent(pkg: String?, label: String?): Intent =
        Intent(this, BlockActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
            .putExtra(BlockActivity.EXTRA_PACKAGE, pkg)
            .putExtra(BlockActivity.EXTRA_LABEL, label)

    private fun showBlock(limit: AppLimit) {
        startActivity(
            blockIntent(limit.packageName, limit.label)
                .putExtra(BlockActivity.EXTRA_LIMIT_MS, limit.limitMs)
                .putExtra(BlockActivity.EXTRA_RESET_AT, DayWindow.nextReset(System.currentTimeMillis()))
        )
    }

    private fun showQuietBlock(limit: AppLimit, endsAtMs: Long) {
        startActivity(
            blockIntent(limit.packageName, limit.label)
                .putExtra(BlockActivity.EXTRA_QUIET, true)
                .putExtra(BlockActivity.EXTRA_RESET_AT, endsAtMs)
        )
    }

    private fun showModeBlock(mode: ActiveMode, pkg: String) {
        val label = try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
        } catch (_: Exception) {
            pkg
        }
        startActivity(
            blockIntent(pkg, label)
                .putExtra(BlockActivity.EXTRA_MODE_NAME, mode.name)
                .putExtra(BlockActivity.EXTRA_RESET_AT, System.currentTimeMillis() + modeStore.remainingMs(mode))
        )
    }

    /**
     * Only when the user opted in to uninstall protection (device admin) and a lock is
     * running, cover the screens that would remove Focus. Everything else in Settings
     * stays reachable, so the user is never locked out of their phone.
     */
    private fun coverUninstallScreen(event: AccessibilityEvent, pkg: String): Boolean {
        if (!UninstallGuard.isCandidatePackage(pkg)) return false
        val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
        if (!dpm.isAdminActive(ComponentName(this, FocusDeviceAdminReceiver::class.java))) return false
        val texts = event.text.map { it.toString() }
        val label = applicationInfo.loadLabel(packageManager).toString()
        if (!UninstallGuard.isProtectedScreen(pkg, event.className?.toString(), texts, label, packageName)) {
            return false
        }
        val until = lockInfo.lockedUntil(System.currentTimeMillis()) ?: return false
        startActivity(
            blockIntent(null, null)
                .putExtra(BlockActivity.EXTRA_LOCKED, true)
                .putExtra(BlockActivity.EXTRA_RESET_AT, until)
        )
        return true
    }

    private fun isLaunchable(pkg: String): Boolean {
        val now = System.currentTimeMillis()
        if (pkg in launchable) return true
        // A newly installed app may not be in the cached set yet.
        if (now - launchableLoadedAt > REFRESH_MS) {
            val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            launchable = packageManager.queryIntentActivities(launcher, 0)
                .map { it.activityInfo.packageName }.toSet()
            launchableLoadedAt = now
        }
        return pkg in launchable
    }

    override fun onInterrupt() {
        cancelPending()
    }

    override fun onUnbind(intent: Intent?): Boolean {
        cancelPending()
        return super.onUnbind(intent)
    }

    private companion object {
        const val REFRESH_MS = 30_000L
    }
}
