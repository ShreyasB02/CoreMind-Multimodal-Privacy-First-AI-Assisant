import 'mcp_client.dart';

class MCPService {
  static final MCPService _instance = MCPService._internal();
  factory MCPService() => _instance;
  MCPService._internal();

  MCPClient? _client;
  bool _serverRunning = false;

  // Start MCP server and optionally connect client
  Future<bool> startService({bool connectClient = false}) async {
    try {
      // Start server on Android
      final result = await MCPClient.startServer();
      _serverRunning = true;
      print('MCP Server: $result');

      if (connectClient) {
        // Connect client for testing
        _client = MCPClient();
        await _client!.connect();
      }

      return true;
    } catch (e) {
      print('Failed to start MCP service: $e');
      return false;
    }
  }

  // Stop MCP service
  Future<bool> stopService() async {
    try {
      _client?.disconnect();
      _client = null;

      if (_serverRunning) {
        await MCPClient.stopServer();
        _serverRunning = false;
      }

      return true;
    } catch (e) {
      print('Failed to stop MCP service: $e');
      return false;
    }
  }

  // Get service status
  Future<Map<String, dynamic>> getStatus() async {
    final serverStatus = await MCPClient.getServerStatus();
    return {
      ...serverStatus,
      'client_connected': _client != null,
    };
  }

  // Convenience methods for common operations
  Future<String> launchApp(String packageName) async {
    if (_client == null) throw Exception('MCP client not connected');
    return await _client!.callTool('launch_app', {'package_name': packageName});
  }

  Future<String> getAppInfo() async {
    if (_client == null) throw Exception('MCP client not connected');
    return await _client!.callTool('get_app_info', {});
  }

  Future<String> loadAIModel() async {
    if (_client == null) throw Exception('MCP client not connected');
    return await _client!.callTool('load_ai_model', {});
  }

  Future<String> generateResponse(String prompt, {int maxTokens = 100}) async {
    if (_client == null) throw Exception('MCP client not connected');
    return await _client!.callTool('generate_response', {
      'prompt': prompt,
      'max_tokens': maxTokens,
    });
  }
}
