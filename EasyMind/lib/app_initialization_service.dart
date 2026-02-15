import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';
import 'memory_retention_system.dart';

/// Main App Initialization Service
/// Handles setup of memory retention features
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final NotificationService _notificationService = NotificationService();
  final MemoryRetentionSystem _retentionSystem = MemoryRetentionSystem();
  bool _isInitialized = false;

  /// Initialize all memory retention features
  Future<void> initializeApp() async {
    if (_isInitialized) return;

    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      print('✅ Memory retention features initialized successfully');
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing memory retention features: $e');
    }
  }

  /// Initialize user-specific features
  Future<void> initializeUser(String nickname) async {
    try {
      // Update user activity for smart scheduling
      await _retentionSystem.updateUserActivity(nickname);
      
      // Schedule smart reminders based on user patterns
      await _notificationService.scheduleSmartReminders(nickname);
      
      // Show lessons due notification if any
      await _notificationService.showLessonsDueNotification(nickname);
      
      print('✅ User features initialized for: $nickname');
    } catch (e) {
      print('❌ Error initializing user features: $e');
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      await _notificationService.cancelAllNotifications();
      _isInitialized = false;
      print('✅ App initialization service disposed');
    } catch (e) {
      print('❌ Error disposing app initialization service: $e');
    }
  }
}

/// Widget to wrap the app with memory retention initialization
class MemoryRetentionWrapper extends StatefulWidget {
  final Widget child;
  final String nickname;

  const MemoryRetentionWrapper({
    super.key,
    required this.child,
    required this.nickname,
  });

  @override
  State<MemoryRetentionWrapper> createState() => _MemoryRetentionWrapperState();
}

class _MemoryRetentionWrapperState extends State<MemoryRetentionWrapper> {
  final AppInitializationService _initService = AppInitializationService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _initService.initializeApp();
      await _initService.initializeUser(widget.nickname);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error initializing app: $e');
    }
  }

  @override
  void dispose() {
    _initService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFE9D5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF648BA2)),
              ),
              const SizedBox(height: 20),
              Text(
                'Initializing Memory Retention Features...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
