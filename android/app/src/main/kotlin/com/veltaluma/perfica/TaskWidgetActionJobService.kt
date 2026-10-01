package com.veltaluma.perfica

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.PersistableBundle
import android.os.SystemClock
import android.util.Log

class TaskWidgetActionJobService : JobService() {
    override fun onStartJob(params: JobParameters): Boolean {
        val taskId = params.extras.getInt(EXTRA_TASK_ID, -1)

        if (taskId <= 0) {
            jobFinished(params, false)
            return false
        }

        val completed = params.extras.getBoolean(EXTRA_COMPLETED, true)

        TaskWidgetBackgroundRunner.enqueue(
            context = applicationContext,
            taskId = taskId,
            completed = completed,
        ) {
            jobFinished(params, false)
        }

        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        return true
    }

    companion object {
        private const val TAG = "TaskWidgetJob"

        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_COMPLETED = "completed"

        fun enqueue(
            context: Context,
            taskId: Int,
            completed: Boolean,
        ): Boolean {
            val scheduler =
                context.getSystemService(JobScheduler::class.java)
                    ?: return false

            val extras = PersistableBundle().apply {
                putInt(EXTRA_TASK_ID, taskId)
                putBoolean(EXTRA_COMPLETED, completed)
            }

            val dynamicId =
                (
                    SystemClock.elapsedRealtime().toInt() xor
                        taskId
                    ) and 0x0FFFFFFF

            val job = JobInfo.Builder(
                400000 + dynamicId,
                ComponentName(
                    context,
                    TaskWidgetActionJobService::class.java,
                ),
            )
                .setExtras(extras)
                .setMinimumLatency(0L)
                .setOverrideDeadline(0L)
                .build()

            val result = scheduler.schedule(job)

            if (result != JobScheduler.RESULT_SUCCESS) {
                Log.e(TAG, "JobScheduler rejected task widget action.")
            }

            return result == JobScheduler.RESULT_SUCCESS
        }
    }
}
