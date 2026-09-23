package com.fourandhalf.fitness_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FitnessWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_fitness)
            views.setTextViewText(
                R.id.widget_streak_count,
                widgetData.getInt("streak", 0).toString(),
            )
            views.setOnClickPendingIntent(
                R.id.widget_camera_button,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fitnesstracker:///nutrition?capture=camera"),
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
