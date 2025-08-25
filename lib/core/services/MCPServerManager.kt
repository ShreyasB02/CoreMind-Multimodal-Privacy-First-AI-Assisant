package com.example.coremind.mcp

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.InetSocketAddress
import org.java_websocket.WebSocket
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.server.WebSocketServer

class MCPServerManager(private val context: Context) {
    private var webSocketServer: MCPWebSocketServer? = null
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        private const val TAG = "MCPServer"
        private const val DEFAULT_PORT = 8765
    }

    fun startServer(port: Int = DEFAULT_PORT) {
        try {
            webSocketServer = MCPWebSocketServer(InetSocketAddress(port), context)
            webSocketServer?.start()
            Log.d(TAG, "MCP Server started on port $port")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start MCP Server: ${e.message}")
        }
    }

    fun stopServer() {
        try {
            webSocketServer?.stop()
            Log.d(TAG, "MCP Server stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping MCP Server: ${e.message}")
        }
    }

    class MCPWebSocketServer(address: InetSocketAddress, private val context: Context) : WebSocketServer(address) {

        override fun onOpen(conn: WebSocket?, handshake: ClientHandshake?) {
            Log.d(TAG, "New MCP connection: ${conn?.remoteSocketAddress}")

            // Send server capabilities
            val capabilities = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("method", "initialize")
                put("params", JSONObject().apply {
                    put("protocolVersion", "2024-11-05")
                    put("capabilities", JSONObject().apply {
                        put("tools", JSONObject())
                        put("resources", JSONObject())
                    })
                    put("serverInfo", JSONObject().apply {
                        put("name", "CoreMind MCP Server")
                        put("version", "1.0.0")
                    })
                })
            }
            conn?.send(capabilities.toString())
        }

        override fun onClose(conn: WebSocket?, code: Int, reason: String?, remote: Boolean) {
            Log.d(TAG, "MCP connection closed: $reason")
        }

        override fun onMessage(conn: WebSocket?, message: String?) {
            Log.d(TAG, "Received MCP message: $message")

            try {
                val jsonMessage = JSONObject(message ?: "")
                val method = jsonMessage.optString("method")
                val id = jsonMessage.opt("id")

                when (method) {
                    "tools/list" -> handleToolsList(conn, id)
                    "tools/call" -> handleToolCall(conn, jsonMessage, id)
                    "resources/list" -> handleResourcesList(conn, id)
                    "resources/read" -> handleResourceRead(conn, jsonMessage, id)
                    else -> {
                        sendError(conn, id, -32601, "Method not found: $method")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing message: ${e.message}")
                sendError(conn, null, -32700, "Parse error")
            }
        }

        override fun onError(conn: WebSocket?, ex: Exception?) {
            Log.e(TAG, "MCP Server error: ${ex?.message}")
        }

        override fun onStart() {
            Log.d(TAG, "MCP WebSocket server started")
        }

        private fun handleToolsList(conn: WebSocket?, id: Any?) {
            val response = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("id", id)
                put("result", JSONObject().apply {
                    put("tools", listOf(
                        JSONObject().apply {
                            put("name", "launch_app")
                            put("description", "Launch an Android application")
                            put("inputSchema", JSONObject().apply {
                                put("type", "object")
                                put("properties", JSONObject().apply {
                                    put("package_name", JSONObject().apply {
                                        put("type", "string")
                                        put("description", "Package name of the app to launch")
                                    })
                                })
                                put("required", listOf("package_name"))
                            })
                        },
                        JSONObject().apply {
                            put("name", "get_app_info")
                            put("description", "Get information about installed apps")
                            put("inputSchema", JSONObject().apply {
                                put("type", "object")
                                put("properties", JSONObject())
                            })
                        },
                        JSONObject().apply {
                            put("name", "load_ai_model")
                            put("description", "Load the AI model for inference")
                            put("inputSchema", JSONObject().apply {
                                put("type", "object")
                                put("properties", JSONObject())
                            })
                        },
                        JSONObject().apply {
                            put("name", "generate_response")
                            put("description", "Generate AI response from prompt")
                            put("inputSchema", JSONObject().apply {
                                put("type", "object")
                                put("properties", JSONObject().apply {
                                    put("prompt", JSONObject().apply {
                                        put("type", "string")
                                        put("description", "Input prompt for AI generation")
                                    })
                                    put("max_tokens", JSONObject().apply {
                                        put("type", "integer")
                                        put("description", "Maximum tokens to generate")
                                    })
                                })
                                put("required", listOf("prompt"))
                            })
                        }
                    ))
                })
            }
            conn?.send(response.toString())
        }

        private fun handleToolCall(conn: WebSocket?, message: JSONObject, id: Any?) {
            val params = message.optJSONObject("params")
            val toolName = params?.optString("name")
            val arguments = params?.optJSONObject("arguments")

            when (toolName) {
                "launch_app" -> {
                    val packageName = arguments?.optString("package_name")
                    val result = launchApp(packageName)
                    sendToolResult(conn, id, result)
                }
                "get_app_info" -> {
                    val result = getAppInfo()
                    sendToolResult(conn, id, result)
                }
                "load_ai_model" -> {
                    val result = loadAIModel()
                    sendToolResult(conn, id, result)
                }
                "generate_response" -> {
                    val prompt = arguments?.optString("prompt")
                    val maxTokens = arguments?.optInt("max_tokens", 100)
                    val result = generateResponse(prompt, maxTokens)
                    sendToolResult(conn, id, result)
                }
                else -> {
                    sendError(conn, id, -32602, "Unknown tool: $toolName")
                }
            }
        }

        private fun handleResourcesList(conn: WebSocket?, id: Any?) {
            val response = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("id", id)
                put("result", JSONObject().apply {
                    put("resources", listOf(
                        JSONObject().apply {
                            put("uri", "coremind://model/status")
                            put("name", "AI Model Status")
                            put("description", "Current status of the AI model")
                            put("mimeType", "application/json")
                        },
                        JSONObject().apply {
                            put("uri", "coremind://app/info")
                            put("name", "App Information")
                            put("description", "CoreMind application information")
                            put("mimeType", "application/json")
                        }
                    ))
                })
            }
            conn?.send(response.toString())
        }

        private fun handleResourceRead(conn: WebSocket?, message: JSONObject, id: Any?) {
            val params = message.optJSONObject("params")
            val uri = params?.optString("uri")

            val content = when (uri) {
                "coremind://model/status" -> getModelStatus()
                "coremind://app/info" -> getAppInfo()
                else -> "Resource not found"
            }

            val response = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("id", id)
                put("result", JSONObject().apply {
                    put("contents", listOf(
                        JSONObject().apply {
                            put("uri", uri)
                            put("mimeType", "application/json")
                            put("text", content)
                        }
                    ))
                })
            }
            conn?.send(response.toString())
        }

        private fun sendToolResult(conn: WebSocket?, id: Any?, result: String) {
            val response = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("id", id)
                put("result", JSONObject().apply {
                    put("content", listOf(
                        JSONObject().apply {
                            put("type", "text")
                            put("text", result)
                        }
                    ))
                })
            }
            conn?.send(response.toString())
        }

        private fun sendError(conn: WebSocket?, id: Any?, code: Int, message: String) {
            val response = JSONObject().apply {
                put("jsonrpc", "2.0")
                put("id", id)
                put("error", JSONObject().apply {
                    put("code", code)
                    put("message", message)
                })
            }
            conn?.send(response.toString())
        }

        // Tool implementations
        private fun launchApp(packageName: String?): String {
            return try {
                if (packageName.isNullOrEmpty()) {
                    "Error: Package name is required"
                } else {
                    val pm = context.packageManager
                    val intent = pm.getLaunchIntentForPackage(packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                        "Successfully launched $packageName"
                    } else {
                        "App not found: $packageName"
                    }
                }
            } catch (e: Exception) {
                "Error launching app: ${e.message}"
            }
        }

        private fun getAppInfo(): String {
            return try {
                val pm = context.packageManager
                val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                val appList = packages.map { app ->
                    JSONObject().apply {
                        put("packageName", app.packageName)
                        put("name", pm.getApplicationLabel(app).toString())
                        put("enabled", app.enabled)
                    }
                }
                JSONObject().apply {
                    put("installedApps", appList)
                    put("totalCount", appList.size)
                }.toString()
            } catch (e: Exception) {
                "Error getting app info: ${e.message}"
            }
        }

        private fun loadAIModel(): String {
            return try {
                // This would integrate with your existing model loading logic
                "AI model loading initiated"
            } catch (e: Exception) {
                "Error loading AI model: ${e.message}"
            }
        }

        private fun generateResponse(prompt: String?, maxTokens: Int?): String {
            return try {
                if (prompt.isNullOrEmpty()) {
                    "Error: Prompt is required"
                } else {
                    // This would integrate with your existing AI generation logic
                    "Generated response for: $prompt (max_tokens: $maxTokens)"
                }
            } catch (e: Exception) {
                "Error generating response: ${e.message}"
            }
        }

        private fun getModelStatus(): String {
            return JSONObject().apply {
                put("status", "ready")
                put("model_name", "Gemma 3-1B IT")
                put("memory_usage", "1.2GB")
                put("last_updated", System.currentTimeMillis())
            }.toString()
        }
    }
}
