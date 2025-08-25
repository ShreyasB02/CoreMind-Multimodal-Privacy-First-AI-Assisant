package com.example.coremind

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import kotlinx.coroutines.*
import android.util.Log
import android.content.Context
import java.io.File
import java.io.FileInputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.coremind.ai/gemma"
    private var llmInference: LlmInference? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    loadGemmaModel(modelPath, result)
                }
                "generateResponse" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    val maxTokens = call.argument<Int>("maxTokens") ?: 100
                    generateResponse(prompt, maxTokens, result)
                }
                "disposeModel" -> {
                    disposeModel(result)
                }
                "validateModel" -> {
                    validateModelFile(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun loadGemmaModel(modelPath: String?, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val actualModelPath = getModelPath(modelPath)
                if (actualModelPath == null) {
                    result.error("MODEL_NOT_FOUND", "Model file not found", null)
                    return@launch
                }

                Log.d("CoreMind", "Loading Gemma model from: $actualModelPath")

                if (!validateModelFileInternal(actualModelPath)) {
                    result.error("MODEL_CORRUPTED", "Model file validation failed", null)
                    return@launch
                }

                // Memory check
                val runtime = Runtime.getRuntime()
                val availableMemory = runtime.maxMemory() - (runtime.totalMemory() - runtime.freeMemory())
                Log.d("CoreMind", "Available memory: ${availableMemory / 1024 / 1024}MB")

                if (availableMemory < 1_000_000_000L) {
                    System.gc()
                    delay(500)
                }

                val options = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(actualModelPath)
                    .setMaxTokens(512)
                    .build()

                llmInference = withContext(Dispatchers.IO) {
                    LlmInference.createFromOptions(this@MainActivity, options)
                }

                Log.d("CoreMind", "✅ Gemma model loaded successfully!")
                result.success(true)
            } catch (e: Exception) {
                Log.e("CoreMind", "❌ Failed to load Gemma model: ${e.message}", e)
                val errorMessage = when {
                    e.message?.contains("flatbuffer", true) == true ->
                        "Model file corrupted or invalid format - retry download"
                    e.message?.contains("memory", true) == true ->
                        "Insufficient device memory to load model"
                    e.message?.contains("path", true) == true ->
                        "Cannot access model file - check permissions"
                    else ->
                        "Model loading failed - file may be corrupted - retry download"
                }
                val errorCode = when {
                    errorMessage.contains("corrupted") -> "MODEL_CORRUPTED"
                    errorMessage.contains("memory") -> "INSUFFICIENT_MEMORY"
                    else -> "LOAD_ERROR"
                }
                result.error(errorCode, errorMessage, null)
            }
        }
    }

    // ✅ FIXED: Match Flutter's getApplicationDocumentsDirectory path
    private fun getModelPath(modelPath: String?): String? {
        modelPath?.let {
            if (File(it).canRead()) return it
        }

        // ✅ CRITICAL: Match Flutter's path exactly
        // Flutter uses getApplicationDocumentsDirectory() which maps to app_flutter directory
        val flutterDocsDir = File(filesDir.parent, "app_flutter")
        val internalFile = File(flutterDocsDir, "models/gemma3-1b-it-int4.task")

        if (internalFile.exists() && internalFile.canRead()) {
            Log.d("CoreMind", "Using Flutter documents directory: ${internalFile.absolutePath}")
            return internalFile.absolutePath
        }

        // Fallback: try old location
        val fallbackFile = File(filesDir, "models/gemma3-1b-it-int4.task")
        if (fallbackFile.exists() && fallbackFile.canRead()) {
            Log.d("CoreMind", "Using fallback location: ${fallbackFile.absolutePath}")
            return fallbackFile.absolutePath
        }

        Log.e("CoreMind", "Model not found. Checked:")
        Log.e("CoreMind", "  Primary: ${internalFile.absolutePath}")
        Log.e("CoreMind", "  Fallback: ${fallbackFile.absolutePath}")
        return null
    }

    // ✅ UPDATED: Stricter validation for .task files
    private fun validateModelFileInternal(modelPath: String): Boolean {
        try {
            val file = File(modelPath)
            if (!file.exists() || !file.canRead()) {
                Log.e("CoreMind", "Model file inaccessible: $modelPath")
                return false
            }

            val sizeMB = file.length() / (1024 * 1024)
            Log.d("CoreMind", "Model file size: ${sizeMB}MB")
            if (file.length() < 500_000_000L) {
                Log.e("CoreMind", "Model file too small: ${file.length()} bytes")
                return false
            }

            FileInputStream(file).use { input ->
                val header = ByteArray(16)
                val bytesRead = input.read(header)
                if (bytesRead < 4) {
                    Log.e("CoreMind", "Cannot read model file header")
                    return false
                }

                val sig = header.copyOfRange(0, 4)
                val hexSig = sig.joinToString(" ") { "%02x".format(it) }
                Log.d("CoreMind", "Header bytes: $hexSig")

                // ✅ CRITICAL: Check for all-zero corruption first
                if (sig.all { it == 0.toByte() }) {
                    Log.e("CoreMind", "❌ Model file is corrupted (all zero header)")
                    return false
                }

                // ZIP signature: PK..
                val zipSig = byteArrayOf(0x50.toByte(), 0x4B.toByte(), 0x03.toByte(), 0x04.toByte())
                if (sig.contentEquals(zipSig)) {
                    Log.d("CoreMind", "✅ .task ZIP archive detected")
                    return true
                }

                // flatbuffer binary
                if (sig[0] == 0x1C.toByte() && sig[1] == 0x00.toByte()) {
                    Log.d("CoreMind", "✅ flatbuffer binary detected")
                    return true
                }

                // TFLite-based
                if (sig[0] == 0x54.toByte() && sig[1] == 0x46.toByte() && sig[2] == 0x4C.toByte()) {
                    Log.d("CoreMind", "✅ TFLite-based binary detected")
                    return true
                }

                Log.e("CoreMind", "❌ Unknown .task header: $hexSig")
                return false
            }
        } catch (e: Exception) {
            Log.e("CoreMind", "Model validation error: ${e.message}")
            return false
        }
    }

    private fun validateModelFile(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val path = getModelPath(null)
                result.success(path != null && validateModelFileInternal(path))
            } catch (e: Exception) {
                result.error("VALIDATION_ERROR", e.message, null)
            }
        }
    }

    private fun generateResponse(prompt: String, maxTokens: Int, result: MethodChannel.Result) {
        val inference = llmInference
        if (inference == null) {
            result.error("MODEL_NOT_LOADED", "Gemma model not loaded", null)
            return
        }
        coroutineScope.launch {
            try {
                Log.d("CoreMind", "Generating response for: $prompt")
                val response = withContext(Dispatchers.IO) {
                    inference.generateResponse(prompt)
                }
                Log.d("CoreMind", "Generated response: $response")
                result.success(response)
            } catch (e: Exception) {
                Log.e("CoreMind", "Generation error: ${e.message}", e)
                result.error("GENERATION_ERROR", e.message, null)
            }
        }
    }

    private fun disposeModel(result: MethodChannel.Result) {
        llmInference?.close()
        llmInference = null
        Log.d("CoreMind", "Gemma model disposed")
        result.success(true)
    }

    override fun onDestroy() {
        llmInference?.close()
        coroutineScope.cancel()
        super.onDestroy()
    }
}
