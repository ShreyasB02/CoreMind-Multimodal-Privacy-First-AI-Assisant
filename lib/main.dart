import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/permission_service.dart';
import 'features/voice/voice_service.dart';
import 'core/database/memory_database.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI for privacy-focused design
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
    ),
  );

  runApp(const CoreMindApp());
}

class CoreMindApp extends StatelessWidget {
  const CoreMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoreMind Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a1a),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final VoiceService _voiceService = VoiceService();
  final MemoryDatabase _memoryDb = MemoryDatabase();

  final bool _isInitializing = true;
  String _initStatus = 'Initializing CoreMind...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Step 1: Request permissions
      setState(() => _initStatus = 'Requesting permissions...');
      await PermissionService.requestVoicePermissions();

      // Step 2: Initialize database
      setState(() => _initStatus = 'Setting up secure storage...');
      await _memoryDb.database; // Initialize database

      // Step 3: Initialize voice service
      setState(() => _initStatus = 'Configuring voice processing...');
      bool voiceReady = await _voiceService.initialize();

      if (!voiceReady) {
        throw Exception('Voice service initialization failed');
      }

      // Step 4: Ready to go
      setState(() => _initStatus = 'Ready!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              voiceService: _voiceService,
              memoryDatabase: _memoryDb,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _initStatus = 'Initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CoreMind Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: const Icon(
                Icons.psychology,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            Text(
              'CoreMind',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Privacy-First AI Assistant',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[400],
              ),
            ),

            const SizedBox(height: 60),

            if (_isInitializing) ...[
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                _initStatus,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
