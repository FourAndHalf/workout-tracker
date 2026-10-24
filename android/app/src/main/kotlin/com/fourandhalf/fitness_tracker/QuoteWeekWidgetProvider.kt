package com.fourandhalf.fitness_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

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
        val states = (widgetData.getString("week_states", null) ?: "").split(",")
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quote_week)
            views.setTextViewText(R.id.widget_quote, widgetData.getString("quote_text", "") ?: "")
            views.setTextViewText(
                R.id.widget_quote_source,
                widgetData.getString("quote_source", "") ?: "",
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
    }
}
