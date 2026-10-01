package com.veltaluma.perfica

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.view.FlutterCallbackInformation
import java.io.File

object TaskWidgetBackgroundRunner {
    private const val TAG = "TaskWidgetBackground"

    private const val CHANNEL =
        "com.veltaluma.perfica/task_widget_background"

    private const val CALLBACK_FILE =
        "perfica_task_widget_background_callback.txt"

    private val handler = Handler(Looper.getMainLooper())

    private val queue = ArrayDeque<Work>()

    private var running = false

    private data class Work(
        val context: Context,
        val taskId: Int,
        val completed: Boolean,
        val onFinished: () -> Unit,
    )

    @Synchronized
    fun enqueue(
        context: Context,
        taskId: Int,
        completed: Boolean,
        onFinished: () -> Unit,
    ) {
        queue.addLast(
            Work(
                context = context.applicationContext,
                taskId = taskId,
                completed = completed,
                onFinished = onFinished,
            ),
        )

        if (running) {
            return
        }

        running = true

        handler.post {
            startNext()
        }
    }

    private fun startNext() {
        val work = synchronized(this) {
            queue.firstOrNull()
        }

        if (work == null) {
            synchronized(this) {
                running = false
            }

            return
        }

        var engine: FlutterEngine? = null
        var finished = false

        lateinit var timeout: Runnable

        fun finish() {
            if (finished) {
                return
            }

            finished = true

            handler.removeCallbacks(timeout)

            runCatching {
                PerficaTasksWidgetProvider.refreshAll(work.context)
            }

            runCatching {
                engine?.destroy()
            }

            runCatching {
                work.onFinished()
            }

            synchronized(this) {
                if (queue.isNotEmpty()) {
                    queue.removeFirst()
                }

                if (queue.isEmpty()) {
                    running = false
                } else {
                    handler.post {
                        startNext()
                    }
                }
            }
        }

        timeout = Runnable {
            Log.e(
                TAG,
                "Task widget background action timed out.",
            )

            finish()
        }

        try {
            val callbackHandle =
                File(work.context.filesDir, CALLBACK_FILE)
                    .takeIf { it.exists() }
                    ?.readText(Charsets.UTF_8)
                    ?.trim()
                    ?.toLongOrNull()
                    ?: throw IllegalStateException(
                        "Task widget background callback handle is unavailable.",
                    )

            val loader =
                FlutterInjector.instance().flutterLoader()

            loader.startInitialization(work.context)

            loader.ensureInitializationComplete(
                work.context,
                null,
            )

            val callbackInfo =
                FlutterCallbackInformation.lookupCallbackInformation(
                    callbackHandle,
                )
                    ?: throw IllegalStateException(
                        "Task widget background callback information is unavailable.",
                    )

            engine = FlutterEngine(work.context)

            GeneratedPluginRegistrant.registerWith(engine!!)

            val channel = MethodChannel(
                engine!!.dartExecutor.binaryMessenger,
                CHANNEL,
            )

            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getArgs" -> {
                        result.success(
                            mapOf(
                                "taskId" to work.taskId,
                                "completed" to work.completed,
                                "filesDirectory" to
                                    work.context.filesDir.absolutePath,
                            ),
                        )
                    }

                    "done" -> {
                        result.success(null)
                        finish()
                    }

                    else -> result.notImplemented()
                }
            }

            val callback = DartExecutor.DartCallback(
                work.context.assets,
                loader.findAppBundlePath(),
                callbackInfo,
            )

            handler.postDelayed(timeout, 20_000L)

            engine!!.dartExecutor.executeDartCallback(callback)
        } catch (error: Throwable) {
            Log.e(
                TAG,
                "Unable to execute task widget action.",
                error,
            )

            finish()
        }
    }
}
