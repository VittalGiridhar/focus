package com.focus.focus

import android.app.Activity
import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class UsageChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val context: Context = activity.applicationContext
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingNotificationResult: MethodChannel.Result? = null
    private val store = LimitStore(context)
    private val modeStore = ModeStore(context)
    private val reader = UsageReader(context)
    private val protectedApps = ProtectedApps(context)

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "usageAccessGranted" -> result.success(hasUsageAccess())
            "openUsageAccessSettings" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            "accessibilityEnabled" -> result.success(isAccessibilityEnabled())
            "openAccessibilitySettings" -> {
                openAccessibilitySettings()
                result.success(null)
            }
            "syncLimits" -> {
                val raw = call.argument<List<Map<String, Any?>>>("limits")
                    ?: return result.error("BAD_ARGS", "limits required", null)
                store.save(raw.mapNotNull(::parseLimit))
                result.success(null)
            }
            "syncQuietHours" -> {
                val start = call.argument<Int>("startMinute")
                val end = call.argument<Int>("endMinute")
                val enabled = call.argument<Boolean>("enabled")
                if (start == null || end == null || enabled == null ||
                    start !in 0..1439 || end !in 0..1439
                ) {
                    return result.error("BAD_ARGS", "valid enabled/startMinute/endMinute required", null)
                }
                store.saveQuiet(QuietHours(enabled, start, end))
                result.success(null)
            }
            "eraseAllData" -> {
                if (isLocked()) return result.error("LOCKED", "Locked while a block is active", null)
                modeStore.all().forEach { ModeNotifications.cancelActive(context, it.id) }
                modeStore.clear()
                ModeScheduler.cancel(context)
                store.clearAll()
                result.success(null)
            }
            "notificationsGranted" -> result.success(notificationsGranted())
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "activeModes" -> result.success(modeStore.active().map(::modeMap))
            "startMode" -> startMode(call, result)
            "grantAccess" -> {
                val pkg = call.argument<String>("packageName")
                val label = call.argument<String>("label") ?: pkg
                val durationMs = call.argument<Number>("durationMs")?.toLong()
                if (pkg.isNullOrBlank() || label == null || durationMs == null ||
                    durationMs < MIN_MODE_MS || durationMs > Grants.MAX_MS
                ) {
                    return result.error("BAD_ARGS", "packageName and a 1-60 minute duration required", null)
                }
                result.success(modeMap(Grants.grant(context, pkg, label, durationMs), grantStore))
            }
            "activeGrants" -> result.success(grantStore.active().map { modeMap(it, grantStore) })
            "removeFromBlocks" -> {
                val pkg = call.argument<String>("packageName")
                    ?: return result.error("BAD_ARGS", "packageName required", null)
                Grants.removeFromBlocks(context, pkg)
                result.success(null)
            }
            "setPartnerConfigured" -> {
                store.setPartnerConfigured(call.argument<Boolean>("configured") == true)
                result.success(null)
            }
            "takeUnlockRequest" -> {
                val pending = pendingUnlock
                pendingUnlock = null
                result.success(pending?.let { mapOf("packageName" to it.first, "label" to it.second) })
            }
            "sendUnlockRequest" -> {
                val number = call.argument<String>("number")
                val body = call.argument<String>("body")
                val via = call.argument<String>("via")
                if (number.isNullOrBlank() || body == null) {
                    return result.error("BAD_ARGS", "number and body required", null)
                }
                result.success(sendRequest(number, body, via == "whatsapp"))
            }
            "uninstallProtectionEnabled" -> result.success(dpm.isAdminActive(adminComponent))
            "requestUninstallProtection" -> {
                activity.startActivity(
                    Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                        .putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                        .putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "Makes Focus harder to uninstall while your blocks are running. " +
                                "It gives Focus no other powers."
                        )
                )
                result.success(null)
            }
            "removeUninstallProtection" -> {
                if (isLocked()) return result.error("LOCKED", "Locked while a block is active", null)
                dpm.removeActiveAdmin(adminComponent)
                result.success(null)
            }
            "installedApps" -> async(result) { installedApps() }
            "appIcon" -> {
                val pkg = call.argument<String>("packageName")
                    ?: return result.error("BAD_ARGS", "packageName required", null)
                async(result) { appIcon(pkg) }
            }
            "usageSessions" -> {
                val since = call.argument<Number>("sinceMs")?.toLong()
                val until = call.argument<Number>("untilMs")?.toLong()
                if (since == null || until == null || until <= since) {
                    return result.error("BAD_ARGS", "valid sinceMs/untilMs required", null)
                }
                if (!hasUsageAccess()) {
                    return result.error("NO_PERMISSION", "Usage access not granted", null)
                }
                async(result) { usageSessions(since, until) }
            }
            else -> result.notImplemented()
        }
    }

    private val adminComponent = ComponentName(context, FocusDeviceAdminReceiver::class.java)
    private val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val lockInfo = LockInfo(store, modeStore, reader)

    private val grantStore = Grants.store(context)

    /** Set by [MainActivity] when the block screen's "Ask partner to unlock" opens the app. */
    var pendingUnlock: Pair<String, String>? = null

    private fun isLocked(): Boolean = lockInfo.lockedUntil(System.currentTimeMillis()) != null

    private fun modeMap(m: ActiveMode, from: ModeStore = modeStore): Map<String, Any> = mapOf(
        "id" to m.id,
        "name" to m.name,
        "packages" to m.packages.toList(),
        "endsAtMs" to System.currentTimeMillis() + from.remainingMs(m),
    )

    /**
     * Opens the user's own SMS or WhatsApp with the request pre-filled to the partner.
     * Focus never sends messages itself, so it needs no SMS permission.
     */
    private fun sendRequest(number: String, body: String, whatsapp: Boolean): Boolean {
        val intent = if (whatsapp) {
            val digits = number.filter { it.isDigit() }
            Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$digits?text=${Uri.encode(body)}"))
        } else {
            Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:${Uri.encode(number)}")).putExtra("sms_body", body)
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    // There is deliberately no way to end a block early: that is what makes it a commitment.
    private fun startMode(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")?.trim()
        val name = call.argument<String>("name")?.trim()
        val packages = call.argument<List<String>>("packages")?.filter { it.isNotBlank() }?.toSet()
        val durationMs = call.argument<Number>("durationMs")?.toLong()
        if (id.isNullOrEmpty() || name.isNullOrEmpty() || packages.isNullOrEmpty() ||
            durationMs == null || durationMs < MIN_MODE_MS || durationMs > MAX_MODE_MS
        ) {
            return result.error("BAD_ARGS", "id, name, packages and a 1 minute to 24 hour duration required", null)
        }
        val existing = modeStore.find(id)
        if (existing != null && modeStore.remainingMs(existing) > 0) {
            return result.error("MODE_ACTIVE", "This block is already running", null)
        }
        val blockable = packages.filterNot { protectedApps.isProtected(it) }.toSet()
        if (blockable.isEmpty()) return result.error("BAD_ARGS", "No blockable apps selected", null)

        val wall = System.currentTimeMillis()
        val elapsed = SystemClock.elapsedRealtime()
        val mode = ActiveMode(
            id = id,
            name = name,
            packages = blockable,
            startedAtWallMs = wall,
            endsAtWallMs = wall + durationMs,
            endElapsedMs = elapsed + durationMs,
            bootCount = DeviceClock.bootCount(context),
        )
        modeStore.save(mode)
        ModeScheduler.scheduleNext(context)
        ModeNotifications.postActive(context, mode, durationMs)
        result.success(modeMap(mode))
    }

    private fun notificationsGranted(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        }
        return (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .areNotificationsEnabled()
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (notificationsGranted() || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return result.success(notificationsGranted())
        }
        if (pendingNotificationResult != null) {
            return result.error("IN_PROGRESS", "Permission request already running", null)
        }
        pendingNotificationResult = result
        activity.requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST_NOTIFICATIONS) return
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingNotificationResult?.success(granted)
        pendingNotificationResult = null
    }

    private fun parseLimit(m: Map<String, Any?>): AppLimit? {
        val pkg = m["packageName"] as? String ?: return null
        val minutes = (m["limitMinutes"] as? Number)?.toLong() ?: return null
        if (minutes <= 0) return null
        return AppLimit(
            packageName = pkg,
            label = m["label"] as? String ?: pkg,
            limitMs = minutes * 60_000L,
            enabled = m["enabled"] as? Boolean ?: true,
        )
    }

    private fun async(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("NATIVE_ERROR", e.javaClass.simpleName, null) }
            }
        }
    }

    private fun hasUsageAccess(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName
            )
        }
        return if (mode == AppOpsManager.MODE_DEFAULT) {
            context.checkCallingOrSelfPermission(android.Manifest.permission.PACKAGE_USAGE_STATS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            mode == AppOpsManager.MODE_ALLOWED
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val mine = ComponentName(context, FocusAccessibilityService::class.java)
        return enabled.split(':').any {
            ComponentName.unflattenFromString(it) == mine
        }
    }

    private fun openUsageAccessSettings() {
        val withPackage = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            .setData(Uri.parse("package:${context.packageName}"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(withPackage)
        } catch (e: Exception) {
            context.startActivity(
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
    }

    private fun openAccessibilitySettings() {
        context.startActivity(
            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    private fun installedApps(): List<Map<String, String>> {
        val pm = context.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(launcher, 0)
            .asSequence()
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .filter { !protectedApps.isProtected(it.first) }
            .distinctBy { it.first }
            .sortedBy { it.second.lowercase() }
            .map { mapOf("packageName" to it.first, "label" to it.second) }
            .toList()
    }

    private fun appIcon(packageName: String): ByteArray? {
        return try {
            val drawable = context.packageManager.getApplicationIcon(packageName)
            val size = 96
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            ByteArrayOutputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                it.toByteArray()
            }
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun usageSessions(sinceMs: Long, untilMs: Long): List<Map<String, Any>> =
        reader.sessions(sinceMs, untilMs).map {
            mapOf(
                "packageName" to it.packageName,
                "startMs" to it.start,
                "endMs" to it.end,
            )
        }

    companion object {
        const val CHANNEL = "com.focus.focus/usage"
        private const val REQUEST_NOTIFICATIONS = 4201
        private const val MIN_MODE_MS = 60_000L
        private const val MAX_MODE_MS = 24L * 60 * 60 * 1000
    }
}
