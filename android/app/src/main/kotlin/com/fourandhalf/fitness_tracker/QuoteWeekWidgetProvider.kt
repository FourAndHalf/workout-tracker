package com.fourandhalf.fitness_tracker

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.Locale

/** The 4x2 widget: today's quote with the Monday-Sunday workout status beneath. */
class QuoteWeekWidgetProvider : QuoteWidgetBase(showWeek = true, fallbackHeightDp = 130f)

/** The 4x1 widget: just today's quote. */
class QuoteWidgetProvider : QuoteWidgetBase(showWeek = false, fallbackHeightDp = 70f)

abstract class QuoteWidgetBase(
    private val showWeek: Boolean,
    private val fallbackHeightDp: Float,
) : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val day = todaysEntry(widgetData)
        val quote = widgetData.getString("day${day}_quote", "") ?: ""
        val source = widgetData.getString("day${day}_source", "") ?: ""
        val states = if (showWeek) {
            (widgetData.getString("day${day}_states", null) ?: "").split(",")
        } else {
            null
        }
        appWidgetIds.forEach { widgetId ->
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            // Portrait is width = min width, height = max height.
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).let { if (it > 0) it.toFloat() else 320f }
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0).let { if (it > 0) it.toFloat() else fallbackHeightDp }
            val views = RemoteViews(context.packageName, R.layout.widget_quote_week)
            views.setImageViewBitmap(
                R.id.widget_image,
                QuoteCardRenderer.render(context, width, height, quote, source, states),
            )
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

    /** Resizing changes the size the card is drawn at, so draw it again. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(
            context,
            appWidgetManager,
            intArrayOf(appWidgetId),
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE),
        )
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
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, javaClass))
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
            Intent(context, javaClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
