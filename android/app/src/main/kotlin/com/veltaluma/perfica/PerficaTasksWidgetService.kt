package com.veltaluma.perfica

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

class PerficaTasksWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(
        intent: Intent,
    ): RemoteViewsFactory {
        return TaskFactory(
            applicationContext,
            intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            ),
            intent.getBooleanExtra(
                EXTRA_COMPLETED_MODE,
                false,
            ),
        )
    }

    data class SubtaskItem(
        val title: String,
        val completed: Boolean,
    )

    data class TaskItem(
        val id: Int,
        val title: String,
        val description: String?,
        val priority: String?,
        val workflowStatus: String?,
        val dueAt: String?,
        val completedAt: String?,
        val recurrence: String?,
        val monthlyAnchorDay: Int?,
        val reminderAt: String?,
        val reminderRepeatMinutes: Int?,
        val reminderSnoozedUntil: String?,
        val tags: List<String>,
        val attachments: List<String>,
        val subtasks: List<SubtaskItem>,
    )

    private class TaskFactory(
        private val context: Context,
        private val appWidgetId: Int,
        private val completedMode: Boolean,
    ) : RemoteViewsFactory {
        private var items: List<TaskItem> =
            emptyList()

        override fun onCreate() = Unit

        override fun onDataSetChanged() {
            items =
                readItems(
                    context = context,
                    completedMode = completedMode,
                )
        }

        override fun onDestroy() {
            items = emptyList()
        }

        override fun getCount(): Int =
            items.size

        override fun getViewAt(
            position: Int,
        ): RemoteViews? {
            val item =
                items.getOrNull(position)
                    ?: return null

            return buildItemRemoteViews(
                context = context,
                item = item,
                completedMode = completedMode,
                appWidgetId = appWidgetId,
            )
        }

        override fun getLoadingView():
            RemoteViews? = null

        override fun getViewTypeCount():
            Int = 1

        override fun getItemId(
            position: Int,
        ): Long {
            return items
                .getOrNull(position)
                ?.id
                ?.toLong()
                ?: position.toLong()
        }

        override fun hasStableIds():
            Boolean = true
    }

    companion object {
        const val EXTRA_COMPLETED_MODE =
            "completed_mode"

        fun readItems(
            context: Context,
            completedMode: Boolean,
        ): List<TaskItem> {
            val payload =
                TaskWidgetStore
                    .readSnapshot(context)
                    ?: return emptyList()

            return runCatching {
                val root =
                    JSONObject(payload)

                val array =
                    root.getJSONArray(
                        if (completedMode) {
                            "completed"
                        } else {
                            "active"
                        },
                    )

                parse(array)
            }.getOrElse {
                emptyList()
            }
        }

        fun buildItemRemoteViews(
            context: Context,
            item: TaskItem,
            completedMode: Boolean,
            appWidgetId: Int,
        ): RemoteViews {
            val expanded =
                !completedMode &&
                    TaskWidgetStore
                        .isTaskExpanded(
                            context,
                            appWidgetId,
                            item.id,
                        )

            val expandable =
                !completedMode &&
                    hasExpandableDetails(
                        item,
                    )

            return RemoteViews(
                context.packageName,
                R.layout.perfica_tasks_widget_item,
            ).apply {
                setTextViewText(
                    R.id.perfica_widget_task_title,
                    item.title,
                )

                bindOptionalText(
                    this,
                    R.id.perfica_widget_task_description,
                    item.description
                        ?.trim()
                        ?.takeIf {
                            it.isNotEmpty()
                        },
                )

                bindOptionalText(
                    this,
                    R.id.perfica_widget_task_meta,
                    if (completedMode) {
                        buildCompletedMetadata(
                            item,
                        )
                    } else {
                        buildActiveMetadata(
                            item,
                        )
                    },
                )

                setImageViewResource(
                    R.id.perfica_widget_task_check,
                    if (completedMode) {
                        R.drawable
                            .ic_perfica_widget_checked
                    } else {
                        R.drawable
                            .ic_perfica_widget_unchecked
                    },
                )

                setOnClickFillInIntent(
                    R.id.perfica_widget_task_content,
                    Intent().apply {
                        putExtra(
                            PerficaTasksWidgetActionReceiver
                                .EXTRA_KIND,
                            PerficaTasksWidgetActionReceiver
                                .KIND_OPEN,
                        )

                        putExtra(
                            PerficaTasksWidgetActionReceiver
                                .EXTRA_TASK_ID,
                            item.id,
                        )
                    },
                )

                setOnClickFillInIntent(
                    R.id.perfica_widget_task_check,
                    Intent().apply {
                        putExtra(
                            PerficaTasksWidgetActionReceiver
                                .EXTRA_KIND,
                            PerficaTasksWidgetActionReceiver
                                .KIND_SET_COMPLETED,
                        )

                        putExtra(
                            PerficaTasksWidgetActionReceiver
                                .EXTRA_TASK_ID,
                            item.id,
                        )

                        putExtra(
                            PerficaTasksWidgetActionReceiver
                                .EXTRA_COMPLETED,
                            !completedMode,
                        )
                    },
                )

                if (expandable) {
                    setViewVisibility(
                        R.id.perfica_widget_task_expand,
                        View.VISIBLE,
                    )

                    setTextViewText(
                        R.id.perfica_widget_task_expand,
                        if (expanded) {
                            "▲"
                        } else {
                            "▼"
                        },
                    )

                    setOnClickFillInIntent(
                        R.id.perfica_widget_task_expand,
                        Intent().apply {
                            putExtra(
                                PerficaTasksWidgetActionReceiver
                                    .EXTRA_KIND,
                                PerficaTasksWidgetActionReceiver
                                    .KIND_TOGGLE_EXPANDED,
                            )

                            putExtra(
                                PerficaTasksWidgetActionReceiver
                                    .EXTRA_TASK_ID,
                                item.id,
                            )

                            putExtra(
                                PerficaTasksWidgetActionReceiver
                                    .EXTRA_APP_WIDGET_ID,
                                appWidgetId,
                            )
                        },
                    )
                } else {
                    setViewVisibility(
                        R.id.perfica_widget_task_expand,
                        View.GONE,
                    )
                }

                bindOptionalText(
                    this,
                    R.id.perfica_widget_task_details,
                    if (expanded) {
                        buildExpandedDetails(
                            item,
                        )
                    } else {
                        null
                    },
                )
            }
        }

        private fun parse(
            array: JSONArray,
        ): List<TaskItem> {
            return buildList {
                for (
                    index in
                    0 until array.length()
                ) {
                    val item =
                        array.getJSONObject(
                            index,
                        )

                    add(
                        TaskItem(
                            id =
                                item.getInt("id"),

                            title =
                                item.optString(
                                    "title",
                                ),

                            description =
                                item.optNullableString(
                                    "description",
                                ),

                            priority =
                                item.optNullableString(
                                    "priority",
                                ),

                            workflowStatus =
                                item.optNullableString(
                                    "workflowStatus",
                                ),

                            dueAt =
                                item.optNullableString(
                                    "dueAt",
                                ),

                            completedAt =
                                item.optNullableString(
                                    "completedAt",
                                ),

                            recurrence =
                                item.optNullableString(
                                    "recurrence",
                                ),

                            monthlyAnchorDay =
                                item.optNullableInt(
                                    "monthlyAnchorDay",
                                ),

                            reminderAt =
                                item.optNullableString(
                                    "reminderAt",
                                ),

                            reminderRepeatMinutes =
                                item.optNullableInt(
                                    "reminderRepeatMinutes",
                                ),

                            reminderSnoozedUntil =
                                item.optNullableString(
                                    "reminderSnoozedUntil",
                                ),

                            tags =
                                item.optStringList(
                                    "tags",
                                ),

                            attachments =
                                item.optStringList(
                                    "attachments",
                                ),

                            subtasks =
                                item.optSubtasks(
                                    "subtasks",
                                ),
                        ),
                    )
                }
            }
        }

        private fun hasExpandableDetails(
            item: TaskItem,
        ): Boolean {
            return item.workflowStatus
                    ?.takeIf {
                        it != "todo"
                    } != null ||
                item.priority
                    ?.takeIf {
                        it != "none"
                    } != null ||
                item.dueAt != null ||
                item.reminderAt != null ||
                item.reminderSnoozedUntil != null ||
                item.reminderRepeatMinutes != null ||
                item.recurrence != null ||
                item.monthlyAnchorDay != null ||
                item.tags.isNotEmpty() ||
                item.attachments.isNotEmpty() ||
                item.subtasks.isNotEmpty()
        }

        private fun buildActiveMetadata(
            item: TaskItem,
        ): String? {
            val parts =
                mutableListOf<String>()

            formatDateTime(
                item.dueAt,
            )?.let {
                parts +=
                    "Due $it"
            }

            item.priority
                ?.takeIf {
                    it != "none"
                }
                ?.let {
                    parts +=
                        humanizeToken(it)
                }

            item.workflowStatus
                ?.takeIf {
                    it != "todo" &&
                        it != "done"
                }
                ?.let {
                    parts +=
                        humanizeToken(it)
                }

            return parts
                .takeIf {
                    it.isNotEmpty()
                }
                ?.joinToString(
                    " · ",
                )
        }

        private fun buildCompletedMetadata(
            item: TaskItem,
        ): String? {
            val parts =
                mutableListOf<String>()

            formatDateTime(
                item.completedAt,
            )?.let {
                parts +=
                    "Completed $it"
            }

            item.priority
                ?.takeIf {
                    it != "none"
                }
                ?.let {
                    parts +=
                        humanizeToken(it)
                }

            return parts
                .takeIf {
                    it.isNotEmpty()
                }
                ?.joinToString(
                    " · ",
                )
        }

        private fun buildExpandedDetails(
            item: TaskItem,
        ): String? {
            val lines =
                mutableListOf<String>()

            item.workflowStatus
                ?.takeIf {
                    it.isNotBlank()
                }
                ?.let {
                    lines +=
                        "Status: " +
                            humanizeToken(it)
                }

            item.priority
                ?.takeIf {
                    it.isNotBlank() &&
                        it != "none"
                }
                ?.let {
                    lines +=
                        "Priority: " +
                            humanizeToken(it)
                }

            formatDateTime(
                item.dueAt,
            )?.let {
                lines +=
                    "Due: $it"
            }

            formatDateTime(
                item.reminderSnoozedUntil
                    ?: item.reminderAt,
            )?.let {
                lines +=
                    if (
                        item.reminderSnoozedUntil
                            != null
                    ) {
                        "Reminder: $it (snoozed)"
                    } else {
                        "Reminder: $it"
                    }
            }

            item.reminderRepeatMinutes
                ?.let {
                    lines +=
                        "Reminder repeat: " +
                            "every $it min"
                }

            item.recurrence
                ?.takeIf {
                    it.isNotBlank()
                }
                ?.let {
                    lines +=
                        "Recurrence: " +
                            humanizeToken(it)
                }

            item.monthlyAnchorDay
                ?.let {
                    if (
                        item.recurrence ==
                            "monthly"
                    ) {
                        lines +=
                            "Monthly day: $it"
                    }
                }

            if (
                item.tags.isNotEmpty()
            ) {
                lines +=
                    "Tags: " +
                        item.tags
                            .joinToString(
                                " · ",
                            )
            }

            if (
                item.attachments.isNotEmpty()
            ) {
                val names =
                    item.attachments
                        .map {
                            File(it)
                                .name
                                .ifBlank {
                                    it
                                }
                        }

                lines +=
                    "Attachments " +
                        "(${item.attachments.size}): " +
                        names.joinToString(
                            ", ",
                        )
            }

            if (
                item.subtasks.isNotEmpty()
            ) {
                val completed =
                    item.subtasks
                        .count {
                            it.completed
                        }

                lines +=
                    "Subtasks: " +
                        "$completed/" +
                        "${item.subtasks.size}"

                item.subtasks.forEach {
                    subtask ->

                    lines +=
                        if (
                            subtask.completed
                        ) {
                            "✓ ${subtask.title}"
                        } else {
                            "○ ${subtask.title}"
                        }
                }
            }

            return lines
                .takeIf {
                    it.isNotEmpty()
                }
                ?.joinToString(
                    "\n",
                )
        }

        private fun formatDateTime(
            value: String?,
        ): String? {
            if (
                value.isNullOrBlank()
            ) {
                return null
            }

            val normalized =
                value.replace(
                    'T',
                    ' ',
                )

            return when {
                normalized.length >= 16 ->
                    normalized.substring(
                        0,
                        16,
                    )

                normalized.length >= 10 ->
                    normalized.substring(
                        0,
                        10,
                    )

                else ->
                    normalized
            }
        }

        private fun humanizeToken(
            value: String,
        ): String {
            if (value.isBlank()) {
                return value
            }

            val spaced =
                value.replace(
                    Regex(
                        "([a-z0-9])([A-Z])",
                    ),
                    "$1 $2",
                )

            return spaced
                .replace('_', ' ')
                .replace('-', ' ')
                .lowercase()
                .replaceFirstChar {
                    if (
                        it.isLowerCase()
                    ) {
                        it.titlecase()
                    } else {
                        it.toString()
                    }
                }
        }

        private fun bindOptionalText(
            views: RemoteViews,
            viewId: Int,
            value: String?,
        ) {
            if (
                value.isNullOrBlank()
            ) {
                views.setViewVisibility(
                    viewId,
                    View.GONE,
                )
            } else {
                views.setViewVisibility(
                    viewId,
                    View.VISIBLE,
                )

                views.setTextViewText(
                    viewId,
                    value,
                )
            }
        }

        private fun JSONObject
            .optNullableString(
                key: String,
            ): String? {
            if (
                !has(key) ||
                isNull(key)
            ) {
                return null
            }

            return optString(key)
                .takeIf {
                    it.isNotBlank() &&
                        it != "null"
                }
        }

        private fun JSONObject
            .optNullableInt(
                key: String,
            ): Int? {
            if (
                !has(key) ||
                isNull(key)
            ) {
                return null
            }

            val raw = opt(key)

            return if (
                raw is Number
            ) {
                raw.toInt()
            } else {
                null
            }
        }

        private fun JSONObject
            .optStringList(
                key: String,
            ): List<String> {
            val array =
                optJSONArray(key)
                    ?: return emptyList()

            return buildList {
                for (
                    index in
                    0 until array.length()
                ) {
                    val value =
                        array
                            .optString(index)
                            .trim()

                    if (
                        value.isNotEmpty()
                    ) {
                        add(value)
                    }
                }
            }
        }

        private fun JSONObject
            .optSubtasks(
                key: String,
            ): List<SubtaskItem> {
            val array =
                optJSONArray(key)
                    ?: return emptyList()

            return buildList {
                for (
                    index in
                    0 until array.length()
                ) {
                    val raw =
                        array
                            .optJSONObject(index)
                            ?: continue

                    val title =
                        raw
                            .optString(
                                "title",
                            )
                            .trim()

                    if (
                        title.isEmpty()
                    ) {
                        continue
                    }

                    add(
                        SubtaskItem(
                            title =
                                title,

                            completed =
                                raw.optBoolean(
                                    "isCompleted",
                                    false,
                                ),
                        ),
                    )
                }
            }
        }
    }
}
