package com.veltaluma.perfica

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.os.Build
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class PerficaTasksWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_SWITCH_MODE) {
            return
        }

        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            return
        }

        val completedMode =
            TaskWidgetStore.toggleMode(context, appWidgetId)

        val manager = AppWidgetManager.getInstance(context)

        updateWidget(
            context,
            manager,
            appWidgetId,
            completedModeOverride = completedMode,
        )

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            @Suppress("DEPRECATION")
            manager.notifyAppWidgetViewDataChanged(
                appWidgetId,
                R.id.perfica_tasks_list,
            )
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        appWidgetIds.forEach { appWidgetId ->
            TaskWidgetStore.removeWidgetState(context, appWidgetId)
        }

        super.onDeleted(context, appWidgetIds)
    }

    companion object {
        private const val ACTION_SWITCH_MODE =
            "com.veltaluma.perfica.widget.SWITCH_MODE"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(
                context,
                PerficaTasksWidgetProvider::class.java,
            )
            val ids = manager.getAppWidgetIds(component)

            ids.forEach { appWidgetId ->
                updateWidget(context, manager, appWidgetId)
            }

            if (
                ids.isNotEmpty() &&
                Build.VERSION.SDK_INT < Build.VERSION_CODES.S
            ) {
                @Suppress("DEPRECATION")
                manager.notifyAppWidgetViewDataChanged(
                    ids,
                    R.id.perfica_tasks_list,
                )
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            completedModeOverride: Boolean? = null,
        ) {
            val completedMode =
                completedModeOverride
                    ?: TaskWidgetStore.isCompletedMode(
                        context,
                        appWidgetId,
                    )

            val views = RemoteViews(
                context.packageName,
                R.layout.perfica_tasks_widget,
            )

            views.setTextViewText(
                R.id.perfica_tasks_mode,
                if (completedMode) {
                    context.getString(R.string.perfica_widget_completed)
                } else {
                    context.getString(R.string.perfica_widget_active)
                },
            )

            views.setTextViewText(
                R.id.perfica_tasks_empty,
                if (completedMode) {
                    context.getString(R.string.perfica_widget_empty_completed)
                } else {
                    context.getString(R.string.perfica_widget_empty_active)
                },
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val items =
                    PerficaTasksWidgetService.readItems(
                        context = context,
                        completedMode = completedMode,
                    )

                val collection =
                    RemoteViews.RemoteCollectionItems.Builder()
                        .setHasStableIds(true)
                        .setViewTypeCount(1)
                        .apply {
                            items.forEach { item ->
                                addItem(
                                    item.id.toLong(),
                                    PerficaTasksWidgetService
                                        .buildItemRemoteViews(
                                            context = context,
                                            item = item,
                                            completedMode = completedMode,
                                            appWidgetId = appWidgetId,
                                        ),
                                )
                            }
                        }
                        .build()

                views.setRemoteAdapter(
                    R.id.perfica_tasks_list,
                    collection,
                )
            } else {
                val serviceIntent =
                    Intent(
                        context,
                        PerficaTasksWidgetService::class.java,
                    ).apply {
                        putExtra(
                            AppWidgetManager.EXTRA_APPWIDGET_ID,
                            appWidgetId,
                        )
                        putExtra(
                            PerficaTasksWidgetService.EXTRA_COMPLETED_MODE,
                            completedMode,
                        )
                        data = Uri.parse(
                            "perfica-widget://tasks/$appWidgetId/" +
                                if (completedMode) {
                                    "completed"
                                } else {
                                    "active"
                                },
                        )
                    }

                @Suppress("DEPRECATION")
                views.setRemoteAdapter(
                    R.id.perfica_tasks_list,
                    serviceIntent,
                )
            }

            views.setEmptyView(
                R.id.perfica_tasks_list,
                R.id.perfica_tasks_empty,
            )

            val itemTemplateIntent =
                Intent(
                    context,
                    PerficaTasksWidgetActionReceiver::class.java,
                ).apply {
                    action =
                        PerficaTasksWidgetActionReceiver.ACTION_WIDGET_ITEM
                }

            val itemTemplate = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                itemTemplateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_MUTABLE,
            )

            views.setPendingIntentTemplate(
                R.id.perfica_tasks_list,
                itemTemplate,
            )

            val switchIntent =
                Intent(
                    context,
                    PerficaTasksWidgetProvider::class.java,
                ).apply {
                    action = ACTION_SWITCH_MODE
                    putExtra(
                        AppWidgetManager.EXTRA_APPWIDGET_ID,
                        appWidgetId,
                    )
                }

            val switchPendingIntent = PendingIntent.getBroadcast(
                context,
                100000 + appWidgetId,
                switchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE,
            )

            views.setOnClickPendingIntent(
                R.id.perfica_tasks_switch,
                switchPendingIntent,
            )

            val addIntent = Intent(
                context,
                WidgetTaskEditorActivity::class.java,
            ).apply {
                action = "com.veltaluma.perfica.widget.NEW_TASK"
                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            }

            val addPendingIntent = PendingIntent.getActivity(
                context,
                200000 + appWidgetId,
                addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE,
            )

            views.setOnClickPendingIntent(
                R.id.perfica_tasks_add,
                addPendingIntent,
            )

            manager.updateAppWidget(appWidgetId, views)
        }
    }
}