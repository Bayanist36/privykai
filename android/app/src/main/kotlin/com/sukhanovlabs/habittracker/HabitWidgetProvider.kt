package com.sukhanovlabs.habittracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Renders today's habit progress on the launcher (design/WIDGET_SPEC_v1.0.md).
 *
 * The widget is read-only: Flutter pushes the snapshot into the shared
 * preferences of the `home_widget` plugin and this provider turns it into
 * `RemoteViews`. A tap opens MainActivity on the Today tab.
 */
class HabitWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED,
            -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids =
                    manager.getAppWidgetIds(
                        ComponentName(context, HabitWidgetProvider::class.java),
                    )
                ids.forEach { updateWidget(context, manager, it) }
            }
        }
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        try {
            val prefs =
                context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            val total = prefs.getInt(KEY_TOTAL, 0).coerceAtLeast(0)
            val completed =
                prefs.getInt(KEY_COMPLETED, 0).coerceIn(0, total)
            val pendingLabel =
                prefs.getString(KEY_PENDING, null) ?: "Добавьте первую"
            val savedDate = prefs.getString(KEY_DATE, null).orEmpty()
            val savedState = prefs.getString(KEY_STATE, null).orEmpty()
            val topName = prefs.getString(KEY_TOP_NAME, null).orEmpty()
            val topStreak = prefs.getInt(KEY_TOP_STREAK, 0).coerceAtLeast(0)
            val items = parseItems(prefs.getString(KEY_ITEMS, null))

            val stale = savedDate.isNotEmpty() && savedDate != todayKey()
            val state =
                when {
                    stale -> STATE_STALE
                    total == 0 -> STATE_EMPTY
                    completed >= total -> STATE_DONE
                    savedState == STATE_STREAK || topStreak >= STREAK_THRESHOLD ->
                        STATE_STREAK
                    else -> STATE_ACTIVE
                }

            val options = manager.getAppWidgetOptions(widgetId)
            val wide =
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) >=
                    WIDE_MIN_WIDTH_DP
            val views =
                if (wide) {
                    buildWide(
                        context = context,
                        state = state,
                        completed = completed,
                        total = total,
                        pendingLabel = pendingLabel,
                        topName = topName,
                        topStreak = topStreak,
                        items = items,
                    )
                } else {
                    buildCompact(
                        context = context,
                        state = state,
                        completed = completed,
                        total = total,
                        topName = topName,
                        topStreak = topStreak,
                    )
                }
            manager.updateAppWidget(widgetId, views)
        } catch (error: Exception) {
            // Keep the last valid snapshot: never show made-up zeros.
            Log.w(TAG, "Could not render the habit widget")
        }
    }

    private fun buildCompact(
        context: Context,
        state: String,
        completed: Int,
        total: Int,
        topName: String,
        topStreak: Int,
    ): RemoteViews {
        val views =
            RemoteViews(context.packageName, R.layout.widget_habit_2x1)
        views.setOnClickPendingIntent(R.id.widget_root, openToday(context))

        val percent = percentOf(completed, total)
        var progressText = "$completed из $total"
        var pendingText = "Осталось ${(total - completed).coerceAtLeast(0)}"
        var percentText = "$percent%"
        var barProgress = percent
        var done = false

        when (state) {
            STATE_STALE -> {
                progressText = "Новый день"
                pendingText = "Откройте приложение"
                percentText = "0%"
                barProgress = 0
            }
            STATE_EMPTY -> {
                progressText = "Пусто"
                pendingText = "Добавьте первую"
                percentText = "+"
                barProgress = 0
            }
            STATE_DONE -> {
                progressText = "$completed из $total"
                pendingText = "Всё выполнено"
                percentText = "100%"
                barProgress = 100
                done = true
            }
            STATE_STREAK -> {
                progressText = topName.ifBlank { "$completed из $total" }
                pendingText =
                    if (topStreak > 0) {
                        "$topStreak ${dayWord(topStreak)} подряд"
                    } else {
                        "Осталось ${(total - completed).coerceAtLeast(0)}"
                    }
            }
        }

        views.setTextViewText(R.id.widget_progress, progressText)
        views.setTextViewText(R.id.widget_pending, pendingText)
        views.setTextViewText(R.id.widget_percent, percentText)
        views.setProgressBar(R.id.widget_bar, 100, barProgress, false)
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (done) {
                R.drawable.widget_background_2x1_done
            } else {
                R.drawable.widget_background_2x1
            },
        )
        views.setContentDescription(
            R.id.widget_root,
            descriptionFor(state, completed, total, topStreak),
        )
        return views
    }

    private fun buildWide(
        context: Context,
        state: String,
        completed: Int,
        total: Int,
        pendingLabel: String,
        topName: String,
        topStreak: Int,
        items: List<WidgetItem>,
    ): RemoteViews {
        val views =
            RemoteViews(context.packageName, R.layout.widget_habit_4x2)
        views.setOnClickPendingIntent(R.id.widget_root, openToday(context))

        val percent = percentOf(completed, total)
        var title = "Сегодня"
        var progressText = "$completed из $total"
        var footer = "Осталось ${(total - completed).coerceAtLeast(0)}"
        var barProgress = percent
        var done = false
        var showList = true
        var showEmpty = false
        var emptyTitle = "Нет привычек"
        var emptyBody = "Добавьте первую в приложении"

        when (state) {
            STATE_STALE -> {
                title = "Откройте приложение"
                progressText = ""
                emptyTitle = "Данные обновятся при запуске"
                emptyBody = ""
                showList = false
                showEmpty = true
                barProgress = 0
            }
            STATE_EMPTY -> {
                progressText = "0 из 0"
                emptyTitle = "Нет привычек"
                emptyBody = "Добавьте первую в приложении"
                showList = false
                showEmpty = true
                barProgress = 0
            }
            STATE_DONE -> {
                title = "Готово"
                footer =
                    "Всё выполнено" +
                        if (topStreak > 0) {
                            " · Серия $topStreak"
                        } else {
                            ""
                        }
                barProgress = 100
                done = true
            }
            STATE_STREAK -> {
                title = "Серия · лучшая $topStreak"
                footer =
                    if (topStreak > 0) {
                        "Лучшая серия — $topStreak ${dayWord(topStreak)}"
                    } else {
                        "Осталось ${(total - completed).coerceAtLeast(0)}"
                    }
            }
            else -> {
                footer =
                    "Осталось ${(total - completed).coerceAtLeast(0)}" +
                        if (topStreak > 0) {
                            " · ${topName.ifBlank { "Серия" }} $topStreak"
                        } else {
                            ""
                        }
            }
        }

        views.setTextViewText(R.id.widget_title, title)
        views.setTextViewText(R.id.widget_progress, progressText)
        views.setTextViewText(R.id.widget_footer, footer)
        views.setProgressBar(R.id.widget_bar, 100, barProgress, false)
        views.setViewVisibility(
            R.id.widget_empty,
            if (showEmpty) View.VISIBLE else View.GONE,
        )
        views.setTextViewText(R.id.widget_empty_title, emptyTitle)
        views.setTextViewText(R.id.widget_empty_body, emptyBody)
        views.setViewVisibility(
            R.id.widget_bar,
            if (showEmpty) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(
            R.id.widget_footer,
            if (showEmpty) View.GONE else View.VISIBLE,
        )
        views.setInt(
            R.id.widget_root,
            "setBackgroundResource",
            if (done) {
                R.drawable.widget_background_4x2_done
            } else {
                R.drawable.widget_background_4x2
            },
        )

        if (showList) {
            addRows(context, views, items, state, pendingLabel, total)
        } else {
            views.removeAllViews(R.id.widget_rows)
            views.setViewVisibility(R.id.widget_rows, View.GONE)
        }
        views.setContentDescription(
            R.id.widget_root,
            descriptionFor(state, completed, total, topStreak),
        )
        return views
    }

    private fun addRows(
        context: Context,
        views: RemoteViews,
        items: List<WidgetItem>,
        state: String,
        pendingLabel: String,
        total: Int,
    ) {
        views.removeAllViews(R.id.widget_rows)
        val rows = items.ifEmpty {
            if (total > 0 && state != STATE_DONE) {
                listOf(WidgetItem(pendingLabel, false, 0, ""))
            } else {
                emptyList()
            }
        }
        if (rows.isEmpty()) {
            views.setViewVisibility(R.id.widget_rows, View.GONE)
            views.setViewVisibility(R.id.widget_footer, View.VISIBLE)
            return
        }
        views.setViewVisibility(R.id.widget_rows, View.VISIBLE)
        val accent = color(context, R.color.widget_accent)
        val emptyCheck = color(context, R.color.widget_check_empty)
        for (item in rows.take(MAX_ROWS)) {
            val row =
                RemoteViews(context.packageName, R.layout.widget_habit_row)
            row.setTextViewText(R.id.widget_item_emoji, item.emoji)
            row.setTextViewText(R.id.widget_item_name, truncate(item.name))
            row.setTextViewText(
                R.id.widget_item_streak,
                if (item.streak > 0) "${item.streak} дн." else "",
            )
            row.setTextViewText(
                R.id.widget_item_check,
                if (item.done) "✓" else "○",
            )
            row.setTextColor(
                R.id.widget_item_check,
                if (item.done) accent else emptyCheck,
            )
            views.addView(R.id.widget_rows, row)
        }
    }

    private fun openToday(context: Context): PendingIntent {
        val intent =
            Intent(context, MainActivity::class.java).apply {
                action = HOME_WIDGET_LAUNCH_ACTION
                data = Uri.parse(OPEN_TODAY_URI)
                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        return PendingIntent.getActivity(context, 0, intent, flags)
    }

    private fun parseItems(raw: String?): List<WidgetItem> {
        if (raw.isNullOrBlank()) {
            return emptyList()
        }
        return try {
            val array = JSONArray(raw)
            (0 until minOf(array.length(), MAX_ROWS)).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                val name = item.optString("name").trim()
                if (name.isEmpty()) {
                    null
                } else {
                    WidgetItem(
                        name = name,
                        done = item.optBoolean("done", false),
                        streak = item.optInt("streak", 0).coerceAtLeast(0),
                        emoji = item.optString("emoji"),
                    )
                }
            }
        } catch (error: Exception) {
            emptyList()
        }
    }

    private fun percentOf(completed: Int, total: Int): Int =
        if (total <= 0) 0 else (completed * 100 / total).coerceIn(0, 100)

    private fun descriptionFor(
        state: String,
        completed: Int,
        total: Int,
        topStreak: Int,
    ): String =
        when (state) {
            STATE_STALE -> "Сегодня, данные устарели. Откройте приложение"
            STATE_EMPTY -> "Сегодня, привычек нет. Открыть приложение"
            STATE_DONE -> "Сегодня, выполнено $completed из $total. Открыть приложение"
            STATE_STREAK ->
                "Сегодня, выполнено $completed из $total, серия $topStreak. " +
                    "Открыть приложение"
            else ->
                "Сегодня, выполнено $completed из $total, " +
                    "осталось ${(total - completed).coerceAtLeast(0)}. " +
                    "Открыть приложение"
        }

    private fun truncate(name: String): String =
        if (name.length <= MAX_NAME_LENGTH) {
            name
        } else {
            name.take(MAX_NAME_LENGTH - 1) + "…"
        }

    private fun dayWord(value: Int): String {
        val mod100 = value % 100
        val mod10 = value % 10
        return when {
            mod10 == 1 && mod100 != 11 -> "день"
            mod10 in 2..4 && mod100 !in 12..14 -> "дня"
            else -> "дней"
        }
    }

    private fun color(context: Context, resourceId: Int): Int =
        @Suppress("DEPRECATION")
        context.resources.getColor(resourceId)

    private fun todayKey(): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    private data class WidgetItem(
        val name: String,
        val done: Boolean,
        val streak: Int,
        val emoji: String,
    )

    companion object {
        private const val TAG = "HabitWidgetProvider"
        internal const val PREFERENCES = "HomeWidgetPreferences"
        internal const val KEY_COMPLETED = "widget_completed"
        internal const val KEY_TOTAL = "widget_total"
        internal const val KEY_PROGRESS = "widget_progress"
        internal const val KEY_PENDING = "widget_pending"
        internal const val KEY_DATE = "widget_date"
        internal const val KEY_STATE = "widget_state"
        internal const val KEY_ITEMS = "widget_items_json"
        internal const val KEY_TOP_NAME = "widget_top_name"
        internal const val KEY_TOP_STREAK = "widget_top_streak"

        private const val STATE_EMPTY = "empty"
        private const val STATE_ACTIVE = "active"
        private const val STATE_DONE = "done"
        private const val STATE_STREAK = "streak"
        private const val STATE_STALE = "stale"

        private const val HOME_WIDGET_LAUNCH_ACTION =
            "com.sukhanovlabs.habittracker.action.OPEN_TODAY"
        private const val OPEN_TODAY_URI = "habittracker://today"
        private const val WIDE_MIN_WIDTH_DP = 250
        private const val STREAK_THRESHOLD = 7
        private const val MAX_ROWS = 3
        private const val MAX_NAME_LENGTH = 16
    }
}
