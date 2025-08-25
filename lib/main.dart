import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../core/services/model_downloader.dart';
import '../ui/model_download_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ GALLERY-STYLE ERROR HANDLING IN MAIN
  try {
    runApp(CoreMindApp());
  } catch (e, st) {
    // Log error and show error widget instead of crashing
    debugPrint('🔍 ❌ App startup error: $e');
    debugPrint('🔍 Stack trace: $st');
    runApp(MaterialApp(
      home: AppStartupErrorWidget(error: e.toString()),
      debugShowCheckedModeBanner: false,
    ));
  }
}

/// ✅ GALLERY-STYLE ERROR WIDGET FOR STARTUP FAILURES
class AppStartupErrorWidget extends StatelessWidget {
  final String error;

  const AppStartupErrorWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'App Startup Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Restart the app
                  SystemNavigator.pop();
                },
                icon: Icon(Icons.restart_alt),
                label: Text('Restart App'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ GALLERY-STYLE MAIN APP WITH ERROR BOUNDARY
class CoreMindApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoreMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppInitializationWrapper(),
    );
  }
}

/// ✅ GALLERY-STYLE INITIALIZATION WRAPPER WITH LOADING STATES
class AppInitializationWrapper extends StatefulWidget {
  @override
  _AppInitializationWrapperState createState() => _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _initializationStatus = 'Starting CoreMind AI...';

  @override
  void initState() {
    super.initState();
    _performAppInitialization();
  }

  /// ✅ GALLERY-STYLE COMPREHENSIVE APP INITIALIZATION
  Future<void> _performAppInitialization() async {
    try {
      setState(() {
        _initializationStatus = 'Initializing system components...';
      });

      // Small delay to show loading state
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _initializationStatus = 'Setting up AI authentication...';
      });

      // Initialize token storage
      await ModelDownloader.saveHuggingFaceToken("HF_TOKEN");

      setState(() {
        _initializationStatus = 'Verifying system requirements...';
      });

      // Verify token and system readiness
      final hasValidToken = await ModelDownloader.hasValidToken();
      if (!hasValidToken) {
        throw Exception('Authentication setup failed');
      }

      setState(() {
        _initializationStatus = 'Initialization complete ✓';
      });

      await Future.delayed(Duration(milliseconds: 300));

      setState(() {
        _isInitialized = true;
      });

    } catch (e, st) {
      debugPrint('🔍 ❌ App initialization error: $e');
      debugPrint('🔍 Stack trace: $st');

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _initializationStatus = 'Initialization failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen();
    }

    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return CoreMindHomePage();
  }

  /// ✅ GALLERY-STYLE LOADING SCREEN
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'CoreMind AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'On-Device AI Intelligence',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              _initializationStatus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ GALLERY-STYLE ERROR SCREEN WITH RETRY
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Initialization Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                    _initializationStatus = 'Retrying initialization...';
                  });
                  _performAppInitialization();
                },
                icon: Icon(Icons.refresh),
                label: Text('Retry Initialization'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ MAIN HOME PAGE WITH GALLERY-STYLE ARCHITECTURE
class CoreMindHomePage extends StatefulWidget {
  @override
  _CoreMindHomePageState createState() => _CoreMindHomePageState();
}

class _CoreMindHomePageState extends State<CoreMindHomePage> {
  static const platform = MethodChannel('com.coremind.ai/gemma');

  // ✅ GALLERY-STYLE STATE MANAGEMENT
  bool _modelLoaded = false;
  bool _modelLoading = false;
  bool _modelDownloading = false;
  bool _modelValidating = false;
  double _downloadProgress = 0.0;
  String _statusMessage = "Checking AI model status...";
  String _detailedStatus = "";

  @override
  void initState() {
    super.initState();
    _initializeModelSystem();
  }

  /// ✅ GALLERY-STYLE MODEL SYSTEM INITIALIZATION
  Future<void> _initializeModelSystem() async {
    try {
      setState(() {
        _statusMessage = "Checking AI model availability...";
        _detailedStatus = "Scanning local storage for existing models";
      });

      // Check if model exists and is valid
      final isDownloaded = await ModelDownloader.isModelDownloaded();

      if (isDownloaded) {
        setState(() {
          _statusMessage = "AI model found - validating...";
          _detailedStatus = "Performing integrity and compatibility checks";
        });
        await _validateAndLoadModel();
      } else {
        setState(() {
          _statusMessage = "AI model not found";
          _detailedStatus = "Ready to download Gemma 3 1B IT model (~557 MB)";
        });
        await _initiateModelDownload();
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Model system initialization failed";
        _detailedStatus = "Error: $e";
      });
    }
  }

  /// ✅ GALLERY-STYLE MODEL VALIDATION AND LOADING
  Future<void> _validateAndLoadModel() async {
    try {
      setState(() {
        _modelValidating = true;
        _statusMessage = "Validating AI model...";
        _detailedStatus = "Checking file integrity and format compatibility";
      });

      // First validate using Flutter-side validation
      final flutterValidation = await ModelDownloader.isModelDownloaded();
      if (!flutterValidation) {
        throw Exception('Flutter-side validation failed');
      }

      // Then validate using native Android validation
      final nativeValidation = await platform.invokeMethod('validateModel');
      if (!nativeValidation) {
        setState(() {
          _statusMessage = "Model validation failed";
          _detailedStatus = "File may be corrupted - please re-download";
        });
        return;
      }

      setState(() {
        _statusMessage = "Validation successful - loading AI model...";
        _detailedStatus = "Initializing MediaPipe inference engine";
      });

      await _loadModelIntoEngine();
    } catch (e) {
      setState(() {
        _modelValidating = false;
        _statusMessage = "Model validation error";
        _detailedStatus = "Error: $e";
      });
    } finally {
      setState(() {
        _modelValidating = false;
      });
    }
  }

  /// ✅ GALLERY-STYLE MODEL LOADING INTO ENGINE
  Future<void> _loadModelIntoEngine() async {
    try {
      setState(() {
        _modelLoading = true;
        _statusMessage = "Loading AI model into engine...";
        _detailedStatus = "This may take a moment for large models";
      });

      final result = await platform.invokeMethod('loadModel');

      setState(() {
        _modelLoaded = result;
        _modelLoading = false;
        _statusMessage = result ? "🎉 AI Model Ready!" : "Failed to load model";
        _detailedStatus = result
            ? "Gemma 3 1B IT model loaded and ready for inference"
            : "Model loading failed - check device memory and model format";
      });
    } on PlatformException catch (e) {
      setState(() {
        _modelLoading = false;
        _statusMessage = "Model loading error";
        _detailedStatus = "Platform error: ${e.message}";
      });
    }
  }

  /// ✅ GALLERY-STYLE AUTOMATIC MODEL DOWNLOAD
  Future<void> _initiateModelDownload() async {
    try {
      setState(() {
        _modelDownloading = true;
        _statusMessage = "Starting AI model download...";
        _detailedStatus = "Preparing download from Hugging Face repository";
      });

      await ModelDownloader.downloadModel(
        onProgress: (downloaded, total, progress) {
          setState(() {
            _downloadProgress = progress;
            _statusMessage = "Downloading AI model...";
            _detailedStatus = "${(progress * 100).toStringAsFixed(1)}% - "
                "${ModelDownloader.formatBytes(downloaded)}/"
                "${ModelDownloader.formatBytes(total)} - "
                "ETA: ${_calculateETA(downloaded, total, progress)}";
          });
        },
        onComplete: () async {
          setState(() {
            _modelDownloading = false;
            _statusMessage = "Download completed - validating...";
            _detailedStatus = "Verifying downloaded model integrity";
          });
          await _validateAndLoadModel();
        },
        onError: (error) {
          setState(() {
            _modelDownloading = false;
            _statusMessage = "Download failed";
            _detailedStatus = "Error: $error";
          });
        },
      );
    } catch (e) {
      setState(() {
        _modelDownloading = false;
        _statusMessage = "Download initialization failed";
        _detailedStatus = "Error: $e";
      });
    }
  }

  /// ✅ GALLERY-STYLE ETA CALCULATION
  String _calculateETA(int downloaded, int total, double progress) {
    if (progress <= 0 || total <= 0) return "Calculating...";

    final remainingBytes = total - downloaded;
    final downloadSpeed = downloaded / DateTime.now().millisecondsSinceEpoch * 1000; // bytes per second

    if (downloadSpeed <= 0) return "Calculating...";

    final remainingSeconds = remainingBytes / downloadSpeed;

    if (remainingSeconds < 60) return "${remainingSeconds.toInt()}s";
    if (remainingSeconds < 3600) return "${(remainingSeconds / 60).toInt()}m";
    return "${(remainingSeconds / 3600).toInt()}h";
  }

  /// ✅ GALLERY-STYLE AI TESTING
  Future<void> _testAI() async {
    if (!_modelLoaded) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Generating AI response..."),
              SizedBox(height: 8),
              Text(
                "This may take a moment",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );

      final response = await platform.invokeMethod('generateResponse', {
        'prompt': 'Hello! Please introduce yourself as CoreMind AI, a helpful on-device AI assistant.',
        'maxTokens': 100,
      });

      Navigator.pop(context); // Close loading dialog

      // Show response dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.psychology, color: Colors.green),
              SizedBox(width: 8),
              Text('AI Response'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(response),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _testAI(); // Test again
              },
              child: Text('Test Again'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Error: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _testAI,
          ),
        ),
      );
    }
  }

  /// ✅ GALLERY-STYLE MANUAL DOWNLOAD SCREEN
  void _showManualDownloadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelDownloadScreen(
          onDownloadComplete: _validateAndLoadModel,
        ),
      ),
    );
  }

  /// ✅ GALLERY-STYLE RETRY FUNCTIONALITY
  Future<void> _retryModelSetup() async {
    setState(() {
      _modelLoaded = false;
      _modelLoading = false;
      _modelDownloading = false;
      _modelValidating = false;
      _downloadProgress = 0.0;
      _statusMessage = "Retrying model setup...";
      _detailedStatus = "";
    });

    await _initializeModelSystem();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CoreMind AI'),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          if (_modelLoaded)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showModelInfo(),
            ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ GALLERY-STYLE STATUS CARD
            _buildStatusCard(),
            SizedBox(height: 16),

            // ✅ GALLERY-STYLE ACTION BUTTONS
            _buildActionButtons(),

            // ✅ GALLERY-STYLE MODEL INFO (when ready)
            if (_modelLoaded) ...[
              SizedBox(height: 16),
              _buildModelInfoCard(),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ GALLERY-STYLE STATUS CARD
  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_detailedStatus.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          _detailedStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Progress bar for download
            if (_modelDownloading) ...[
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 8),
              Text(
                "${(_downloadProgress * 100).toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ GALLERY-STYLE STATUS ICON
  Widget _buildStatusIcon() {
    if (_modelLoading || _modelDownloading || _modelValidating) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_modelLoaded) {
      return Icon(Icons.check_circle, color: Colors.green, size: 28);
    }

    if (_statusMessage.contains("failed") || _statusMessage.contains("error")) {
      return Icon(Icons.error, color: Colors.red, size: 28);
    }

    return Icon(Icons.hourglass_empty, color: Colors.orange, size: 28);
  }

  /// ✅ GALLERY-STYLE ACTION BUTTONS
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Test AI button (when model is ready)
        if (_modelLoaded)
          ElevatedButton.icon(
            onPressed: _testAI,
            icon: Icon(Icons.psychology),
            label: Text("Test AI Intelligence"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        // Manual download button
        if (!_modelLoaded && !_modelLoading && !_modelDownloading && !_modelValidating)
          ElevatedButton.icon(
            onPressed: _showManualDownloadScreen,
            icon: Icon(Icons.cloud_download),
            label: Text("Manual Download & Setup"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        // Retry button (for failed states)
        if (!_modelLoaded && !_modelLoading && !_modelDownloading && !_modelValidating &&
            (_statusMessage.contains("failed") || _statusMessage.contains("error"))) ...[
          if (!_modelLoaded && !_modelLoading && !_modelDownloading && !_modelValidating)
            SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _retryModelSetup,
            icon: Icon(Icons.refresh),
            label: Text("Retry Setup"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  /// ✅ GALLERY-STYLE MODEL INFO CARD
  Widget _buildModelInfoCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.green.shade700),
                SizedBox(width: 8),
                Text(
                  "AI Model Information",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow("Model:", "Gemma 3 1B IT"),
            _buildInfoRow("Type:", "Instruction-tuned Language Model"),
            _buildInfoRow("Provider:", "Google AI Edge"),
            FutureBuilder<int>(
              future: ModelDownloader.getModelFileSize(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildInfoRow("Size:", ModelDownloader.formatBytes(snapshot.data!));
                }
                return _buildInfoRow("Size:", "Loading...");
              },
            ),
            _buildInfoRow("Status:", "Ready for inference ✓"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Model Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: Gemma 3 1B IT'),
            Text('Quantization: INT4'),
            Text('Runtime: MediaPipe GenAI'),
            Text('Platform: On-device Android'),
            SizedBox(height: 8),
            FutureBuilder<Map<String, dynamic>>(
              future: ModelDownloader.getStorageInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final info = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Storage Path:'),
                      Text(
                        info['model_file_path'] ?? 'Unknown',
                        style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  );
                }
                return Text('Loading storage info...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
