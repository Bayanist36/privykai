package com.sukhanovlabs.habittracker

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Flutter and the small widget channel.
 *
 * The home screen widget does not need WorkManager or Glance: Flutter writes
 * the snapshot here and the provider is redrawn with a normal
 * `ACTION_APPWIDGET_UPDATE` broadcast (QA-24-03).
 */
class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
                .also { channel ->
                    channel.setMethodCallHandler { call, result ->
                        when (call.method) {
                            UPDATE_WIDGET -> {
                                val args = call.arguments as? Map<*, *>
                                if (args == null) {
                                    result.error(
                                        "invalid_arguments",
                                        "updateWidget expects a map",
                                        null,
                                    )
                                } else {
                                    publishSnapshot(args)
                                    result.success(null)
                                }
                            }
                            else -> result.notImplemented()
                        }
                    }
                }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.data?.toString() == OPEN_TODAY_URI) {
            widgetChannel?.invokeMethod(WIDGET_TAP, null)
        }
    }

    private fun publishSnapshot(args: Map<*, *>) {
        val prefs =
            getSharedPreferences(HabitWidgetProvider.PREFERENCES, Context.MODE_PRIVATE)
        prefs
            .edit()
            .putInt(HabitWidgetProvider.KEY_COMPLETED, args.intValue(HabitWidgetProvider.KEY_COMPLETED))
            .putInt(HabitWidgetProvider.KEY_TOTAL, args.intValue(HabitWidgetProvider.KEY_TOTAL))
            .putString(HabitWidgetProvider.KEY_PROGRESS, args.stringValue(HabitWidgetProvider.KEY_PROGRESS))
            .putString(HabitWidgetProvider.KEY_PENDING, args.stringValue(HabitWidgetProvider.KEY_PENDING))
            .putString(HabitWidgetProvider.KEY_DATE, args.stringValue(HabitWidgetProvider.KEY_DATE))
            .putString(HabitWidgetProvider.KEY_STATE, args.stringValue(HabitWidgetProvider.KEY_STATE))
            .putString(HabitWidgetProvider.KEY_ITEMS, args.stringValue(HabitWidgetProvider.KEY_ITEMS))
            .putString(HabitWidgetProvider.KEY_TOP_NAME, args.stringValue(HabitWidgetProvider.KEY_TOP_NAME))
            .putInt(HabitWidgetProvider.KEY_TOP_STREAK, args.intValue(HabitWidgetProvider.KEY_TOP_STREAK))
            .commit()

        val manager = AppWidgetManager.getInstance(this)
        val ids =
            manager.getAppWidgetIds(
                ComponentName(this, HabitWidgetProvider::class.java),
            )
        if (ids.isEmpty()) {
            return
        }
        val update =
            Intent(this, HabitWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
        sendBroadcast(update)
    }

    private fun Map<*, *>.intValue(key: String): Int =
        (this[key] as? Number)?.toInt() ?: 0

    private fun Map<*, *>.stringValue(key: String): String =
        this[key] as? String ?: ""

    companion object {
        private const val WIDGET_CHANNEL = "com.sukhanovlabs.habittracker/widget"
        private const val UPDATE_WIDGET = "updateWidget"
        private const val WIDGET_TAP = "widgetTap"
        private const val OPEN_TODAY_URI = "habittracker://today"
    }
}
