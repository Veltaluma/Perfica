package com.veltaluma.perfica

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class PerficaTasksWidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_WIDGET_ITEM) {
            return
        }

        val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)

        if (taskId <= 0) {
            return
        }

        when (intent.getStringExtra(EXTRA_KIND)) {
            KIND_OPEN -> {
                val openIntent = Intent(
                    context,
                    WidgetTaskEditorActivity::class.java,
                ).apply {
                    action = "com.veltaluma.perfica.widget.EDIT_TASK"

                    putExtra(
                        WidgetTaskEditorActivity.EXTRA_TASK_ID,
                        taskId,
                    )

                    flags =
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                }

                context.startActivity(openIntent)
            }

            KIND_SET_COMPLETED -> {
                val scheduled = TaskWidgetActionJobService.enqueue(
                    context = context.applicationContext,
                    taskId = taskId,
                    completed = intent.getBooleanExtra(
                        EXTRA_COMPLETED,
                        true,
                    ),
                )

                if (!scheduled) {
                    Log.e(
                        TAG,
                        "Unable to schedule task widget completion job.",
                    )
                }
            }

            KIND_TOGGLE_EXPANDED -> {
                val appWidgetId =
                    intent.getIntExtra(
                        EXTRA_APP_WIDGET_ID,
                        -1,
                    )

                if (appWidgetId <= 0) {
                    return
                }

                TaskWidgetStore.toggleTaskExpanded(
                    context =
                        context.applicationContext,
                    appWidgetId =
                        appWidgetId,
                    taskId =
                        taskId,
                )

                PerficaTasksWidgetProvider.refreshAll(
                    context.applicationContext,
                )
            }
        }
    }

    companion object {
        private const val TAG = "TaskWidgetAction"

        const val ACTION_WIDGET_ITEM =
            "com.veltaluma.perfica.widget.ITEM"

        const val EXTRA_KIND = "kind"
        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_COMPLETED = "completed"
        const val EXTRA_APP_WIDGET_ID =
            "app_widget_id"

        const val KIND_OPEN = "open"
        const val KIND_SET_COMPLETED =
            "set_completed"
        const val KIND_TOGGLE_EXPANDED =
            "toggle_expanded"
    }
}
