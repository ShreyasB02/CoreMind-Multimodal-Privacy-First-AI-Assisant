import 'package:flutter/material.dart';
import '../core/services/model_downloader.dart';

class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback? onDownloadComplete;

  const ModelDownloadScreen({Key? key, this.onDownloadComplete}) : super(key: key);

  @override
  _ModelDownloadScreenState createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isLoading = true; // ✅ Added loading state
  bool _hasValidToken = false; // ✅ Added token state
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String _statusMessage = "Checking status..."; // ✅ Better initial message

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Checking model and token status...";
    });

    try {
      // ✅ Check both model and token status
      final isDownloaded = await ModelDownloader.isModelDownloaded();
      final hasToken = await ModelDownloader.hasValidToken();
      final fileSize = await ModelDownloader.getModelFileSize();

      setState(() {
        _isDownloaded = isDownloaded;
        _hasValidToken = hasToken;
        _isLoading = false;

        if (!hasToken) {
          _statusMessage = "⚠️ Hugging Face token required";
        } else if (isDownloaded) {
          _statusMessage = "✅ Model ready (${ModelDownloader.formatBytes(fileSize)})";
        } else {
          _statusMessage = "Model not downloaded";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error checking status: $e";
      });
    }
  }

  // ✅ Removed duplicate _formatBytes method since ModelDownloader already has it

  Future<void> _downloadModel() async {
    // ✅ Check token before downloading
    if (!_hasValidToken) {
      _showTokenDialog();
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = "Starting download...";
    });

    try {
      await ModelDownloader.downloadModel(
        onProgress: (downloaded, total, progress) {
          setState(() {
            _downloadedBytes = downloaded;
            _totalBytes = total;
            _progress = progress;
            _statusMessage = "Downloading... ${ModelDownloader.formatBytes(downloaded)}/${ModelDownloader.formatBytes(total)} (${(progress * 100).toStringAsFixed(1)}%)";
          });
        },
        onComplete: () {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
            _statusMessage = "✅ Download completed!";
          });

          if (widget.onDownloadComplete != null) {
            widget.onDownloadComplete!();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Model downloaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
            _statusMessage = "❌ Error: $error";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Download failed: $error"),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = "❌ Download error: $e";
      });
    }
  }

  // ✅ Added token input dialog
  void _showTokenDialog() {
    String token = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hugging Face Token Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To download the Gemma model, you need a Hugging Face token:'),
            SizedBox(height: 8),
            Text('1. Go to https://huggingface.co/settings/tokens',
                style: TextStyle(fontSize: 12)),
            Text('2. Create a token with "Read" permissions',
                style: TextStyle(fontSize: 12)),
            Text('3. Accept the Gemma license',
                style: TextStyle(fontSize: 12)),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Hugging Face Token',
                hintText: 'hf_...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) => token = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (token.isNotEmpty) {
                await ModelDownloader.saveHuggingFaceToken(token);
                Navigator.pop(context);
                _checkModelStatus(); // Refresh status
              }
            },
            child: Text('Save Token'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteModel() async {
    // ✅ Added confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Model'),
        content: Text('Are you sure you want to delete the downloaded model?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ModelDownloader.deleteModel();
      if (success) {
        setState(() {
          _isDownloaded = false;
          _statusMessage = "Model deleted";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Model deleted successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Model Manager'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLoading) // ✅ Loading indicator
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _isDownloaded ? Icons.check_circle :
                            _hasValidToken ? Icons.cloud_download : Icons.warning,
                            color: _isDownloaded ? Colors.green :
                            _hasValidToken ? Colors.orange : Colors.red,
                          ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gemma 3 1B IT Model', // ✅ Fixed model name
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (!_hasValidToken && !_isLoading)
                                Text(
                                  'Authentication required',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_statusMessage),

                    if (_isDownloading) ...[
                      SizedBox(height: 16),
                      LinearProgressIndicator(value: _progress),
                      SizedBox(height: 8),
                      Text(
                        "${(_progress * 100).toStringAsFixed(1)}%",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // ✅ Better button logic
            if (!_isDownloaded && !_isDownloading && !_isLoading)
              ElevatedButton.icon(
                onPressed: _downloadModel,
                icon: Icon(Icons.cloud_download),
                label: Text(_hasValidToken ? 'Download Model (~722 MB)' : 'Setup Token & Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasValidToken ? null : Colors.orange,
                ),
              ),

            if (_isDownloading)
              ElevatedButton(
                onPressed: null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Downloading...'),
                  ],
                ),
              ),

            if (_isDownloaded) ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onDownloadComplete != null) {
                    widget.onDownloadComplete!();
                  }
                  Navigator.pop(context);
                },
                icon: Icon(Icons.check),
                label: Text('Use Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _deleteModel,
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Delete Model', style: TextStyle(color: Colors.red)),
              ),
            ],

            // ✅ Added token management button
            if (!_isDownloading)
              TextButton.icon(
                onPressed: _showTokenDialog,
                icon: Icon(Icons.key),
                label: Text(_hasValidToken ? 'Update Token' : 'Set Token'),
              ),
          ],
        ),
      ),
    );
  }
}
