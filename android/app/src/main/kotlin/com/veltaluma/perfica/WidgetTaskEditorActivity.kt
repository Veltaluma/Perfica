package com.veltaluma.perfica

import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.view.FlutterCallbackInformation
import java.io.File

class WidgetTaskEditorActivity : FlutterActivity() {
    private var widgetEngine: FlutterEngine? = null
    private var callbackInfo: FlutterCallbackInformation? = null
    private var appBundlePath: String? = null
    private var callbackStarted = false

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        val callbackHandle =
            File(context.filesDir, CALLBACK_FILE)
                .takeIf { it.exists() }
                ?.readText(Charsets.UTF_8)
                ?.trim()
                ?.toLongOrNull()

        if (callbackHandle == null) {
            Log.e(TAG, "Widget editor callback handle is unavailable.")
            return null
        }

        val loader = FlutterInjector.instance().flutterLoader()

        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)

        val resolved =
            FlutterCallbackInformation.lookupCallbackInformation(
                callbackHandle,
            )

        if (resolved == null) {
            Log.e(TAG, "Widget editor callback information is unavailable.")
            return null
        }

        val engine = FlutterEngine(context)

        GeneratedPluginRegistrant.registerWith(engine)
        registerWidgetChannels(engine)

        callbackInfo = resolved
        appBundlePath = loader.findAppBundlePath()
        widgetEngine = engine

        return engine
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Custom engine is fully configured before Dart callback execution.
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startWidgetCallbackIfReady()
    }

    override fun shouldDestroyEngineWithHost(): Boolean = true

    private fun startWidgetCallbackIfReady() {
        if (callbackStarted) {
            return
        }

        val engine = widgetEngine
        val info = callbackInfo
        val bundlePath = appBundlePath

        if (engine == null || info == null || bundlePath.isNullOrEmpty()) {
            Log.e(
                TAG,
                "Widget editor engine was not created from a valid callback handle.",
            )
            finishAndRemoveTask()
            return
        }

        callbackStarted = true

        val callback = DartExecutor.DartCallback(
            assets,
            bundlePath,
            info,
        )

        engine.dartExecutor.executeDartCallback(callback)
    }

    private fun registerWidgetChannels(engine: FlutterEngine) {
        MethodChannel(
            engine.dartExecutor.binaryMessenger,
            EDITOR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_TASK_ID -> {
                    val taskId =
                        intent.getIntExtra(
                            EXTRA_TASK_ID,
                            INVALID_TASK_ID,
                        )

                    result.success(
                        if (taskId > 0) taskId else null,
                    )
                }

                METHOD_REFRESH -> {
                    PerficaTasksWidgetProvider.refreshAll(
                        applicationContext,
                    )
                    result.success(null)
                }

                METHOD_FINISH -> {
                    result.success(null)
                    finishAndRemoveTask()
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            engine.dartExecutor.binaryMessenger,
            TASK_WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_REFRESH -> {
                    PerficaTasksWidgetProvider.refreshAll(
                        applicationContext,
                    )
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EDITOR_CHANNEL,
        ).setMethodCallHandler(null)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TASK_WIDGET_CHANNEL,
        ).setMethodCallHandler(null)

        widgetEngine = null
        callbackInfo = null
        appBundlePath = null

        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        const val EXTRA_TASK_ID = "widget_task_id"

        private const val TAG = "WidgetTaskEditor"

        private const val INVALID_TASK_ID = -1

        private const val CALLBACK_FILE =
            "perfica_task_widget_editor_callback.txt"

        private const val EDITOR_CHANNEL =
            "com.veltaluma.perfica/widget_task_editor"

        private const val TASK_WIDGET_CHANNEL =
            "com.veltaluma.perfica/task_widget"

        private const val METHOD_GET_TASK_ID = "getTaskId"
        private const val METHOD_REFRESH = "refresh"
        private const val METHOD_FINISH = "finish"
    }
}
