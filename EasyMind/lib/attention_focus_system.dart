import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Attention and Focus Management System for EasyMind App
/// Helps maintain learner engagement through interactive elements, timers, and breaks
class AttentionFocusSystem {
  static final AttentionFocusSystem _instance = AttentionFocusSystem._internal();
  factory AttentionFocusSystem() => _instance;
  AttentionFocusSystem._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts _flutterTts = FlutterTts();

  // Focus session settings
  static const int _defaultFocusDuration = 15; // minutes
  static const int _maxConsecutiveSessions = 3;

  // Current session state
  DateTime? _sessionStartTime;
  DateTime? _lastBreakTime;
  int _consecutiveSessions = 0;
  bool _isOnBreak = false;
  bool _isSessionActive = false;

  /// Initialize the attention system
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _loadUserPreferences();
  }

  /// Start a new focus session
  Future<void> startFocusSession({
    required String nickname,
    required String moduleName,
    required String lessonType,
  }) async {
    if (_isSessionActive) return;

    _sessionStartTime = DateTime.now();
    _isSessionActive = true;
    _isOnBreak = false;

    // Speak encouragement
    // Voice announcement disabled for immediate modal display
    // await _flutterTts.speak(
    //   "Great! Let's focus and learn together! 🌟 You can do this! Take your time and have fun!"
    // );

    // Save session start
    await _saveFocusSession(nickname, moduleName, lessonType, 'started');
  }

  /// End the current focus session
  Future<void> endFocusSession({
    required String nickname,
    required String moduleName,
    required String lessonType,
    bool completed = true,
  }) async {
    if (!_isSessionActive) return;

    final sessionDuration = DateTime.now().difference(_sessionStartTime!);

    _isSessionActive = false;
    _consecutiveSessions++;

    // Save session end
    await _saveFocusSession(
      nickname, 
      moduleName, 
      lessonType, 
      completed ? 'completed' : 'abandoned',
      duration: sessionDuration.inMinutes,
    );

    // Check if break is needed
    if (_consecutiveSessions >= _maxConsecutiveSessions) {
      await _suggestBreak(nickname);
    } else {
      // Voice announcement disabled for immediate modal display
      // await _flutterTts.speak(
      //   "Awesome work! 🌟 You're doing great! Keep up the amazing learning!"
      // );
    }
  }

  /// Suggest a break to the user
  Future<void> _suggestBreak(String nickname) async {
    _consecutiveSessions = 0;
    _isOnBreak = true;
    _lastBreakTime = DateTime.now();

    // Voice announcement disabled for immediate modal display
    // await _flutterTts.speak(
    //   "Hey there! 🌟 You've been learning so well! Let's take a fun little break! "
    //   "Stretch your arms, take a deep breath, and get ready for more awesome learning!"
    // );

    // Save break session
    await _saveBreakSession(nickname);
  }

  /// End the current break
  Future<void> endBreak(String nickname) async {
    if (!_isOnBreak) return;

    final breakDuration = DateTime.now().difference(_lastBreakTime!);

    _isOnBreak = false;

    // Voice announcement disabled for immediate modal display
    // await _flutterTts.speak(
    //   "Break time is over! 🌟 Are you ready to learn more amazing things? Let's go!"
    // );

    // Save break completion
    await _saveBreakSession(nickname, completed: true, duration: breakDuration.inMinutes);
  }

  /// Get current focus status
  FocusStatus getCurrentStatus() {
    if (_isOnBreak) {
      return FocusStatus.onBreak;
    } else if (_isSessionActive) {
      return FocusStatus.focused;
    } else {
      return FocusStatus.idle;
    }
  }

  /// Get session duration
  Duration? getSessionDuration() {
    if (_sessionStartTime != null && _isSessionActive) {
      return DateTime.now().difference(_sessionStartTime!);
    }
    return null;
  }

  /// Get break duration
  Duration? getBreakDuration() {
    if (_lastBreakTime != null && _isOnBreak) {
      return DateTime.now().difference(_lastBreakTime!);
    }
    return null;
  }

  /// Get focus statistics for a user
  Future<FocusStatistics> getUserFocusStats(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('focusSessions')
          .where('nickname', isEqualTo: nickname)
          .get();

      int totalSessions = 0;
      int completedSessions = 0;
      int totalFocusTime = 0;
      int totalBreakTime = 0;
      double averageSessionLength = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalSessions++;
        
        if (data['status'] == 'completed') {
          completedSessions++;
        }
        
        if (data['duration'] != null) {
          totalFocusTime += data['duration'] as int;
        }
      }

      // Get break sessions
      final breakQuerySnapshot = await _firestore
          .collection('breakSessions')
          .where('nickname', isEqualTo: nickname)
          .get();

      for (var doc in breakQuerySnapshot.docs) {
        final data = doc.data();
        if (data['duration'] != null) {
          totalBreakTime += data['duration'] as int;
        }
      }

      averageSessionLength = totalSessions > 0 ? totalFocusTime / totalSessions : 0;

      return FocusStatistics(
        totalSessions: totalSessions,
        completedSessions: completedSessions,
        totalFocusTime: totalFocusTime,
        totalBreakTime: totalBreakTime,
        averageSessionLength: averageSessionLength,
        focusScore: _calculateFocusScore(completedSessions, totalSessions, averageSessionLength),
      );
    } catch (e) {
      print('Error getting focus stats: $e');
      return FocusStatistics.empty();
    }
  }

  /// Calculate focus score based on completion rate and session length
  double _calculateFocusScore(int completed, int total, double avgLength) {
    if (total == 0) return 0;
    
    final completionRate = completed / total;
    final lengthScore = (avgLength / _defaultFocusDuration).clamp(0.0, 1.0);
    
    return ((completionRate * 0.7) + (lengthScore * 0.3)) * 100;
  }

  /// Save focus session to Firebase
  Future<void> _saveFocusSession(
    String nickname,
    String moduleName,
    String lessonType,
    String status, {
    int? duration,
  }) async {
    try {
      final sessionData = {
        'nickname': nickname,
        'moduleName': moduleName,
        'lessonType': lessonType,
        'status': status,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'duration': duration,
        'consecutiveSessions': _consecutiveSessions,
      };

      await _firestore.collection('focusSessions').add(sessionData);
    } catch (e) {
      print('Error saving focus session: $e');
    }
  }

  /// Save break session to Firebase
  Future<void> _saveBreakSession(
    String nickname, {
    bool completed = false,
    int? duration,
  }) async {
    try {
      final breakData = {
        'nickname': nickname,
        'status': completed ? 'completed' : 'started',
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'duration': duration,
      };

      await _firestore.collection('breakSessions').add(breakData);
    } catch (e) {
      print('Error saving break session: $e');
    }
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _consecutiveSessions = prefs.getInt('consecutive_sessions') ?? 0;
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  /// Reset session state
  void resetSession() {
    _sessionStartTime = null;
    _lastBreakTime = null;
    _consecutiveSessions = 0;
    _isOnBreak = false;
    _isSessionActive = false;
  }
}

/// Focus session data model
class FocusSession {
  final String nickname;
  final String moduleName;
  final String lessonType;
  final String status;
  final DateTime timestamp;
  final int? duration;
  final int consecutiveSessions;

  FocusSession({
    required this.nickname,
    required this.moduleName,
    required this.lessonType,
    required this.status,
    required this.timestamp,
    this.duration,
    required this.consecutiveSessions,
  });
}

/// Focus statistics data model
class FocusStatistics {
  final int totalSessions;
  final int completedSessions;
  final int totalFocusTime;
  final int totalBreakTime;
  final double averageSessionLength;
  final double focusScore;

  FocusStatistics({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalFocusTime,
    required this.totalBreakTime,
    required this.averageSessionLength,
    required this.focusScore,
  });

  factory FocusStatistics.empty() {
    return FocusStatistics(
      totalSessions: 0,
      completedSessions: 0,
      totalFocusTime: 0,
      totalBreakTime: 0,
      averageSessionLength: 0,
      focusScore: 0,
    );
  }
}

/// Focus status enum
enum FocusStatus {
  idle,
  focused,
  onBreak,
}
