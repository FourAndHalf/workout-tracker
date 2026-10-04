package com.fourandhalf.fitness_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 4x2 "Kinetic Flux" widget: energy balance, streak and a start-workout shortcut. */
class FluxWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        fun text(key: String, fallback: String = "") = widgetData.getString(key, fallback) ?: fallback

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_flux)
            views.setTextViewText(R.id.flux_status, text("flux_status", "ON TRACK"))
            views.setTextViewText(R.id.flux_net, text("flux_net", "--"))
            views.setTextViewText(R.id.flux_net_label, text("flux_net_label"))
            views.setTextViewText(R.id.flux_burned, text("flux_burned", "--"))
            views.setTextViewText(R.id.flux_consumed, text("flux_consumed", "--"))
            views.setProgressBar(R.id.flux_burned_bar, 100, widgetData.getInt("flux_burned_pct", 0), false)
            views.setProgressBar(R.id.flux_consumed_bar, 100, widgetData.getInt("flux_consumed_pct", 0), false)
            views.setTextViewText(R.id.flux_streak_chip, text("flux_streak_chip", "0D"))
            views.setTextViewText(R.id.flux_streak_day, text("flux_streak_day", "Day 0"))
            views.setTextViewText(R.id.flux_target, text("flux_target"))
            views.setTextViewText(R.id.flux_today, text("flux_today"))
            views.setTextViewText(R.id.flux_start, text("flux_start", "Open app"))
            views.setTextViewText(R.id.flux_updated, text("flux_updated"))
            views.setTextViewText(R.id.flux_shield, text("flux_shield"))

            views.setOnClickPendingIntent(
                R.id.flux_root,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fitnesstracker:///"),
                ),
            )
            views.setOnClickPendingIntent(
                R.id.flux_start,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse(text("flux_start_uri", "fitnesstracker:///")),
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
