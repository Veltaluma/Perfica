package com.veltaluma.perfica

import android.content.Context
import java.io.File

object TaskWidgetStore {
    const val SNAPSHOT_FILE = "perfica_task_widget_snapshot.json"
    const val PREFS = "perfica_tasks_widget"

    private fun file(context: Context): File =
        File(context.filesDir, SNAPSHOT_FILE)

    fun readSnapshot(context: Context): String? {
        val file = file(context)

        if (!file.exists()) {
            return null
        }

        return runCatching { file.readText(Charsets.UTF_8) }.getOrNull()
    }

    fun writeSnapshot(context: Context, payload: String) {
        val target = file(context)
        val temp = File(context.filesDir, "$SNAPSHOT_FILE.tmp")

        temp.writeText(payload, Charsets.UTF_8)

        if (target.exists() && !target.delete()) {
            throw IllegalStateException("Unable to replace widget snapshot.")
        }

        if (!temp.renameTo(target)) {
            target.writeText(payload, Charsets.UTF_8)
            temp.delete()
        }
    }

    fun isCompletedMode(context: Context, appWidgetId: Int): Boolean {
        return context
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean("completed_$appWidgetId", false)
    }

    fun toggleMode(context: Context, appWidgetId: Int): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val next = !prefs.getBoolean("completed_$appWidgetId", false)

        val committed =
            prefs
                .edit()
                .putBoolean("completed_$appWidgetId", next)
                .commit()

        if (!committed) {
            return prefs.getBoolean("completed_$appWidgetId", false)
        }

        return next
    }

    private fun expandedTaskKey(
        appWidgetId: Int,
        taskId: Int,
    ): String =
        "expanded_${appWidgetId}_$taskId"

    fun isTaskExpanded(
        context: Context,
        appWidgetId: Int,
        taskId: Int,
    ): Boolean {
        return context
            .getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE,
            )
            .getBoolean(
                expandedTaskKey(
                    appWidgetId,
                    taskId,
                ),
                false,
            )
    }

    fun toggleTaskExpanded(
        context: Context,
        appWidgetId: Int,
        taskId: Int,
    ): Boolean {
        val prefs =
            context.getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE,
            )

        val key =
            expandedTaskKey(
                appWidgetId,
                taskId,
            )

        val next =
            !prefs.getBoolean(
                key,
                false,
            )

        val committed =
            prefs.edit()
                .putBoolean(
                    key,
                    next,
                )
                .commit()

        return if (committed) {
            next
        } else {
            prefs.getBoolean(
                key,
                false,
            )
        }
    }

    fun removeWidgetState(context: Context, appWidgetId: Int) {
        context
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove("completed_$appWidgetId")
            .apply()
    }
}