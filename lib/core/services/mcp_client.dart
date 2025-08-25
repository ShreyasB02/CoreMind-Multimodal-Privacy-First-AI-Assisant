import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MCPClient {
  static const MethodChannel _channel = MethodChannel('com.coremind.ai/mcp');

  WebSocketChannel? _wsChannel;
  int _requestId = 1;
  final Map<int, Completer<dynamic>> _pendingRequests = {};

  // Start MCP server on Android
  static Future<String> startServer({int port = 8765}) async {
    try {
      final result = await _channel.invokeMethod('startMCPServer', {'port': port});
      return result as String;
    } catch (e) {
      throw Exception('Failed to start MCP server: $e');
    }
  }

  // Stop MCP server
  static Future<String> stopServer() async {
    try {
      final result = await _channel.invokeMethod('stopMCPServer');
      return result as String;
    } catch (e) {
      throw Exception('Failed to stop MCP server: $e');
    }
  }

  // Get MCP server status
  static Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final result = await _channel.invokeMethod('getMCPStatus');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw Exception('Failed to get MCP status: $e');
    }
  }

  // Connect to MCP server as client
  Future<void> connect({String host = 'localhost', int port = 8765}) async {
    try {
      final uri = Uri.parse('ws://$host:$port');
      _wsChannel = WebSocketChannel.connect(uri);

      _wsChannel!.stream.listen(
            (message) => _handleMessage(message),
        onError: (error) => print('WebSocket error: $error'),
        onDone: () => print('WebSocket connection closed'),
      );

      // Initialize connection
      await _sendRequest('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}, 'resources': {}},
        'clientInfo': {'name': 'CoreMind Flutter Client', 'version': '1.0.0'},
      });

      print('Connected to MCP server');
    } catch (e) {
      throw Exception('Failed to connect to MCP server: $e');
    }
  }

  // Disconnect from MCP server
  void disconnect() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _pendingRequests.clear();
  }

  // List available tools
  Future<List<dynamic>> listTools() async {
    final response = await _sendRequest('tools/list', {});
    return response['tools'] as List<dynamic>;
  }

  // Call a tool
  Future<String> callTool(String toolName, Map<String, dynamic> arguments) async {
    final response = await _sendRequest('tools/call', {
      'name': toolName,
      'arguments': arguments,
    });

    final content = response['content'] as List<dynamic>;
    if (content.isNotEmpty && content[0]['type'] == 'text') {
      return content[0]['text'] as String;
    }
    return 'No response';
  }

  // List available resources
  Future<List<dynamic>> listResources() async {
    final response = await _sendRequest('resources/list', {});
    return response['resources'] as List<dynamic>;
  }

  // Read a resource
  Future<String> readResource(String uri) async {
    final response = await _sendRequest('resources/read', {'uri': uri});
    final contents = response['contents'] as List<dynamic>;
    if (contents.isNotEmpty) {
      return contents[0]['text'] as String;
    }
    return 'No content';
  }

  // Send JSON-RPC request
  Future<dynamic> _sendRequest(String method, Map<String, dynamic> params) async {
    if (_wsChannel == null) {
      throw Exception('Not connected to MCP server');
    }

    final id = _requestId++;
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    _wsChannel!.sink.add(json.encode(request));

    return completer.future.timeout(
      Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('Request timeout', Duration(seconds: 30));
      },
    );
  }

  // Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);

      if (data['id'] != null) {
        // Response to a request
        final id = data['id'] as int;
        final completer = _pendingRequests.remove(id);

        if (completer != null) {
          if (data['error'] != null) {
            completer.completeError(Exception(data['error']['message']));
          } else {
            completer.complete(data['result']);
          }
        }
      } else {
        // Notification or other message
        print('Received notification: $data');
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }
}
