package com.fourandhalf.fitness_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 2x2 "Kinetic Flux Mini" widget: net calories and streak at a glance. */
class FluxCompactWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        fun text(key: String, fallback: String = "") = widgetData.getString(key, fallback) ?: fallback

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_flux_compact)
            views.setTextViewText(R.id.flux_streak_short, text("flux_streak_short", "0d"))
            views.setTextViewText(R.id.flux_net, text("flux_net", "--"))
            views.setTextViewText(R.id.flux_compact_label, text("flux_compact_label", "KCAL"))
            views.setProgressBar(R.id.flux_compact_bar, 100, widgetData.getInt("flux_compact_pct", 0), false)
            views.setTextViewText(R.id.flux_compact_sub, text("flux_compact_sub"))

            views.setOnClickPendingIntent(
                R.id.flux_compact_root,
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
