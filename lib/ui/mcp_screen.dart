import 'package:flutter/material.dart';
import '../core/services/mcp_service.dart';

class MCPTestScreen extends StatefulWidget {
  @override
  _MCPTestScreenState createState() => _MCPTestScreenState();
}

class _MCPTestScreenState extends State<MCPTestScreen> {
  final MCPService _mcpService = MCPService();
  String _status = "MCP Service stopped";
  String _result = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MCP Connectivity Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startService,
                            child: Text('Start MCP Server'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _stopService,
                            child: Text('Stop MCP Server'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Test MCP Tools:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testGetAppInfo,
              child: Text('Get App Info'),
            ),
            ElevatedButton(
              onPressed: _testLaunchApp,
              child: Text('Launch Calculator'),
            ),
            ElevatedButton(
              onPressed: _testAIGeneration,
              child: Text('Test AI Generation'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(_result, style: TextStyle(fontFamily: 'monospace')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startService() async {
    final success = await _mcpService.startService(connectClient: true);
    final status = await _mcpService.getStatus();
    setState(() {
      _status = success ? "MCP Service running" : "Failed to start";
      _result = "Service Status:\n${status.toString()}";
    });
  }

  Future<void> _stopService() async {
    await _mcpService.stopService();
    setState(() {
      _status = "MCP Service stopped";
      _result = "";
    });
  }

  Future<void> _testGetAppInfo() async {
    try {
      final result = await _mcpService.getAppInfo();
      setState(() {
        _result = "App Info:\n$result";
      });
    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    }
  }

  Future<void> _testLaunchApp() async {
    try {
      final result = await _mcpService.launchApp('com.android.calculator2');
      setState(() {
        _result = "Launch Result:\n$result";
      });
    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    }
  }

  Future<void> _testAIGeneration() async {
    try {
      final result = await _mcpService.generateResponse("What is artificial intelligence?");
      setState(() {
        _result = "AI Response:\n$result";
      });
    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    }
  }
}
