import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Offline Manager - Handles offline functionality for educational content
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  // Removed unused _prefs field
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Download educational game data for offline use
  Future<void> downloadGameData(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Download game configurations
      await _downloadGameConfigs(prefs);
      
      // Download user progress
      await _downloadUserProgress(nickname, prefs);
      
      // Download adaptive assessment data
      await _downloadAdaptiveData(nickname, prefs);
      
      // Mark as downloaded
      await prefs.setBool('${nickname}_offline_downloaded', true);
      await prefs.setString('${nickname}_last_download', DateTime.now().toIso8601String());
      
      print('✅ Offline data downloaded for $nickname');
    } catch (e) {
      print('❌ Error downloading offline data: $e');
    }
  }

  /// Check if offline data is available
  Future<bool> isOfflineDataAvailable(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${nickname}_offline_downloaded') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get offline game data
  Future<Map<String, dynamic>?> getOfflineGameData(String gameType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('offline_${gameType}_data');
      return data != null ? jsonDecode(data) : null;
    } catch (e) {
      print('Error getting offline game data: $e');
      return null;
    }
  }

  /// Save offline progress
  Future<void> saveOfflineProgress(String nickname, String gameType, Map<String, dynamic> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${nickname}_${gameType}_offline_progress';
      await prefs.setString(key, jsonEncode(progress));
      
      // Queue for sync when online
      await _queueForSync(nickname, gameType, progress);
    } catch (e) {
      print('Error saving offline progress: $e');
    }
  }

  /// Sync offline progress when online
  Future<void> syncOfflineProgress(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueue = prefs.getString('${nickname}_sync_queue');
      
      if (syncQueue != null) {
        final List<Map<String, dynamic>> queue = List<Map<String, dynamic>>.from(
          jsonDecode(syncQueue)
        );
        
        for (final item in queue) {
          await _syncProgressItem(nickname, item);
        }
        
        // Clear sync queue
        await prefs.remove('${nickname}_sync_queue');
        print('✅ Offline progress synced for $nickname');
      }
    } catch (e) {
      print('❌ Error syncing offline progress: $e');
    }
  }

  /// Download game configurations
  Future<void> _downloadGameConfigs(SharedPreferences prefs) async {
    try {
      // SayItRight words
      final sayItRightWords = [
        {'word': 'apple', 'difficulty': 'beginner', 'category': 'fruits'},
        {'word': 'ball', 'difficulty': 'beginner', 'category': 'toys'},
        {'word': 'cat', 'difficulty': 'beginner', 'category': 'animals'},
        {'word': 'dog', 'difficulty': 'beginner', 'category': 'animals'},
        {'word': 'elephant', 'difficulty': 'intermediate', 'category': 'animals'},
        {'word': 'fish', 'difficulty': 'beginner', 'category': 'animals'},
        {'word': 'guitar', 'difficulty': 'intermediate', 'category': 'instruments'},
        {'word': 'house', 'difficulty': 'beginner', 'category': 'places'},
        {'word': 'ice', 'difficulty': 'beginner', 'category': 'nature'},
        {'word': 'jungle', 'difficulty': 'intermediate', 'category': 'places'},
      ];
      
      await prefs.setString('offline_sayItRight_data', jsonEncode(sayItRightWords));
      
      // MatchTheSound sounds
      final matchTheSoundData = [
        {'sound': 'cat_meow', 'options': ['cat', 'dog', 'bird'], 'correct': 'cat'},
        {'sound': 'dog_bark', 'options': ['cat', 'dog', 'bird'], 'correct': 'dog'},
        {'sound': 'bird_chirp', 'options': ['cat', 'dog', 'bird'], 'correct': 'bird'},
        {'sound': 'cow_moo', 'options': ['cow', 'horse', 'sheep'], 'correct': 'cow'},
        {'sound': 'duck_quack', 'options': ['duck', 'goose', 'swan'], 'correct': 'duck'},
      ];
      
      await prefs.setString('offline_matchTheSound_data', jsonEncode(matchTheSoundData));
      
      // FormTheWord words
      final formTheWordData = [
        {'word': 'cat', 'letters': ['c', 'a', 't'], 'image': 'cat.png'},
        {'word': 'dog', 'letters': ['d', 'o', 'g'], 'image': 'dog.png'},
        {'word': 'sun', 'letters': ['s', 'u', 'n'], 'image': 'sun.png'},
        {'word': 'moon', 'letters': ['m', 'o', 'o', 'n'], 'image': 'moon.png'},
        {'word': 'star', 'letters': ['s', 't', 'a', 'r'], 'image': 'star.png'},
      ];
      
      await prefs.setString('offline_formTheWord_data', jsonEncode(formTheWordData));
      
      print('✅ Game configurations downloaded');
    } catch (e) {
      print('❌ Error downloading game configs: $e');
    }
  }

  /// Download user progress
  Future<void> _downloadUserProgress(String nickname, SharedPreferences prefs) async {
    try {
      // Download from Firebase
      final userStatsDoc = await _firestore.collection('userStats').doc(nickname).get();
      if (userStatsDoc.exists) {
        await prefs.setString('${nickname}_offline_userStats', jsonEncode(userStatsDoc.data()));
      }
      
      final studentDoc = await _firestore.collection('students')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      if (studentDoc.docs.isNotEmpty) {
        await prefs.setString('${nickname}_offline_student', jsonEncode(studentDoc.docs.first.data()));
      }
      
      print('✅ User progress downloaded');
    } catch (e) {
      print('❌ Error downloading user progress: $e');
    }
  }

  /// Download adaptive assessment data
  Future<void> _downloadAdaptiveData(String nickname, SharedPreferences prefs) async {
    try {
      final adaptiveDoc = await _firestore.collection('userAdaptiveLevels').doc(nickname).get();
      if (adaptiveDoc.exists) {
        await prefs.setString('${nickname}_offline_adaptive', jsonEncode(adaptiveDoc.data()));
      }
      
      print('✅ Adaptive data downloaded');
    } catch (e) {
      print('❌ Error downloading adaptive data: $e');
    }
  }

  /// Queue progress for sync
  Future<void> _queueForSync(String nickname, String gameType, Map<String, dynamic> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = '${nickname}_sync_queue';
      
      final existingQueue = prefs.getString(queueKey);
      List<Map<String, dynamic>> queue = [];
      
      if (existingQueue != null) {
        queue = List<Map<String, dynamic>>.from(jsonDecode(existingQueue));
      }
      
      queue.add({
        'gameType': gameType,
        'progress': progress,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(queueKey, jsonEncode(queue));
    } catch (e) {
      print('Error queuing for sync: $e');
    }
  }

  /// Sync individual progress item
  Future<void> _syncProgressItem(String nickname, Map<String, dynamic> item) async {
    try {
      final gameType = item['gameType'];
      final progress = item['progress'];
      
      // Sync based on game type
      switch (gameType) {
        case 'sayItRight':
          await _syncSayItRightProgress(nickname, progress);
          break;
        case 'matchTheSound':
          await _syncMatchTheSoundProgress(nickname, progress);
          break;
        case 'formTheWord':
          await _syncFormTheWordProgress(nickname, progress);
          break;
        default:
          print('Unknown game type for sync: $gameType');
      }
    } catch (e) {
      print('Error syncing progress item: $e');
    }
  }

  /// Sync SayItRight progress
  Future<void> _syncSayItRightProgress(String nickname, Map<String, dynamic> progress) async {
    try {
      // Save to memory retention
      await _firestore.collection('lessonRetention').add({
        'nickname': nickname,
        'moduleName': 'Speech Recognition',
        'lessonType': 'SayItRight Game (Offline)',
        'score': progress['score'] ?? 0,
        'totalQuestions': progress['totalQuestions'] ?? 1,
        'passed': progress['passed'] ?? false,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'nextReviewDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'reviewCount': 0,
        'masteryLevel': progress['passed'] == true ? 1 : 0,
        'retentionScore': progress['accuracy'] ?? 0.0,
        'offlineSync': true,
      });
      
      // Award XP if applicable
      if (progress['xpAwarded'] != null) {
        await _firestore.collection('userActivities').add({
          'nickname': nickname,
          'activity': progress['activity'] ?? 'speech_practice',
          'xpAwarded': progress['xpAwarded'],
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'metadata': {
            'module': 'sayItRight',
            'offlineSync': true,
            'accuracy': progress['accuracy'] ?? 0.0,
          },
        });
      }
      
      print('✅ SayItRight progress synced');
    } catch (e) {
      print('❌ Error syncing SayItRight progress: $e');
    }
  }

  /// Sync MatchTheSound progress
  Future<void> _syncMatchTheSoundProgress(String nickname, Map<String, dynamic> progress) async {
    try {
      await _firestore.collection('lessonRetention').add({
        'nickname': nickname,
        'moduleName': 'Sound Recognition',
        'lessonType': 'MatchTheSound Game (Offline)',
        'score': progress['score'] ?? 0,
        'totalQuestions': progress['totalQuestions'] ?? 1,
        'passed': progress['passed'] ?? false,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'nextReviewDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'reviewCount': 0,
        'masteryLevel': progress['passed'] == true ? 1 : 0,
        'retentionScore': progress['score'] ?? 0.0,
        'offlineSync': true,
      });
      
      print('✅ MatchTheSound progress synced');
    } catch (e) {
      print('❌ Error syncing MatchTheSound progress: $e');
    }
  }

  /// Sync FormTheWord progress
  Future<void> _syncFormTheWordProgress(String nickname, Map<String, dynamic> progress) async {
    try {
      await _firestore.collection('lessonRetention').add({
        'nickname': nickname,
        'moduleName': 'Word Formation',
        'lessonType': 'FormTheWord Game (Offline)',
        'score': progress['score'] ?? 0,
        'totalQuestions': progress['totalQuestions'] ?? 1,
        'passed': progress['passed'] ?? false,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'nextReviewDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'reviewCount': 0,
        'masteryLevel': progress['passed'] == true ? 1 : 0,
        'retentionScore': progress['score'] ?? 0.0,
        'offlineSync': true,
      });
      
      print('✅ FormTheWord progress synced');
    } catch (e) {
      print('❌ Error syncing FormTheWord progress: $e');
    }
  }

  /// Clear offline data
  Future<void> clearOfflineData(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('${nickname}_offline_') || 
            key.startsWith('offline_') ||
            key.startsWith('${nickname}_sync_queue')) {
          await prefs.remove(key);
        }
      }
      
      print('✅ Offline data cleared for $nickname');
    } catch (e) {
      print('❌ Error clearing offline data: $e');
    }
  }

  /// Get offline status
  Future<Map<String, dynamic>> getOfflineStatus(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getBool('${nickname}_offline_downloaded') ?? false;
      final lastDownload = prefs.getString('${nickname}_last_download');
      final syncQueue = prefs.getString('${nickname}_sync_queue');
      
      return {
        'downloaded': downloaded,
        'lastDownload': lastDownload,
        'pendingSync': syncQueue != null,
        'syncQueueSize': syncQueue != null ? jsonDecode(syncQueue).length : 0,
      };
    } catch (e) {
      return {
        'downloaded': false,
        'lastDownload': null,
        'pendingSync': false,
        'syncQueueSize': 0,
      };
    }
  }
}
