package com.focus.focus

import android.app.Activity
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.format.DateFormat
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.Date

/** Calm full-screen notice shown over an app that is blocked right now. */
class BlockActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = BG
        window.navigationBarColor = BG

        val pkg = intent.getStringExtra(EXTRA_PACKAGE)
        val label = intent.getStringExtra(EXTRA_LABEL) ?: "this app"
        val limitMs = intent.getLongExtra(EXTRA_LIMIT_MS, 0L)
        val resetAt = intent.getLongExtra(EXTRA_RESET_AT, 0L)
        val modeName = intent.getStringExtra(EXTRA_MODE_NAME)
        val quiet = intent.getBooleanExtra(EXTRA_QUIET, false)
        val locked = intent.getBooleanExtra(EXTRA_LOCKED, false)

        val (hud, title, body) = when {
            locked -> Triple(
                "UNINSTALL PROTECTION",
                "Focus is locked",
                "Focus can't be removed while your blocks are running. You chose this to help you stay on track.",
            )
            quiet -> Triple("QUIET HOURS", "Time to wind down", "$label is resting while you wind down.")
            modeName != null -> Triple("${modeName.uppercase()} · ON", "$label is paused", "It stays closed until this block ends.")
            else -> Triple(
                "DAILY LIMIT",
                "Limit reached",
                "You've used your ${formatDuration(limitMs)} for $label today.",
            )
        }

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(56), dp(28), dp(28))
        }
        column.addView(ring(), LinearLayout.LayoutParams(dp(104), dp(104)))
        column.addView(hudText(hud), spaced(top = 28))
        column.addView(text(title, 30f, FG, light = true), spaced(top = 10))
        column.addView(text(body, 16f, MUTED), spaced(top = 12))
        if (resetAt > 0) {
            val time = DateFormat.getTimeFormat(this).format(Date(resetAt))
            val until = if (locked) "CHANGES ALLOWED AT $time" else "OPENS AGAIN AT $time"
            column.addView(hudText(until, ACCENT), spaced(top = 20))
        }
        column.addView(button("Go back", filled = true) { goHome() }, spaced(top = 36))
        if (pkg != null && !locked && LimitStore(this).partnerConfigured()) {
            column.addView(button("Ask partner to unlock", filled = false) { askPartner(pkg, label) }, spaced(top = 12))
        }
        column.addView(button("Open Focus", filled = false) { openFocus(null, null) }, spaced(top = 12))

        val scroll = ScrollView(this).apply {
            setBackgroundColor(BG)
            isFillViewport = true
            fitsSystemWindows = true
            addView(column, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        }
        setContentView(scroll)
    }

    @Deprecated("Back always returns home so the blocked app is not revealed.")
    override fun onBackPressed() {
        goHome()
    }

    private fun goHome() {
        startActivity(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        finish()
    }

    private fun askPartner(pkg: String, label: String) = openFocus(pkg, label)

    private fun openFocus(pkg: String?, label: String?) {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (pkg != null) {
            intent.putExtra(MainActivity.EXTRA_UNLOCK_PACKAGE, pkg)
            intent.putExtra(MainActivity.EXTRA_UNLOCK_LABEL, label)
        }
        startActivity(intent)
        finish()
    }

    private fun ring(): FrameLayout = FrameLayout(this).apply {
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(ACCENT_DIM)
            setStroke(dp(2), ACCENT)
        }
        addView(
            ImageView(this@BlockActivity).apply {
                setImageResource(R.drawable.ic_stat_focus)
                imageTintList = ColorStateList.valueOf(ACCENT)
            },
            FrameLayout.LayoutParams(dp(44), dp(44), Gravity.CENTER),
        )
    }

    private fun hudText(value: String, color: Int = MUTED) = TextView(this).apply {
        text = value
        typeface = Typeface.MONOSPACE
        letterSpacing = 0.16f
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
        setTextColor(color)
        gravity = Gravity.CENTER
    }

    private fun text(value: String, sp: Float, color: Int, light: Boolean = false) =
        TextView(this).apply {
            text = value
            setTextSize(TypedValue.COMPLEX_UNIT_SP, sp)
            setTextColor(color)
            gravity = Gravity.CENTER
            if (light) typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
        }

    private fun button(label: String, filled: Boolean, onClick: () -> Unit) =
        Button(this).apply {
            text = label
            isAllCaps = false
            stateListAnimator = null
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            minimumHeight = dp(54)
            minHeight = dp(54)
            setTextColor(if (filled) ON_ACCENT else ACCENT)
            background = GradientDrawable().apply {
                cornerRadius = dp(28).toFloat()
                if (filled) setColor(ACCENT) else {
                    setColor(Color.TRANSPARENT)
                    setStroke(dp(1), ACCENT_LINE)
                }
            }
            setOnClickListener { onClick() }
        }

    private fun spaced(top: Int) = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { topMargin = dp(top) }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private fun formatDuration(ms: Long): String {
        val totalMinutes = ms / 60_000
        val h = totalMinutes / 60
        val m = totalMinutes % 60
        return when {
            h == 0L -> "$m min"
            m == 0L -> if (h == 1L) "1 hour" else "$h hours"
            else -> "${h}h ${m}m"
        }
    }

    companion object {
        const val EXTRA_PACKAGE = "package"
        const val EXTRA_LABEL = "label"
        const val EXTRA_MODE_NAME = "modeName"
        const val EXTRA_QUIET = "quiet"
        const val EXTRA_LOCKED = "locked"
        const val EXTRA_LIMIT_MS = "limitMs"
        const val EXTRA_RESET_AT = "resetAt"

        private const val BG = 0xFF07090C.toInt()
        private const val FG = 0xFFE9EEF3.toInt()
        private const val MUTED = 0xFF8A97A6.toInt()
        private const val ACCENT = 0xFF3CF0DC.toInt()
        private const val ACCENT_DIM = 0xFF0E2B29.toInt()
        private const val ACCENT_LINE = 0x733CF0DC
        private const val ON_ACCENT = 0xFF00201D.toInt()
    }
}
