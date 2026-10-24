package com.fourandhalf.fitness_tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.Locale

class QuoteWeekWidgetProvider : HomeWidgetProvider() {
    private val dayViews = intArrayOf(
        R.id.widget_day_0, R.id.widget_day_1, R.id.widget_day_2, R.id.widget_day_3,
        R.id.widget_day_4, R.id.widget_day_5, R.id.widget_day_6,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val day = todaysEntry(widgetData)
        val states = (widgetData.getString("day${day}_states", null) ?: "").split(",")
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quote_week)
            views.setTextViewText(R.id.widget_quote, widgetData.getString("day${day}_quote", "") ?: "")
            views.setTextViewText(
                R.id.widget_quote_source,
                widgetData.getString("day${day}_source", "") ?: "",
            )
            dayViews.forEachIndexed { index, viewId ->
                val state = states.getOrNull(index)
                views.setInt(
                    viewId,
                    "setBackgroundResource",
                    when (state) {
                        "done" -> R.drawable.widget_day_done
                        "today" -> R.drawable.widget_day_today
                        else -> R.drawable.widget_day_idle
                    },
                )
                views.setTextViewText(viewId, if (state == "done") "✓" else "")
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fitnesstracker:///"),
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        scheduleMidnightRefresh(context, appWidgetManager)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(refreshIntent(context, IntArray(0)))
    }

    /** The published entry whose date is today, or the latest one if the app has not run for a while. */
    private fun todaysEntry(widgetData: SharedPreferences): Int {
        val now = Calendar.getInstance()
        val today = String.format(
            Locale.US, "%04d-%02d-%02d",
            now.get(Calendar.YEAR), now.get(Calendar.MONTH) + 1, now.get(Calendar.DAY_OF_MONTH),
        )
        var latest = 0
        for (i in 0 until 7) {
            val date = widgetData.getString("day${i}_date", null) ?: break
            if (date == today) return i
            latest = i
        }
        return latest
    }

    /** Re-renders the widget just after midnight so the quote and week strip roll over. */
    private fun scheduleMidnightRefresh(context: Context, appWidgetManager: AppWidgetManager) {
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, QuoteWeekWidgetProvider::class.java))
        val midnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 5)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .set(AlarmManager.RTC, midnight, refreshIntent(context, ids))
    }

    private fun refreshIntent(context: Context, ids: IntArray): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, QuoteWeekWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
